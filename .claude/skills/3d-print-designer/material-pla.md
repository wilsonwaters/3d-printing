# PLA Material Reference for OpenSCAD Design

**Print settings (for the header):** nozzle 200-210C (215-225 for maximum Z-strength), bed 50-60C, fan 100% (off for the first layer), no enclosure. Layers 0.16-0.20mm; above 0.28mm Z-strength drops, so not for structural parts.

## Properties

| Property | Value | Design impact |
|---|---|---|
| Tensile strength | 47-70 MPa bulk, 25-50 MPa printed Z | Put tensile loads in XY |
| Flexural strength | 80-110 MPa | Good for bending in the XY plane |
| Young's modulus | 2.7-4.1 GPa | Stiff but brittle |
| Elongation at break | 2.5-6% | Very low: snaps without warning |
| Impact (Izod, notched) | 2.0-4.6 kJ/m² | One of the most brittle filaments |
| Tg / HDT (0.45 MPa) | 55-65C / 50-55C | Deforms in hot cars and direct sun; max continuous use 40-45C |
| Shrinkage | 0.3-0.5% | Best dimensional accuracy of common filaments |

**Anisotropy (Z/XY):** tensile 0.50-0.75 (25-50% weaker across layers), modulus 0.70-0.90, impact 0.30-0.50 (extremely weak in Z), fatigue life 0.20-0.40: **never cycle-load across layers**.

## Design Rules

**Walls** (minimum / recommended): decorative 0.8 / 1.2mm; light handling 1.2 / 1.6mm; structural 1.6 / 2.0mm+; impact-resistant 2.4 / 3.0mm+.

**Minimum features, 0.4mm nozzle** (minimum / practical): pin diameter 1.5 / 2.0mm; hole diameter 1.0 / 1.5mm; text stroke 0.5 / 0.8mm; slot width 0.5 / 0.8mm; emboss or engrave depth 0.3 / 0.5mm.

**Overhangs and bridges: the best of any common filament**, thanks to fast solidification under the fan. Safe overhang 45° from vertical (universal), 60-70° achievable with good cooling. Bridges clean to 25mm, functional to 60mm, 80-120mm at most with tuned settings.

**Infill:** gyroid at 20-40% with 3-4 perimeters. One more perimeter is worth roughly double the infill percentage, so add walls before infill.

**Snap-fits: PLA is BRITTLE, the worst common filament for them** (ABS in brackets): max design strain 1.0-1.5% (3-5%); cantilever L:T 10:1 minimum (5:1); max undercut 0.3-0.5mm (0.8-1.5mm); root fillet 1mm minimum (0.5mm). Prefer annular snap-fits over cantilevers (they spread the stress), or compliant mechanisms. Use generous root fillets (prefer 2mm), design for single-use or very gentle engagement, and print snap features parallel to the layer lines. Suggest PETG if the snap must engage repeatedly.

**Creep:** measurable above 10-15 MPa at room temperature. Keep sustained stress in printed parts **under 12-15 MPa** (<25-30% of ultimate). PLA is unsuitable for long-term structural loads (springs, clamps, constant-tension applications).

## Failure Modes

- **Brittle fracture (primary):** sudden, with no visible deformation first, and highly notch-sensitive: sharp corners cut impact strength 60-80%, and holes concentrate stress 2.5-3.0x. **Fillet ALL internal corners** (minimum R=0.5mm, prefer 1-2mm).
- **Layer delamination:** the usual structural failure under Z-axis tension, shear, impact or thermal cycling. Orient loads along the layers and add perimeters.
- **Warping:** 0.1-0.5mm of corner lift on 150mm+ parts. Round corners, chamfer bottom edges, add mouse ears; elephant's foot is 0.1-0.3mm, compensated by the bottom chamfer.
- **Environment:** UV degrades it noticeably in 2-6 months outdoors (10-30% strength loss in 6-12 months), and it deforms above 55C. Not for outdoor use, hot environments or dishwashers.

## Print Orientation

**Critical rule: orient so the primary failure load does NOT pull layers apart.** Tension along the layers (XY), never across (Z). Compression is the most forgiving: Z is acceptable. Impact surfaces parallel to the layer planes. Gears print flat (tooth loads in XY). Mating surfaces on vertical walls, for the best dimensional consistency.

The bed-facing surface is smoothest, the top is good (better with ironing), and vertical walls show regular layer lines. Keep supports off cosmetic and mating surfaces.
