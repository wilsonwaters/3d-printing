# PETG Material Reference for OpenSCAD Design

**Print settings (for the header):** nozzle 240C for the best layer bond (230-235 for detail and overhangs, +5 on the first layer), bed 70-85C, fan 30-40% (0% on the first layer, 80-100% on bridges), no enclosure needed. Hygroscopic: dry at 60-65C for 4-6h before critical prints.

## Properties

| Property | PETG | vs PLA |
|---|---|---|
| Tensile / flexural strength | 50-60 / 70-80 MPa | Similar / slightly lower |
| Young's modulus | 2.0-2.2 GPa | Less stiff (more flexible) |
| Elongation at break | 150-300% | 20-30x more |
| Impact (Izod, notched) | 2-8 kJ/m² | 3-5x better |
| Tg / HDT (0.45 MPa) | 75-85C / 65-70C | +20C / +15C |
| Shrinkage | 0.3-0.8% | Slightly more |
| Z/XY tensile ratio | 0.65-0.75 | Better (0.50-0.75) |
| Layer adhesion | 90-95% of bulk at 240C | Much better (75-85%): PETG's biggest structural advantage |

## Design Rules

**Walls** (minimum / recommended): decorative 0.8mm (2 perimeters) / 1.2mm; light-duty functional 1.2mm (3) / 1.6mm; structural 1.6mm (4) / 2.0-2.4mm; heavy-duty 2.0mm (5) / 2.4mm+. 4 walls + 20% infill is 30% stronger than 2 walls + 50% infill, for the same material.

**Overhangs and bridges are WORSE than PLA** (hotter, less cooling). **Keep overhangs to 45° maximum** (vs 60+ for PLA): 30-45° droops slightly, 45-50° sags, past 50° needs support. Bridges under 10mm are reliable, 10-20mm good with tuned settings, 20-30mm marginal, over 30mm need support.

**Stringing is 3-5x worse than PLA**, so cut travel and points for strings to catch on: connect separate features where possible; thicken protrusions to ≥2mm diameter; avoid small details on large flat surfaces; 0.5-1mm fillets on sharp external corners; give the Z-seam a corner or edge to hide in; space multiple parts >10mm apart and align holes in rows.

**Snap-fits: PETG excels** (PLA in brackets): max design strain 5-8% repeated (1.0-1.5%), 10-15% single-use (2-3%); cantilever L:T 10:1 to 15:1 (10:1 minimum); undercut 0.5-1.0mm deep (0.3-0.5mm) at 30-45°. Print snap features parallel to the layer lines, use 0.5mm+ fillets at all corners, and add deflection stops against over-bending. Note 100% infill in the snap areas (and 0.1-0.15mm layers for more flexibility) in PRINT SETTINGS.

**Living hinges: PETG is ideal.** Cycles to failure: 0.3mm 50-100k, 0.4mm 20-50k, 0.5mm 10-30k, 0.6mm 5-15k. Make them 0.4-0.5mm thick for a 0.4mm nozzle and ≥5mm wide, tapered from 2-3mm thick over 2-3mm. **Print the hinge perpendicular to the layers** so it bends along the layer lines, with 0% infill in the hinge (single-wall is strongest). Work it in with 5-10 slow first bends.

**Clearances:** sliding 0.3-0.4mm, snap 0.2mm, press -0.05 to -0.10mm (interference; 0.00 slides).

## Failure Modes

- **Ductile (opposite of PLA):** bends and whitens before breaking; doesn't shatter. Leave room to deform, add stops against over-bending, and ribs every 30-40mm against buckling under compression.
- **Warping:** less than ABS, more than PLA: 0.5-2mm corner lift on prints over 100mm. Round footprint corners (5-10mm radius), chamfer bottom edges, add mouse ears at sharp corners, leave room for a 5-10mm brim. Scale precise fits by 1.003-1.005 for the 0.3-0.8% shrinkage.

### First-Layer Fragmentation (open/skeletal footprints)

On an open footprint (lattices, grids, frames, ribbed or perforated plates), any feature cut down to z=0 (drain channels, notches, slots) **severs the first layer into islands with free ends**, and PETG curls from free ends. A slicer brim can't reach the interior islands: it's geometry, not a setting.

Measured on a 196mm PETG lattice (the outdoor pot stand), textured PEI plate:

| | channels cut to z=0 | channels on a sill + flared foot |
|---|---|---|
| First-layer islands | **36** (avg 0.9cm²) | **1** |
| Plate contact area | 32.6cm² | 72.8cm² |
| Outcome | peeled repeatedly, brim on *and* off | prints |

1. **Never cut a through-feature to z=0 on an open footprint.** Stand it on a sill of at least 3 layers (0.6-0.8mm), so the bottom stays one connected region. Water steps over 0.8mm.
2. **Flare the foot rather than chamfering it** wherever nothing mates at the plate: widen every wall ~0.5-0.8mm per side at the plate, tapering back at 45°. It's self-supporting, a brim built into the part. Set the slicer's elephant-foot compensation to 0 and drop `ef_chamfer` on that face.

The gate's `first layer` report shows the regions and their areas; its `WARN` line flags an island under 1cm² or a largest region under 20%.

## Special Applications

- **Watertight:** layer lines wick water. Walls ≥2mm (5 perimeters), 3mm recommended, printed vertical so the layer lines are perpendicular to the water pressure. O-ring grooves 70-80% of the cord diameter deep; labyrinth seals of 3-5 overlapping walls with 0.3-0.5mm gaps. 2-3 coats of food-safe epoxy seal the layer lines.
- **Outdoor/UV:** better than PLA, worse than ASA: under 15% strength loss in 6-12 months, 20-30% in 1-2 years. Walls 50% thicker, in white or a light colour.
- **Food contact:** cold and dry only (dry storage, cookie cutters, cold drinks), never hot food or the dishwasher. Layer lines harbour bacteria: food-safe filament, a stainless nozzle (brass contains lead) and a food-safe epoxy coat.
- **Impact:** absorbs energy by deforming. Curved surfaces, a 3-5mm radius on exposed external corners, and a thin outer shell (0.8-1.5mm) over internal ribs or honeycomb.
