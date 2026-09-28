#!/usr/bin/env python3
"""Deterministic checker for a generated OpenSCAD model.

Independent of the agent that wrote the model: it compiles every `part=` value
itself with the OpenSCAD CLI, then measures the resulting meshes. Nothing here
calls a model, so results are reproducible and free.

Reports, per part:
  compile   exit code, wall time, fatal stderr lines (same phrases as the
            skill's verification gate), warning count
  mesh      bbox, volume, surface area, shells (disconnected bodies),
            non-manifold edges, bed-contact area, overhang area past 45/60 deg
            from vertical (flat ceilings split out, since short ones bridge)
and, for the file as a whole, conformance to the skill's file structure
(headers, PRINT SETTINGS fields, asserts, $fn, fudge, part selector).

Usage:
  python evals/bench/scadcheck.py MODEL.scad [--build-volume 256x256x256]
         [--parts a,b] [--json out.json] [--stl-dir DIR] [-j 2]
"""

import argparse
import concurrent.futures
import json
import math
import os
import re
import struct
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import find_openscad, openscad_version, read_text, save_json  # noqa: E402

# The skill's verification gate (verification.md 1a): any of these after
# dropping ECHO lines fails the part.
FATAL_RE = re.compile(
    r"^ERROR:|^WARNING:|^EXPORT-WARNING:|Assertion|CGAL error|not be a valid 2-manifold"
    r"|may need repair|Simple:\s*no|Current top level object is empty",
    re.I,
)
# verification.md also fails on "(PolySet)", but the nightly prints that for any
# bare primitive (a lone cube() or cylinder()), so here it is only reported;
# the mesh edge count below is the independent manifold test.
POLYSET_RE = re.compile(r"\(PolySet\)")
# Part names that show the assembly rather than a print-oriented part. They are
# compiled (they must build) but excluded from printability metrics.
NON_PRINT_RE = re.compile(
    r"^(all|assembl|explod|section|cut|preview|view|demo|display|installed|in[-_ ]?use|render)",
    re.I,
)
# Interference-check parts (an intersection() of mating parts) must render
# EMPTY: empty is the pass, any solid is a clash.
CLASH_RE = re.compile(r"^(fit|clash.*|.*interfer.*|.*collision.*)$", re.I)
# A multi-body part with a name like these lays several parts out on the plate.
# It must fit the bed, but counting it as a part would double every per-part metric.
LAYOUT_RE = re.compile(r"^(plate|layout|print|bed|build)|parts$|coupons$", re.I)
OVERHANG_LIMITS = (45, 60)
ANGLE_SLACK = 0.5  # degrees; faceting puts exact-45 chamfers at 45.0x
FLAT_DEG = 89.0
BED_TOL = 0.02  # mm above z-min that still counts as touching the plate


# --------------------------------------------------------------------------
# Part discovery and compilation
# --------------------------------------------------------------------------

PART_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")


def _listed_parts(src):
    """Part names listed in the comment on the `part = "...";` line and any
    comment-only lines straight after it (the skill's template convention,
    e.g. `part = "all"; // "all", "base", "lid"` or `// all | base | lid`).
    Catches models that dispatch through a helper like show_part(part)."""
    lines = src.splitlines()
    for i, line in enumerate(lines):
        m = re.match(r'^\s*part\s*=\s*"[^"]*"\s*;\s*//(.*)$', line)
        if not m:
            continue
        text = [m.group(1)]
        for nxt in lines[i + 1:]:
            c = re.match(r"^\s*//(.*)$", nxt)
            if not c:
                break
            text.append(c.group(1))
        blob = " ".join(text)
        quoted = re.findall(r'"([^"]+)"', blob)
        tokens = quoted or re.split(r"[|,\s]+", blob)
        return [t.strip(" .;:") for t in tokens if PART_NAME_RE.match(t.strip(" .;:"))]
    return []


def discover_parts(src):
    """Values the model's `part` selector accepts, default first."""
    code = re.sub(r"//[^\n]*", "", src)
    found = []
    m = re.search(r'^\s*part\s*=\s*"([^"]*)"', code, re.M)
    if m:
        found.append(m.group(1))
    for pat in (r'\bpart\s*==\s*"([^"]+)"', r'"([^"]+)"\s*==\s*part\b'):
        found.extend(re.findall(pat, code))
    # Names only listed in the comment count too (the selector may be dispatched
    # through a helper), but only if the default is among them: that separates a
    # list of part names from a prose comment like "// which part to show".
    listed = _listed_parts(src)
    if listed and (not found or found[0] in listed):
        found.extend(listed)
    seen, parts = set(), []
    for p in found:
        if p not in seen:
            seen.add(p)
            parts.append(p)
    return parts


def compile_part(binary, scad, part, outdir, timeout, summary_ok):
    tag = re.sub(r"[^A-Za-z0-9_.-]+", "_", part or "default")
    stl = os.path.join(outdir, tag + ".stl")
    # Text STL, not binary: binary rounds coordinates to float32, which merges
    # vertices a hair apart and reports false non-manifold edges. Text STL is also
    # what the skill's own edge check (verification.md 1g) reads.
    cmd = [binary, "-o", stl, "--export-format", "asciistl"]
    js = os.path.join(outdir, tag + ".summary.json")
    if summary_ok:
        cmd += ["--summary", "all", "--summary-file", js]
    if part is not None:
        cmd += ["-D", 'part="%s"' % part]
    scad = os.path.abspath(scad)
    cmd.append(scad)
    t0 = time.time()
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                              cwd=os.path.dirname(scad))
        code, stderr = proc.returncode, proc.stderr + proc.stdout
    except subprocess.TimeoutExpired:
        code, stderr = None, "TIMEOUT after %ss" % timeout
    secs = round(time.time() - t0, 2)
    lines = [ln for ln in stderr.splitlines() if not ln.startswith("ECHO:")]
    fatal = [ln.strip() for ln in lines if FATAL_RE.search(ln)]
    if code is None or (code != 0 and not fatal):
        fatal.append(stderr.strip()[-400:] or "exit %s" % code)
    res = {
        "part": part,
        "exit": code,
        "seconds": secs,
        "fatal": fatal[:20],
        "warnings": sum(1 for ln in lines if ln.startswith("WARNING:")),
        "polyset": any(POLYSET_RE.search(ln) for ln in lines),
        "echo": [ln[5:].strip() for ln in stderr.splitlines() if ln.startswith("ECHO:")][:50],
        "stl": stl if os.path.exists(stl) and os.path.getsize(stl) > 84 else None,
    }
    res["ok"] = code == 0 and res["stl"] is not None and not fatal
    return res


# --------------------------------------------------------------------------
# Mesh metrics (binary or ASCII STL)
# --------------------------------------------------------------------------

def read_stl(path):
    """Return a list of triangles, each a 9-tuple of floats."""
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        head = f.read(84)
        if len(head) == 84:
            (n,) = struct.unpack("<I", head[80:84])
            if 84 + 50 * n == size:
                data = f.read()
                unpack = struct.Struct("<12x9f2x").unpack_from
                return [unpack(data, i * 50) for i in range(n)]
    tris, cur = [], []
    with open(path, encoding="ascii", errors="replace") as f:
        for line in f:
            s = line.split()
            if s[:1] == ["vertex"]:
                cur.extend(float(v) for v in s[1:4])
                if len(cur) == 9:
                    tris.append(tuple(cur))
                    cur = []
    return tris


def mesh_metrics(tris):
    if not tris:
        return None
    xs = [t[i] for t in tris for i in (0, 3, 6)]
    ys = [t[i] for t in tris for i in (1, 4, 7)]
    zs = [t[i] for t in tris for i in (2, 5, 8)]
    mn = (min(xs), min(ys), min(zs))
    mx = (max(xs), max(ys), max(zs))
    zmin = mn[2]
    sin_lim = {d: math.sin(math.radians(d + ANGLE_SLACK)) for d in OVERHANG_LIMITS}
    sin_flat = math.sin(math.radians(FLAT_DEG))

    vid, parent = {}, []

    def vindex(v):
        i = vid.get(v)
        if i is None:
            i = vid[v] = len(parent)
            parent.append(i)
        return i

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    edges = {}
    area = vol = bed = flat = 0.0
    over = {d: 0.0 for d in OVERHANG_LIMITS}
    degenerate = 0
    for t in tris:
        a, b, c = (t[0], t[1], t[2]), (t[3], t[4], t[5]), (t[6], t[7], t[8])
        ia, ib, ic = vindex(a), vindex(b), vindex(c)
        for u, v in ((ia, ib), (ib, ic), (ic, ia)):
            k = (u, v) if u < v else (v, u)
            edges[k] = edges.get(k, 0) + 1
            ru, rv = find(u), find(v)
            if ru != rv:
                parent[ru] = rv
        ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
        cx, cy, cz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
        norm = math.sqrt(cx * cx + cy * cy + cz * cz)
        if norm < 1e-12:
            degenerate += 1
            continue
        ar = norm / 2.0
        area += ar
        vol += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
        nz = cz / norm
        if nz >= 0:
            continue
        if max(a[2], b[2], c[2]) <= zmin + BED_TOL:
            bed += ar
            continue
        down = -nz  # sin of the overhang angle measured from vertical
        for d in OVERHANG_LIMITS:
            if down > sin_lim[d]:
                over[d] += ar
        if down > sin_flat:
            flat += ar
    roots = {find(i) for i in range(len(parent))}
    bad_edges = sum(1 for n in edges.values() if n != 2)
    r1 = lambda x: round(x, 1)  # noqa: E731
    out = {
        "triangles": len(tris),
        "bbox_min": [round(v, 3) for v in mn],
        "bbox_size": [round(mx[i] - mn[i], 3) for i in range(3)],
        "volume_mm3": r1(abs(vol)),
        "area_mm2": r1(area),
        "shells": len(roots),
        "non_manifold_edges": bad_edges,
        "degenerate_triangles": degenerate,
        "bed_contact_mm2": r1(bed),
        "flat_ceiling_mm2": r1(flat),
        "on_plate": abs(zmin) < 0.05,
    }
    for d in OVERHANG_LIMITS:
        out["overhang_%d_mm2" % d] = r1(over[d])
        # Sloped overhang only: flat ceilings are reported separately because a
        # short one bridges fine and a long one needs judgement.
        out["overhang_%d_sloped_mm2" % d] = r1(over[d] - flat)
        out["overhang_%d_pct" % d] = round(100.0 * over[d] / area, 2) if area else 0.0
    return out


# --------------------------------------------------------------------------
# File-structure conformance (the skill's File Structure section)
# --------------------------------------------------------------------------

SECTIONS = {
    "description": r"===\s*DESCRIPTION\s*===",
    "print_settings": r"===\s*PRINT SETTINGS\s*===",
    "parameters": r"===\s*PARAMETERS\s*===",
    "derived_constants": r"===\s*DERIVED CONSTANTS\s*===",
    "modules": r"===\s*MODULES\s*===",
    "assembly_render": r"===\s*(ASSEMBLY|RENDER)[^=\n]*===",
}
PRINT_FIELDS = {
    "material": r"Material",
    "layer_height": r"Layer Height",
    "walls": r"(Walls|Perimeters)",
    "infill": r"Infill",
    "supports": r"Supports?",
    "orientation": r"Orientation",
    "notes": r"Notes",
}
DESCRIPTION_ITEMS = {
    "design_decisions": r"Design decisions",
    "terminology_map": r"Terminology",
    "common_modifications": r"Common modifications",
    "overall_dimensions": r"Overall dimensions",
    "coordinate_system": r"Coordinate system",
}
CONVENTIONS = {
    "nozzle_diameter": r"^\s*nozzle_diameter\s*=",
    "layer_height_param": r"^\s*layer_height\s*=",
    "fudge": r"^\s*fudge\s*=",
    "tolerance": r"^\s*\w*tol\w*\s*=",
    "ef_chamfer": r"^\s*\w*(ef_chamfer|elephant)\w*\s*=",
    "fn_preview_conditional": r"\$fn\s*=\s*\(?\s*\$preview\s*\?",
    "has_assert": r"\bassert\s*\(",
}
_SAFE_LITERALS = {"0", "1", "2", "0.5", "90", "180", "270", "360", "45", "-1"}


def _block(src, key):
    m = re.search(SECTIONS[key], src)
    if not m:
        return ""
    nxt = re.search(r"//\s*={2,}\s*[A-Z]", src[m.end():])
    return src[m.end(): m.end() + nxt.start()] if nxt else src[m.end():]


def structure_metrics(src):
    items = {}
    for k, pat in SECTIONS.items():
        items["section_" + k] = bool(re.search(pat, src))
    ps = _block(src, "print_settings")
    for k, pat in PRINT_FIELDS.items():
        items["print_" + k] = bool(re.search(r"^\s*//\s*" + pat + r"\b", ps, re.M | re.I))
    desc = _block(src, "description")
    for k, pat in DESCRIPTION_ITEMS.items():
        items["desc_" + k] = bool(re.search(pat, desc, re.I))
    for k, pat in CONVENTIONS.items():
        items["conv_" + k] = bool(re.search(pat, src, re.M))
    items["conv_part_selector"] = bool(discover_parts(src))

    lines = src.splitlines()
    code_lines = [ln for ln in lines if ln.strip() and not ln.strip().startswith("//")]
    mod = re.search(SECTIONS["modules"], src)
    body = src[mod.end():] if mod else src
    body = re.sub(r"//[^\n]*|/\*.*?\*/", "", body, flags=re.S)
    body = re.sub(r'"[^"\n]*"', "", body)
    body = re.sub(r"\$fn\s*=\s*[\d.]+", "", body)
    lits = re.findall(r"(?<![\w.$])-?(\d+\.\d*|\.\d+|\d+)(?![\w.])", body)
    magic = [x for x in lits if x not in _SAFE_LITERALS]
    body_loc = max(1, sum(1 for ln in body.splitlines() if ln.strip()))
    return {
        "bytes": len(src.encode("utf-8")),
        "lines": len(lines),
        "code_lines": len(code_lines),
        "comment_lines": len(lines) - len(code_lines) - sum(1 for ln in lines if not ln.strip()),
        "asserts": len(re.findall(r"\bassert\s*\(", src)),
        "echos": len(re.findall(r"\becho\s*\(", src)),
        "modules": len(re.findall(r"^\s*module\s+\w+", src, re.M)),
        "magic_numbers_per_100_loc": round(100.0 * len(magic) / body_loc, 1),
        "items": items,
        "score": round(sum(items.values()) / len(items), 3),
    }


# --------------------------------------------------------------------------
# Whole-file check
# --------------------------------------------------------------------------

def fits(size, volume):
    if not volume:
        return None
    xy = sorted(size[:2])
    bed = sorted(volume[:2])
    return xy[0] <= bed[0] + 1e-6 and xy[1] <= bed[1] + 1e-6 and size[2] <= volume[2] + 1e-6


def check_scad(scad, build_volume=None, parts=None, stl_dir=None, timeout=900, jobs=1,
               binary=None):
    binary = binary or find_openscad()
    src = read_text(scad)
    result = {"scad": os.path.abspath(scad), "structure": structure_metrics(src), "parts": {}}
    if not binary:
        result["error"] = "OpenSCAD not found (set $OPENSCAD)"
        result["summary"] = {"gate_pass": False}
        return result
    result["openscad"] = openscad_version(binary)
    try:
        help_text = subprocess.run([binary, "--help"], capture_output=True, text=True,
                                   timeout=60).stdout
    except (OSError, subprocess.TimeoutExpired):
        help_text = ""
    summary_ok = "--summary" in help_text
    names = parts if parts is not None else (discover_parts(src) or [None])
    outdir = stl_dir or tempfile.mkdtemp(prefix="scadcheck-")
    os.makedirs(outdir, exist_ok=True)

    def work(p):
        comp = compile_part(binary, scad, p, outdir, timeout, summary_ok)
        if p is not None and CLASH_RE.search(p):
            # OpenSCAD exits 1 on an empty top-level object, so judge by the message
            empty = not comp["stl"] and bool(comp["fatal"]) and all(
                "empty" in ln.lower() for ln in comp["fatal"])
            comp["ok"] = empty
            comp["fatal"] = [] if empty else (comp["fatal"] or ["interference: solid overlap found"])
            return p, {"compile": comp, "mesh": None, "printable": False, "clash_check": True}
        mesh = mesh_metrics(read_stl(comp["stl"])) if comp["stl"] else None
        printable = p is None or not NON_PRINT_RE.search(p)
        if mesh:
            mesh["fits_build_volume"] = fits(mesh["bbox_size"], build_volume)
        if not stl_dir and comp["stl"]:
            os.remove(comp["stl"])
            comp["stl"] = None
        return p, {"compile": comp, "mesh": mesh, "printable": printable}

    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
        for p, res in pool.map(work, names):
            result["parts"][p or "default"] = res

    for name, r in result["parts"].items():
        r["layout"] = bool(r["printable"] and r["mesh"] and r["mesh"]["shells"] > 1
                           and LAYOUT_RE.search(name))
    pr = printable_parts(result)
    s = {
        "gate_pass": all(r["compile"]["ok"] for r in result["parts"].values()),
        "parts_total": len(result["parts"]),
        "parts_failed": [k for k, r in result["parts"].items() if not r["compile"]["ok"]],
        "printable_parts": len(pr),
        "compile_seconds": round(sum(r["compile"]["seconds"] for r in result["parts"].values()), 1),
        "warnings": sum(r["compile"]["warnings"] for r in result["parts"].values()),
        "structure_score": result["structure"]["score"],
        "asserts": result["structure"]["asserts"],
    }
    if pr:
        every = [r for r in result["parts"].values() if r["printable"] and r["mesh"]]
        s["fits_build_volume"] = (None if build_volume is None
                                  else all(r["mesh"]["fits_build_volume"] for r in every))
        s["non_manifold_edges"] = sum(r["mesh"]["non_manifold_edges"] for r in pr)
        s["all_on_plate"] = all(r["mesh"]["on_plate"] for r in pr)
        tot_area = sum(r["mesh"]["area_mm2"] for r in pr)
        for d in OVERHANG_LIMITS:
            o = sum(r["mesh"]["overhang_%d_mm2" % d] for r in pr)
            s["overhang_%d_mm2" % d] = round(o, 1)
            s["overhang_%d_pct" % d] = round(100.0 * o / tot_area, 2) if tot_area else 0.0
            s["overhang_%d_sloped_mm2" % d] = round(
                sum(r["mesh"]["overhang_%d_sloped_mm2" % d] for r in pr), 1)
        s["flat_ceiling_mm2"] = round(sum(r["mesh"]["flat_ceiling_mm2"] for r in pr), 1)
        s["volume_mm3"] = round(sum(r["mesh"]["volume_mm3"] for r in pr), 1)
        s["min_bed_contact_mm2"] = min(r["mesh"]["bed_contact_mm2"] for r in pr)
    result["summary"] = s
    return result


def printable_parts(result):
    """Printable parts for per-part metrics: print layouts are left out when the
    individual parts they lay out are also selectable."""
    pr = [r for r in result["parts"].values() if r["printable"] and r["mesh"]]
    single = [r for r in pr if not r.get("layout")]
    return single or pr


def parse_volume(text):
    if not text:
        return None
    vals = [float(v) for v in re.split(r"[x,]", text)]
    if len(vals) != 3:
        raise argparse.ArgumentTypeError("build volume must be WxDxH")
    return vals


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scad")
    ap.add_argument("--build-volume", type=parse_volume, help="e.g. 256x256x256")
    ap.add_argument("--parts", help="comma-separated part values (default: auto-discover)")
    ap.add_argument("--stl-dir", help="keep exported STLs here")
    ap.add_argument("--json", help="write the full result here")
    ap.add_argument("--timeout", type=int, default=900, help="seconds per part")
    ap.add_argument("-j", "--jobs", type=int, default=1)
    args = ap.parse_args()
    parts = args.parts.split(",") if args.parts else None
    res = check_scad(args.scad, args.build_volume, parts, args.stl_dir, args.timeout, args.jobs)
    if args.json:
        save_json(args.json, res)
    s = res["summary"]
    print("%s  gate=%s  parts=%d  structure=%.2f  asserts=%d" % (
        os.path.basename(args.scad), "PASS" if s.get("gate_pass") else "FAIL",
        s.get("parts_total", 0), s.get("structure_score", 0), s.get("asserts", 0)))
    for name, r in res["parts"].items():
        c, m = r["compile"], r["mesh"] or {}
        print("  %-24s %s %6.1fs  bbox=%s  shells=%s  overhang45=%s mm2  bed=%s mm2%s" % (
            name[:24], "ok  " if c["ok"] else "FAIL", c["seconds"],
            "x".join("%.1f" % v for v in m.get("bbox_size", [])) or "-",
            m.get("shells", "-"), m.get("overhang_45_mm2", "-"), m.get("bed_contact_mm2", "-"),
            "  (print layout)" if r.get("layout") else "" if r["printable"] else "  (assembly view)"))
        for line in c["fatal"][:3]:
            print("      ! " + line[:160])
    if "error" in res:
        print(res["error"], file=sys.stderr)
    return 0 if s.get("gate_pass") else 1


if __name__ == "__main__":
    sys.exit(main())
