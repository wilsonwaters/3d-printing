# MakerX Skyline Acoustic Tile (Fable v1)

A 250 × 250 mm parametric wall-tile set that scatters mid/high-frequency
sound reflections and traps a narrow band of speech-frequency energy —
branded with the exact MakerX logo vector and official palette from
[makerx.com.au](https://makerx.com.au/).

Designed fresh by Claude Fable 5 (independent of the earlier
`MakerX Acoustic Tile` project).

## The set

One `.scad` file, two variants via `part=`:

| Variant | What it is | Relief |
|---|---|---|
| `diffuser` | 13×13 quadratic-residue **skyline diffuser**; the acoustic workhorse — print several with different `tile_index` values (0–12) so adjacent tiles don't repeat | 0–48 mm |
| `logo` | Same field, shallow (0–14.4 mm) and all-navy, with the website's actual X-mark polygons extruded 18 mm as a two-colour relief with a 0.8 mm shadow moat | 18 mm X |

## What it honestly does (and doesn't)

- **Diffusion** ≈ 1.8–8.9 kHz: column heights follow `(m²+n²) mod 13` — a
  quadratic-residue sequence with a flat spatial power spectrum. Lower
  limit set by 48 mm max depth (`c/4d`), upper by the 19.2 mm cell width
  (`c/2w`). Partial scattering roughly an octave below. Tames flutter
  echo and harshness; does **not** treat bass — no 250 mm rigid tile can.
- **Resonant absorption** ≈ 700–1260 Hz: columns 32 mm and taller are
  hollow **Helmholtz resonators** (square neck in the cap, 45° internal
  roof). Neck size varies with column height, spreading five resonances
  across the speech band (s=8: ~1258 Hz … s=12: ~705 Hz). This is
  narrowband energy trapping — the closest a rigid printed tile gets to
  "absorbing" — not broadband deadening.
- Arrays work better than single tiles: vary `tile_index` and rotate
  alternate tiles 90°/180° to avoid periodic grating lobes.

## Colours (≤ 4 per tile, official brand CSS values)

Bodies are exported as separate, aligned STLs — import together as one
object in Bambu Studio ("Yes" to *load as single object with multiple
parts*) and assign a filament per part:

| Body | Colour | Hex |
|---|---|---|
| `field` (base + plain columns) | mx-blue navy | `#0f1c57` |
| `accent_gold` (tallest columns, s=12, diffuser only) | mx-gold | `#ffc023` |
| `accent_magenta` (s=11 columns, diffuser only) | mx-magenta | `#cc3a9d` |
| `x_solid` (logo tile) | mx-white | `#f2f2f2` |
| `x_outline` (logo tile) | mx-magenta | `#cc3a9d` |

The logo tile is deliberately a calm 3-colour print (navy field, white +
magenta X) so the mark owns the colour, per design review.

Zero-purge alternative: print each tile `body="all"` in a single brand
colour and mix colours across the wall.

## Printing

- **PLA (matte)**, 0.2 mm layers, 3 walls, 10 % gyroid, no supports,
  **no brim** (250 mm footprint leaves only ~3 mm bed margin per side on
  a 256 mm Bambu bed). PETG also works.
- Fully support-free: vertical columns, 45° internal cavity roofs;
  keyhole and cavity ceilings are short bridges (≤ 16 mm).
- Budget ~0.5 kg and ~20 h per tile.

## 250 mm tiles need the full-volume unlock (X1/P1)

Stock X1/P1 printers exclude an **18 × 28 mm front-left corner** of the
bed — it protects the filament-cutter stopper — so the largest printable
square is 238 mm (dragged fully right) or 220 mm (auto-centred). A 250 mm
tile cannot avoid it in any placement.

Bambu's official fix ([print volume limitations wiki](https://wiki.bambulab.com/en/knowledge-sharing/print-volume-limitations))
unlocks the full 256 × 256 bed:

1. **Hardware**: print a small retainer clip (higher-temp material,
   PETG/ABS) that holds the cutter-lever stopper collapsed, and clean any
   debris from the chamber floor.
2. **Bambu Studio** → Printer settings: clear **"Excluded bed area"** and
   set printable height 250 → 256; keep *Z hop + Z hop upper boundary* ≤
   256 mm in Extruder → Retraction (and in any filament overrides).
3. **Caveats**: the AMS **cannot** be used on full-volume prints (the
   cutter is disabled), so 250 mm tiles are **single-colour** prints.
   Multi-colour AMS tiles must be stock-size — set `tile_size = 220` in
   the model (keyholes and logo rescale automatically in v2).

The shipped `.3mf` files bake a cleared `bed_exclude_area` into the
project (shown as a "(modified)" printer preset), so they slice at full
size once the hardware mod is done. If you haven't done the mod, don't
print them at 250 mm — regenerate at `tile_size = 220` instead.

## Mounting

Two keyhole hangers on the back (150 mm apart, for 4 mm pan-head screws,
tile hangs +Y up = logo upright), or adhesive strips on the flat back.

## Files

- `makerx acoustic tile fable - v2.scad` — the parametric model (current)
- `makerx acoustic tile fable - v1.scad` — superseded; kept for history
  (v1 STL exports had non-manifold edges where diagonal columns touched)
- `stl/` — per-body and combined exports (diffuser index 0 and 1, logo),
  built from v2, verified manifold
- `*.3mf` — Bambu Studio projects with print settings baked in, including
  a cleared "Excluded bed area" for full-volume printing (see above)
- `renders/` — preview images
