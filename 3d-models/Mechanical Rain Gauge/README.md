# Mechanical Tipping-Bucket Rain Gauge — 4-Dial Odometer (v1: mechanism core)

A fully **mechanical** (no electronics) rain gauge that records rainfall on an old-style 4-dial
odometer counter (**0000–9999, reads directly in mm of rain**). A twin-chamber **tipping bucket**
tips once per **1.0 mm of rain** and mechanically advances the counter one digit per tip. **Manual
knob/lift-rail reset** to 0000.

> **v1 is the mechanism core only** — the hard part. The Ø159.6 mm collector funnel, weatherproof
> housing, glazed digit window and mounting are a planned **v2** that wraps this proven core.

## How the calibration works (why 10 mm rain = 10 mm on the dials)

`1 mm of rain = 1 litre/m² = collected volume (mL) / catch area (cm²) × 10`.
With the WMO-standard **200.0 cm²** collector (Ø159.6 mm, added in v2) and a **20.0 mL** trip volume
per bucket chamber, **each tip = exactly 1.00 mm**. One tip advances the units wheel one digit, so the
dials read rainfall in mm directly. Everything is parametric in `mechanical-rain-gauge-v1.scad` —
change `mm_per_tip` or `catch_area_cm2` and the trip volume recomputes (and is asserted).

## ⚠ The make-or-break risk: tip energy

A single 20 mL tip releases only ~6 mJ (≈2 mJ usable). That has to advance the units wheel **and**,
every 10th tip, drive a decade carry. This is **marginal** — it is the one thing most likely to stop
the gauge working. The design fights it (steel-rod shafts, low-friction lost-motion carry, light
detents, lost-motion pawl slot), but **the OpenSCAD model proves geometry, not function**. You must
validate energy on the bench before trusting the full counter (see staged build below). If the bench
test comes up short, the documented fallbacks are a per-carry energy accumulator or a clock-spring
gated escapement (notes in the `.scad` header).

## Parts (`part=` in the .scad)

| part | qty | what |
|------|-----|------|
| `wheel` | 3 | number wheel with transfer post (units, tens, hundreds) |
| `wheel_top` | 1 | number wheel, no transfer post (thousands) |
| `idler` | 3 | carry idler (countershaft), 1:1 with the ring |
| `drive_pawl` | 1–2 | advances the units ring one tooth per tip (lost-motion slot) |
| `hold_pawl` | 1 | anti-backdrive holding pawl on the units ring |
| `tappet` | 1 | crank keyed to the bucket pivot rod; kicks the drive pawl |
| `bucket` | 1 | twin-chamber tipping bucket, 20 mL/chamber, peaked divider |
| `frame` | 1 | end plates + splash wall (wet/dry) + drain |
| `reset_rail` | 1 | lift-rail to free the wheels for reset |
| `knob` | 1 | reset knob |

**Non-printed:** steel rod — Ø5 (wheel shaft), Ø4 (carry countershaft + reset), Ø3 (bucket pivot);
M3 grub screws + heat-set inserts for bucket calibration; small springs/rubber bands for the pawls.

## Print (PETG, Bambu, 0.4 mm nozzle)

All parts are modeled flat in their print orientation (open faces up, overhangs ≤45°, teardrop
horizontal bores) — slice as-rendered. Use **0.20 mm** layers (0.16 for wheels/idlers/pawls if teeth
look rough), 4 perimeters, ~30% gyroid. **Enable the slicer's elephant-foot compensation (~0.15 mm)**
— sharp first-layer bulge is the #1 cause of sticky counter mechanisms. Dry the PETG first.
**Seal the bucket interior** (food-safe epoxy / wipe-on) so the trip volume is repeatable.

## Build & validate in stages (de-risk by measurement — don't print it all at once)

1. **Bucket energy rig** — print `bucket` + a steel pivot. Measure real trip volume vs 20 mL; check
   it snaps decisively. This validates the energy budget before committing counter geometry.
2. **Units indexer** — `wheel` + `drive_pawl` + `hold_pawl` + `tappet` on a steel shaft. Confirm
   exactly one count per tip across ~100 tips, both directions, no double/skip. Tune detent force.
3. **Decision gate** — enough energy? direct drive stands. If not, add an accumulator / spring escapement.
4. **One decade carry** — 2 wheels + 1 `idler`. Tune `idler_offset` and the transfer-post angle; add a
   leaf detent so the free wheel holds its digit. Verify the 9→0 carry doesn't stall.
5. **Full 4-wheel stack** — verify the 9999→0000 rollover.
6. **Reset** last — `reset_rail` + `knob`; thumb each freed wheel to 0.

## v2 roadmap (after the core works)

Ø159.6 mm knife-edge collector funnel (mouth-up print, ≤45° walls), weatherproof housing over the dry
counter, glazed digit window, level base + feet, debris screen, wall/post mount.

## Research basis

WMO CIMO Guide (200 cm² standard orifice; 1 mm = 1 L/m²); classic tipping-bucket seesaw; Veeder-Root /
odometer decade-carry (US 548,482 Veeder 1895; US 3,554,439 Sigl/Bowmar; US 3,137,444 Harada/GM);
heart-cam reset (Nicole 1844, not used here — manual reset chosen for FDM robustness).
