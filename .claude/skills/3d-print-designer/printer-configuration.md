# Printer Configuration

How to identify the printer, check the material against it, and turn its specs into design parameters.

## Step 1: Identify the Printer

**Ask: "What 3D printer are you using?"** If the user names a make and model, match it (fuzzily) against the table below. Show the matched specs and ask about non-stock changes, such as a different nozzle or an added enclosure. If the printer isn't listed, collect the specs in the order of the next section.

### Known printers

All use 1.75mm filament and have auto bed leveling, except the Ender 3 / Pro / V2 and the Ankermake M5C. Layer range with a 0.4 nozzle: Bambu 0.08–0.28mm; Prusa, Voron and Ratrig 0.05–0.30mm; the rest 0.10–0.30mm.

| Printer | Build X×Y×Z mm | Stock nozzle (others) | Hotend / bed max °C | Enclosure | Extruder | Multi-material | Notes |
|---|---|---|---|---|---|---|---|
| Bambu X1 Carbon / X1C | 256×256×256 | 0.4 hardened (0.2, 0.6, 0.8) | 300 / 120 | Yes, passive ~50°C | DD | AMS, up to 16 | Hardened nozzle takes CF/abrasives; the best Bambu for engineering materials (ABS, ASA, PA, PC) |
| Bambu P1S | 256×256×256 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | Yes, passive ~45-50°C | DD | AMS, up to 16 | Enclosure enables ABS/ASA; the 100°C bed limits PC; PA with caution |
| Bambu P1P | 256×256×256 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | No | DD | AMS, up to 16 | PLA, PETG, TPU; no ABS/ASA |
| Bambu A1 | 256×256×256 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | No, bed-slinger | DD | AMS Lite, 4 | PLA, PETG, TPU; tall prints wobble |
| Bambu A1 Mini | 180×180×180 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | No | DD | AMS Lite, 4 | Small parts only |
| Prusa MK4S / MK4 | 250×210×220 | 0.4 brass (0.25, 0.6, 0.8) | 290 / 120 | No (optional) | DD | MMU3, 5 | Asymmetric bed; the 120°C bed handles PC; ABS needs the enclosure |
| Prusa MK3S+ / MK3S | 250×210×210 | 0.4 brass (0.25, 0.6, 0.8) | 280 / 100 | No (optional) | DD | MMU2S, 5 | Asymmetric bed; ABS needs an enclosure |
| Prusa XL | 360×360×360 | 0.4 brass (0.25, 0.6, 0.8) | 290 / 120 | No (optional) | DD, up to 5 toolheads | 5 toolheads, no purge | Segmented bed |
| Prusa Core One | 250×220×270 | 0.4 brass (0.25, 0.6, 0.8) | 290 / 120 | Yes, active airflow | DD | MMU3, 5 | Enclosed CoreXY; all common materials |
| Creality K1C | 220×220×250 | 0.4 hardened (0.6, 0.8) | 300 / 100 | Yes | DD | No | Takes CF; ABS/ASA OK |
| Creality K1 / K1 Max | 220×220×250 / 300×300×300 | 0.4 brass (0.6, 0.8) | 300 / 100 | Yes | DD | No | Brass nozzle: avoid CF |
| Creality Ender 3 V3 / SE / KE | 220×220×250 | 0.4 brass (0.6, 0.8) | 260 / 100 | No | DD (SE: Bowden) | No | 260°C limits it to PLA, PETG, TPU (TPU not on the SE) |
| Creality Ender 3 / Pro / V2 | 220×220×250 | 0.4 brass (0.6, 0.8) | 255 / 100 | No | Bowden | No | PLA, PETG; manual leveling |
| Voron 2.4 | 250², 300² or 350² × 230/280/330 | 0.4, hotend varies (any) | 285-300 / 120 | Yes, ~50-60°C | DD | Optional (ERCF etc.) | A kit, so specs vary: ask for their build size |
| Voron Trident | 250³, 300³ or 350³ | 0.4 (any) | 285-300 / 120 | Yes | DD | Optional | Ask for their build size |
| Voron 0.2 | 120×120×120 | 0.4 (0.2) | 285-300 / 120 | Yes | DD | No | Small, fast parts; layers up to 0.25mm |
| Ankermake M5 / M5C | 235×235×250 | 0.4 brass (0.6, 0.8) | 260 / 100 | No | DD | No | PLA, PETG, TPU |
| Elegoo Neptune 4 Pro / 4 | 225×225×265 | 0.4 brass (0.6, 0.8) | 300 / 110 | No | DD (base 4: Bowden) | No | TPU on the Pro only; ABS limited without an enclosure |
| Ratrig V-Core 4 | 200³ to 500³ | 0.4 (any) | 285-300 / 120 | Optional panels | DD | Optional | A semi-kit: ask for their build size |

### Printer not listed: collect specs manually

In order of importance:

1. **Build volume** (X × Y × Z mm): the maximum single-piece size.
2. **Nozzle diameter** (default 0.4mm): drives every minimum dimension.
3. **Max hotend temperature**, **enclosure**, **max bed temperature**, **extruder type** (direct drive or Bowden): these gate which materials are practical.
4. Only if the design needs them: **auto bed leveling** (large flat parts) and **multi-material** (soluble supports, multi-colour).

Defaults when the user doesn't know: 0.4mm nozzle, 0.2mm layers, 260°C hotend, 100°C bed, no enclosure, direct drive, auto bed leveling, single material.

## Step 2: Validate Material Compatibility

Cross-reference the user's printer capabilities with the requested material:

| Material | Min Hotend | Min Bed | Enclosure | Extruder Notes |
|----------|-----------|---------|-----------|----------------|
| PLA | 200C | 50C (or none) | Not needed | Any |
| PETG | 230C | 70C | Not needed | Any |
| TPU | 220C | 50C | Not needed | Direct drive strongly preferred |
| ABS | 240C | 90C | **Required** | Any |
| ASA | 240C | 90C | **Required** | Any |
| Nylon (PA) | 260C | 80C | Preferred | Direct drive preferred; dry storage critical |
| Polycarbonate | 280C | 110C | **Required** | Direct drive; hardened nozzle recommended |
| CF composites | 240C+ | 80C+ | Preferred | **Hardened nozzle required** (steel/ruby) |

**If the user's printer can't handle the requested material:**
- Warn them clearly: "Your [printer] maxes at [temp]C / has no enclosure — [material] will likely warp/fail."
- Suggest the best alternative their printer supports
- If they want to proceed anyway, note the risk in the PRINT SETTINGS header

## Step 3: Apply Specs to Design Parameters

Printer specs flow into the `// Printer settings` block in every generated .scad file:

```openscad
// === PRINTER ===
// Printer: Bambu Lab P1S (or "Custom / Unknown")
// Build Volume: 256 x 256 x 256 mm

// === PARAMETERS ===
// Printer settings
nozzle_diameter = 0.4;
layer_height = 0.2;
build_x = 256;
build_y = 256;
build_z = 256;
```

### How each spec drives design decisions:

**Build volume** — the hard constraint:
- If any part dimension exceeds build volume, the part MUST be split into a multi-part assembly with joints, fasteners, or alignment features
- Leave 5-10mm margin from bed edges for adhesion reliability
- For bed-slinger printers (e.g., Bambu A1, Ender 3), tall prints are more prone to wobble — prefer wider/shorter orientations

**Bambu X1/P1 front-left exclusion zone** — these printers reserve an **18×28mm front-left corner** of the bed (the `bed_exclude_area` in the machine profile protects the filament-cutter stopper). The real printable square is therefore **~220mm auto-centred** (or ~238mm if the part is shoved fully to the right), NOT the full 256mm — check `bed_exclude_area`, not just build volume, whenever a footprint approaches the bed edges. If the model's footprint would cover that corner:
1. **Preferred:** ask the user to fit Bambu's official stopper-clip mod (a small printed clip that tucks the cutter lever away, per the [full print volume guide](https://wiki.bambulab.com/en/knowledge-sharing/print-volume-limitations)) — this frees the whole 256×256 bed and keeps the design at full size. **Caveat to state every time:** the clip disables the filament cutter, so **AMS / multi-colour cannot be used** on those prints (single-colour only), and the chamber floor must be clear of debris. Bake the cleared bed area into the 3MF (see [bambu-3mf-export.md](bambu-3mf-export.md)).
2. **Fallback:** if the user can't or won't fit the clip (e.g. they need AMS/multi-colour), shrink the footprint to fit the stock exclusion (≤220mm centred) instead.

**Nozzle diameter** — drives minimum dimensions:

| Design Parameter | Formula | 0.4mm Nozzle | 0.6mm Nozzle | 0.2mm Nozzle |
|------------------|---------|-------------|-------------|-------------|
| Extrusion width | nozzle * 1.125 | 0.45mm | 0.675mm | 0.225mm |
| Min wall thickness | 2 * extrusion width | 0.9mm | 1.35mm | 0.45mm |
| Ideal wall multiples | N * extrusion width | 0.9, 1.35, 1.8mm | 1.35, 2.0, 2.7mm | 0.45, 0.9, 1.35mm |
| Min standalone feature | ~4 * extrusion width | ~1.8mm | ~2.7mm | ~0.9mm |
| Hole diameter compensation | +0.3 to +0.4mm | **+0.30mm** (measured, PETG/X1C) | +0.4mm | +0.2mm |
| Sliding fit clearance (per side) | ~0.5 * nozzle | 0.2mm | 0.3mm | 0.1mm |
| Min embossed text line width | ~6 * nozzle | 2.5mm | 3.0mm | 1.5mm |
| Min engraved text line width | ~2.5 * nozzle | 1.0mm | 1.5mm | 0.5mm |
| Max layer height | ~0.75 * nozzle | 0.3mm | 0.45mm | 0.15mm |

**Enclosure** — affects material viability and warping:
- No enclosure: stick to PLA/PETG/TPU. For large flat PLA/PETG parts, consider adding chamfered first-layer edges and avoid sharp corners on the base
- With enclosure: ABS/ASA/Nylon/PC become viable. Note: PLA can soften in enclosed printers if chamber exceeds ~50C

**Extruder type** — affects flexible material design:
- Bowden: TPU possible but tricky (15-20mm/s max). Design TPU parts with thicker walls (min 3x nozzle). Minimize disconnected features on same layer (stringing)
- Direct drive: TPU prints well (25-35mm/s). Standard wall thickness rules apply

**Multi-material** — unlocks advanced techniques:
- Soluble supports (PVA/BVOH): design can include aggressive overhangs, internal cavities, and features that would otherwise need support
- Multi-color: design separate bodies per color, exported as aligned STLs
- Multi-material interfaces: add interlocking geometry at material boundaries
