# PETG Material Reference for OpenSCAD Design

## Material Properties

| Property | Value | vs PLA |
|----------|-------|--------|
| Tensile strength | 50-60 MPa | Similar |
| Flexural strength | 70-80 MPa | Slightly lower |
| Young's modulus | 2.0-2.2 GPa | Less stiff (more flexible) |
| Elongation at break | 150-300% | 20-30x more than PLA |
| Impact (Izod, notched) | 2-8 kJ/m^2 | 3-5x better than PLA |
| Glass transition (Tg) | 75-85C | +20C vs PLA |
| Heat deflection (HDT) | 65-70C at 0.45 MPa | +15C vs PLA |
| Shrinkage | 0.3-0.8% | Slightly more than PLA |
| Moisture absorption (24h) | 0.15-0.25% by weight | Hygroscopic — dry before printing |

## Anisotropy (Z/XY Strength Ratios)

| Property | Z/XY Ratio | vs PLA |
|----------|------------|--------|
| Tensile strength | 0.65-0.75 | Better than PLA (0.50-0.75) |
| Layer adhesion | 90-95% of bulk | Significantly better than PLA (75-85%) |

PETG has **superior layer adhesion** — its biggest structural advantage over PLA.

### Layer Adhesion vs Temperature

| Nozzle Temp | Bond Strength | Notes |
|-------------|---------------|-------|
| 230C | 80-85% | Minimum acceptable |
| 240C | 90-95% | Optimal for strength |
| 250C | 95-98% | Maximum, but extreme stringing |

## PETG-Specific Design Rules

### Wall Thickness

| Use Case | Minimum | Recommended |
|----------|---------|-------------|
| Decorative | 0.8mm (2 perimeters) | 1.2mm |
| Light-duty functional | 1.2mm (3 perimeters) | 1.6mm |
| Structural | 1.6mm (4 perimeters) | 2.0-2.4mm |
| Heavy-duty | 2.0mm (5 perimeters) | 2.4mm+ |

**Key insight**: 4 walls + 20% infill is stronger than 2 walls + 50% infill (30% stronger, same material).

### Overhang and Bridging (WORSE than PLA)

PETG overhangs and bridges poorly due to higher print temperature and restricted cooling.

| Angle/Distance | Performance | Notes |
|----------------|-------------|-------|
| 0-30 degrees overhang | Excellent | No issues |
| 30-45 degrees | Good | Minor drooping |
| 45-50 degrees | Fair | Noticeable sag |
| 50+ degrees | Poor | Needs support |
| Bridges <10mm | Excellent | Reliable |
| Bridges 10-20mm | Good | With optimized settings |
| Bridges 20-30mm | Marginal | Requires optimization |
| Bridges 30mm+ | Poor | Needs support |

**Design limit**: Keep overhangs to **45 degrees maximum** (vs 60+ for PLA).

For bridges: reduce temp 5-10C, 100% fan for bridge only, 20-30 mm/s speed.

### Stringing Mitigation (CRITICAL — PETG strings 3-5x worse than PLA)

PETG's biggest print quality problem. Design geometry to minimize it:

**Geometry rules to reduce stringing:**
1. Combine separate features into connected geometry where possible
2. Minimize travel moves between separate printed areas
3. Avoid thin protruding features (<2mm diameter)
4. Add 0.5-1mm fillets on sharp external corners (strings attach to points)
5. Design a corner or edge where Z-seam can hide
6. Space parts >10mm apart when printing multiples
7. Align holes in rows (reduces unique travel paths)

**Features that attract strings (avoid or thicken):**
- Sharp external corners and points
- Isolated features requiring travel
- Thin vertical protrusions (<2mm)
- Small details on large flat surfaces

### Snap-Fit Design (PETG EXCELS here)

PETG's high elongation makes it **ideal for snap-fits** — the opposite of PLA.

| Parameter | PETG | PLA (comparison) |
|-----------|------|------------------|
| Max design strain | 5-8% (repeated) | 1.0-1.5% |
| Single-use strain | 10-15% | 2-3% |
| Cantilever L:T ratio | 10:1 to 15:1 | 10:1 minimum |
| Undercut depth | 0.5-1.0mm | 0.3-0.5mm |
| Undercut angle | 30-45 degrees | N/A (too brittle) |

**PETG snap-fit rules:**
- Print snap features parallel to layer lines for maximum flexibility
- Use 100% infill in snap-fit areas
- Lower layer heights (0.1-0.15mm) improve flexibility
- Use 0.5mm+ fillets at all corners
- Add deflection stops to prevent over-bending

### Living Hinges (PETG is ideal)

PETG's elongation and fatigue resistance make it one of the best filaments for living hinges.

| Hinge Thickness | Cycles to Failure |
|-----------------|-------------------|
| 0.3mm | 50,000-100,000 |
| 0.4mm | 20,000-50,000 |
| 0.5mm | 10,000-30,000 |
| 0.6mm | 5,000-15,000 |

**Design rules:**
- Thickness: 0.3-0.6mm (optimal: 0.4-0.5mm for 0.4mm nozzle)
- Width: 5mm minimum
- **Print hinge perpendicular to layers** (bend along layer lines)
- Use 0% infill in hinge region (single-wall is strongest)
- Taper from thick (2-3mm) to thin (0.4mm) over 2-3mm
- First 5-10 bends should be slow ("work in" the hinge)

### Thread Design

- Larger clearances than PLA due to flexibility: 0.25-0.35mm
- PETG threads wear faster — use brass inserts for repeated use
- Pre-heat inserts to 200-220C (PETG flows around insert well)
- Buttress threads better for FDM than standard metric (45 degree load face, 5 degree relief)

| Thread | External Reduction | Internal Increase |
|--------|-------------------|-------------------|
| M3 | -0.15mm | +0.20mm |
| M4 | -0.20mm | +0.20mm |
| M6 | -0.20mm | +0.25mm |
| M8 | -0.25mm | +0.25mm |

### Clearances and Fits

| Fit Type | Clearance |
|----------|-----------|
| Sliding fit | 0.3-0.4mm |
| Press fit | -0.1 to 0.1mm |
| Snap fit | 0.2mm |
| Thread | 0.25-0.35mm |

## Slicer Parameters Affecting Design

### Temperature

| Purpose | Range |
|---------|-------|
| Structural (max layer bond) | 240-245C |
| Detailed parts (less ooze) | 230-235C |
| Overhangs/bridges | 230-235C |
| First layer | +5C above normal |

### Cooling (CRITICAL DIFFERENCE FROM PLA)

| Feature | Fan Speed | Reason |
|---------|-----------|--------|
| First layer | 0% | Bed adhesion |
| Layers 2-4 | 0-20% | Build foundation |
| Standard layers | **30-40%** | Balance adhesion/quality |
| Overhangs >45 degrees | 50-70% | Prevent sag |
| Bridges | 80-100% | Solidify quickly |
| Small parts <20mm | 50-60% | Prevent heat buildup |

**PLA uses 100% fan. PETG uses 30-40%.** Too much cooling = poor layer adhesion.

### Speed

| Feature | Speed |
|---------|-------|
| Perimeters | 30-50 mm/s |
| External perimeters | 25-40 mm/s |
| Infill | 50-80 mm/s |
| Bridges | 20-30 mm/s |
| Overhangs | 20-35 mm/s |
| Travel | 150-200 mm/s (fast to reduce oozing) |

Speed impact on strength: 30 mm/s = 100%, 50 mm/s = 95%, 70 mm/s = 88%, 90 mm/s = 80%.

## PETG Failure Modes

### Ductile Failure (opposite of PLA)
- **Bends and deforms before breaking** — shows warning signs (whitening, stretching)
- Does not shatter like PLA
- Design implications:
  - Allow deformation space around parts
  - Add stop features to prevent excessive bending
  - Design for buckling resistance (ribs every 30-40mm for compression)

### Warping
- Less than ABS, more than PLA
- Corner lift: 0.5-2mm on prints >100mm
- **Mitigation**: Mouse ears at corners, chamfered edges, 5-10mm brim, rounded corners (5-10mm radius)
- Shrinkage: 0.3-0.8%, scale by 1.003-1.005x for precise fits

### Moisture Degradation

| Moisture Level | Strength Loss | Symptoms |
|----------------|---------------|----------|
| <0.02% (dry) | 0% | Perfect |
| 0.05-0.15% | 0-5% | Slightly rough |
| 0.2-0.4% | 10-20% | Bubbling, strings |
| 0.5-0.8% | 25-35% | Gaps, very rough |
| >1.0% | 40-50% | Unusable |

**Always dry PETG before critical prints**: 60-65C for 4-6 hours.

## Special Applications

### Waterproof Containers
- PETG itself is water-resistant (0.15% absorption)
- Layer lines can wick water — design around this:
  - Minimum walls: 2mm (5 perimeters), recommended 3mm
  - Print walls vertically (layer lines perpendicular to water pressure)
  - Use O-ring grooves for lids (groove depth: 70-80% of O-ring diameter)
  - Labyrinth seals: 3-5 overlapping walls with 0.3-0.5mm gaps
  - Post-process: 2-3 coats food-safe epoxy to seal layer lines

### Outdoor / UV Use
- Moderate UV resistance (better than PLA, worse than ASA)
- 6-12 months: <15% strength loss
- 1-2 years: 20-30% loss, noticeable embrittlement
- **Design for outdoor**: 50% thicker walls, white/light colors (best UV reflection), UV-resistant coatings extend life 50-100%

### Food Contact
- Base PETG is FDA-approved for food contact
- Printed parts have challenges: porous layer lines harbor bacteria
- **Rules**: Use stainless steel nozzle (brass contains lead), food-safe filament, coat with food-safe epoxy
- Suitable for: cookie cutters, dry food storage, cold beverage cups, funnels
- NOT suitable for: repeated use without coating, hot food/beverages, dishwasher

### Impact-Resistant Design
- 3-5x better impact resistance than PLA
- Absorbs energy through plastic deformation
- **Design patterns**:
  - Curved surfaces distribute impact over larger area
  - 3-5mm radius on external corners subject to impacts
  - Honeycomb/ribbed internal structure absorbs energy
  - Thin outer shell (0.8-1.5mm) + internal ribs = best energy absorption

## When to Recommend PETG

**Good for**: Functional mechanical parts, snap-fits, living hinges, outdoor use (1-2 years), impact-resistant parts, waterproof containers, food storage (cold/dry), parts needing flexibility, parts operating 45-70C

**Bad for**: Fine detail (stringing ruins it), parts needing crisp overhangs, dimensionally critical parts (shrinks more), environments >70C, strong chemical exposure (ketones, chlorinated solvents), parts requiring beautiful surface finish without post-processing
