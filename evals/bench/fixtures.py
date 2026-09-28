#!/usr/bin/env python3
"""Re-measure the existing models in 3d-models/ and compare with a snapshot.

These are the designs this skill has already produced, with known properties
(printed and failed, printed and fixed, known-bad). They calibrate the grader
on real output rather than toy shapes, and catch an OpenSCAD upgrade or a
grader change that shifts the numbers. They do not test the skill itself.

  python evals/bench/fixtures.py            # compare with evals/fixtures.json
  python evals/bench/fixtures.py --update   # re-snapshot (review the diff first)
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import EVALS_DIR, REPO_ROOT, find_openscad, load_json, save_json  # noqa: E402
from scadcheck import check_scad  # noqa: E402

SNAPSHOT = os.path.join(EVALS_DIR, "fixtures.json")
VOLUME = [256, 256, 256]
# path under 3d-models -> why it is here
FIXTURES = {
    "outdoor-plant-pot-stand/pot-stand-v1.scad": "good: full structure, 17 asserts, one-piece first layer",
    "caster-tube-insert/caster-tube-insert-v3.scad": "good: smallest file with the full structure",
    "caster-tube-insert/caster-tube-insert-v2.scad": "printed and failed (seized pilot, snapped fins): geometry passes, judgement needed",
    "land-rover-d4-phone-mount/d4-phone-mount-v1.scad": "good: 37 asserts; gauge part is two bodies by design",
    "Gate Latch Leaver/gate latch leaver - v1.scad": "pre-structure file: structure score 0",
    "Gate Latch Leaver/gate latch leaver - v4.scad": "known issue: lever part is a display pose, off the plate",
    "hand-pump-bracket/hand-pump-bracket-3/hand-pump-bracket.scad": "known bad: 300 mm tall, header claims it fits the bed",
    "MakerX Acoustic Tile Fable/makerx acoustic tile fable - v1.scad": "known bad: non-manifold diagonal contacts Bambu Studio flagged",
    "MakerX Acoustic Tile Fable/makerx acoustic tile fable - v2.scad": "the fix for v1 (diffuser clean)",
    "MakerX Acoustic Tile Opus5.0/makerx-acoustic-tile-v2.scad": "fit part is an interference check that must render empty",
    "Mechanical Rain Gauge Opus5.0/mechanical-rain-gauge-opus5-v1.scad": "clash parts must render empty; 50 asserts",
}
PART_KEYS = ("ok", "printable", "bbox_size", "shells", "non_manifold_edges", "on_plate")


def snapshot_of(res):
    parts = {}
    for name, p in res["parts"].items():
        m = p["mesh"] or {}
        parts[name] = {"ok": p["compile"]["ok"], "printable": p["printable"],
                       "bbox_size": m.get("bbox_size"), "shells": m.get("shells"),
                       "non_manifold_edges": m.get("non_manifold_edges"), "on_plate": m.get("on_plate")}
    s = res["summary"]
    return {"gate_pass": s["gate_pass"], "fits_build_volume": s.get("fits_build_volume"),
            "structure_score": s["structure_score"], "asserts": s["asserts"], "parts": parts}


def diff(want, got, path=""):
    out = []
    if isinstance(want, dict) and isinstance(got, dict):
        for k in sorted(set(want) | set(got)):
            out += diff(want.get(k), got.get(k), "%s.%s" % (path, k) if path else k)
    elif isinstance(want, list) and isinstance(got, list) and len(want) == len(got):
        if any(abs(a - b) > 0.05 for a, b in zip(want, got)):
            out.append("%s: %s -> %s" % (path, want, got))
    elif want != got:
        out.append("%s: %s -> %s" % (path, want, got))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--update", action="store_true")
    args = ap.parse_args()
    if not find_openscad():
        print("SKIP: OpenSCAD not found (set $OPENSCAD)")
        return 0
    old = load_json(SNAPSHOT, {}).get("fixtures", {})
    new, problems = {}, []
    for rel, why in FIXTURES.items():
        path = os.path.join(REPO_ROOT, "3d-models", rel)
        if not os.path.exists(path):
            problems.append("%s: missing" % rel)
            continue
        snap = snapshot_of(check_scad(path, VOLUME, jobs=2))
        snap["why"] = why
        new[rel] = snap
        d = diff({k: v for k, v in old.get(rel, {}).items() if k != "why"},
                 {k: v for k, v in snap.items() if k != "why"}) if rel in old else ["not in snapshot"]
        print("%-66s %s" % (rel[:66], "ok" if not d else "CHANGED"))
        problems += ["%s: %s" % (rel, x) for x in d]
    if args.update:
        save_json(SNAPSHOT, {"build_volume": VOLUME, "fixtures": new})
        print("snapshot written: %s" % os.path.relpath(SNAPSHOT))
        return 0
    for p in problems:
        print("  " + p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
