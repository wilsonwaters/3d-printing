# ABS Material Reference for OpenSCAD Design

## Material Properties

| Property | Value | vs PLA | vs PETG |
|----------|-------|--------|---------|
| Tensile strength | 40-50 MPa (bulk), 25-40 MPa (printed XY) | Similar bulk, similar printed | Slightly lower |
| Flexural strength | 60-80 MPa | Lower | Similar |
| Young's modulus | 1.5-2.5 GPa | Less stiff (more flexible than PLA) | Similar |
| Elongation at break | 10-50% (bulk), 5-25% (printed) | 5-10x more than PLA | Less than PETG |
| Impact (Izod, notched) | 10-20 kJ/m^2 | 3-5x better than PLA | 2-3x better than PETG |
| Glass transition (Tg) | 100-110C | +45C vs PLA | +25C vs PETG |
| Heat deflection (HDT) | 80-100C at 0.45 MPa | +30C vs PLA | +20C vs PETG |
| Shrinkage | 0.4-0.9% | More than PLA (0.3-0.5%) | Similar to PETG |
| Density | 1.04 g/cm^3 | Lighter than PLA (1.24) | Lighter than PETG (1.27) |

## Anisotropy (Z/XY Strength Ratios)

| Property | Z/XY Ratio | Notes |
|----------|------------|-------|
| Tensile strength | 0.50-0.75 | Highly dependent on enclosure/cooling conditions |
| Modulus | 0.65-0.85 | Stiffness moderately affected |
| Impact | 0.40-0.60 | Better than PLA Z-axis impact |
| Layer adhesion | 70-85% of bulk (with enclosure) | Drops to 40-60% without enclosure |

ABS layer adhesion is **highly sensitive to print conditions** — proper enclosure and cooling control is critical. With optimal settings, ABS Z-strength can exceed PLA.

### Layer Adhesion vs Temperature and Environment

| Conditions | Bond Strength | Notes |
|------------|---------------|-------|
| 230C, no enclosure | 40-60% | Poor — expect delamination on tall parts |
| 240C, no enclosure | 55-70% | Marginal — small parts only |
| 235C, with enclosure | 70-80% | Good — acceptable for most uses |
| 240-250C, with enclosure, no fan | 80-90% | Optimal — strongest ABS prints |

## CRITICAL: Enclosure and Ventilation Requirements

### Enclosure (Strongly Recommended)

ABS has a high coefficient of thermal expansion. Without an enclosure, uneven cooling causes warping, cracking, and delamination.

| Enclosure State | Outcome |
|-----------------|---------|
| Full enclosure (45-60C ambient) | Best results — minimal warping, strong layer bonds |
| Partial enclosure / draft shield | Acceptable for parts <80mm |
| No enclosure, draft-free room | Small parts only (<60mm), expect some warping |
| No enclosure, drafty room | Will fail on anything beyond trivial prints |

- The heated bed (100-110C) naturally raises enclosure temperature to 40-50C
- Active enclosure heating is rarely needed for consumer printers
- Keep printer electronics outside the enclosure or ensure adequate ventilation for them

### Ventilation (MANDATORY — Safety Concern)

ABS emits **styrene** (a suspected carcinogen), formaldehyde, and ultrafine particles during printing.

| Ventilation Method | Effectiveness |
|--------------------|---------------|
| Enclosed printer ducted to outside | Best |
| HEPA + activated carbon filter | Very good |
| Open window + enclosure | Moderate |
| Unventilated room | **NOT safe for regular use** |

**Always note ventilation requirements in PRINT SETTINGS header when generating ABS models.**

## ABS-Specific Design Rules

### Wall Thickness

| Use Case | Minimum | Recommended |
|----------|---------|-------------|
| Visual/decorative | 1.2mm | 1.6mm |
| Light-duty functional | 1.6mm | 2.0mm |
| Structural | 2.0mm | 2.4mm+ |
| Impact-resistant | 2.4mm | 3.0mm+ |

ABS minimum wall: **1.5mm** (thicker than PLA due to shrinkage stresses). Design walls as integer multiples of extrusion width (0.4mm nozzle: 0.8, 1.2, 1.6, 2.0mm).

### Minimum Feature Sizes (0.4mm nozzle)

| Feature | Minimum | Practical |
|---------|---------|-----------|
| Pin diameter | 2.0mm | 2.5mm |
| Hole diameter | 1.5mm | 2.0mm |
| Text stroke width | 0.6mm | 1.0mm |
| Slot width | 0.8mm | 1.0mm |
| Emboss/engrave depth | 0.4mm | 0.6mm |

Features are slightly larger than PLA minimums due to ABS shrinkage and reduced overhang performance.

### Overhang and Bridging

ABS overhangs and bridges are **worse than PLA, similar to PETG** due to restricted cooling.

| Angle/Distance | Performance | Notes |
|----------------|-------------|-------|
| 0-30 degrees overhang | Excellent | No issues |
| 30-45 degrees | Good | Minor drooping |
| 45-50 degrees | Fair | Noticeable sag |
| 50+ degrees | Poor | Needs support |
| Bridges <10mm | Good | Reliable with brief fan burst |
| Bridges 10-20mm | Fair | Requires 30-50% fan during bridge |
| Bridges 20mm+ | Poor | Needs support |

**Design limit**: Keep overhangs to **45 degrees maximum**. For bridges, use a brief 30-50% fan burst during the bridge only — fan must be off otherwise.

### Infill

| Use Case | Infill % | Pattern | Notes |
|----------|----------|---------|-------|
| Visual models | 10-15% | Grid or Lines | Minimal material |
| Light-duty functional | 20-25% | Grid or Gyroid | Good strength/weight |
| General functional | 25-40% | Gyroid or Triangular | Sweet spot for ABS |
| Structural | 40-60% | Triangular or Concentric | Diminishing returns above 60% |
| Maximum strength | 80-100% | Concentric | Concentric is strongest for ABS |

**Key insight**: Higher infill increases shrinkage forces. Use 25-40% with more walls (4-6 perimeters) rather than high infill with few walls. Adding 1 perimeter is more effective than adding 10% infill.

### Shrinkage Compensation (CRITICAL for ABS)

ABS shrinks **0.4-0.9%** — significantly more than PLA (0.3-0.5%).

| Approach | Method |
|----------|--------|
| Slicer compensation | Scale to 100.5-101.0% or use horizontal size compensation |
| OpenSCAD compensation | Use `shrinkage_factor = 1.007;` variable, apply to critical dimensions |
| Hole compensation | Add **0.3-0.5mm** to functional hole diameters (more than PLA's 0.2-0.3mm) |
| Calibration | Print 20mm cube, measure, calculate per-axis shrinkage |

Shrinkage is **not isotropic**: XY shrinkage is typically greater than Z shrinkage. Parts with high infill shrink more than low-infill parts.

### Clearances and Fits

| Fit Type | Clearance | vs PLA |
|----------|-----------|--------|
| Sliding fit | 0.4-0.6mm per side | +0.2mm vs PLA |
| Press fit | 0.1-0.2mm | +0.1mm vs PLA |
| Clearance fit | 0.4-0.6mm per side | +0.2mm vs PLA |
| Screw hole (M3 clearance) | 3.5-3.6mm diameter | +0.1mm vs PLA |
| Screw hole (M3 tap) | 2.6-2.8mm diameter | +0.1mm vs PLA |

Tolerances are **larger than PLA** due to shrinkage variability. Consider printing mating parts on the same plate for consistent shrinkage.

### Snap-Fit Design (ABS is Good — Between PLA and PETG)

ABS's elongation (10-50%) makes snap-fits practical — unlike brittle PLA.

| Parameter | ABS | PLA (comparison) | PETG (comparison) |
|-----------|-----|-------------------|-------------------|
| Max design strain | 3-5% | 1.0-1.5% | 5-8% |
| Cantilever L:T ratio | 5:1 | 10:1 minimum | 10:1 to 15:1 |
| Max undercut depth | 0.8-1.5mm | 0.3-0.5mm | 0.5-1.0mm |
| Root fillet | 0.5mm minimum | 1mm minimum | 0.5mm minimum |
| Lead-in angle | 30-45 degrees | N/A (too brittle) | 30-45 degrees |

ABS snap-fits can handle repeated engagement. Print snap features parallel to layer lines.

### Thread Design

- Printable at **M4 and above** (same as PLA)
- Use coarse pitch threads
- Add 0.25-0.35mm clearance (slightly more than PLA)
- **Heat-set brass inserts strongly preferred** — ABS works well with them due to high Tg
  - Boss outer diameter: at least 2x insert diameter
  - Hole diameter: insert outer diameter minus 0.1-0.2mm
  - Insert temperature: 230-250C (higher than PETG due to ABS Tg)

### Anti-Warping Design Strategies

ABS warping is the **#1 printing challenge**. Design geometry to minimize it:

1. **Round base corners** — sharp 90-degree corners concentrate warping stress. Use `offset(r=2)` or chamfer base corners before extruding.
2. **Avoid large flat bottom surfaces** — add relief features, ribs, or a slight concavity to bases.
3. **Use ribs on large flat panels** — ribs every 20-30mm break up shrinkage forces.
4. **Minimize abrupt cross-section changes** — taper transitions over 3-5mm to avoid internal stress buildup.
5. **Design for brim removal** — allow 8-15mm brim width; avoid delicate features at base edges.
6. **Add mouse ears at corners** — 3-5mm diameter, 1-layer-thick discs at rectangular corners.
7. **Prefer taller walls over wider flat areas** — vertical surfaces warp less than horizontal ones.

## Slicer Parameters Affecting Design

### Temperature

| Purpose | Range | Notes |
|---------|-------|-------|
| Nozzle (general) | 235-245C | Start at 240C, adjust +/-5C |
| Nozzle (max Z-strength) | 245-250C | Best layer adhesion |
| Nozzle (first layer) | +5C above normal | Better bed adhesion |
| Bed | 100-110C | Mandatory heated bed |
| Enclosure ambient | 40-60C | Passive from bed heat is usually sufficient |

### Cooling (CRITICAL — OPPOSITE of PLA)

| Feature | Fan Speed | Reason |
|---------|-----------|--------|
| First 3-4 layers | 0% | Mandatory for bed adhesion |
| Standard layers | **0%** | Any fan causes warping/delamination |
| Bridges only | 30-50% (brief burst) | Only during bridge moves, off immediately after |
| Small features <15mm | 10-20% temporarily | Prevent heat buildup |
| Overhangs | 0-20% | Minimal — accept droop over cracking |

**PLA uses 100% fan. PETG uses 30-40%. ABS uses 0%.** Cooling is ABS's enemy.

### Speed

| Feature | Speed | Notes |
|---------|-------|-------|
| Outer walls | 30-40 mm/s | Slower for surface quality |
| Inner walls | 40-50 mm/s | Can be faster than outer |
| Infill | 50-60 mm/s | Can match general speed |
| First layer | 15-25 mm/s | Critical for adhesion — never exceed 30 |
| Bridges | 15-25 mm/s | Slow to minimize sag |
| General | 30-60 mm/s | Slower than PLA for best results |

ABS benefits from slower speeds than PLA. If experiencing delamination, reduce speed by 5 mm/s increments.

### Retraction

| Setting | Direct Drive | Bowden |
|---------|-------------|--------|
| Distance | 1-2mm | 3-4mm |
| Speed | 30-40 mm/s | 40-50 mm/s |
| Minimum travel | 1.0-1.5mm | 1.5-2.0mm |
| Z-hop | 0.1-0.2mm (optional) | 0.2-0.4mm (optional) |

ABS is less prone to stringing than PETG at proper temperatures. Use combing mode to reduce retractions.

### Bed Adhesion Helpers

| Method | Effectiveness | Notes |
|--------|---------------|-------|
| PEI sheet (smooth or textured) | Excellent | Best overall; sticks at temp, releases when cool |
| ABS slurry on glass | Very good | Dissolved ABS in acetone — chemical bond |
| Kapton tape | Very good | Classic ABS surface |
| PVA glue stick | Good | Easy, cheap, water-soluble for removal |
| Hairspray on glass | Good | Unscented works best |

**Brim**: Use 8-15mm width for ABS (wider than PLA's 3-5mm). Use 8-10 brim lines for large parts.

**Draft shield**: A tall skirt around the entire part that blocks air currents — especially useful without a full enclosure.

## ABS Failure Modes

### Warping (Primary Challenge)

- Corners of large rectangular bases lift from the bed
- Caused by differential cooling and thermal contraction
- **Mitigation**: Enclosure + brim + ABS slurry + bed 100-110C + no fan + dry filament + rounded base corners
- Wet filament warps ~30% more than dry

### Layer Delamination / Cracking

- Layers separate due to rapid cooling — ABS's primary structural failure mode
- Can cause complete part failure with loud cracking sounds during printing
- **Mitigation**: Increase nozzle temp to 245-250C, use enclosure, disable fan, slow print speed, dry filament
- If hearing cracks during print: raise enclosure temp and nozzle temp immediately

### Surface Blistering / Bubbles

- Caused by moisture in filament boiling at extrusion temperature
- **Mitigation**: Dry filament at 80C for 4-6 hours; store in dry box with desiccant

### Elephant's Foot

- First layer over-squished due to high bed temperature + nozzle pressure
- **Mitigation**: Slicer's elephant foot compensation (-0.1 to -0.2mm), reduce first layer flow to 90-95%
- Compensation: `ef_chamfer = 0.4` (slightly more than PLA's 0.3)

### Environmental Degradation

- **UV**: Poor resistance — yellowing and embrittlement within months of outdoor exposure. Use ASA instead for outdoor.
- **Heat**: Excellent — maintains properties up to 80C continuous use. Major advantage over PLA and PETG.
- **Chemical**: Resistant to oils, alkalis, dilute acids. Dissolves in acetone, ketones, chlorinated solvents.

## Post-Processing (ABS Excels Here)

### Acetone Vapor Smoothing (Unique to ABS/ASA)

Eliminates visible layer lines by chemically melting the surface. **Not possible with PLA or PETG.**

| Method | Time | Control | Safety |
|--------|------|---------|--------|
| Cold vapor bath (sealed container) | 30-60 min | Best — slow and even | Moderate |
| Warm vapor bath (water bath heated) | 10-30 min | Fast but uneven | **Flammable — never direct heat** |
| Brush application | 1-5 min | Spot treatment only | Moderate |

- Achieves 72-81% surface roughness reduction
- Dissolves 0.1-0.3mm of surface — fine features lose definition
- Design tolerance: account for 0.1-0.5mm loss on external surfaces if vapor smoothing planned

### Acetone Welding

Brush acetone on mating surfaces, press together, hold until evaporated. Creates a **solvent weld approaching base material strength** — far stronger than any glue. Design multi-part assemblies with flat mating surfaces (3-5mm minimum overlap width) for acetone welding.

### Sanding and Painting

- ABS sands easily (better than PETG which gums up)
- Start at 100-200 grit, progress to 400-800+ grit
- Accepts primer and paint very well
- 2 coats filler primer + enamel spray paint for excellent finish

## Print Orientation for ABS

**Critical rule**: Orient so primary failure load does NOT pull layers apart (same as PLA/PETG), AND minimize large flat bottom surfaces that warp.

| Load Type | Orientation Rule |
|-----------|-----------------|
| Tension | Load along layers (XY), never across (Z) |
| Compression | Most forgiving — Z-axis compression is acceptable |
| Impact | Impact surfaces parallel to layer planes — ABS excels here |
| Screw bosses | Print vertically (layers wrap around hole) |
| Flat panels | Print vertically if possible to avoid base warping |
| Snap-fits | Print features parallel to layer lines |
| Parts for vapor smoothing | Orient with cosmetic surfaces accessible |

**Surface finish**:
- Bed-facing: smoothest (PEI/glass finish), but may show elephant's foot
- Top: good
- Vertical walls: regular layer lines — can be vapor-smoothed to glossy
- ABS vertical walls can be acetone smoothed to near-injection-mold finish

## OpenSCAD Design Considerations for ABS

When generating ABS models, apply these ABS-specific parameters:

```openscad
// === ABS-SPECIFIC PARAMETERS ===
// Material: ABS
tolerance = 0.4;               // ABS needs more clearance than PLA (0.2) or PETG (0.3)
ef_chamfer = 0.4;              // Slightly more elephant foot than PLA
shrinkage_factor = 1.007;      // 0.7% compensation — adjust after calibration cube
base_corner_radius = 2;        // Round base corners to reduce warping stress
min_wall = 1.6;                // ABS minimum wall (thicker than PLA's 1.2mm)
```

**ABS-specific OpenSCAD patterns:**

1. **Round base corners** to prevent warping:
```openscad
module abs_base(width, depth, height, corner_r=2) {
    linear_extrude(height)
        offset(r=corner_r)
            offset(r=-corner_r)
                square([width, depth]);
}
```

2. **Hole compensation** — add 0.3-0.5mm (more than PLA):
```openscad
// M3 clearance hole for ABS
abs_m3_clearance = 3.5;  // PLA uses 3.3-3.4
```

3. **Heat-set insert bosses**:
```openscad
module heat_set_boss(insert_od, insert_len, wall_t=2) {
    boss_od = insert_od + 2 * wall_t;
    hole_d = insert_od - 0.15;  // Slightly undersized for press-in
    difference() {
        cylinder(d=boss_od, h=insert_len + 1);
        translate([0, 0, -fudge])
            cylinder(d=hole_d, h=insert_len + 1 + 2*fudge);
    }
}
```

4. **Anti-warp ribs for flat panels**:
```openscad
module flat_panel_with_ribs(width, depth, thickness, rib_spacing=25) {
    // Main panel
    cube([width, depth, thickness]);
    // Bottom-side ribs to resist warping
    for (y = [rib_spacing : rib_spacing : depth - rib_spacing])
        translate([0, y - 0.6, -1.2])
            cube([width, 1.2, 1.2]);
}
```

## Filament Drying

| Parameter | Value |
|-----------|-------|
| Drying temperature | 80C |
| Drying time | 4-6 hours |
| Storage | Dry box with desiccant, <15% RH |
| Wet filament symptoms | Bubbles, popping, rough surface, internal voids |
| Wet filament warping | ~30% worse than dry filament |

**Always dry ABS before critical prints.** Note drying requirements in PRINT SETTINGS header.

## When to Recommend ABS

**Good for**: Heat-resistant parts (up to 80C continuous), impact-resistant functional parts, parts needing acetone vapor smoothing, multi-part assemblies using solvent welding, automotive/mechanical prototypes, snap-fit parts, parts needing painting, lightweight parts (lowest density of common filaments)

**Bad for**: Outdoor/UV exposure (use ASA instead), printing without enclosure or ventilation, dimensionally critical parts (shrinkage), food contact (styrene concerns), fine detail with tight tolerances, beginners (hardest common filament to print), environments without ventilation
