# Mechanical Rain Gauge "Fable"

A **fully mechanical tipping-bucket rain gauge** — no electronics, no batteries.
Rain collects in a WMO-standard funnel, tips a calibrated bucket, and the tipping
motion itself drives a 4-digit **drum odometer register** reading cumulative
rainfall **0000–9999 mm** (1 dial-mm ≡ 1 mm of rain). A front push-button snaps
the register back to zero, stopwatch-style. PETG on a Bambu Lab (256³), designed
support-free, verified in OpenSCAD.

> Everything lives in one parametric file:
> `mechanical-rain-gauge-fable-v1.scad` (use the `part` variable to export each
> piece; extensive DESCRIPTION / PRINT SETTINGS headers inside).
>
> Ready-to-use exports: **`stl/`** (one per part, verified builds) and
> **`3mf/`** (Bambu Studio *project* files with print settings baked in —
> P1S · 0.20mm Standard · 4 walls · 20% gyroid · no supports; just open,
> pick filament, slice). `previews/` has renders.

## How it works

| Stage | Mechanism | Lineage |
|---|---|---|
| Collect | Ø159.6 mm knife-edge orifice = **exactly 200 cm²** (WMO minimum; the de-facto tipping-bucket standard worldwide). 1 mm of rain = 20 mL. Deep splash rim, ≥45° cone, snap-in debris screen, drip-former lip over the bucket | WMO CIMO Guide No. 8; Hellmann pattern |
| Tip | Dual-chamber seesaw on a Ø3 steel pin in open V-seats; tips every **10 mL = 0.5 mm**; two M3 screws are the calibration stops | Wren & Hooke 1662; every commercial TBRG |
| Count | Bucket crank peg drives a rocker **pin-and-slot**; a single flexure pawl advances the units drum one digit per *driving* tip → **2 tips = 1 mm = 1 count** (a coaxial pawl can only drive one stroke direction — same reason a tally counter counts on press, not press *and* release) | Negretti & Zambra's 1890 mechanical-dial tipping gauge proves tip-driven registers work |
| Carry | 2-tooth sector → 8-tooth long/short transfer pinion → 20-tooth internal ring = **exactly 36° (one digit)** per decade; a locking disc holds idle drums dead still | Veeder-Root US 548,482 (1895), US 2,285,844 |
| Reset | Button slider, staged: nose 1 swings the **pinion yoke out of mesh**, then a fork drives **hammer fingers onto snail cams** — every drum runs forward to 0 independently; the fork *pulls* the hammer clear on release | Reset staging per Veeder-Root US 3,244,368; snail cams as in tally counters |

**Why 0.5 mm per tip is safe for a plastic mechanism:** each driving tip delivers
~1.3 mJ from 10 g of falling water vs ~0.5–1 mJ needed per count. And a heavy
count (e.g. the 0999→1000 triple carry) can never hard-fail — the bucket is
*force-unlimited*: water keeps accumulating until it tips, so the worst case is a
moment's delay, self-correcting to ≤1 count of momentary lag.

## Bill of materials (non-printed)

- **Ø3 mm steel rod, ~230 mm** (a TIG rod / bike spoke works): cut to
  drum shaft (~126 mm) + bucket pivot (~94 mm)
- **2× M3×12** — bucket calibration stops (self-tap into printed bosses)
- **2× M3×10** — pipe-socket clamp screws
- Mounting pipe, **Ø25.4 mm** default (`pipe_od` is parametric)
- Optional: stick-on bubble level; clear PET film behind the window apertures

## Printed parts

| Part (`part=`) | Qty | Orientation (as modeled) |
|---|---|---|
| `funnel` | 1 | spout-lip ring on bed, knife edge up |
| `screen` | 1 | flat |
| `body` | 1 | upright (window corbels + 45° eave are support-free) |
| `base` | 1 | upright (all vertical walls, gothic drain vents) |
| `chassis` | 1 | deck on bed, towers up |
| `bucket` | 1 | chambers up (teardrop pivot bore) |
| `crank` | 1 | flat, peg + lap boss up |
| `drum_units` | 1 | cam flank down (axis vertical) |
| `drum_std` | 3 | cam flank down |
| `pinion` | 3 | ring-gear band down |
| `yoke`, `rocker`, `hammer`, `slider` | 1 ea | flat |
| `detent` | 1 | flat, nub up (a 2 g spring — reprint thicker/thinner to tune click force) |
| `clip` | 6 | flat |
| `plate` | — | all small parts on one 245×237 plate |

## Print settings (PETG)

0.2 mm layers (0.12 mm recommended for drums/pinions/rocker), 4 walls, 20% gyroid
(mechanism smalls 100%), **no supports anywhere**, **no rafts** (they wreck the
running fits), brim for drums/pinions. 30–40% fan; 50%+ on the funnel cone.
**Dry your PETG** (65 °C, 4–6 h) — flexure pawls and springs hate moisture.

## Assembly (bottom-up)

1. **Base**: clamp screws into the socket bosses; drop the **chassis** onto the
   internal ledge.
2. **Register**: slide the **detent** spring into its saddle on the bulkhead
   top (from the bucket side — do this first, drums block it later). Fit the
   **yoke** stubs into their bosses. Thread onto the Ø3 shaft, right-to-left:
   rocker, units drum, pinion+drum ×3 (pinions rest in the yoke saddles);
   lower the shaft into the journal slots; cap with 2 clips. **Hammer** stubs
   into the tower slots last. The detent nub should click softly into the
   units drum's notch track as you turn it.
3. **Slider** through the front rail loops (button forward); its fork strad­dles
   the hammer tail; nose 1 rests on the yoke tail.
4. **Bucket**: press the steel pin through the teardrop bore, rest it in the
   V-seats, cap with 2 clips. Slide the **crank** pocket down over the bucket's
   tab fin; its peg enters the rocker slot.
5. **Body** over the base upstand (bayonet twist); **funnel** onto the body top
   (bayonet twist); **screen** into the funnel ledge.
6. Set all drums to 0 (press the reset button), and you're live.

## Calibration (do this — surface wetting shifts the tip point)

1. Mount on the pipe, **level the funnel rim** (torpedo level across the knife
   edge, two directions).
2. Drip exactly **10 mL** of water slowly into the funnel (syringe): the bucket
   should tip just as the last mL arrives. Turn the M3 stop under the *raised*
   end to adjust (screw in = earlier tip = reads high).
3. Repeat for the other chamber. Commercial practice: calibrate ~2 % *low* to
   offset water lost while the bucket is mid-tip in heavy rain.
4. Sanity check: 100 mL poured slowly = 10 tips = the dial advances 5 mm.

## Honest limits

- **Resolution 1 mm** (one count); the bucket physically resolves 0.5 mm.
- High rain rates under-read slightly (tip-transit loss) — same as every tipping
  gauge; the low calibration offsets it.
- Wind-blown rain can enter the digit apertures; drums shed it and the bay
  drains, but a strip of clear PET film behind the window is a nice upgrade.
- The counter mechanism is printed plastic running dry: expect to tune the pawl
  /detent feel on the first print, and don't oil it (dust paste). PTFE dry lube
  is fine.
- UV: PETG lasts 1–2 years outdoors before embrittling; print in a light colour
  or hit it with UV-resistant clear coat for longer.

## Verification status

Verified on OpenSCAD 2026.06.19 (Manifold backend): all 16 `part=` values +
assembly compile clean; measured bounding boxes within the 250 mm envelope
(largest: funnel 178×178×116, body 174×181×156); all `assert()` contracts pass
(collector area exact, 36°/digit carry ratio, cam/sleeve clearances, 2×10 mL =
1 mm calibration identity, reset staging order, pawl stroke bounds). A
fresh-eyes design review (Opus, clean context) ran the FDM checklist and
mechanism-judgment pass: it caught one real modeling bug (the anti-reverse
detent was a floating solid), which drove the redesign to the separate
saddle-mounted detent spring + shallow notch track; the focused re-review
returned all-clear. **First-print watch items** from the review: the
pawl↔track axial gap (~0.2 mm) and the detent beam's 0.7 mm static clearance
over the ratchet. **Print-only residuals:** true tip volume (calibrate!),
pawl/detent feel, reset feel, bayonet fits.

## Research sources

WMO Guide No. 8 (CIMO) collector guidance; Bureau of Meteorology 203 mm/0.2 mm
standard (RIMCO 7499-BOM); Hellmann 200 cm² pattern; Negretti & Zambra 1890
mechanical-dial tipping gauge (Science Museum co55130); Halliwell's Hyetograph
GB 27,174/1908; Veeder-Root US 548,482, US 2,285,844, US 2,716,524, US 3,244,368;
ratchet feed US 925,855.
