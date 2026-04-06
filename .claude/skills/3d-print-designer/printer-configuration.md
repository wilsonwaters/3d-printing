# Printer Configuration Guide

How to collect, validate, and apply printer-specific specs to OpenSCAD model design.

## Step 1: Identify the Printer

**Ask: "What 3D printer are you using?"**

### If the user provides a make and model:

1. Look up the printer in [printer-profiles.md](printer-profiles.md)
2. Present the matched specs and ask: "I found specs for your [printer]. Does this look right? Are you using any non-stock modifications (different nozzle size, enclosure mod, etc.)?"
3. Apply any user corrections (e.g., "I swapped to a 0.6mm nozzle", "I added an enclosure")

### If the printer is not in the database:

Collect specs manually in order of importance:

**Must-have (affects model geometry directly):**

1. **Build volume** (X x Y x Z mm) — determines max single-piece part size
2. **Nozzle diameter** (mm) — affects all minimum dimensions (default: 0.4mm if unknown)

**Important (affects material and feature choices):**

3. **Max hotend temperature** (C) — gates which materials are available
4. **Enclosure** (yes/no) — gates whether ABS/ASA/Nylon/PC are practical
5. **Max bed temperature** (C) — supports or limits material adhesion
6. **Extruder type** (direct drive / bowden) — affects TPU capability and stringing

**Ask only if relevant to the current design:**

7. **Auto bed leveling** (yes/no) — affects first-layer strategy for large flat parts
8. **Multi-material capability** (AMS, MMU, etc.) — affects multi-color/soluble support designs

### Sensible defaults (when user doesn't know a spec):

| Spec | Default | Rationale |
|------|---------|-----------|
| Nozzle diameter | 0.4mm | Stock on nearly all consumer printers |
| Layer height | 0.2mm | Good balance of speed and quality |
| Max hotend temp | 260C | Conservative; covers PLA/PETG safely |
| Max bed temp | 100C | Common for mid-range printers |
| Enclosure | No | Most consumer printers are open frame |
| Extruder | Direct Drive | Standard on modern printers (2022+) |
| ABL | Yes | Standard on modern printers |
| Multi-material | No | Most setups are single material |

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

**Nozzle diameter** — drives minimum dimensions:

| Design Parameter | Formula | 0.4mm Nozzle | 0.6mm Nozzle | 0.2mm Nozzle |
|------------------|---------|-------------|-------------|-------------|
| Extrusion width | nozzle * 1.125 | 0.45mm | 0.675mm | 0.225mm |
| Min wall thickness | 2 * extrusion width | 0.9mm | 1.35mm | 0.45mm |
| Ideal wall multiples | N * extrusion width | 0.9, 1.35, 1.8mm | 1.35, 2.0, 2.7mm | 0.45, 0.9, 1.35mm |
| Min standalone feature | ~4 * extrusion width | ~1.8mm | ~2.7mm | ~0.9mm |
| Hole diameter compensation | +0.3 to +0.4mm | +0.3mm | +0.4mm | +0.2mm |
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
