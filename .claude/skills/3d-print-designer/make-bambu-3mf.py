#!/usr/bin/env python3
"""
make-bambu-3mf.py — assemble a Bambu Studio *project* .3mf with print settings baked in.

WHY THIS EXISTS
---------------
OpenSCAD (and every mesh exporter) writes geometry-only files: an STL, or a bare
3MF whose ZIP contains just [Content_Types].xml, _rels/.rels and 3D/3dmodel.model.
Opening one in Bambu Studio drops it onto the plate with *default* settings, so the
user still has to dial in layer height / walls / infill / supports / material by hand.

A Bambu Studio project 3MF additionally stores the entire slicer configuration inside
the same ZIP — chiefly Metadata/project_settings.config, a flat JSON of ~500 keys.
When Bambu opens such a file it restores those settings automatically. This tool takes
an OpenSCAD-rendered mesh plus a chosen printer/process/filament and emits exactly that:
a project 3MF that opens in Bambu Studio with the print settings already applied.

HOW THE SETTINGS ARE SOURCED (official presets, bound by name)
--------------------------------------------------------------
The output does NOT embed a full slicer config. It writes a *lean* project_settings.config:
the identity ids (printer / process / filament preset names) plus only the process settings
the model overrides, listed in `different_settings_to_system`. On open, Bambu binds the
named SYSTEM presets from the user's own install — carrying their trusted, byte-identical
machine and filament G-code — and applies the project's overrides on top. This is the same
layering Bambu itself uses (printer -> print -> project -> filament).

Bambu's official profile JSONs (resources/profiles/BBL/{machine,process}/*.json, resolved
through their "inherits" chains) are read only to (a) look up identity values such as the
printer's declared default filament and bed size, and (b) decide which overrides genuinely
differ from the process preset so the "modified" markers are accurate. Nothing is copied
wholesale — that keeps the file small AND avoids Bambu's "customized preset - confirm the
G-code is safe" warning, which fires whenever an embedded preset isn't byte-identical to
the installed one (a from-profiles dump never quite is).

If Bambu Studio isn't installed (a server, a cloud session, a fresh machine), the identity
values come from BUILTIN_PRINTERS below instead: a table generated from those same official
machine profiles. Every override is then flagged, since there is no process preset to
compare against; flagging a key that happens to equal the preset is harmless. The file
binds the same named presets when it is opened on a machine that has Bambu Studio.
--base-3mf reuses an existing project's (full) config as the baseline instead.

The output is checked before the tool exits: the package structure always, and a round
trip through OpenSCAD's import() (lib3mf, the library slicers use) whenever OpenSCAD is
found. A failed check exits non-zero.

USAGE
-----
  python make-bambu-3mf.py --scad model.scad --printer P1S \
      --layer-height 0.2 --walls 4 --infill 20 --infill-pattern gyroid --supports off \
      --out model.3mf

  # --printer takes a short name (X1C, P1S, "A1 mini", "H2D 0.6") or the full preset name.
  # --process defaults to that printer's own 0.20mm preset; layer height is an override.
  # --openscad is found on PATH / in the usual install folders when omitted.
  # Mesh instead of .scad (skip OpenSCAD): --mesh model.3mf  or  --mesh model.stl
  # Reuse an existing project's settings as baseline: --base-3mf existing.3mf
  # Arbitrary extra override: --set brim_type=outer_only --set sparse_infill_density=15%

The tool is intentionally dependency-free (Python 3.8+ stdlib only).
"""

import argparse
import glob
import json
import os
import random
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import uuid
import zipfile
from pathlib import Path

# ----------------------------------------------------------------------------------
# Mesh loading — produce (vertices, triangles) where vertices is a list of (x,y,z)
# floats and triangles is a list of (i,j,k) vertex indices.
# ----------------------------------------------------------------------------------

_VERT_RE = re.compile(r'<vertex[^>]*\bx="([^"]+)"[^>]*\by="([^"]+)"[^>]*\bz="([^"]+)"')
_TRI_RE = re.compile(r'<triangle[^>]*\bv1="(\d+)"[^>]*\bv2="(\d+)"[^>]*\bv3="(\d+)"')


def load_mesh_from_3mf(path):
    """Extract indexed mesh from any 3MF (namespace-agnostic regex parse)."""
    with zipfile.ZipFile(path) as zf:
        # The primary model part is conventionally 3D/3dmodel.model, but be lenient.
        model_names = [n for n in zf.namelist() if n.lower().endswith("3dmodel.model")]
        if not model_names:
            model_names = [n for n in zf.namelist() if n.lower().endswith(".model")]
        if not model_names:
            raise ValueError(f"{path}: no .model part found inside 3MF")
        xml = zf.read(model_names[0]).decode("utf-8", "replace")
    verts = [(float(a), float(b), float(c)) for a, b, c in _VERT_RE.findall(xml)]
    tris = drop_degenerate([(int(a), int(b), int(c)) for a, b, c in _TRI_RE.findall(xml)])
    if not verts or not tris:
        raise ValueError(f"{path}: parsed {len(verts)} vertices / {len(tris)} triangles")
    return verts, tris


def drop_degenerate(tris):
    """Remove triangles that repeat a vertex index. Merging near-coincident vertices (the STL
    path below) can collapse a sliver triangle onto two corners, and lib3mf rejects the whole
    package for one such triangle ("Invalid Model Coordinate Indices"). They have no area, so
    dropping them leaves the surface unchanged."""
    return [t for t in tris if t[0] != t[1] and t[1] != t[2] and t[0] != t[2]]


def load_mesh_from_stl(path):
    """Parse binary or ASCII STL into an indexed mesh, deduplicating vertices."""
    data = Path(path).read_bytes()
    verts, tris = [], []
    index = {}

    def vid(x, y, z):
        key = (round(x, 5), round(y, 5), round(z, 5))
        i = index.get(key)
        if i is None:
            i = len(verts)
            index[key] = i
            verts.append((x, y, z))
        return i

    is_ascii = data[:5].lower() == b"solid" and b"facet" in data[:2048].lower()
    if is_ascii:
        nums = re.findall(rb"vertex\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)", data)
        for k in range(0, len(nums) - 2, 3):
            tri = [vid(*(float(v) for v in nums[k + o])) for o in range(3)]
            tris.append(tuple(tri))
    else:
        (n,) = struct.unpack("<I", data[80:84])
        off = 84
        for _ in range(n):
            if off + 50 > len(data):
                break
            tri = []
            for c in range(3):
                x, y, z = struct.unpack("<3f", data[off + 12 + c * 12: off + 24 + c * 12])
                tri.append(vid(x, y, z))
            tris.append(tuple(tri))
            off += 50
    tris = drop_degenerate(tris)
    if not verts or not tris:
        raise ValueError(f"{path}: parsed no geometry")
    return verts, tris


def render_scad(openscad, scad, defines):
    """Render a .scad to a temporary geometry 3MF via the OpenSCAD CLI, return its path."""
    tmp = Path(tempfile.mkdtemp(prefix="scad3mf_")) / "geometry.3mf"
    cmd = [openscad]
    for d in defines or []:
        cmd += ["-D", d]
    cmd += ["-o", str(tmp), str(scad)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 or not tmp.exists() or tmp.stat().st_size == 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit(f"OpenSCAD render failed (exit {proc.returncode})")
    return tmp


# ----------------------------------------------------------------------------------
# Official profile resolution
# ----------------------------------------------------------------------------------

DEFAULT_PROFILE_DIRS = [
    r"C:\Program Files\Bambu Studio\resources\profiles\BBL",
    r"C:\Program Files\BambuStudio\resources\profiles\BBL",
    os.path.expanduser("~/Library/Application Support/BambuStudio/system/BBL"),
    "/Applications/BambuStudio.app/Contents/Resources/profiles/BBL",
    os.path.expanduser("~/.config/BambuStudio/system/BBL"),
    "/usr/share/bambu-studio/resources/profiles/BBL",
]


def find_profiles_dir(explicit):
    if explicit:
        p = Path(explicit)
        return p if p.exists() else None
    for cand in DEFAULT_PROFILE_DIRS:
        if Path(cand).exists():
            return Path(cand)
    return None


# Identity values of every official BBL machine preset, generated from Bambu Studio's
# resources/profiles/BBL/machine/*.json (inherits chains resolved). Used when no profiles
# directory is installed, and to resolve short printer names. Columns:
#   printer_variant, nozzle count, printable area WxD x height, bed_exclude_area (WxD at the
#   front-left origin, "" = none), default_filament_profile, default_print_profile
BUILTIN_PRINTERS = {
    "Bambu Lab A1 0.2 nozzle": ("0.2", 1, "256x256x256", "", "Bambu PLA Basic @BBL A1 0.2 nozzle", "0.10mm Standard @BBL A1 0.2 nozzle"),
    "Bambu Lab A1 0.4 nozzle": ("0.4", 1, "256x256x256", "", "Bambu PLA Basic @BBL A1", "0.20mm Standard @BBL A1"),
    "Bambu Lab A1 0.6 nozzle": ("0.6", 1, "256x256x256", "", "Bambu PLA Basic @BBL A1", "0.30mm Strength @BBL A1 0.6 nozzle"),
    "Bambu Lab A1 0.8 nozzle": ("0.8", 1, "256x256x256", "", "Bambu PLA Basic @BBL A1", "0.40mm Standard @BBL A1 0.8 nozzle"),
    "Bambu Lab A1 mini 0.2 nozzle": ("0.2", 1, "180x180x180", "", "Bambu PLA Basic @BBL A1M 0.2 nozzle", "0.10mm Standard @BBL A1M 0.2 nozzle"),
    "Bambu Lab A1 mini 0.4 nozzle": ("0.4", 1, "180x180x180", "", "Bambu PLA Basic @BBL A1M", "0.20mm Standard @BBL A1M"),
    "Bambu Lab A1 mini 0.6 nozzle": ("0.6", 1, "180x180x180", "", "Bambu PLA Basic @BBL A1M", "0.30mm Standard @BBL A1M 0.6 nozzle"),
    "Bambu Lab A1 mini 0.8 nozzle": ("0.8", 1, "180x180x180", "", "Bambu PLA Basic @BBL A1M", "0.40mm Standard @BBL A1M 0.8 nozzle"),
    "Bambu Lab A2L 0.2 nozzle": ("0.2", 1, "330x320x325", "", "Bambu PLA Basic @BBL A2L 0.2 nozzle", "0.10mm Standard @BBL A2L 0.2 nozzle"),
    "Bambu Lab A2L 0.4 nozzle": ("0.4", 1, "330x320x325", "", "Bambu PLA Basic @BBL A2L 0.4 nozzle", "0.20mm Standard @BBL A2L"),
    "Bambu Lab A2L 0.6 nozzle": ("0.6", 1, "330x320x325", "", "Bambu PLA Basic @BBL A2L 0.6 nozzle", "0.30mm Standard @BBL A2L 0.6 nozzle"),
    "Bambu Lab A2L 0.8 nozzle": ("0.8", 1, "330x320x325", "", "Bambu PLA Basic @BBL A2L 0.8 nozzle", "0.40mm Standard @BBL A2L 0.8 nozzle"),
    "Bambu Lab H2C 0.2 nozzle": ("0.2", 2, "330x320x325", "", "Bambu PLA Basic @BBL H2C 0.2 nozzle", "0.10mm Standard @BBL H2C 0.2 nozzle"),
    "Bambu Lab H2C 0.4 nozzle": ("0.4", 2, "330x320x325", "", "Bambu PLA Basic @BBL H2C", "0.20mm Standard @BBL H2C"),
    "Bambu Lab H2C 0.6 nozzle": ("0.6", 2, "330x320x325", "", "Bambu PLA Basic @BBL H2C 0.6 nozzle", "0.30mm Standard @BBL H2C 0.6 nozzle"),
    "Bambu Lab H2C 0.8 nozzle": ("0.8", 2, "330x320x325", "", "Bambu PLA Basic @BBL H2C 0.8 nozzle", "0.40mm Standard @BBL H2C 0.8 nozzle"),
    "Bambu Lab H2D 0.2 nozzle": ("0.2", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2D 0.2 nozzle", "0.10mm Standard @BBL H2D 0.2 nozzle"),
    "Bambu Lab H2D 0.4 nozzle": ("0.4", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2D", "0.20mm Standard @BBL H2D"),
    "Bambu Lab H2D 0.6 nozzle": ("0.6", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2D 0.6 nozzle", "0.30mm Standard @BBL H2D 0.6 nozzle"),
    "Bambu Lab H2D 0.8 nozzle": ("0.8", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2D 0.8 nozzle", "0.40mm Standard @BBL H2D 0.8 nozzle"),
    "Bambu Lab H2D Pro 0.2 nozzle": ("0.2", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2DP 0.2 nozzle", "0.10mm Standard @BBL H2DP 0.2 nozzle"),
    "Bambu Lab H2D Pro 0.4 nozzle": ("0.4", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2DP", "0.20mm Standard @BBL H2DP"),
    "Bambu Lab H2D Pro 0.6 nozzle": ("0.6", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2DP 0.6 nozzle", "0.30mm Standard @BBL H2DP 0.6 nozzle"),
    "Bambu Lab H2D Pro 0.8 nozzle": ("0.8", 2, "350x320x325", "", "Bambu PLA Basic @BBL H2DP 0.8 nozzle", "0.40mm Standard @BBL H2DP 0.8 nozzle"),
    "Bambu Lab H2S 0.2 nozzle": ("0.2", 1, "340x320x340", "", "Bambu PLA Basic @BBL H2S 0.2 nozzle", "0.10mm Standard @BBL H2S 0.2 nozzle"),
    "Bambu Lab H2S 0.4 nozzle": ("0.4", 1, "340x320x340", "", "Bambu PLA Basic @BBL H2S", "0.20mm Standard @BBL H2S"),
    "Bambu Lab H2S 0.6 nozzle": ("0.6", 1, "340x320x340", "", "Bambu PLA Basic @BBL H2S 0.6 nozzle", "0.30mm Standard @BBL H2S 0.6 nozzle"),
    "Bambu Lab H2S 0.8 nozzle": ("0.8", 1, "340x320x340", "", "Bambu PLA Basic @BBL H2S 0.8 nozzle", "0.40mm Standard @BBL H2S 0.8 nozzle"),
    "Bambu Lab P1P 0.2 nozzle": ("0.2", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL P1P 0.2 nozzle", "0.10mm Standard @BBL P1P 0.2 nozzle"),
    "Bambu Lab P1P 0.4 nozzle": ("0.4", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL P1P", "0.20mm Standard @BBL P1P"),
    "Bambu Lab P1P 0.6 nozzle": ("0.6", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL P1P 0.6 nozzle", "0.30mm Standard @BBL P1P 0.6 nozzle"),
    "Bambu Lab P1P 0.8 nozzle": ("0.8", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL P1P", "0.40mm Standard @BBL P1P 0.8 nozzle"),
    "Bambu Lab P1S 0.2 nozzle": ("0.2", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.2 nozzle", "0.10mm Standard @BBL X1C 0.2 nozzle"),
    "Bambu Lab P1S 0.4 nozzle": ("0.4", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL P1S 0.4 nozzle", "0.20mm Standard @BBL X1C"),
    "Bambu Lab P1S 0.6 nozzle": ("0.6", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL P1S 0.6 nozzle", "0.30mm Standard @BBL X1C 0.6 nozzle"),
    "Bambu Lab P1S 0.8 nozzle": ("0.8", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.8 nozzle", "0.40mm Standard @BBL X1C 0.8 nozzle"),
    "Bambu Lab P2S 0.2 nozzle": ("0.2", 1, "256x256x256", "", "Bambu PLA Basic @BBL P2S 0.2 nozzle", "0.10mm Standard @BBL P2S 0.2 nozzle"),
    "Bambu Lab P2S 0.4 nozzle": ("0.4", 1, "256x256x256", "", "Bambu PLA Basic @BBL P2S", "0.20mm Standard @BBL P2S"),
    "Bambu Lab P2S 0.6 nozzle": ("0.6", 1, "256x256x256", "", "Bambu PLA Basic @BBL P2S 0.6 nozzle", "0.30mm Standard @BBL P2S 0.6 nozzle"),
    "Bambu Lab P2S 0.8 nozzle": ("0.8", 1, "256x256x256", "", "Bambu PLA Basic @BBL P2S 0.8 nozzle", "0.40mm Standard @BBL P2S 0.8 nozzle"),
    "Bambu Lab X1 0.2 nozzle": ("0.2", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.2 nozzle", "0.10mm Standard @BBL X1C 0.2 nozzle"),
    "Bambu Lab X1 0.4 nozzle": ("0.4", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1", "0.20mm Standard @BBL X1C"),
    "Bambu Lab X1 0.6 nozzle": ("0.6", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1", "0.30mm Standard @BBL X1 0.6 nozzle"),
    "Bambu Lab X1 0.8 nozzle": ("0.8", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1", "0.40mm Standard @BBL X1 0.8 nozzle"),
    "Bambu Lab X1 Carbon 0.2 nozzle": ("0.2", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.2 nozzle", "0.10mm Standard @BBL X1C 0.2 nozzle"),
    "Bambu Lab X1 Carbon 0.4 nozzle": ("0.4", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C", "0.20mm Standard @BBL X1C"),
    "Bambu Lab X1 Carbon 0.6 nozzle": ("0.6", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.6 nozzle", "0.30mm Standard @BBL X1C 0.6 nozzle"),
    "Bambu Lab X1 Carbon 0.8 nozzle": ("0.8", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.8 nozzle", "0.40mm Standard @BBL X1C 0.8 nozzle"),
    "Bambu Lab X1E 0.2 nozzle": ("0.2", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.2 nozzle", "0.10mm Standard @BBL X1C 0.2 nozzle"),
    "Bambu Lab X1E 0.4 nozzle": ("0.4", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C", "0.20mm Standard @BBL X1C"),
    "Bambu Lab X1E 0.6 nozzle": ("0.6", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C", "0.30mm Standard @BBL X1C 0.6 nozzle"),
    "Bambu Lab X1E 0.8 nozzle": ("0.8", 1, "256x256x250", "18x28", "Bambu PLA Basic @BBL X1C 0.8 nozzle", "0.40mm Standard @BBL X1C 0.8 nozzle"),
    "Bambu Lab X2D 0.2 nozzle": ("0.2", 2, "256x256x261", "", "Bambu PLA Basic @BBL X2D 0.2 nozzle", "0.10mm Standard @BBL X2D 0.2 nozzle"),
    "Bambu Lab X2D 0.4 nozzle": ("0.4", 2, "256x256x261", "", "Bambu PLA Basic @BBL X2D 0.4 nozzle", "0.20mm Standard @BBL X2D"),
    "Bambu Lab X2D 0.6 nozzle": ("0.6", 2, "256x256x261", "", "Bambu PLA Basic @BBL X2D 0.6 nozzle", "0.30mm Standard @BBL X2D 0.6 nozzle"),
    "Bambu Lab X2D 0.8 nozzle": ("0.8", 2, "256x256x261", "", "Bambu PLA Basic @BBL X2D 0.8 nozzle", "0.40mm Standard @BBL X2D 0.8 nozzle"),
}


def resolve_printer_name(name):
    """Map a short or loose name ('P1S', 'x1c', 'A1 mini 0.2', 'Bambu Lab H2D') onto the
    official machine preset name. An exact preset name is returned unchanged."""
    if name in BUILTIN_PRINTERS:
        return name
    s = name.lower().replace("bambu lab", "").replace("bambu", "").replace("nozzle", "")
    s = s.replace("x1 carbon", "x1c").replace("mini", " mini ").replace("pro", " pro ")
    m = re.search(r"\b(0\.[2468])\b", s)
    nozzle = m.group(1) if m else "0.4"
    if m:
        s = s[:m.start()] + s[m.end():]
    want = " ".join(s.split())
    for full in BUILTIN_PRINTERS:
        model = full[len("Bambu Lab "):full.rindex(" ", 0, full.rindex(" "))].lower()
        model = model.replace("x1 carbon", "x1c")
        if model == want and full.endswith(f" {nozzle} nozzle"):
            return full
    return name  # unknown here; may still exist in an installed profiles directory


def builtin_machine(printer):
    """The machine-profile keys this tool reads, from BUILTIN_PRINTERS (or None)."""
    row = BUILTIN_PRINTERS.get(printer)
    if not row:
        return None
    variant, nozzles, size, excl, fil, proc = row
    w, d, h = size.split("x")
    m = {"printer_model": printer[:printer.rindex(" ", 0, printer.rindex(" "))],
         "printer_variant": variant, "nozzle_diameter": [variant] * nozzles,
         "printable_area": ["0x0", f"{w}x0", f"{w}x{d}", f"0x{d}"], "printable_height": h,
         "default_filament_profile": [fil], "default_print_profile": proc,
         "bed_exclude_area": []}
    if excl:
        ew, ed = excl.split("x")
        m["bed_exclude_area"] = ["0x0", f"{ew}x0", f"{ew}x{ed}", f"0x{ed}"]
    return m


def find_openscad(explicit=None):
    """An OpenSCAD executable: the one given, $OPENSCAD, PATH, then the usual install
    folders (newest nightly first). None if there isn't one."""
    for c in (explicit, os.environ.get("OPENSCAD")):
        if c:
            return c
    for exe in ("openscad", "openscad-nightly"):
        hit = shutil.which(exe)
        if hit:
            return hit
    cands = []
    for pat in (r"C:\Program Files\OpenSCAD*\openscad.exe", r"C:\Program Files (x86)\OpenSCAD*\openscad.exe",
                "/Applications/OpenSCAD*.app/Contents/MacOS/OpenSCAD"):
        cands += glob.glob(pat)
    # newest dated build ("OpenSCAD-2026.06.19-x86-64") before the undated 2021 stable
    ver = lambda p: re.findall(r"\d{4}\.\d\d\.\d\d", p) or ["0"]  # noqa: E731
    return max(cands, key=ver) if cands else None


def _find_preset_file(profiles_dir, ptype, name):
    """Locate <name>.json for a preset type, tolerating flat or subdir layouts."""
    candidates = [
        profiles_dir / ptype / f"{name}.json",
        profiles_dir / f"{name}.json",
    ]
    for c in candidates:
        if c.exists():
            return c
    # last resort: recursive search (profiles ship with unique preset filenames)
    hits = list(profiles_dir.rglob(f"{name}.json"))
    return hits[0] if hits else None


def resolve_preset(profiles_dir, ptype, name, _seen=None):
    """Resolve a preset and its inherits-chain into one flat dict (parent first)."""
    _seen = _seen or set()
    if name in _seen:
        raise ValueError(f"inherits cycle at {name}")
    _seen.add(name)
    f = _find_preset_file(profiles_dir, ptype, name)
    if not f:
        raise FileNotFoundError(f"{ptype} preset not found: {name!r} under {profiles_dir}")
    data = json.loads(f.read_text(encoding="utf-8"))
    parent = data.get("inherits")
    merged = resolve_preset(profiles_dir, ptype, parent, _seen) if parent else {}
    for k, v in data.items():
        merged[k] = v  # child overrides parent; arrays replace wholesale
    return merged


def bed_from_printable_area(area):
    """Derive (x,y) bed size from a printable_area list like ['0x0','256x0','256x256','0x256']."""
    xs, ys = [], []
    for pt in area or []:
        if "x" in pt:
            a, b = pt.split("x")
            xs.append(float(a)); ys.append(float(b))
    if xs and ys:
        return max(xs), max(ys)
    return 256.0, 256.0


def rect_from_area(area):
    """Bounding rect (x0, y0, x1, y1) of an area list like ['0x0','18x0','18x28','0x28']."""
    xs, ys = [], []
    for pt in area or []:
        if "x" in pt:
            a, b = pt.split("x")
            xs.append(float(a)); ys.append(float(b))
    if not xs:
        return None
    return min(xs), min(ys), max(xs), max(ys)


def _hits_exclusion(px, py, w, h, excl, clearance):
    """True if a footprint centred at (px,py) overlaps the exclusion rect plus clearance."""
    if not excl:
        return False
    ex0, ey0, ex1, ey1 = excl
    if ex1 <= ex0 or ey1 <= ey0:
        return False
    return not (px - w / 2.0 >= ex1 + clearance or px + w / 2.0 <= ex0 - clearance
                or py - h / 2.0 >= ey1 + clearance or py + h / 2.0 <= ey0 - clearance)


def choose_placement(bed_x, bed_y, w, h, excl, scatter, scatter_max, seed, margin=8.0):
    """Pick where the part's footprint centre lands on the plate.

    Parts always landing dead centre wear one patch of the build plate, so by default this
    nudges each print somewhere else within whatever room the part leaves. The offset is
    bounded by the part's own size (a big part barely moves, a small one roams), clamped so
    the footprint keeps `margin` clear of every bed edge, and rejected if it would touch the
    printer's bed_exclude_area — on an X1/P1 that is the 18x28mm front-left corner reserved
    for the filament cutter, and a part parked there will not slice cleanly.

    Returns (cx, cy, (dx, dy)) where dx/dy are the offset from plate centre.
    """
    cx0, cy0 = bed_x / 2.0, bed_y / 2.0
    if scatter != "on":
        return cx0, cy0, (0.0, 0.0)
    lo_x, hi_x = margin + w / 2.0, bed_x - margin - w / 2.0
    lo_y, hi_y = margin + h / 2.0, bed_y - margin - h / 2.0
    if lo_x >= hi_x or lo_y >= hi_y:
        return cx0, cy0, (0.0, 0.0)          # part fills the bed: leave it centred
    rx = min((hi_x - lo_x) / 2.0, scatter_max)
    ry = min((hi_y - lo_y) / 2.0, scatter_max)
    rng = random.Random(seed)                # seed=None -> genuinely different each run
    for _ in range(64):
        px = min(hi_x, max(lo_x, cx0 + rng.uniform(-rx, rx)))
        py = min(hi_y, max(lo_y, cy0 + rng.uniform(-ry, ry)))
        if not _hits_exclusion(px, py, w, h, excl, 1.0):
            return px, py, (px - cx0, py - cy0)
    return cx0, cy0, (0.0, 0.0)              # could not find a clear spot: fall back to centre


def _as_list(v):
    if isinstance(v, list):
        return v
    return [v] if v else []


def build_minimal_config(profiles_dir, printer, process, filaments, overrides, studio_version):
    """Emit a *lean* project_settings.config: identity IDs + only the process overrides.

    This mirrors how Bambu itself layers config on open — it binds the named machine /
    process / filament SYSTEM presets (which carry the trusted, byte-identical G-code) and
    applies the project's overrides on top via `different_settings_to_system`. By NOT
    embedding the full printer/filament config we avoid two problems seen with a full dump:
      * Bambu's "customized preset - confirm G-code is safe" warning (fires whenever the
        embedded preset isn't byte-identical to the installed one — which a from-profiles
        resolution never quite is), and
      * a from-scratch filament that shows up named after the file instead of the printer
        default.
    The machine/process profiles are still resolved, but only to read identity values and to
    decide which overrides genuinely differ from the process preset (so the "modified" flag
    is accurate). Without a profiles directory the identity comes from BUILTIN_PRINTERS and
    every override is flagged. `process=None` means the printer's own default preset.
    Returns (cfg, bed_exclude_area, where the identity came from).
    """
    machine = proc = None
    source = "built-in table (Bambu Studio profiles not installed; every override flagged)"
    if profiles_dir:
        try:
            machine = resolve_preset(profiles_dir, "machine", printer)
            source = f"profiles in {profiles_dir}"
        except FileNotFoundError:
            if printer not in BUILTIN_PRINTERS:
                raise
            source = f"built-in table ({printer!r} not in {profiles_dir}; every override flagged)"
    if machine is None:
        machine = builtin_machine(printer)
        if machine is None:
            near = [n for n in BUILTIN_PRINTERS if n.endswith(" 0.4 nozzle")]
            raise SystemExit(f"Unknown printer {printer!r}. Known: "
                             + ", ".join(n[len("Bambu Lab "):-len(" 0.4 nozzle")] for n in near)
                             + " (add a nozzle size, e.g. 'P1S 0.6', for other nozzles)")
    process = process or machine.get("default_print_profile") or "0.20mm Standard @BBL X1C"
    if profiles_dir and source.startswith("profiles"):
        try:
            proc = resolve_preset(profiles_dir, "process", process)
        except FileNotFoundError:
            raise SystemExit(f"process preset not found: {process!r}. This printer's default is "
                             f"{machine.get('default_print_profile')!r}; omit --process to use it "
                             f"and pass --layer-height instead.")
    proc = proc or {}

    if filaments:
        fil_ids = list(filaments)
    else:
        # The printer preset declares its own default filament — use that so the file opens
        # on the printer's normal default material (user can still switch it in Bambu Studio).
        fil_ids = _as_list(machine.get("default_filament_profile")) or ["Bambu PLA Basic @BBL X1C"]

    cfg = {
        "from": "project",
        "name": "project_settings",
        "version": studio_version,
        "printer_settings_id": printer,
        "print_settings_id": process,
        "filament_settings_id": fil_ids,
        "printer_model": machine.get("printer_model", ""),
        "printer_variant": machine.get("printer_variant", "0.4"),
        "nozzle_diameter": _as_list(machine.get("nozzle_diameter")) or ["0.4"],
        "printable_area": machine.get("printable_area", ["0x0", "256x0", "256x256", "0x256"]),
        "printable_height": machine.get("printable_height", "256"),
        "curr_bed_type": "Textured PEI Plate",
    }

    # Apply overrides, flagging only those that genuinely differ from the process preset.
    changed = {}
    for k, val in overrides.items():
        base = proc.get(k, machine.get(k))
        newv = coerce_like(base, val) if base is not None else as_config_value(val)
        cfg[k] = newv
        if base is None or str(base) != str(newv):
            changed.setdefault(classify_override(k), set()).add(k)
    cfg["different_settings_to_system"] = build_different_settings(None, changed, len(fil_ids))
    return cfg, machine.get("bed_exclude_area"), source


def load_config_from_base_3mf(path):
    with zipfile.ZipFile(path) as zf:
        name = next((n for n in zf.namelist()
                     if n.lower().endswith("project_settings.config")), None)
        if not name:
            raise ValueError(f"{path}: no project_settings.config inside")
        return json.loads(zf.read(name).decode("utf-8"))


# ----------------------------------------------------------------------------------
# Overrides
# ----------------------------------------------------------------------------------

def as_config_value(v):
    """Bambu config values are strings, or lists of strings for per-filament/extruder keys."""
    return [str(x) for x in v] if isinstance(v, list) else str(v)


def coerce_like(baseline_value, new_value):
    """Match the baseline serialization: wrap into a 1-element list if baseline is a list."""
    if isinstance(new_value, list):
        return as_config_value(new_value)
    if isinstance(baseline_value, list):
        return [str(new_value)]
    return str(new_value)


def apply_overrides(cfg, overrides):
    for key, val in overrides.items():
        if key in cfg:
            cfg[key] = coerce_like(cfg[key], val)
        else:
            cfg[key] = as_config_value(val)
    return cfg


def collect_overrides(args):
    """Translate friendly CLI flags + --set pairs into concrete config-key overrides."""
    ov = {}
    if args.layer_height is not None:
        ov["layer_height"] = args.layer_height
    if args.walls is not None:
        ov["wall_loops"] = args.walls
    if args.infill is not None:
        pct = str(args.infill)
        ov["sparse_infill_density"] = pct if pct.endswith("%") else pct + "%"
    if args.infill_pattern is not None:
        ov["sparse_infill_pattern"] = args.infill_pattern
    if args.top_layers is not None:
        ov["top_shell_layers"] = args.top_layers
    if args.bottom_layers is not None:
        ov["bottom_shell_layers"] = args.bottom_layers
    if args.supports is not None:
        ov["enable_support"] = "1" if args.supports == "on" else "0"
    if args.support_type is not None:
        ov["support_type"] = args.support_type
    if args.brim is not None:
        ov["brim_type"] = args.brim
    for pair in args.set or []:
        if "=" not in pair:
            raise SystemExit(f"--set expects key=value, got {pair!r}")
        k, v = pair.split("=", 1)
        # allow JSON values so arrays can be supplied, e.g. --set 'nozzle_temperature=["230"]'
        try:
            v = json.loads(v)
        except json.JSONDecodeError:
            pass
        ov[k.strip()] = v
    return ov


# Keys that live in the filament or printer config; everything else is a process key.
# Used only to route an override into the right `different_settings_to_system` slot.
_FILAMENT_OVERRIDE_KEYS = {
    "nozzle_temperature", "nozzle_temperature_initial_layer", "hot_plate_temp",
    "hot_plate_temp_initial_layer", "textured_plate_temp", "textured_plate_temp_initial_layer",
    "cool_plate_temp", "cool_plate_temp_initial_layer", "eng_plate_temp", "eng_plate_temp_initial_layer",
    "chamber_temperature", "filament_flow_ratio", "fan_max_speed", "fan_min_speed",
}
_PRINTER_OVERRIDE_KEYS = {"printable_height", "nozzle_diameter", "gcode_flavor", "printer_variant"}


def classify_override(key):
    if key in _FILAMENT_OVERRIDE_KEYS or key.startswith("filament_"):
        return "filament"
    if key in _PRINTER_OVERRIDE_KEYS:
        return "printer"
    return "process"


def build_different_settings(existing, changed_by_category, n_filaments):
    """Reconstruct `different_settings_to_system` = [process, fil0..filN-1, printer].

    Bambu binds the named system presets on open and RESETS every key to the preset
    default UNLESS the key is listed here. So each override that differs from the
    preset must be flagged in its category slot, or Bambu silently discards it.
    Seeds from an existing list (base-3mf path) so pre-existing diffs are preserved.
    """
    n = max(1, n_filaments)
    proc, printer = set(), set()
    fils = [set() for _ in range(n)]
    if isinstance(existing, list) and len(existing) >= 2:
        if existing[0]:
            proc |= {k for k in existing[0].split(";") if k}
        if existing[-1]:
            printer |= {k for k in existing[-1].split(";") if k}
        for i, entry in enumerate(existing[1:-1]):
            if i < n and entry:
                fils[i] |= {k for k in entry.split(";") if k}
    proc |= changed_by_category.get("process", set())
    printer |= changed_by_category.get("printer", set())
    fils[0] |= changed_by_category.get("filament", set())
    return [";".join(sorted(proc))] + [";".join(sorted(f)) for f in fils] + [";".join(sorted(printer))]


# ----------------------------------------------------------------------------------
# 3MF container assembly
# ----------------------------------------------------------------------------------

CONTENT_TYPES = """<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
 <Default Extension="png" ContentType="image/png"/>
 <Default Extension="gcode" ContentType="text/x.gcode"/>
</Types>
"""

ROOT_RELS = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
"""

MODEL_RELS = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/Objects/object_1.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
"""


def uuid_str():
    return str(uuid.uuid4())


def object_model_xml(verts, tris, obj_uuid):
    v = "\n".join(f'     <vertex x="{x:.6f}" y="{y:.6f}" z="{z:.6f}"/>'
                  for (x, y, z) in verts)
    t = "\n".join(f'     <triangle v1="{a}" v2="{b}" v3="{c}"/>' for (a, b, c) in tris)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="1" p:UUID="{obj_uuid}" type="model">
   <mesh>
    <vertices>
{v}
    </vertices>
    <triangles>
{t}
    </triangles>
   </mesh>
  </object>
 </resources>
 <build/>
</model>
"""


def root_model_xml(transform, studio_version, container_uuid, component_uuid, build_uuid, item_uuid):
    # NOTE: every p:UUID in the package must be unique (3MF production extension).
    # The <component> gets its OWN uuid, distinct from the object it references.
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="Application">BambuStudio-{studio_version}</metadata>
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <metadata name="Copyright"></metadata>
 <metadata name="CreationDate">1970-01-01</metadata>
 <metadata name="Description"></metadata>
 <metadata name="Designer"></metadata>
 <metadata name="ModificationDate">1970-01-01</metadata>
 <metadata name="Title"></metadata>
 <resources>
  <object id="2" p:UUID="{container_uuid}" type="model">
   <components>
    <component p:path="/3D/Objects/object_1.model" objectid="1" p:UUID="{component_uuid}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>
 </resources>
 <build p:UUID="{build_uuid}">
  <item objectid="2" p:UUID="{item_uuid}" transform="{transform}" printable="1"/>
 </build>
</model>
"""


def model_settings_xml(part_name, face_count):
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<config>
  <object id="2">
    <metadata key="name" value="{part_name}"/>
    <metadata key="extruder" value="1"/>
    <metadata face_count="{face_count}"/>
    <part id="1" subtype="normal_part">
      <metadata key="name" value="{part_name}"/>
      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>
      <metadata key="source_file" value="{part_name}"/>
      <metadata key="source_object_id" value="0"/>
      <metadata key="source_volume_id" value="0"/>
      <mesh_stat face_count="{face_count}" edges_fixed="0" degenerate_facets="0" facets_removed="0" facets_reversed="0" backwards_edges="0"/>
    </part>
  </object>
  <plate>
    <metadata key="plater_id" value="1"/>
    <metadata key="plater_name" value=""/>
    <metadata key="locked" value="false"/>
    <metadata key="thumbnail_file" value="Metadata/plate_1.png"/>
    <model_instance>
      <metadata key="object_id" value="2"/>
      <metadata key="instance_id" value="0"/>
    </model_instance>
  </plate>
</config>
"""


def slice_info_xml(studio_version):
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<config>
  <header>
    <header_item key="X-BBL-Client-Type" value="slicer"/>
    <header_item key="X-BBL-Client-Version" value="{studio_version}"/>
  </header>
</config>
"""


def assemble_3mf(out_path, verts, tris, cfg, part_name, studio_version,
                 scatter="on", scatter_max=60.0, scatter_seed=None, exclude_area=None):
    xs = [v[0] for v in verts]; ys = [v[1] for v in verts]; zs = [v[2] for v in verts]
    cx = (min(xs) + max(xs)) / 2.0
    cy = (min(ys) + max(ys)) / 2.0
    minz = min(zs)
    w = max(xs) - min(xs); h = max(ys) - min(ys)
    bed_x, bed_y = bed_from_printable_area(cfg.get("printable_area"))
    # Place the footprint (scattered by default to spread build-plate wear); rest its base on
    # the bed, since the mesh is modelled with Z=0 = plate.
    px, py, delta = choose_placement(bed_x, bed_y, w, h, rect_from_area(exclude_area),
                                     scatter, scatter_max, scatter_seed)
    tx, ty, tz = px - cx, py - cy, -minz
    transform = f"1 0 0 0 1 0 0 0 1 {tx:.6f} {ty:.6f} {tz:.6f}"
    excl = rect_from_area(exclude_area)
    assemble_3mf.last_placement = (
        px, py, delta, w, h,
        _hits_exclusion(px, py, w, h, excl, 0.0),
        px - w / 2.0 < 7.9 or px + w / 2.0 > bed_x - 7.9
        or py - h / 2.0 < 7.9 or py + h / 2.0 > bed_y - 7.9)

    obj_uuid = uuid_str()
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("[Content_Types].xml", CONTENT_TYPES)
        zf.writestr("_rels/.rels", ROOT_RELS)
        zf.writestr("3D/3dmodel.model",
                    root_model_xml(transform, studio_version, uuid_str(), uuid_str(),
                                   uuid_str(), uuid_str()))
        zf.writestr("3D/_rels/3dmodel.model.rels", MODEL_RELS)
        zf.writestr("3D/Objects/object_1.model", object_model_xml(verts, tris, obj_uuid))
        zf.writestr("Metadata/project_settings.config",
                    json.dumps(cfg, indent=4, ensure_ascii=False))
        zf.writestr("Metadata/model_settings.config",
                    model_settings_xml(part_name, len(tris)))
        zf.writestr("Metadata/slice_info.config", slice_info_xml(studio_version))


def _bbox_size(points):
    return [max(p[i] for p in points) - min(p[i] for p in points) for i in range(3)]


def verify_3mf(path, verts, n_filaments, openscad):
    """Check the written package; return (problems, note). Structure is always checked. When
    OpenSCAD is available, the file is also re-imported through its import(), which uses
    lib3mf (the reference 3MF library slicers use): lib3mf rejects a malformed package with
    one uninformative line, so this is the check that catches what the structure pass can't.
    The re-imported size must match the mesh that went in (position differs by design: the
    part is placed on the plate)."""
    import xml.etree.ElementTree as ET
    problems = []
    need = ["[Content_Types].xml", "_rels/.rels", "3D/3dmodel.model", "3D/_rels/3dmodel.model.rels",
            "3D/Objects/object_1.model", "Metadata/project_settings.config",
            "Metadata/model_settings.config"]
    try:
        zf = zipfile.ZipFile(path)
    except zipfile.BadZipFile as e:
        return [f"not a zip: {e}"], ""
    with zf:
        names = set(zf.namelist())
        problems += [f"missing {n}" for n in need if n not in names]
        uuids = []
        for n in sorted(x for x in names if x.endswith(".model")):
            data = zf.read(n).decode("utf-8")
            try:
                root = ET.fromstring(data)
            except ET.ParseError as e:
                problems.append(f"{n}: XML error {e}")
                continue
            if not any(el.tag.endswith("}build") for el in root):
                problems.append(f"{n}: no <build> element (lib3mf rejects the package)")
            uuids += re.findall(r'p:UUID="([^"]+)"', data)
            if n == "3D/Objects/object_1.model":
                nv = len(_VERT_RE.findall(data))
                bad = [t for t in _TRI_RE.findall(data)
                       if len({t[0], t[1], t[2]}) < 3 or max(int(i) for i in t) >= nv]
                if bad:
                    problems.append(f"{n}: {len(bad)} degenerate/out-of-range triangles")
        if len(uuids) != len(set(uuids)):
            problems.append("a p:UUID is used twice")
        try:
            cfg = json.loads(zf.read("Metadata/project_settings.config"))
            if len(cfg.get("different_settings_to_system", [])) != max(1, n_filaments) + 2:
                problems.append("different_settings_to_system has the wrong number of slots")
        except (KeyError, ValueError) as e:
            problems.append(f"project_settings.config: {e}")
    if problems or not openscad:
        return problems, "" if problems else "structure only (OpenSCAD not found for the lib3mf round trip)"
    tmp = Path(tempfile.mkdtemp(prefix="rt3mf_"))
    (tmp / "rt.scad").write_text(f'import("{Path(path).resolve().as_posix()}");\n')
    proc = subprocess.run([openscad, "--export-format", "binstl", "-o", str(tmp / "rt.stl"),
                           str(tmp / "rt.scad")], capture_output=True, text=True)
    if proc.returncode != 0 or not (tmp / "rt.stl").exists() or "Could not read" in proc.stderr:
        return [f"OpenSCAD/lib3mf could not re-import it: {proc.stderr.strip()[-300:]}"], ""
    rv, _ = load_mesh_from_stl(tmp / "rt.stl")
    want, got = _bbox_size(verts), _bbox_size(rv)
    if any(abs(a - b) > 0.01 + 1e-4 * a for a, b in zip(want, got)):
        return [f"re-imported size {got} != input {want}"], ""
    shutil.rmtree(tmp, ignore_errors=True)
    return [], "structure + OpenSCAD/lib3mf round trip, size %.2f x %.2f x %.2f mm matches" % tuple(got)


# ----------------------------------------------------------------------------------
# CLI
# ----------------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Assemble a Bambu Studio project .3mf with settings baked in.")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--scad", help="OpenSCAD source to render")
    src.add_argument("--mesh", help="Existing geometry mesh: .3mf or .stl")
    ap.add_argument("--openscad", help="OpenSCAD executable (default: $OPENSCAD, PATH, usual install dirs)")
    ap.add_argument("-D", dest="defines", action="append", help="OpenSCAD -D define (repeatable)")
    ap.add_argument("--out", required=True, help="Output .3mf path")

    ap.add_argument("--printer", default="X1C",
                    help="machine preset: short (X1C, P1S, 'A1 mini', 'H2D 0.6') or full name")
    ap.add_argument("--process", help="print_settings_id (default: the printer's own 0.20mm preset)")
    ap.add_argument("--filament", action="append",
                    help="filament_settings_id (repeatable). Default: the printer's default filament")
    ap.add_argument("--profiles-dir", help="Bambu Studio resources/profiles/BBL dir (auto-detected if omitted)")
    ap.add_argument("--base-3mf", help="Fallback: reuse this project's project_settings.config as baseline")
    ap.add_argument("--studio-version", default="02.05.00.66", help="Value stamped as the writing app version")

    ap.add_argument("--layer-height", type=str)
    ap.add_argument("--walls", type=str, help="wall_loops (perimeter count)")
    ap.add_argument("--infill", type=str, help="sparse_infill_density, e.g. 20 or 20%%")
    ap.add_argument("--infill-pattern", type=str, help="e.g. gyroid, grid, honeycomb")
    ap.add_argument("--top-layers", type=str)
    ap.add_argument("--bottom-layers", type=str)
    ap.add_argument("--supports", choices=["on", "off"])
    ap.add_argument("--support-type", type=str, help="e.g. 'tree(auto)', 'normal(auto)'")
    ap.add_argument("--brim", type=str, help="brim_type, e.g. auto_brim, outer_only, no_brim")
    ap.add_argument("--set", action="append", help="Arbitrary override key=value (repeatable; value may be JSON)")
    ap.add_argument("--scatter", choices=["on", "off"], default="on",
                    help="Nudge the part to a random spot on the plate instead of always dead "
                         "centre, to spread build-plate wear. Bounded by the part's own size, "
                         "kept clear of the bed edges and of bed_exclude_area. Default: on")
    ap.add_argument("--scatter-max", type=float, default=60.0,
                    help="Largest offset from plate centre, mm (default 60)")
    ap.add_argument("--scatter-seed", type=int, default=None,
                    help="Seed the scatter for a reproducible placement (default: random each run)")
    ap.add_argument("--full-bed", action="store_true",
                    help="X1/P1 only: clear bed_exclude_area (the front-left cutter corner) for a "
                         "full-bed print; the user must fit Bambu's stopper clip (single colour only)")
    ap.add_argument("--no-verify", action="store_true",
                    help="skip the OpenSCAD/lib3mf round trip of the written file")

    args = ap.parse_args()
    filaments = args.filament or []  # empty => don't bake a filament; user picks in Bambu Studio
    args.printer = resolve_printer_name(args.printer)
    openscad = find_openscad(args.openscad)

    # 1) Geometry
    if args.scad:
        if not openscad:
            raise SystemExit("OpenSCAD not found: pass --openscad <path to the executable>")
        mesh_3mf = render_scad(openscad, args.scad, args.defines)
        verts, tris = load_mesh_from_3mf(mesh_3mf)
        default_name = Path(args.scad).with_suffix(".stl").name
    else:
        ext = Path(args.mesh).suffix.lower()
        verts, tris = (load_mesh_from_stl if ext == ".stl" else load_mesh_from_3mf)(args.mesh)
        default_name = Path(args.mesh).with_suffix(".stl").name

    # 2) Settings
    overrides = collect_overrides(args)
    if args.base_3mf:
        # Fallback: reuse an existing project's full config. This carries the base's embedded
        # presets, so Bambu may show its "customized preset - confirm G-code" dialog on open.
        cfg = load_config_from_base_3mf(args.base_3mf)
        cfg["printer_settings_id"] = args.printer
        cfg["print_settings_id"] = args.process or cfg.get("print_settings_id")
        if filaments:
            cfg["filament_settings_id"] = list(filaments)
        pre = {k: cfg.get(k) for k in overrides}
        cfg = apply_overrides(cfg, overrides)
        changed = {}
        for k in overrides:
            if str(pre.get(k)) != str(cfg.get(k)):
                changed.setdefault(classify_override(k), set()).add(k)
        cfg["different_settings_to_system"] = build_different_settings(
            cfg.get("different_settings_to_system"), changed, len(filaments) if filaments else 1)
        exclude_area = cfg.get("bed_exclude_area")
        source = f"base project {args.base_3mf}"
    else:
        profiles_dir = find_profiles_dir(args.profiles_dir)
        if args.profiles_dir and not profiles_dir:
            raise SystemExit(f"--profiles-dir not found: {args.profiles_dir}")
        cfg, exclude_area, source = build_minimal_config(
            profiles_dir, args.printer, args.process, filaments, overrides, args.studio_version)

    if args.full_bed:
        # A printer-slot key: it binds only when flagged in the LAST slot of the list.
        cfg["bed_exclude_area"] = []
        slots = cfg["different_settings_to_system"]
        slots[-1] = ";".join(sorted(set(filter(None, slots[-1].split(";"))) | {"bed_exclude_area"}))
        exclude_area = None

    # 3) Assemble
    assemble_3mf(args.out, verts, tris, cfg, default_name, args.studio_version,
                 scatter=args.scatter, scatter_max=args.scatter_max,
                 scatter_seed=args.scatter_seed, exclude_area=exclude_area)
    print(f"Wrote {args.out}")
    print(f"  geometry : {len(verts)} vertices, {len(tris)} triangles")
    print(f"  printer  : {args.printer}")
    print(f"  process  : {cfg.get('print_settings_id')}")
    print(f"  identity : {source}")
    fil = cfg.get("filament_settings_id")
    fil = ", ".join(fil) if isinstance(fil, list) else fil
    print(f"  filament : {fil}{'' if args.filament else '  (printer default - user can change)'}")
    print(f"  modified : {cfg['different_settings_to_system'][0] or '(none)'}")
    print(f"  settings : {len(cfg)} keys in project_settings.config (lean: IDs + overrides only)")
    px, py, (dx, dy), w, h, in_excl, at_edge = assemble_3mf.last_placement
    if args.scatter == "on" and (dx or dy):
        print(f"  placed   : {w:.0f} x {h:.0f}mm at ({px:.1f}, {py:.1f}) "
              f"= centre {dx:+.1f}, {dy:+.1f} mm  (scatter on, spreads plate wear)")
    else:
        print(f"  placed   : {w:.0f} x {h:.0f}mm centred at ({px:.1f}, {py:.1f})"
              f"{'  (no room to scatter)' if args.scatter == 'on' else '  (scatter off)'}")
    if in_excl:
        print(f"  WARNING  : this {w:.0f} x {h:.0f}mm footprint covers the printer's "
              f"bed_exclude_area (the front-left filament-cutter corner). Above roughly "
              f"220mm that is unavoidable. Either fit Bambu's stopper-clip mod and clear "
              f"'Excluded bed area' in printer settings (single-colour only - the clip "
              f"disables the cutter), or shrink the footprint. Bambu Studio will otherwise "
              f"refuse to slice cleanly.")
    if at_edge:
        print(f"  WARNING  : footprint reaches within 8mm of a bed edge - check first-layer "
              f"adhesion, or reduce the part size.")
    problems, note = verify_3mf(args.out, verts, len(cfg.get("filament_settings_id") or []),
                                None if args.no_verify else openscad)
    if problems:
        print("  verify   : FAILED - " + "; ".join(problems))
        sys.exit(2)
    print(f"  verify   : OK - {note}")


if __name__ == "__main__":
    main()
