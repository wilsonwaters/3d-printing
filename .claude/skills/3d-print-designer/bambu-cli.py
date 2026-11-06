#!/usr/bin/env python3
"""
bambu-cli.py - drive Bambu Studio's command line on a project .3mf: complete its settings, and
slice it to check what the printer will really do.

WHY THIS EXISTS
---------------
make-bambu-3mf.py writes a *lean* project (preset names plus overrides). Bambu Studio fills
the rest from its system presets when it opens the file. That works for one filament. With two
or more, Bambu Studio 2.x may turn the second filament into a project preset named after the
file, built only from the lean values: no filament_type (so it shows PLA), no density (0 g in
the slicing result). `complete` has Bambu Studio itself write the full settings into the file,
so every filament is a whole preset.

Slicing is also the only check of what the printer will do: the time, the grams per filament,
how many filament changes, whether a prime tower is on, the nozzle temperature of each
filament. `slice` reports those and warns about the traps below.

The Bambu Studio CLI on macOS crashes (exit 139) on a lean project, because it looks for
machine_full/process_full presets the app does not ship. This tool resolves the presets'
inherits chains itself (the same way make-bambu-3mf.py does) and passes them with
--load-settings / --load-filaments.

USAGE
-----
  python bambu-cli.py complete lean.3mf --out full.3mf
  python bambu-cli.py slice full.3mf --temp-range 240-270
  python bambu-cli.py slice full.3mf --temp-range 1=240-260 --temp-range 2=240-270

  --studio   Bambu Studio executable (default: $BAMBU_STUDIO, PATH, usual install folders)
  --profiles Bambu Studio resources/profiles/BBL folder (default: found like make-bambu-3mf.py)

`slice` warnings:
  * a filament whose type is missing or whose density is 0 (a broken project preset);
  * filaments of different families in one object (PLA does not bond to PETG, ABS or TPU);
  * two or more filaments used and no prime tower;
  * a nozzle temperature outside --temp-range (the range printed on the filament's box).

Python 3.8+ standard library only. Exit 0 when the job ran, 1 on warnings with --strict,
2 when Bambu Studio failed.
"""

import argparse
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("make_bambu_3mf", HERE / "make-bambu-3mf.py")
mb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mb)

STUDIO_CANDIDATES = [
    "/Applications/BambuStudio.app/Contents/MacOS/BambuStudio",
    r"C:\Program Files\Bambu Studio\bambu-studio.exe",
    "/usr/bin/bambu-studio",
]

# Keys that identify presets or describe the file; never copied into a flattened preset.
IDENTITY = {
    "from", "name", "version", "inherits", "inherits_group", "printer_settings_id",
    "print_settings_id", "filament_settings_id", "different_settings_to_system",
    "printer_model", "printer_variant", "nozzle_diameter", "printable_area", "printable_height",
    "compatible_printers", "compatible_prints", "setting_id", "instantiation", "type",
}

FAMILIES = [("PLA", "PLA"), ("PETG", "PETG"), ("PCTG", "PETG"), ("ABS", "ABS"), ("ASA", "ABS"),
            ("TPU", "TPU"), ("PA", "PA"), ("PC", "PC"), ("PVA", "PVA")]


def family(ftype):
    t = (ftype or "").upper()
    for prefix, fam in FAMILIES:
        if t.startswith(prefix):
            return fam
    return t or "?"


def find_studio(explicit):
    for cand in [explicit, os.environ.get("BAMBU_STUDIO"), shutil.which("bambu-studio"),
                 shutil.which("BambuStudio"), *STUDIO_CANDIDATES]:
        if cand and Path(cand).exists():
            return cand
    return None


def read_project_config(path):
    with zipfile.ZipFile(path) as zf:
        name = next(n for n in zf.namelist() if n.endswith("project_settings.config"))
        return json.loads(zf.read(name))


def as_list(v):
    return v if isinstance(v, list) else [v]


def flatten(cfg, profiles, outdir):
    """Write machine.json, process.json and one filament_<i>.json, each a resolved system
    preset with the project's overrides applied. Returns (paths, notes, overrides by slot)."""
    printer = cfg["printer_settings_id"]
    machine = mb.resolve_preset(profiles, "machine", printer)
    process = mb.resolve_preset(profiles, "process", cfg["print_settings_id"])
    fil_names = as_list(cfg.get("filament_settings_id") or [])
    n = len(fil_names)
    notes, slots = [], {"process": set(), "machine": set(), "filament": [set() for _ in fil_names]}
    filaments = []
    for i, name in enumerate(fil_names):
        used = mb.compatible_filament_name(profiles, name, printer)
        if used != name:
            notes.append(f"filament {i + 1}: {name!r} is not for {printer}; using {used!r}")
        filaments.append((used, mb.resolve_preset(profiles, "filament", used)))
    for key, val in cfg.items():
        if key in IDENTITY:
            continue
        if key in process:
            process[key] = val
            slots["process"].add(key)
        elif filaments and key in filaments[0][1]:
            vals = as_list(val)
            for i, (_, preset) in enumerate(filaments):
                preset[key] = [vals[i]] if len(vals) == n else vals
                slots["filament"][i].add(key)
        elif key in machine:
            machine[key] = val
            slots["machine"].add(key)
    paths = []
    for label, preset, name in [("machine", machine, printer),
                                ("process", process, cfg["print_settings_id"])]:
        preset.update({"inherits": "", "from": "system", "name": name})
        p = outdir / f"{label}.json"
        p.write_text(json.dumps(preset, indent=1))
        paths.append(p)
    fil_paths = []
    for i, (name, preset) in enumerate(filaments):
        preset.update({"inherits": "", "from": "system", "name": name})
        p = outdir / f"filament_{i + 1}.json"
        p.write_text(json.dumps(preset, indent=1))
        fil_paths.append(p)
    return paths, fil_paths, notes, slots


def run_studio(studio, args, cwd):
    proc = subprocess.run([studio, *args], cwd=cwd, capture_output=True, text=True)
    return proc.returncode, (proc.stdout + proc.stderr)


def extruders_used(path):
    """Filament numbers the parts are assigned to (model_settings.config)."""
    with zipfile.ZipFile(path) as zf:
        try:
            ms = zf.read("Metadata/model_settings.config").decode("utf-8")
        except KeyError:
            return {1}
    used = {int(x) for x in re.findall(r'key="extruder" value="(\d+)"', ms)}
    return used or {1}


def cmd_complete(a, studio, profiles):
    cfg = read_project_config(a.project)
    work = Path(tempfile.mkdtemp(prefix="bambu_complete_"))
    (paths, fil_paths, notes, slots) = flatten(cfg, profiles, work)
    for n in notes:
        print(f"  note     : {n}")
    out_dir = work / "out"
    out_dir.mkdir()
    code, log = run_studio(studio, [
        "--load-settings", ";".join(str(p) for p in paths),
        "--load-filaments", ";".join(str(p) for p in fil_paths),
        "--export-3mf", "full.3mf", "--outputdir", str(out_dir), str(Path(a.project).resolve())], work)
    full = out_dir / "full.3mf"
    if code != 0 or not full.exists():
        print(f"  FAILED   : Bambu Studio exit {code}\n{log[-2000:]}")
        return 2
    # Bambu's export drops the prime tower when it sees one filament per nozzle; a project whose
    # parts use two filaments needs it back. The overrides go back into
    # different_settings_to_system so Bambu Studio marks those presets as modified.
    n_used = len(extruders_used(full))
    out = Path(a.out)
    with zipfile.ZipFile(full) as zin, zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            data = zin.read(item.filename)
            if item.filename == "Metadata/project_settings.config":
                d = json.loads(data)
                if n_used > 1 and "enable_prime_tower" not in cfg:
                    d["enable_prime_tower"] = "1"
                d["different_settings_to_system"] = (
                    [";".join(sorted(slots["process"]))]
                    + [";".join(sorted(s)) for s in slots["filament"]]
                    + [";".join(sorted(slots["machine"]))])
                data = json.dumps(d, indent=4).encode()
                summary = d
            zout.writestr(item, data)
    shutil.rmtree(work, ignore_errors=True)
    print(f"Wrote {out}")
    print(f"  settings : {len(summary)} keys (complete, written by Bambu Studio)")
    print(f"  filament : " + "; ".join(
        f"{i + 1}={n} {t} {d}g/cm3 {tmp}C" for i, (n, t, d, tmp) in enumerate(zip(
            summary["filament_settings_id"], summary["filament_type"],
            summary["filament_density"], summary["nozzle_temperature"]))))
    print(f"  parts use: filament(s) {sorted(extruders_used(out))}, prime tower "
          f"{'on' if summary.get('enable_prime_tower') == '1' else 'off'}")
    return 0


def parse_gcode(path):
    head = {}
    changes = 0
    with open(path, errors="replace") as f:
        for line in f:
            if line.startswith("; ") and " = " in line:
                k, v = line[2:].split(" = ", 1)
                head.setdefault(k.strip(), v.strip())
            elif line.startswith("; model printing time:") or line.startswith("; total filament weight"):
                head[line[2:].split(":")[0].strip()] = line.split(":", 1)[1].strip()
            elif re.match(r"M620 S(\d+)A", line) and not line.startswith("M620 S255"):
                changes += 1
    return head, changes


def parse_temp_ranges(items, n):
    ranges = {}
    for item in items or []:
        if "=" in item:
            idx, rng = item.split("=", 1)
            targets = [int(idx)]
        else:
            rng, targets = item, list(range(1, n + 1))
        lo, hi = (float(x) for x in rng.split("-"))
        for t in targets:
            ranges[t] = (lo, hi)
    return ranges


def cmd_slice(a, studio, profiles):
    project = Path(a.project).resolve()
    cfg = read_project_config(project)
    work = Path(tempfile.mkdtemp(prefix="bambu_slice_"))
    out_dir = work / "out"
    out_dir.mkdir()
    code, log = run_studio(studio, ["--slice", "0", "--outputdir", str(out_dir), str(project)], work)
    how = "the project's own settings"
    if code != 0 or not (out_dir / "plate_1.gcode").exists():
        # Lean project: the CLI needs whole presets.
        paths, fil_paths, notes, _ = flatten(cfg, profiles, work)
        code, log = run_studio(studio, [
            "--load-settings", ";".join(str(p) for p in paths),
            "--load-filaments", ";".join(str(p) for p in fil_paths),
            "--slice", "0", "--outputdir", str(out_dir), str(project)], work)
        how = "flattened system presets (the project is lean; run `complete` before printing)"
    gcode = out_dir / "plate_1.gcode"
    if code != 0 or not gcode.exists():
        print(f"  FAILED   : Bambu Studio exit {code}\n{log[-2000:]}")
        return 2
    head, changes = parse_gcode(gcode)
    result = json.loads((out_dir / "result.json").read_text())["sliced_plates"][0]
    types = head.get("filament_type", "").split(";")
    dens = head.get("filament_density", "").split(",")
    temps = head.get("nozzle_temperature", "").split(",")
    used = sorted(extruders_used(project))
    print(f"Sliced {project.name} with {how}")
    print(f"  time     : {head.get('model printing time', '?')}")
    for f in result["filaments"]:
        i = f["id"]
        print(f"  filament {i}: {types[i - 1] if i <= len(types) else '?'}, "
              f"{temps[i - 1] if i <= len(temps) else '?'} C, in the model {f['main_used_g']:.2f} g, "
              f"with purge {f['total_used_g']:.2f} g")
    print(f"  changes  : {changes} filament change(s); prime tower {head.get('enable_prime_tower', '?')}")
    warnings = []
    for i in used:
        t = types[i - 1] if i <= len(types) else ""
        d = dens[i - 1] if i <= len(dens) else "0"
        if not t or float(d or 0) == 0:
            warnings.append(f"filament {i} has type {t!r} and density {d}: a broken project "
                            f"preset (run `complete`)")
    fams = {family(types[i - 1]) for i in used if i <= len(types)}
    if len(fams) > 1:
        warnings.append(f"one object mixes {', '.join(sorted(fams))}: these do not bond to each "
                        f"other, so an inlay or a second-colour part falls off")
    if len(used) > 1 and head.get("enable_prime_tower") == "0":
        warnings.append("two or more filaments and no prime tower: colour changes bleed")
    for i, (lo, hi) in parse_temp_ranges(a.temp_range, len(temps)).items():
        if i <= len(temps) and not (lo <= float(temps[i - 1]) <= hi):
            warnings.append(f"filament {i} prints at {temps[i - 1]} C, outside {lo:g}-{hi:g} C "
                            f"from its box")
    for w in warnings:
        print(f"  WARNING  : {w}")
    if not warnings:
        print("  check    : OK")
    shutil.rmtree(work, ignore_errors=True)
    return 1 if (warnings and a.strict) else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--studio", help="Bambu Studio executable")
    ap.add_argument("--profiles", help="Bambu Studio resources/profiles/BBL folder")
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("complete", help="write the full settings into a lean project")
    c.add_argument("project")
    c.add_argument("--out", required=True)
    s = sub.add_parser("slice", help="slice a project and report time, grams, changes, temps")
    s.add_argument("project")
    s.add_argument("--temp-range", action="append",
                   help="nozzle range from the filament box: 240-270 for all, or 2=240-270")
    s.add_argument("--strict", action="store_true", help="exit 1 when there are warnings")
    a = ap.parse_args()
    studio = find_studio(a.studio)
    if not studio:
        sys.exit("Bambu Studio not found: pass --studio or set $BAMBU_STUDIO")
    profiles = mb.find_profiles_dir(a.profiles)
    if not profiles:
        sys.exit("Bambu Studio profiles not found: pass --profiles <resources/profiles/BBL>")
    sys.exit((cmd_complete if a.cmd == "complete" else cmd_slice)(a, studio, profiles))


if __name__ == "__main__":
    main()
