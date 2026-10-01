#!/usr/bin/env python3
"""verify-model.py: the deterministic build gate for a .scad model, in one command.

Compiles every value of the model's `part` selector with the OpenSCAD CLI (a full render,
so it catches what the GUI preview hides), measures each mesh, and prints one line per part.
Exit status 0 means every part passed. Python 3.8+ standard library only.

  python verify-model.py model.scad --build-volume 256x256x256 [--export DIR]
         [--parts a,b] [-D 'name=value'] [--openscad PATH] [-j 4] [--first-layer-z 0.1]

How each `part` value is judged, by its name:
  printable (anything else)  compiles clean, one connected body, manifold (every edge shared by
                             exactly two faces), rests on Z=0, fits the build volume
  plate_* / *_parts / *_coupons   a print layout: as printable, but several bodies are fine
  clash_* / *interference* / fit  an interference check (an intersection() of mating parts):
                             must render EMPTY; any solid is a collision, and faces that only
                             touch fail too (pose resting parts fudge apart)
  check_* / verify_* / debug_*    the author's diagnostics: must compile; may be empty
  all / assembly* / explode* / section* / view* / preview*   a view: must compile, not measured

"Compiles clean" means exit 0 and no ERROR/WARNING/assert/CGAL/manifold message on stderr
(ECHO lines are ignored). OpenSCAD's "(PolySet)" note is not a failure: current builds print
it for any bare primitive. Sloped overhang past 45 degrees and flat ceiling area are reported
for printable parts but don't fail the gate: short ceilings bridge, and some designs accept
supports. So is the first layer: the separate regions of each printable part's cross-section at
--first-layer-z (half the first layer), with their areas, ignoring slivers under 0.2 mm2 that no
slicer prints. A WARN line flags an island under 1 cm2 or a largest region under 20% of the
layer, but never fails the gate: four separate feet are fine. --export writes each
printable/layout part as a binary STL deliverable.
"""

import argparse
import concurrent.futures
import glob
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile

FATAL_RE = re.compile(r"^ERROR:|^WARNING:|^EXPORT-WARNING:|Assertion|CGAL error"
                      r"|not be a valid 2-manifold|may need repair|Simple:\s*no", re.I)
EMPTY_RE = re.compile(r"Current top level object is empty|top level geometry|No top.level", re.I)
KINDS = [("view", r"^(all$|assembl|explod|section|cutaway|preview|view)"),
         ("clash", r"^(fit|clash.*|.*interfer.*|.*collision.*)$"),
         ("diag", r"^(check|verify|debug|probe)|_check$"),
         ("layout", r"^(plate|layout|print|bed|build)|parts$|coupons$")]
NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")
ISLAND_MIN_CM2, ISLAND_SHARE = 1.0, 0.20  # first-layer WARN: an island this small, or largest below this share
SLIVER_MM2 = 0.2  # a first-layer region smaller than one extrusion width squared: no slicer prints it


def find_openscad(explicit=None):
    for c in (explicit, os.environ.get("OPENSCAD")):
        if c:
            return c
    for exe in ("openscad", "openscad-nightly"):
        if shutil.which(exe):
            return shutil.which(exe)
    cands = []
    for pat in (r"C:\Program Files\OpenSCAD*\openscad.exe", r"C:\Program Files (x86)\OpenSCAD*\openscad.exe",
                "/Applications/OpenSCAD*.app/Contents/MacOS/OpenSCAD"):
        cands += glob.glob(pat)
    return max(cands, key=lambda p: re.findall(r"\d{4}\.\d\d\.\d\d", p) or ["0"]) if cands else None


def discover_parts(src):
    """The part selector's values, default first: `part == "x"` comparisons plus the names
    listed in the comment on the `part = "...";` line (and comment lines right after it)."""
    code = re.sub(r"//[^\n]*", "", src)
    m = re.search(r'^\s*part\s*=\s*"([^"]*)"', code, re.M)
    found = [m.group(1)] if m else []
    for pat in (r'\bpart\s*==\s*"([^"]+)"', r'"([^"]+)"\s*==\s*part\b'):
        found += re.findall(pat, code)
    lines = src.splitlines()
    for i, line in enumerate(lines):
        c = re.match(r'^\s*part\s*=\s*"[^"]*"\s*;\s*//(.*)$', line)
        if c:
            text = [c.group(1)]
            for nxt in lines[i + 1:]:
                cm = re.match(r"^\s*//(.*)$", nxt)
                if not cm:
                    break
                text.append(cm.group(1))
            blob = " ".join(text)
            toks = re.findall(r'"([^"]+)"', blob) or re.split(r"[|,\s]+", blob)
            listed = [t.strip(" .;:") for t in toks if NAME_RE.match(t.strip(" .;:"))]
            if listed and (not found or found[0] in listed):  # a list of names, not prose
                found += listed
            break
    return list(dict.fromkeys(found))


def kind_of(part):
    for kind, pat in KINDS:
        if part is not None and re.search(pat, part, re.I):
            return kind
    return "printable"


def read_stl(path):
    """ASCII or binary STL -> list of 9-tuples. ASCII keeps the exact coordinates, so edge
    matching is exact; binary rounds to float32 and can fake non-manifold edges."""
    with open(path, "rb") as f:
        data = f.read()
    if len(data) >= 84 and 84 + 50 * struct.unpack("<I", data[80:84])[0] == len(data):
        n = struct.unpack("<I", data[80:84])[0]
        return [struct.unpack_from("<12x9f", data, 84 + 50 * i) for i in range(n)]
    tris, cur = [], []
    for line in data.decode("ascii", "replace").splitlines():
        s = line.split()
        if s[:1] == ["vertex"]:
            cur += s[1:4]
            if len(cur) == 9:
                tris.append(tuple(cur))
                cur = []
    return tris


def measure(tris_text):
    """Mesh facts from exact-text triangles: bbox, bodies, bad edges, volume, overhang."""
    vid, parent, edges = {}, [], {}

    def idx(v):
        if v not in vid:
            vid[v] = len(parent)
            parent.append(len(parent))
        return vid[v]

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    tris = []
    for t in tris_text:
        ids = [idx(tuple(t[k:k + 3])) for k in (0, 3, 6)]
        for u, v in ((ids[0], ids[1]), (ids[1], ids[2]), (ids[2], ids[0])):
            edges[(min(u, v), max(u, v))] = edges.get((min(u, v), max(u, v)), 0) + 1
            ru, rv = root(u), root(v)
            if ru != rv:
                parent[ru] = rv
        tris.append([float(x) for x in t])
    zs = [t[k] for t in tris for k in (2, 5, 8)]
    mn = [min(t[k + a] for t in tris for k in (0, 3, 6)) for a in range(3)]
    mx = [max(t[k + a] for t in tris for k in (0, 3, 6)) for a in range(3)]
    zmin, vol, over, flat = min(zs), 0.0, 0.0, 0.0
    s45, s89 = math.sin(math.radians(45.5)), math.sin(math.radians(89))
    for t in tris:
        a, b, c = t[0:3], t[3:6], t[6:9]
        u = [b[i] - a[i] for i in range(3)]
        w = [c[i] - a[i] for i in range(3)]
        n = [u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0]]
        norm = math.sqrt(sum(x * x for x in n))
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
        if norm < 1e-12 or n[2] >= 0 or max(a[2], b[2], c[2]) <= zmin + 0.02:
            continue
        down = -n[2] / norm
        if down > s89:
            flat += norm / 2
        elif down > s45:
            over += norm / 2
    return {"size": [mx[i] - mn[i] for i in range(3)], "zmin": zmin, "volume": abs(vol),
            "bodies": len({root(i) for i in range(len(parent))}),
            "bad_edges": sum(1 for k in edges.values() if k != 2), "overhang": over, "ceiling": flat}


def first_layer(tris_text, z):
    """Areas (mm2, largest first) of the separate regions in the cross-section at height z.
    Each triangle crossing z gives a segment between points on two of its edges. A point is
    keyed by its edge's exact text vertices, so neighbouring triangles share it and the
    segments join into closed loops. Oriented by the face normal, a loop's shoelace area is
    positive round material and negative round a hole; a region is an outline plus the holes
    directly inside it."""
    parent, segs = {}, []

    def root(k):
        while parent[k] != k:
            parent[k] = parent[parent[k]]
            k = parent[k]
        return k

    for t in tris_text:
        v = [tuple(float(x) for x in t[k:k + 3]) for k in (0, 3, 6)]
        up = [p[2] > z for p in v]
        if all(up) or not any(up):
            continue
        keys, pts = [], []
        for i, j in ((0, 1), (1, 2), (2, 0)):
            if up[i] != up[j]:
                ka, kb, pa, pb = tuple(t[3 * i:3 * i + 3]), tuple(t[3 * j:3 * j + 3]), v[i], v[j]
                if kb < ka:
                    ka, kb, pa, pb = kb, ka, pb, pa
                f = (z - pa[2]) / (pb[2] - pa[2])
                keys.append((ka, kb))
                pts.append((pa[0] + f * (pb[0] - pa[0]), pa[1] + f * (pb[1] - pa[1])))
        nx = (v[1][1] - v[0][1]) * (v[2][2] - v[0][2]) - (v[1][2] - v[0][2]) * (v[2][1] - v[0][1])
        ny = (v[1][2] - v[0][2]) * (v[2][0] - v[0][0]) - (v[1][0] - v[0][0]) * (v[2][2] - v[0][2])
        (p, q), (kp, kq) = pts, keys
        if (q[0] - p[0]) * -ny + (q[1] - p[1]) * nx < 0:  # material on the left, outline CCW
            p, q = q, p
        segs.append((kp, p, q))
        for k in (kp, kq):
            parent.setdefault(k, k)
        parent[root(kp)] = root(kq)
    loops = {}
    for k, p, q in segs:
        lp = loops.setdefault(root(k), {"area": 0.0, "segs": [], "box": [p[0], p[1], p[0], p[1]]})
        lp["area"] += (p[0] * q[1] - q[0] * p[1]) / 2
        lp["segs"].append((p, q))
        b = lp["box"]
        b[:] = [min(b[0], p[0], q[0]), min(b[1], p[1], q[1]), max(b[2], p[0], q[0]), max(b[3], p[1], q[1])]
    loops = [lp for lp in loops.values() if abs(lp["area"]) > 1e-6]
    if sum(lp["area"] for lp in loops) < 0:  # the mesh winds the other way
        for lp in loops:
            lp["area"] = -lp["area"]
    outer = sorted((lp for lp in loops if lp["area"] > 0), key=lambda lp: lp["area"])
    areas = {id(lp): lp["area"] for lp in outer}
    for hole in (lp for lp in loops if lp["area"] < 0):
        hb, (x, y) = hole["box"], hole["segs"][0][0]
        for lp in outer:  # smallest outline containing the hole is its parent
            b = lp["box"]
            if b[0] <= hb[0] and b[1] <= hb[1] and b[2] >= hb[2] and b[3] >= hb[3] and sum(
                    1 for p, q in lp["segs"] if (p[1] > y) != (q[1] > y)
                    and p[0] + (y - p[1]) * (q[0] - p[0]) / (q[1] - p[1]) > x) % 2:
                areas[id(lp)] += hole["area"]
                break
    return sorted(areas.values(), reverse=True)


def report_first_layer(areas, z, info):
    """Append the first-layer regions to a part's info; return (info, WARN text or None)."""
    areas = [a for a in areas if a >= SLIVER_MM2]
    if not areas:
        return info + ", first layer: no material at Z=%g" % z, None
    cm2 = [a / 100 for a in areas]
    total = sum(cm2)
    if len(cm2) == 1:
        return info + ", first layer 1 region %.1f cm2" % total, None
    groups = {}
    for a in cm2:
        groups[round(a, 1)] = groups.get(round(a, 1), 0) + 1
    listed = ["%.1f%s" % (a, " x%d" % n if n > 1 else "") for a, n in sorted(groups.items(), reverse=True)]
    info += ", first layer %d regions %.1f cm2, largest %.0f%%: %s cm2" % (
        len(cm2), total, 100 * cm2[0] / total, ", ".join(listed[:12] + (["..."] if listed[12:] else [])))
    small = sum(1 for a in cm2 if a < ISLAND_MIN_CM2)
    if not small and cm2[0] >= ISLAND_SHARE * total:
        return info, None
    return info, ("first layer in %d separate regions%s, largest %.0f%% of %.1f cm2. Small islands "
                  "with free ends lift, worst in PETG and ABS: stand cuts on a sill of 3+ layers "
                  "instead of Z=0, or flare the foot. Fine if they are deliberate feet." % (
                      len(cm2), ", %d under %g cm2" % (small, ISLAND_MIN_CM2) if small else "",
                      100 * cm2[0] / total, total))


def write_binary_stl(tris_text, path):
    with open(path, "wb") as f:
        f.write(b"verify-model.py".ljust(80, b" ") + struct.pack("<I", len(tris_text)))
        for t in tris_text:
            f.write(struct.pack("<12f2x", 0, 0, 0, *[float(x) for x in t]))


def check_part(osc, scad, part, kind, bv, defines, tmp, export, timeout, layer_z):
    tag = re.sub(r"[^A-Za-z0-9_.-]+", "_", part or "model")
    stl = os.path.join(tmp, tag + ".stl")
    cmd = [osc, "--export-format", "asciistl", "-o", stl] + sum((["-D", d] for d in defines), [])
    if part is not None:
        cmd += ["-D", 'part="%s"' % part]
    try:
        p = subprocess.run(cmd + [scad], capture_output=True, text=True, timeout=timeout,
                           cwd=os.path.dirname(scad) or ".")
        code, err = p.returncode, p.stderr + p.stdout
    except subprocess.TimeoutExpired:
        return part, kind, False, "render timed out after %ss" % timeout, [], None
    echo = [ln[5:].strip() for ln in err.splitlines() if ln.startswith("ECHO:")]
    lines = [ln.strip() for ln in err.splitlines() if not ln.startswith("ECHO:")]
    empty = any(EMPTY_RE.search(ln) for ln in lines) or not (os.path.exists(stl) and os.path.getsize(stl) > 84)
    fatal = [ln for ln in lines if FATAL_RE.search(ln) and not EMPTY_RE.search(ln)]
    if fatal or (code != 0 and not empty):
        return part, kind, False, "; ".join(fatal[:3]) or err.strip()[-300:] or "exit %s" % code, echo, None
    if kind == "clash":
        if empty:
            return part, kind, True, "empty (no collision)", echo, None
        m = measure(read_stl(stl))
        if m["volume"] < 0.01 or min(m["size"]) < 0.001:
            return part, kind, False, ("faces touch (a zero-thickness intersection): pose parts that "
                                       "rest on each other fudge apart in the clash part, so empty "
                                       "proves there is no overlap"), echo, None
        return part, kind, False, "COLLISION: %.2f mm3 of overlap, %.1f x %.1f x %.1f mm" % (
            m["volume"], *m["size"]), echo, None
    if empty:
        return part, kind, kind == "diag", "renders empty", echo, None
    if kind == "view":
        return part, kind, True, "compiles", echo, None
    tris = read_stl(stl)
    m = measure(tris)
    sx, sy, sz = m["size"]
    probs = []
    if kind in ("printable", "diag") and m["bodies"] > 1:
        probs.append("%d separate bodies (a printed part must be one piece; name a multi-part "
                     "layout plate_* or *_parts)" % m["bodies"])
    if m["bad_edges"]:
        probs.append("%d non-manifold edges (solids touch on an edge: overlap them)" % m["bad_edges"])
    if kind != "diag" and abs(m["zmin"]) > 0.05:
        probs.append("not on the plate: lowest point at Z=%.2f" % m["zmin"])
    if kind != "diag" and bv and not (sz <= bv[2] + 0.01 and max(sx, sy) <= max(bv[:2]) + 0.01
                                      and min(sx, sy) <= min(bv[:2]) + 0.01):
        probs.append("exceeds the %gx%gx%g build volume" % tuple(bv))
    info = "%.1f x %.1f x %.1f mm, %d bod%s, %.0f mm3" % (sx, sy, sz, m["bodies"],
                                                         "y" if m["bodies"] == 1 else "ies", m["volume"])
    if kind != "diag":
        info += ", overhang>45deg %.0f mm2, flat ceilings %.0f mm2" % (m["overhang"], m["ceiling"])
    warn = None
    if kind == "printable" and abs(m["zmin"]) <= 0.05:
        info, warn = report_first_layer(first_layer(tris, m["zmin"] + layer_z), layer_z, info)
    if export and kind in ("printable", "layout") and not probs:
        os.makedirs(export, exist_ok=True)
        stem = os.path.splitext(os.path.basename(scad))[0]
        out = os.path.join(export, stem + ("-" + tag if part is not None else "") + ".stl")
        write_binary_stl(tris, out)
        info += " -> " + os.path.relpath(out)
    return part, kind, not probs, "; ".join(probs + [info]), echo, warn


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("scad")
    ap.add_argument("--build-volume", help="WxDxH in mm, e.g. 256x256x256")
    ap.add_argument("--parts", help="comma-separated part values (default: all discovered)")
    ap.add_argument("--export", metavar="DIR", help="write passing printable parts as binary STL here")
    ap.add_argument("-D", dest="defines", action="append", default=[], help="extra OpenSCAD -D (repeatable)")
    ap.add_argument("--openscad", help="OpenSCAD executable (default: $OPENSCAD, PATH, install dirs)")
    ap.add_argument("-j", type=int, default=min(4, os.cpu_count() or 2), help="parallel renders")
    ap.add_argument("--timeout", type=int, default=900, help="seconds per part")
    ap.add_argument("--first-layer-z", type=float, default=0.1, metavar="MM",
                    help="slice height for the first-layer island report: half the first layer (default 0.1)")
    a = ap.parse_args()
    osc = find_openscad(a.openscad)
    if not osc:
        sys.exit("OpenSCAD not found: install it (the nightly is best) or pass --openscad PATH")
    scad = os.path.abspath(a.scad)
    with open(scad, encoding="utf-8", errors="replace") as f:
        parts = [p.strip() for p in a.parts.split(",")] if a.parts else discover_parts(f.read())
    parts = parts or [None]
    bv = [float(x) for x in a.build_volume.lower().split("x")] if a.build_volume else None
    ver = subprocess.run([osc, "--version"], capture_output=True, text=True)
    print("OpenSCAD: %s (%s)" % ((ver.stderr or ver.stdout).strip().split("\n")[-1], osc))
    tmp = tempfile.mkdtemp(prefix="verify_")
    try:
        with concurrent.futures.ThreadPoolExecutor(max(1, a.j)) as ex:
            res = list(ex.map(lambda p: check_part(osc, scad, p, kind_of(p), bv, a.defines, tmp,
                                                   a.export, a.timeout, a.first_layer_z), parts))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    echoes = list(dict.fromkeys(e for r in res for e in r[4]))
    if echoes:
        print("ECHO (%d unique):" % len(echoes))
        for e in echoes[:40]:
            print("  " + e[:200])
    w = max(len(str(r[0])) for r in res)
    for part, kind, ok, msg, _, _ in res:
        print("%s  %-*s  %-9s  %s" % ("PASS" if ok else "FAIL", w, part or "(no selector)", kind, msg))
    for part, kind, _, _, _, warn in res:
        if warn:
            print("WARN  %-*s  %-9s  %s" % (w, part or "(no selector)", kind, warn))
    bad = [r for r in res if not r[2]]
    print("GATE: %s (%d of %d parts pass)" % ("PASS" if not bad else "FAIL", len(res) - len(bad), len(res)))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
