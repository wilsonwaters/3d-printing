#!/usr/bin/env python3
"""Calibrate the deterministic grader against geometry with known answers.

A grader nobody has checked is a second source of noise. This builds a few
shapes whose overhang/bed/shell numbers can be worked out by hand and fails if
scadcheck.py disagrees. Needs OpenSCAD; takes a few seconds.

  python evals/bench/selftest.py
"""

import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scadcheck import check_scad, discover_parts, structure_metrics  # noqa: E402
from common import find_openscad  # noqa: E402

SHAPES = r'''
part = "cube"; // "cube", "tee", "hole", "teardrop", "two", "chamfer", "floating", "all", "clash", "interference", "plate"
$fn = 64;
module teardrop_x(d, len) {   // horizontal hole along X, point up
    rotate([0, 90, 0]) linear_extrude(len) rotate(90) { circle(d = d); rotate(45) square(d / 2); }
}
if (part == "cube") cube(10);
if (part == "tee") { translate([10, 0, 0]) cube([10, 10, 10]); translate([0, 0, 10]) cube([30, 10, 5]); }
if (part == "hole") difference() { cube([20, 20, 10]); translate([-1, 10, 5]) rotate([0, 90, 0]) cylinder(d = 6, h = 22); }
if (part == "teardrop") difference() { cube([20, 20, 10]); translate([-1, 10, 5]) teardrop_x(6, 22); }
if (part == "two") { cube(10); translate([20, 0, 0]) cube(10); }
if (part == "chamfer") hull() { translate([2, 2, 0]) cube([6, 6, 1]); translate([0, 0, 2]) cube([10, 10, 8]); }
if (part == "floating") translate([0, 0, 3]) cube(10);
if (part == "all") { cube(10); translate([0, 0, 20]) cube(10); }
if (part == "clash") intersection() { cube(10); translate([20, 0, 0]) cube(10); }        // clear: empty
if (part == "interference") intersection() { cube(10); translate([5, 0, 0]) cube(10); }  // overlaps
if (part == "plate") { cube(10); translate([20, 0, 0]) cube(10); }   // print layout of two parts
'''

# part -> {metric: (expected, tolerance)}
EXPECT = {
    "cube": {"volume_mm3": (1000, 0.5), "area_mm2": (600, 0.5), "bed_contact_mm2": (100, 0.5),
             "overhang_45_mm2": (0, 0.1), "shells": (1, 0), "non_manifold_edges": (0, 0)},
    # 30x10 slab on a 10x10 pillar: 200 mm2 of flat ceiling either side
    "tee": {"flat_ceiling_mm2": (200, 0.5), "overhang_45_sloped_mm2": (0, 0.1)},
    # d6 x 20 round hole: ceiling arc within 44.5 deg of the top = 3*2*0.777*20 = 93 mm2
    "hole": {"overhang_45_mm2": (93.2, 3.0)},
    # same hole as a teardrop: nothing past 45 deg
    "teardrop": {"overhang_45_mm2": (0, 0.5)},
    "two": {"shells": (2, 0)},
    # 45 deg chamfered underside is self-supporting; bed contact is the 6x6 foot
    "chamfer": {"overhang_45_mm2": (0, 0.1), "bed_contact_mm2": (36, 0.5)},
}


def main():
    if not find_openscad():
        print("SKIP: OpenSCAD not found (set $OPENSCAD)")
        return 0
    failures = []
    parts = discover_parts(SHAPES)
    if parts != ["cube", "tee", "hole", "teardrop", "two", "chamfer", "floating", "all", "clash",
                 "interference", "plate"]:
        failures.append("discover_parts -> %r" % parts)
    with tempfile.TemporaryDirectory() as tmp:
        scad = os.path.join(tmp, "shapes.scad")
        with open(scad, "w") as f:
            f.write(SHAPES)
        res = check_scad(scad, build_volume=[256, 256, 256])
    for part, checks in EXPECT.items():
        r = res["parts"][part]
        if not r["compile"]["ok"]:
            failures.append("%s: did not compile: %s" % (part, r["compile"]["fatal"]))
            continue
        for key, (want, tol) in checks.items():
            got = r["mesh"][key]
            if abs(got - want) > tol:
                failures.append("%s.%s = %s, expected %s +/- %s" % (part, key, got, want, tol))
    if res["parts"]["floating"]["mesh"]["on_plate"]:
        failures.append("floating part reported as on the plate")
    if not res["parts"]["plate"]["layout"] or res["parts"]["two"]["layout"]:
        failures.append("a multi-body 'plate' part is a print layout; 'two' is not")
    if res["parts"]["all"]["printable"]:
        failures.append("'all' should be treated as an assembly view")
    if not res["parts"]["clash"]["compile"]["ok"]:
        failures.append("an empty interference check should pass")
    if res["parts"]["interference"]["compile"]["ok"]:
        failures.append("an overlapping interference check should fail")
    if res["summary"]["parts_failed"] != ["interference"]:
        failures.append("unexpected gate failures: %s" % res["summary"]["parts_failed"])

    good = "\n".join([
        "// === DESCRIPTION ===", "// Design decisions:", "// Terminology → code:",
        "// Common modifications:", "// Overall dimensions: 1x1x1", "// Coordinate system: Z up",
        "// === PRINT SETTINGS ===", "// Material: PLA", "// Layer Height: 0.2",
        "// Walls: 4", "// Infill: 20%", "// Supports: None", "// Orientation: flat",
        "// Notes: none", "// === PARAMETERS ===", "nozzle_diameter = 0.4;", "layer_height = 0.2;",
        "// === DERIVED CONSTANTS ===", "fudge = 0.01;", "tolerance = 0.2;", "ef_chamfer = 0.4;",
        "$fn = $preview ? 32 : 64;", "// === MODULES ===", 'part = "a";',
        'assert(nozzle_diameter > 0);', "// === ASSEMBLY / RENDER ===", 'if (part == "a") cube(1);',
    ])
    st = structure_metrics(good)
    if st["score"] != 1.0:
        failures.append("structure score for a conforming file = %s: %s" % (
            st["score"], [k for k, v in st["items"].items() if not v]))

    for f in failures:
        print("FAIL " + f)
    print("selftest: %d failure(s)" % len(failures) if failures else "selftest: all checks pass")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
