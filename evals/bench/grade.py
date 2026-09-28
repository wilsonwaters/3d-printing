#!/usr/bin/env python3
"""Grade a finished run's output folder against a case's checks.

Every check is computed from the files and the transcript, never from what
the agent says about itself. Checks marked "must" (the default) decide
pass/fail; every check counts toward the 0-1 score.

Check types (case.json "checks"):
  gate                 every deliverable .scad compiles clean, all parts   (auto)
  manifold             no printable part has an edge shared by !=2 faces   (auto; slicers flag these)
  fits_build_volume    every printable part fits the printer's volume      (auto)
  parts_min  value     at least N printable parts
  bbox_max   value     largest printable part fits [a,b,c] (orientation-free: sorted dims);
                       "which": "any" / "all" to test any / every printable part instead
  bbox_min   value     same, at least [a,b,c]
  count_min  value of  at least N of the listed sub-checks pass (e.g. defects a review found)
  overhang_max value   total sloped overhang past 45 deg <= value mm2 (flat ceilings excluded)
  ceiling_max value    total flat ceiling area <= value mm2
  on_plate             every printable part rests on z=0
  shells_max value     no printable part has more than N separate bodies
  structure_min value  skill file-structure conformance score >= value
  asserts_min value    at least N assert() contracts in the primary .scad
  file_exists glob     a file matching glob was produced (exists: false to forbid)
  file_regex glob pattern   a matching file contains the regex
  threemf_valid glob   a .3mf is a zip with a 3D model (bambu: true also needs project settings)
  reply_regex pattern  final message matches (not: true to forbid)
  tool_used tool [input_regex] [min] [max]
  skill_file_read name the named skill file was read (e.g. design-review.md)

  python evals/bench/grade.py OUTPUT_DIR --case evals/cases/caster-plug [--transcript run.jsonl]
"""

import argparse
import fnmatch
import json
import os
import re
import sys
import zipfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import load_json, save_json  # noqa: E402
from scadcheck import check_scad, printable_parts  # noqa: E402
import transcript as tx  # noqa: E402

SKIP_DIRS = {"tmp", "temp", "scratch", ".cache", "__pycache__", "renders", "render", ".git"}
SCRATCH_NAME = re.compile(r"^(test|tmp|scratch|probe|debug|check)[-_.]|[-_](test|tmp|probe)\.scad$", re.I)


def list_files(root):
    out = []
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x.lower() not in SKIP_DIRS]
        for f in files:
            out.append(os.path.relpath(os.path.join(d, f), root).replace("\\", "/"))
    return sorted(out)


def deliverable_scads(root, files):
    scads = [f for f in files if f.lower().endswith(".scad")
             and not SCRATCH_NAME.search(os.path.basename(f))]
    return sorted(scads, key=lambda f: -os.path.getsize(os.path.join(root, f)))


def load_case(case_dir):
    case = load_json(os.path.join(case_dir, "case.json"))
    if case is None:
        raise SystemExit("no case.json in %s" % case_dir)
    case.setdefault("name", os.path.basename(os.path.normpath(case_dir)))
    case["_dir"] = os.path.abspath(case_dir)
    with open(os.path.join(case_dir, "task.md"), encoding="utf-8") as f:
        case["prompt"] = f.read().strip()
    return case


def grade(root, case, metrics=None, fixtures=(), timeout=900, known_files=()):
    """known_files: files the run produced that are no longer on disk (a regrade
    of kept outputs), so file_exists checks still see them."""
    metrics = metrics or {}
    files = list_files(root)
    produced = sorted(set(f for f in files if f not in set(fixtures)) | set(known_files))
    volume = (case.get("printer") or {}).get("build_volume")
    design = case.get("design", True)
    auto = [{"type": "gate"}, {"type": "manifold"}] + ([{"type": "fits_build_volume"}] if volume else [])
    checks = (auto if design else []) + list(case.get("checks", []))

    # edit cases change a fixture in place, so fixtures that remain are graded too
    scads = deliverable_scads(root, files)
    if case.get("scad_glob"):
        scads = [f for f in scads if fnmatch.fnmatch(os.path.basename(f), case["scad_glob"])]
    scad_results = {}
    if design:
        for s in scads[: case.get("max_scads", 3)]:
            scad_results[s] = check_scad(os.path.join(root, s), volume, timeout=timeout)
    primary = scad_results.get(scads[0]) if scads and scads[0] in scad_results else None
    printable = [p for r in scad_results.values() for p in printable_parts(r)]
    # layouts still have to fit the bed
    on_bed = [p for r in scad_results.values() for p in r["parts"].values()
              if p["printable"] and p["mesh"]]
    largest = max(printable, key=lambda p: p["mesh"]["volume_mm3"], default=None)
    final = metrics.get("final_text", "") or ""

    def res(ok, detail):
        return bool(ok), detail

    def run_check(c):
        t = c["type"]
        if t == "gate":
            if not scad_results:
                return res(False, "no .scad deliverable produced")
            bad = {s: r["summary"]["parts_failed"] for s, r in scad_results.items()
                   if not r["summary"]["gate_pass"]}
            return res(not bad, "failed: %s" % bad if bad else "%d file(s), %d part(s) clean" % (
                len(scad_results), sum(r["summary"]["parts_total"] for r in scad_results.values())))
        if t == "manifold":
            bad = ["%s (%d)" % (p["compile"]["part"] or "default", p["mesh"]["non_manifold_edges"])
                   for p in printable if p["mesh"]["non_manifold_edges"]]
            return res(printable and not bad, "non-manifold edges: %s" % bad if bad
                       else "every edge shared by exactly 2 faces")
        if t == "fits_build_volume":
            over = ["%s %s" % (p["compile"]["part"], p["mesh"]["bbox_size"]) for p in on_bed
                    if p["mesh"]["fits_build_volume"] is False]
            return res(on_bed and not over, "too big: %s" % over if over else "all fit %s" % volume)
        if t == "parts_min":
            return res(len(printable) >= c["value"], "%d printable part(s)" % len(printable))
        if t in ("bbox_max", "bbox_min"):
            which = c.get("which", "largest")
            pool = printable if which in ("any", "all") else ([largest] if largest else [])
            if not pool:
                return res(False, "no printable part")
            want = sorted(c["value"])

            def within(p):
                got = sorted(p["mesh"]["bbox_size"])
                if t == "bbox_max":
                    return all(g <= w + 0.05 for g, w in zip(got, want))
                return all(g >= w - 0.05 for g, w in zip(got, want))
            hits = [p for p in pool if within(p)]
            ok = len(hits) == len(pool) if which in ("largest", "all") else bool(hits)
            shown = (hits or pool)[0]
            return res(ok, "%s part %s %s vs %s" % (which, shown["compile"]["part"] or "default",
                                                    shown["mesh"]["bbox_size"], c["value"]))
        if t == "count_min":
            subs = [run_check(x) for x in c["of"]]
            n = sum(1 for ok, _ in subs if ok)
            return res(n >= c["value"], "%d of %d: %s" % (n, len(subs), ", ".join(
                x.get("id", x["type"]) for x, (ok, _) in zip(c["of"], subs) if ok) or "none"))
        if t == "overhang_max":
            tot = sum(p["mesh"]["overhang_45_sloped_mm2"] for p in printable)
            return res(printable and tot <= c["value"], "%.0f mm2 sloped overhang" % tot)
        if t == "ceiling_max":
            tot = sum(p["mesh"]["flat_ceiling_mm2"] for p in printable)
            return res(printable and tot <= c["value"], "%.0f mm2 flat ceiling" % tot)
        if t == "on_plate":
            off = [p["compile"]["part"] for p in printable if not p["mesh"]["on_plate"]]
            return res(printable and not off, "off the plate: %s" % off if off else "all on z=0")
        if t == "shells_max":
            worst = max((p["mesh"]["shells"] for p in printable), default=None)
            return res(worst is not None and worst <= c["value"], "max shells %s" % worst)
        if t == "structure_min":
            s = primary["structure"]["score"] if primary else 0
            return res(s >= c["value"], "structure %.2f" % s)
        if t == "asserts_min":
            n = primary["structure"]["asserts"] if primary else 0
            return res(n >= c["value"], "%d assert()" % n)
        if t == "file_exists":
            hits = [f for f in produced if fnmatch.fnmatch(f.lower(), c["glob"].lower())
                    or fnmatch.fnmatch(os.path.basename(f).lower(), c["glob"].lower())]
            want = c.get("exists", True)
            return res(bool(hits) == want, "%s: %s" % (c["glob"], hits[:5] or "none"))
        if t == "file_regex":
            rx = re.compile(c["pattern"], re.I if c.get("flags") == "i" else 0)
            for f in files:
                if fnmatch.fnmatch(os.path.basename(f), c["glob"]):
                    with open(os.path.join(root, f), encoding="utf-8", errors="replace") as fh:
                        if rx.search(fh.read()):
                            return res(True, "matched in %s" % f)
            return res(False, "no %s matches /%s/" % (c["glob"], c["pattern"]))
        if t == "threemf_valid":
            found = [f for f in produced if fnmatch.fnmatch(os.path.basename(f), c.get("glob", "*.3mf"))]
            for f in found:
                try:
                    with zipfile.ZipFile(os.path.join(root, f)) as z:
                        names = set(z.namelist())
                except zipfile.BadZipFile:
                    continue
                if "3D/3dmodel.model" in names and (not c.get("bambu")
                                                    or "Metadata/project_settings.config" in names):
                    return res(True, "%s ok" % f)
            return res(False, "no valid 3mf among %s" % (found or "none"))
        if t == "reply_regex":
            hit = re.search(c["pattern"], final, re.I if c.get("flags", "i") == "i" else 0)
            return res(bool(hit) != bool(c.get("not")), ("forbidden match" if c.get("not") else
                       "matched") if hit else "no match")
        if t == "tool_used":
            n = metrics.get("_tool_matches", {}).get(json.dumps(c, sort_keys=True))
            if n is None:
                n = metrics.get("tools", {}).get(c["tool"], 0)
            lo, hi = c.get("min", 1), c.get("max")
            return res(n >= lo and (hi is None or n <= hi), "%s x%d" % (c["tool"], n))
        if t == "skill_file_read":
            n = (metrics.get("skill_files_read") or {}).get(c["name"], 0)
            return res(n > 0, "%s read %d time(s)" % (c["name"], n))
        return res(False, "unknown check type %s" % t)

    results = []
    for c in checks:
        try:
            ok, detail = run_check(c)
        except Exception as exc:  # a broken check is a failed check, not a crashed suite
            ok, detail = False, "check error: %s" % exc
        results.append({"type": c["type"], "id": c.get("id", c["type"]), "must": c.get("must", True),
                        "weight": c.get("weight", 1), "ok": ok, "detail": detail})
    wsum = sum(r["weight"] for r in results) or 1
    summary = {}
    if primary:
        summary = {k: primary["summary"].get(k) for k in (
            "gate_pass", "parts_total", "printable_parts", "structure_score", "asserts",
            "overhang_45_sloped_mm2", "flat_ceiling_mm2", "volume_mm3", "warnings",
            "compile_seconds")}
        summary["scad_bytes"] = primary["structure"]["bytes"]
    return {
        "case": case["name"],
        "pass": all(r["ok"] for r in results if r["must"]),
        "score": round(sum(r["weight"] for r in results if r["ok"]) / wsum, 3),
        "checks": results,
        "quality": summary,
        "files": produced,
        "scads": {s: {"summary": r["summary"], "structure": r["structure"]["items"],
                      "parts": {k: {"ok": v["compile"]["ok"], "fatal": v["compile"]["fatal"][:3],
                                    "mesh": v["mesh"], "printable": v["printable"],
                                    "layout": v.get("layout", False)}
                                for k, v in r["parts"].items()}}
                  for s, r in scad_results.items()},
    }


def tool_matches(case, transcript_paths):
    """Count tool calls whose input matches each tool_used check's input_regex."""
    wanted = [c for c in case.get("checks", []) if c["type"] == "tool_used" and c.get("input_regex")]
    if not wanted:
        return {}
    calls = {}
    for e in tx._events(transcript_paths):
        if e.get("type") != "assistant":
            continue
        for b in (e.get("message") or {}).get("content") or []:
            if isinstance(b, dict) and b.get("type") == "tool_use":
                calls[b.get("id")] = (b.get("name"), _tool_text(b.get("input")))
    out = {}
    for c in wanted:
        rx = re.compile(c["input_regex"], re.I)
        out[json.dumps(c, sort_keys=True)] = sum(
            1 for name, inp in calls.values() if name == c["tool"] and rx.search(inp))
    return out


def _tool_text(inp):
    """Match regexes against a Bash command as typed, anything else as JSON."""
    if isinstance(inp, dict) and isinstance(inp.get("command"), str):
        return inp["command"]
    return json.dumps(inp or {})


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("output_dir")
    ap.add_argument("--case", required=True, help="case directory (holds case.json)")
    ap.add_argument("--transcript", nargs="*", default=[], help="stream-json or session .jsonl files")
    ap.add_argument("--scad", help="grade only .scad files matching this glob (e.g. '*-v4.scad')")
    ap.add_argument("--json", help="write the grade here")
    args = ap.parse_args()
    case = load_case(args.case)
    paths = tx.expand(args.transcript)
    metrics = tx.analyse(paths) if paths else {}
    if paths:
        metrics["_tool_matches"] = tool_matches(case, paths)
    if args.scad:
        case["scad_glob"] = args.scad
    g = grade(args.output_dir, case, metrics)
    if args.json:
        save_json(args.json, g)
    print("%s: %s  score %.2f" % (g["case"], "PASS" if g["pass"] else "FAIL", g["score"]))
    for r in g["checks"]:
        print("  [%s] %-18s %s%s" % ("x" if r["ok"] else " ", r["id"], r["detail"],
                                     "" if r["must"] else "  (optional)"))
    return 0 if g["pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
