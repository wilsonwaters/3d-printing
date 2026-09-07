# Outdoor Plant Pot Stand

A square open-lattice riser that a tapered square glazed ceramic pot sits on, out on the
pavers. It lifts the pot **25 mm** clear of the ground so the drain hole in the centre of
the pot's base actually drains — water falls straight through the open lattice, then runs
out sideways at ground level and away, instead of the pot sitting in its own puddle.

![Pot stand](preview-iso.png)

**One size suits every pot from a 170 mm to a 200 mm square base** — the whole top is a
single flat plane, so there is no size-specific seat or lip to foul a different pot.

- Footprint **196 × 196 × 25 mm**, one piece, ~123 g of PETG, no supports, no infill.
- 5 × 5 open cells (37.4 mm clear each), with a whole cell dead centre under the pot's
  drain hole.
- Drain channels notched into the bottom of every rib and through the outer wall on all
  four sides, so water can't be trapped anywhere underneath.
- Fully parametric — change `pot_base_max` (or `stand_size`) and re-export for other pots.

## How it suits 170–200 mm bases

| | |
|---|---|
| ![Top view with pot outlines](preview-top.png) | The grey outlines are a **170 mm** base (inner) and a **200 mm** base (outer). Every rib top and the outer wall top are coplanar at z = 25, so any base in between lands flat on a set of ribs — nothing to rock on. |

![Pot outlines on the stand](preview-with-pot.png)

Because the lattice runs edge to edge:

- A **170 mm** pot sits on 4 ribs per axis, and its base edge still lands on the ribs
  running the other way — support goes right out to its rim, not just under its middle.
- A **200 mm** pot covers the whole stand (which then hides underneath it) and is
  supported to within 2 mm of its base edge, including on the outer wall.
- Anything down to about **120 mm** square still works; below that the base stops
  reaching enough ribs.
- A pot **bigger** than 200 mm is fine too — it just overhangs a little more. Nothing
  about the default stand is size-critical, so you don't need to measure precisely
  before printing (only the optional containment lip below cares about exact size).

Two things worth knowing: it raises the pot's centre of gravity by 25 mm, so a tall pot
gets marginally easier to tip — keep it snug against the wall as in the photos. And on
wavy pavers the stand is stiff enough that it won't conform; it'll bed down on the high
spots the same way the pot does now.

## Where the water goes

![Section](preview-section.png)

1. Water leaves the pot's centre drain hole and drops through the open centre cell —
   nothing to line up, nothing to clog.
2. At ground level, a 14 mm wide × 7 mm tall channel is notched through **every** rib at
   each cell centre, in both directions, so water can cross from cell to cell.
3. The same channels cut through the outer wall — **5 exits per side, 20 in total** — so
   it drains away on whichever side the pavers fall.

The notches are 45° triangles (pointed, not square), which is why the whole part prints
with no supports and no bridging.

## Printing

| | |
|---|---|
| Material | **PETG**, in a light colour (Tg 75–85 °C so it won't sag on hot pavers; tough rather than brittle; moderate UV life). ASA/ASA-CF is the upgrade if you have an enclosure. Don't use PLA outdoors — it creeps under load and goes chalky. |
| Layer height | 0.2 mm |
| Walls | 4 perimeters — the part *is* perimeters |
| Infill | **0 %**, top solid layers **0**, bottom solid layers **0–1** (it's an open lattice by design; solid layers would just try to skin the cells) |
| Supports | **None** |
| Brim | **Yes, 5–10 mm.** A 196 mm footprint of thin walls in PETG will lift at the corners without one |
| Orientation | As modelled — flat on the plate, the ground face down |
| Time / material | ~2–3 h, ~123 g |

Bambu X1C/P1 note: at 196 mm centred it clears the 18 × 28 mm front-left filament-cutter
exclusion zone — just don't let the slicer shove it into that corner.

`pot-stand-v1.3mf` is a Bambu Studio project with these settings already applied; open it,
check the plate, slice. Otherwise import `pot-stand-v1.stl` and dial the table above.

## Tuning

Edit the parameters at the top of `pot-stand-v1.scad`. The asserts in the file will stop
the build (with a message) if a change breaks the design rules.

| Want | Change |
|------|--------|
| Different pots | `pot_base_min` / `pot_base_max` — `stand_size` follows as `pot_base_max - 4` |
| An exact footprint | set `stand_size` directly (≤ 216 mm for an X1C) |
| Taller / more airflow | `stand_height` |
| Less filament, faster print | raise `cell_target` (bigger cells) or drop `stand_height` |
| Stiffer | lower `cell_target`, or `rib_walls` 4 → 5 |
| Bigger drain channels | `drain_w` |
| A lip that stops the pot sliding off | `rim_extra = 8` **and** `stand_size = 206` — see below |

### Optional containment lip

![Containment lip variant](preview-corral.png)

`rim_extra` raises **only the outer wall** above the flat seat, turning the stand into a
shallow tray the pot drops into (206 × 206 × 33 mm shown). It needs
`stand_size >= pot_base_max + 4` so the lip sits outside the biggest pot's base rather
than under it — an assert enforces that, so you can't accidentally build a lip your pot
won't fit inside.

```bash
openscad -o pot-stand-corral.stl -D stand_size=206 -D rim_extra=8 pot-stand-v1.scad
```

## Files

- `pot-stand-v1.scad` — parametric OpenSCAD model (all dimensions + design contracts)
- `pot-stand-v1.stl` — default 196 × 196 × 25 mm, ready to slice
- `pot-stand-v1.3mf` — Bambu Studio project with the print settings baked in
- `preview-*.png` — renders (iso, top with pot outlines, front, section, lip variant)

## Inspection aids

Both are off by default and never reach the exported solid:

```bash
openscad -D show_pot=true pot-stand-v1.scad   # ghost the 170/200 mm pot footprints
openscad -D section=1     pot-stand-v1.scad   # cut away at Y=0 to see the drain channels
```
