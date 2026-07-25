# Mechanical Rain Gauge (Opus 5.0)

A fully mechanical, self-powered rain gauge that totalises rainfall on a 4-digit
"old style" odometer dial — like a water or electricity meter register. It reads
**0000–9999 mm** of rain. No electronics, no battery: the energy to drive the
counter comes entirely from the falling water.

![part list](mechanical-rain-gauge-opus5-v1.scad)

## How it works

| Stage | What happens |
|---|---|
| **Collector** | Round inverted-bucket funnel, sharp level rim, **159.577 mm** aperture = **exactly 200.0 cm²** (the WMO/CIMO standard collection area). This makes 1 mm of rain exactly **20.00 mL**. |
| **Tipping bucket** | Twin chambers, each holding **10.00 mL = 0.5 mm** of rain. Fills, overbalances, dumps, presents the other chamber. Two M3 stop screws trim the tip volume. |
| **Drive** | A crank on the tipper shaft pushes a link, which drives a pawl one tooth of a 10-tooth ratchet on the units wheel. The pawl advances on **one half** of the rocker cycle, so **2 tips = 1 digit = 1.0 mm** of rain. |
| **Register** | Four number wheels with 0–9 on flat facets, read through a window. |
| **Carry (9→0)** | A "mutilated" gear on the lower wheel exposes just **2 teeth**, which kick a 20-tooth transfer pinion 1/10 of a turn once per revolution; the pinion turns the next wheel up one digit. A detent comb holds each wheel crisply on a digit. |
| **Reset** | One push-button. It first rocks the pinion carrier so all three transfer pinions leave mesh, then presses a hammer blade onto a **heart cam** on each wheel. A heart cam pressed by a flat can only rest with its cusp centred, so every wheel is driven to a unique position: **0**. No knob to turn, and it cannot stop between digits. |

## Design lineage

The register is deliberately built the way real cyclometer registers are:

- **US 897379 (Cyclometer, 1908)** — the single/double-tooth carry driver into an
  intermittent transfer pinion, and the *"vibratory frame"* that bodily withdraws
  all the transfer pinions from mesh so the wheels can be zeroed. Both ideas are
  used directly here.
- **Veeder-Root style transfer** — mutilated driver + full-tooth pinion + detent.
- **Chronograph heart-cam reset** — the mechanism that makes a pure push-button
  reset land exactly on zero.
- **WMO/CIMO** guidance for the 200 cm² collection area and the sharp, level,
  outward-sloping rim.

## Why 0.5 mm per tip and not 1.0 mm

A 1 mm/tip bucket at a 200 cm² aperture would need **20 mL** chambers — roughly
three times any commercial tipper, and sluggish. Two 10 mL chambers behave like a
real instrument, and driving the pawl off the half-cycle supplies the 2:1
reduction for free (it also avoids a fragile double-acting pawl). Display
resolution is unchanged at 1 mm either way.

## Parts (all PETG)

| Part | Qty | Notes |
|---|---|---|
| `funnel` | 1 | 175.6 dia × 104 mm. Prints **mouth down** — every layer steps inward, and the aperture edge (the one dimension calibration depends on) is the first layer. |
| `body` | 1 | 182 dia × 178 mm weather shell, top collar, drains, mount lugs |
| `chassis` | 1 | internal deck, tipper bearings, calibration stop screw bosses |
| `tipper` | 1 | twin 10 mL chambers, sloped floors so they drain dry |
| `crank` | 1 | keys onto the tipper hub's D-flat |
| `wheel` | **4** | identical number wheels, 34 mm dia |
| `pinion` | **3** | transfer pinions |
| `reg_frame` | 1 | register U-frame, prints window-face-down |
| `reg_side` | 1 | register back cover |
| `carrier` | 1 | pinion carrier + integral detent comb |
| `hammer` | 1 | reset hammer, one blade per wheel |
| `plunger` | 1 | reset button |
| `pawl` | 1 | drive pawl |
| `link` | 1 | connecting rod |

Non-printed hardware: 3 mm rod (tipper pivot), 4 mm rod (pinion shaft),
a few M3 screws, 2 × M3 set screws for calibration, one light compression
spring for the plunger.

## Printing

```
part = "wheel";   // then render (F6) and export STL (F7)
```

Render a single part from the command line:

```sh
openscad -D 'part="funnel"' -o funnel.stl mechanical-rain-gauge-opus5-v1.scad
```

- **0.20 mm** layers for funnel / body / chassis / tipper
- **0.12 mm** layers for wheels, pinions, pawl, detent comb, hammer
- 4 perimeters general, 5 on the funnel and tipper (so layer lines don't wick water)
- 25% gyroid; 100% infill in the flexures and the link
- **No supports anywhere** — the design is built around that
- Dry the PETG first (60–65 °C, 4–6 h). Wet PETG strings, and there are small gear teeth here.
- 5 mm brim on the funnel: a 176 mm PETG ring will lift at the edge otherwise.

## Calibrating

1 mm of rain = 20.00 mL. Inject **10.0 mL** with a syringe and the bucket should tip
exactly once. Adjust the two M3 stop screws in the chassis to trim. Twenty tips
should read `0010`.

**Do not scale this model** — the calibration depends on the aperture area.

## Siting

Rim at least 300 mm above ground, in the open, clear of obstructions by twice
their height (WMO siting guidance). Level the rim — a tilted rim changes the
effective catch area.
