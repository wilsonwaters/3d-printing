# Pattern: fasteners

**Use when:** the design takes a screw, bolt, threaded stem, nut or heat-set insert, or two printed parts screw together.

## Choose

| Option | When | Refits | Space |
|---|---|---|---|
| Heat-set insert | Load or torque matters | Many | Boss ≈ 2× insert hole |
| Captive nut | High clamp load, no insert or iron | Many | Nut across-corners + 2 walls, and a way in |
| Self-tap hole | No room for a nut, nothing to buy | A few | 2.75 wall round the pilot at M8 |
| Printed thread | Plastic to plastic only (caps, jars), ≥M10 | Many | Depth P/4 |

A metal screw never goes into a printed metric thread: it doesn't form.

## Rules

- **Axis vertical** where you can, so perimeters wrap the hole. A boss or hub taking an insert or a formed thread: ≥4 perimeters, 50-100% infill.
- **Clearance hole:** SKILL.md Rule 8, free-running: `D + hole_comp + 0.30` (M3: 3.6). Recess a head at head Ø + `hole_comp`; a countersink at the top face is self-supporting.
- **Self-tap pilot:** `D − 0.4·P` drawn, about 50% thread as printed. M8: 7.5 held, 7.0 seized. The rule gives M2 1.8, M3 2.8, M4 3.7, M5 4.7, M6 5.6, M10 9.4, the loose end of published tables. Open the mouth to D + 0.6 for 0.5·D so the thread forms only deeper; engage about 1.4·D; pre-form the thread once with a plain bolt. For a size not proven here, print `self_tap_coupon()`.
- **Insert:** the datasheet first. Otherwise typical drawn holes M2 3.2, M3 4.0, M4 5.6, M5 6.4 (well under the knurl Ø); depth = insert length + 1; boss ≈ 2× hole. Iron: PETG 200-220 °C, ABS 230-250 °C (inserts hold best in ABS), PLA per the datasheet.
- **Captive nut:** `$fn = 6` sizes across corners, so divide across-flats by cos 30°. A pocket under a smaller hole leaves a hex ceiling: put it on the top face, slide the nut in from the side, or print one sacrificial layer and drill it out.
- **Printed thread:** axis vertical, downward flank ≤45° from vertical: trapezoidal, buttress with its flat face up, or `coarse_thread()` (BOSL2 `trapezoidal_threaded_rod()` if installed). Radial clearance: PLA 0.2-0.3, PETG and ABS 0.25-0.35. Clash-check mating threads posed a whole number of pitches apart.

## Evidence

| Value | Printer, nozzle | Material | Result | Status | Source | Date |
|---|---|---|---|---|---|---|
| Printed M8×1.25 thread in a cone nut | Bambu, 0.4 | PETG | Didn't form; teeth broke driving it | **failed** | `3d-models/caster-tube-insert` v1 | 2026-07-25 |
| M8 self-tap Ø7.0 (~90% thread) | Bambu, 0.4 | PETG | Seized | **failed** | same, v2 | 2026-07-25 |
| M8 self-tap Ø7.5 (~50%), Ø8.6×4 mouth, 11 engaged, 2.75 wall, pre-formed | X1C, 0.4 | PETG | Held the caster | **proven** | same, v3 | 2026-07-25 |
| Self-tap M6 Ø5.0, M10 Ø9.3 (5.0 breaks the rule: use 5.6) | – | PETG | – | **designed, not printed** | same, README | 2026-07-25 |
| Insert and M2-M5 self-tap sizes, thread clearances, pull-out (insert 200-600 N, printed thread 50-150 N) | – | – | – | **typical** | published tables | – |

## Modules

Gate-tested: each builds one manifold body; a rod and nut cut with `gap = 0.3` clash empty. They use `fudge` and `hole_comp` (Rule 8). Holes run up +Z from z = 0; cut them with `difference()`.

```openscad
module self_tap_hole(d, pitch, engage, mouth = 0, adj = 0) {
    pilot = d - 0.4 * pitch + adj;
    assert(pilot < d, "pilot must be under the screw's major diameter");
    if (mouth > 0) translate([0, 0, -fudge]) cylinder(d = d + 0.6, h = mouth + 2 * fudge);
    translate([0, 0, mouth - fudge]) cylinder(d = pilot, h = engage + 2 * fudge);
}
module insert_boss(hole_d, insert_len, boss_d, h, flare = 1) {   // stands on z = 0
    assert(h >= insert_len + 1, "pocket shallower than insert length + 1");
    assert(boss_d >= 1.75 * hole_d, "boss wall too thin");
    difference() {
        union() { cylinder(d = boss_d, h = h); cylinder(d1 = boss_d + 2 * flare, d2 = boss_d, h = flare); }  // 45° root
        translate([0, 0, h - insert_len - 1]) cylinder(d = hole_d, h = insert_len + 1 + fudge);
    }
}
module nut_pocket(af, h) cylinder(d = (af + hole_comp + 0.1) / cos(30), h = h, $fn = 6);
module coarse_thread(d, pitch, length, gap = 0) {   // gap: radial, for the internal cut
    e = pitch / 8;  n = max($fn, 32);                // depth P/4, flanks ~38° from vertical
    linear_extrude(height = length, twist = -360 * length / pitch, slices = ceil(n * length / pitch))
        translate([e, 0]) circle(d = d - 2 * e + 2 * gap, $fn = n);   // one slice per facet, or flanks overhang
}
module self_tap_coupon(d, pitch, engage, step = 0.1) {   // pilots -step, 0, +step: keep the tightest that drives
    w = d + 6;
    difference() {
        translate([-1.5 * w, -w / 2, 0]) cube([3 * w, w, engage]);
        for (i = [-1 : 1]) translate([i * w, 0, 0]) self_tap_hole(d, pitch, engage, adj = i * step);
    }
}
```
