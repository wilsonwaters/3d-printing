# MakerX Acoustic Tile

A set of three **250 × 250 mm, tileable, MakerX-branded acoustic tiles** for FDM
printing (PETG, Bambu Lab 256³, 4-colour AMS). Each is a different acoustic
mechanism so you can mix-and-match; all share one brand library.

| File | Mechanism | What it does | Depth |
|------|-----------|--------------|-------|
| `makerx-qrd-diffuser-v1.scad` | 1-D Schroeder QRD (wells, depth = n² mod 7) | **Diffuses** — scatters reflections in one plane (kills horizontal flutter echo) | ~26.5 mm |
| `makerx-skyline-diffuser-v1.scad` | 2-D skyline (pillar grid, height = (sᵢ+sⱼ) mod 7) | **Diffuses** — scatters in both planes; most architectural look | ~26.5 mm |
| `makerx-perforated-absorber-v1.scad` | Perforated-panel Helmholtz absorber + 8 mm air-gap | **Absorbs** (resonant) — converts energy to heat; foam-boostable | ~9.6 mm |
| `makerx_brand.scad` | Shared library | Palette, embedded X logomark, gradient zones, 4-colour partition, frame | — |

## The acoustics (honest version)

The user target was **4–10 kHz** (cutting harsh high-frequency reflections). That
band is *high* frequency, which is why these tiles are shallow (~26 mm), not the
80 mm+ a bass diffuser would need. Everything is derived parametrically from the
band in `makerx_brand.scad` (`f_low`, `f_high`, `N`):

- **Feature width** sets the top end (`f = c/2w`): wells/cells ≤ ~15–17 mm → good past 10 kHz.
- **Feature depth** sets the bottom end (Schroeder): max well depth 24.5 mm → ~4 kHz.

> **A rigid plastic panel cannot "absorb" broadband sound by reflecting internally** —
> absorption requires energy loss (porous material or resonant friction). So:
> - The **QRD** and **skyline** tiles **diffuse** (scatter) 4 kHz → >10 kHz. This removes
>   the harsh specular reflection / flutter echo; the room sounds less boxy. It does
>   *not* reduce overall energy much (that's diffusion, not absorption).
> - The **perforated absorber** genuinely absorbs, but as a *resonant* device it peaks
>   around **~4 kHz** (bare panel) and broadens to roughly **3–8 kHz** with 6–10 mm of
>   acoustic foam/felt laid in the cavity. It will **not** absorb strongly to 10 kHz.
>
> For full-band high-frequency treatment, combine the absorber (lows of the band) with
> the diffusers (highs).

## Branding

- Palette (from makerx.com.au): black `#0e0f10`, electric blue `#16acf2`, magenta
  `#cc3a9d`, gold `#ffc023`.
- Signature **blue → magenta → gold** diagonal gradient (blue top-left → gold
  bottom-right, matching the website hero), plus the angular **X logomark** as a
  flush solid black inlay.
- Up to **4 colours** via AMS — see export below.

## Multi-colour export (Bambu Studio / AMS)

Each file has a `part` parameter:

```
part = "all" | "black" | "blue" | "magenta" | "gold"
```

- **Single colour / paint-in-slicer:** export `part="all"` → one STL (the whole tile).
- **4-colour AMS:** export each of `black`, `blue`, `magenta`, `gold` as its own STL,
  then in Bambu Studio import all four together and choose **"load as a single object
  (multiple parts)"**, and assign a filament to each part. The four bodies are an exact
  geometric partition (verified Σvolumes = whole, 0% error) so they assemble with no
  gaps or overlaps.

CLI example (PowerShell, with `$PSNativeCommandArgumentPassing='Standard'`):
```
& openscad -o qrd_black.stl -D 'part="black"' makerx-qrd-diffuser-v1.scad
```

## Print settings (PETG)

- 0.2 mm layers, 3–4 perimeters, 15% gyroid infill (diffuser backs).
- **No supports** — features are vertical walls/prisms/holes by design.
- **Orientation:** diffusers print **back-down** (wells/pillars up); the absorber prints
  **front-face-down** (cavity opens up / toward the wall in use). Each `.scad` header
  states this.
- **Large flat PETG base:** 5–8 mm brim + the slicer's **Elephant-Foot Compensation
  (~0.15 mm)** so tiles butt flush (it is *not* modelled). For the absorber use an
  **outer-perimeter brim only** so it doesn't block the first rows of holes.
- Dry PETG (60–65 °C, 4–6 h); 30–40% part-cooling fan.

## Mounting & tiling

- **Mounting:** flat back (diffusers) / standoff frame (absorber) — use removable
  mounting strips (e.g. Command) or spray/construction adhesive, the normal way to hang
  acoustic panels. No screw bosses (a 2 mm back is too thin; bosses would stop it
  sitting flat).
- **Tiling:** tiles butt on a 250 mm pitch. Each tile's gradient runs corner-to-corner,
  so an array forms a repeating diagonal/chevron pattern (intentional, on-brand). For a
  *continuous* gradient across a wall, rotating alternate tiles 180° would align the
  gradient but also flips the X — choose per your layout.

## Status / residuals to confirm with a real print

- Verified on OpenSCAD 2026.06.19 (Manifold): all three compile clean across all `part`
  values, bounding boxes 250×250×26.5 mm (diffusers) / 250×250×9.6 mm (absorber), all
  `assert()` acoustic contracts pass, 4-colour partitions exact.
- **QRD X logo:** the logomark's narrowest strokes (~2–3 mm) stand up to 24.5 mm tall
  amid the deep wells. They are connected/base-anchored and PETG is ductile, but confirm
  robustness on a first print; reduce `mx_logo_w` (brand) if you want a smaller, sturdier
  mark (note: smaller logo = thinner strokes, larger = thicker but covers more wells).
- Acoustic performance figures are theoretical (geometry-derived); real-world response
  depends on mounting, room, and (for the absorber) foam fill.

## Previews

`previews/` contains coloured `--render` views (`*_face.png`, `*_iso.png`) of each variant.
