# ABS Material Reference for OpenSCAD Design

**Print settings (for the header):** nozzle 240C (245-250 for maximum Z-strength, +5 on the first layer), bed 100-110C, fan 0% (a 30-50% burst on bridges only), 8-15mm brim. Dry at 80C for 4-6h.

**Enclosure and ventilation (put both in the PRINT SETTINGS notes):**
- **Enclosure strongly recommended** (40-60C ambient; the bed's heat usually provides it). Without one, uneven cooling warps, cracks and delaminates parts: only parts under ~60mm print in a draft-free room, and a partial enclosure or draft shield suits parts under ~80mm.
- **Ventilation is mandatory, for safety.** ABS emits styrene (a suspected carcinogen), formaldehyde and ultrafine particles. Vent the enclosure outdoors or through HEPA + activated carbon; never print it regularly in an unventilated room.

## Properties

| Property | ABS | vs PLA / vs PETG |
|---|---|---|
| Tensile strength | 40-50 MPa bulk, 25-40 MPa printed XY | Similar / slightly lower |
| Flexural strength | 60-80 MPa | Lower / similar |
| Young's modulus | 1.5-2.5 GPa | Less stiff / similar |
| Elongation at break | 10-50% bulk, 5-25% printed | 5-10x more / less |
| Impact (Izod, notched) | 10-20 kJ/m² | 3-5x / 2-3x better |
| Tg / HDT (0.45 MPa) | 100-110C / 80-100C | +45C / +25C Tg |
| Shrinkage | 0.4-0.9% | More (PLA 0.3-0.5%) / similar |
| Density | 1.04 g/cm³ | Lighter (1.24 / 1.27) |

**Anisotropy (Z/XY):** tensile 0.50-0.75, modulus 0.65-0.85, impact 0.40-0.60 (better than PLA's). Layer adhesion is **highly sensitive to print conditions**: 70-90% of bulk with an enclosure and no fan, 40-60% without, so expect delamination on tall parts printed open. With optimal settings, ABS Z-strength can exceed PLA's.

## Design Rules

```openscad
// === ABS-SPECIFIC PARAMETERS ===
tolerance = 0.4;               // ABS needs more clearance than PLA (0.2) or PETG (0.3)
ef_chamfer = 0.4;              // Slightly more elephant foot than PLA
shrinkage_factor = 1.007;      // 0.7% compensation — adjust after calibration cube
base_corner_radius = 2;        // Round base corners to reduce warping stress
min_wall = 1.6;                // ABS minimum wall (thicker than PLA's 1.2mm)
```

**Walls** (minimum / recommended), thicker than PLA's because of shrinkage stresses: decorative 1.2 / 1.6mm; light-duty functional 1.6 / 2.0mm; structural 2.0 / 2.4mm+; impact-resistant 2.4 / 3.0mm+.

**Minimum features, 0.4mm nozzle** (minimum / practical): pin diameter 2.0 / 2.5mm; hole diameter 1.5 / 2.0mm; text stroke 0.6 / 1.0mm; slot width 0.8 / 1.0mm; emboss or engrave depth 0.4 / 0.6mm.

**Overhangs and bridges: worse than PLA, similar to PETG**, because the fan stays off. **Keep overhangs to 45° maximum**: 45-50° sags noticeably, past 50° needs support. Bridges under 10mm are good, 10-20mm fair, over 20mm need support.

**Infill:** 25-40% gyroid with 4-6 perimeters. Higher infill raises shrinkage forces, so add perimeters rather than infill: 1 perimeter does more than +10% infill.

**Shrinkage (CRITICAL for ABS):** 0.4-0.9%, more in XY than in Z, and more at high infill. Scale critical dimensions by `shrinkage_factor` (calibrate with a 20mm cube) or have the slicer scale 100.5-101%. Holes need +0.3-0.5mm compensation on functional diameters, more than PLA. Print mating parts on the same plate, so they shrink alike.

**Clearances, larger than PLA's because shrinkage varies:** sliding and clearance fits 0.4-0.6mm per side (+0.2mm vs PLA); press fit 0.1-0.2mm (+0.1mm).

**Snap-fits: ABS is good, between PLA and PETG** (PLA, PETG in brackets): max design strain 3-5% (1.0-1.5%, 5-8%); cantilever L:T 5:1 (10:1, 10:1 to 15:1); max undercut 0.8-1.5mm (0.3-0.5mm, 0.5-1.0mm); root fillet 0.5mm minimum (1mm, 0.5mm); lead-in 30-45°. ABS snap-fits handle repeated engagement. Print snap features parallel to the layer lines.

**Anti-warping design (warping is ABS's #1 failure):**
1. **Round base corners**: `offset(r=R) offset(r=-R)` on the 2D footprint before extruding, R = `base_corner_radius`; sharp corners concentrate warping stress
2. **Avoid large flat bottoms**: add relief features or a slight concavity, and ribs every 20-30mm on large flat panels
3. **Taper cross-section changes** over 3-5mm to avoid internal stress
4. **Leave room for an 8-15mm brim**: no delicate features at the base edges; mouse ears (3-5mm discs, 1 layer thick) at rectangular corners
5. **Prefer tall walls to wide flat areas**: print flat panels on edge where you can

## Print Orientation

Orient so the primary failure load does NOT pull layers apart (as for PLA and PETG), AND minimise large flat bottom surfaces that warp. Tension along the layers (XY), never across (Z); compression is the most forgiving. Impact surfaces parallel to the layer planes: ABS excels here. Flat panels vertical where possible. Snap features parallel to the layer lines. For vapor smoothing, keep cosmetic surfaces accessible.

## Environment and Post-Processing

- **Heat:** excellent: holds its properties to 80C in continuous use.
- **UV:** poor: yellows and embrittles within months outdoors. Use ASA for outdoor parts.
- **Chemicals:** resists oils, alkalis and dilute acids; dissolves in acetone, ketones and chlorinated solvents. Not food-safe (styrene).
- **Acetone vapor smoothing** removes the layer lines but dissolves 0.1-0.3mm of surface: allow up to 0.5mm on external surfaces, and expect fine features to soften.
- **Acetone welding** bonds parts close to bulk strength: give mating faces flat overlaps at least 3-5mm wide.
