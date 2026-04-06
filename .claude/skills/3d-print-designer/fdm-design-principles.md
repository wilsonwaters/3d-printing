# FDM Design Principles for OpenSCAD

## The #1 Rule: Design for Print Orientation from the Start

Do NOT design a generic shape then figure out how to print it. Every design decision must account for how the part is built: layer by layer, bottom to top, with directional strength.

## Material Anisotropy

The inter-layer bond is ALWAYS the weakest point. This is the single most important structural fact for FDM.

| Material | Z/XY Tensile | Z/XY Compression | Z/XY Impact |
|----------|-------------|-------------------|-------------|
| PLA | 50-70% | 80-95% | 30-50% |
| PETG | 65-75% | 75-90% | 50-70% |
| ABS | 30-50% | 70-85% | 40-60% |

**Compression is much less affected than tension.** Compressive loads squeeze layers together rather than pulling them apart.

## Load Path Rules

| Load Type | Rule |
|-----------|------|
| Tension | NEVER in Z-direction if avoidable. Align with XY plane. If unavoidable, increase cross-section 2-3x. |
| Compression | Z-direction is acceptable. Failure is by buckling, not delamination. Use thick perimeters. |
| Bending | Orient neutral axis parallel to layers. Tension surface must be continuous XY extrusion. |
| Shear | In-plane (XY) is excellent. Across layers (Z) is the weak point. |
| Torsion | Hollow shaft with layers along the wall (continuous in XY) is strong. |

## Structural Optimization: Walls vs Infill vs Ribs

### The Critical Insight

**Adding 1 perimeter is roughly equivalent to doubling infill percentage for strength.** Perimeters are far more material-efficient than infill.

| Perimeters (0.4mm nozzle) | Wall Thickness | Use Case |
|---------------------------|---------------|----------|
| 2 | 0.8mm | Non-structural, display |
| 3 | 1.2mm | Standard functional |
| 4 | 1.6mm | High-strength mechanical |
| 5 | 2.0mm | Critical structural |
| 6+ | 2.4mm+ | Diminishing returns |

### Recommended Combinations

| Goal | Perimeters | Infill | Pattern |
|------|-----------|--------|---------|
| Lightweight | 2 | 10% | Lines |
| Standard | 3 | 15% | Grid or gyroid |
| Strong | 4 | 20% | Gyroid |
| Maximum | 5 | 30% | Gyroid or triangular |

Going above 5 perimeters + 30% infill is rarely justified.

### Infill Patterns

- **Gyroid**: Best all-around. Equal strength in all axes, no weak planes. Default recommendation.
- **Grid**: Good for XY loads, fast to print.
- **Triangular**: Excellent compression resistance.
- **Honeycomb**: Very good compression, slow to print.

### Ribs (Most Material-Efficient Reinforcement)

Thin ribs print as solid walls (all perimeters, no infill) making them inherently very strong per gram.

| Parameter | Value |
|-----------|-------|
| Rib thickness | 1.2-2.0mm (3-5 perimeters) |
| Rib height | 2-5x rib thickness (unsupported) |
| Rib spacing | 10-20mm for stiffening panels |
| Base fillet | 0.5-1.0mm minimum (stress distribution) |

**Print ribs vertically whenever possible.** Vertical ribs are continuous perimeter walls and are extremely strong. Horizontal ribs (parallel to layers) are 50-80% weaker.

A single 2mm rib uses ~10-20% of the material of equivalent solid cross-section. Three ribs at 10mm spacing provide ~30-40% stiffness at ~20% weight.

## Stress Concentration Management

### Sharp Internal Corners Are Catastrophic in FDM

A sharp internal corner aligned with a layer boundary is a crack initiation site. This is the **#1 cause of FDM part failure**.

| Corner Treatment | Stress Concentration Factor |
|-----------------|---------------------------|
| Sharp (0mm radius) | 4-10x |
| Small fillet (0.5mm) | 2-3x |
| Medium fillet (1-2mm) | 1.5-2x |
| Large fillet (3mm+) | 1.1-1.3x |

### Fillet vs Chamfer Decision

| Location | Use | Reason |
|----------|-----|--------|
| **Bottom surfaces** | 45-degree chamfer | Self-supporting, no supports needed |
| **Top surfaces** | Fillet | Better appearance, no support concern |
| **Internal corners under stress** | Fillet 2mm+ | Best stress distribution |
| **Angled surfaces** | Chamfer | Cleaner FDM staircase pattern |

**Rule**: Fillet on top, chamfer on bottom. Minimum 1mm on all internal corners.

## Print Orientation Strategy

### Priority Order

1. **Support elimination** (strongest preference): orient so all overhangs are ≤45° — support-free printing is the default goal
2. **Load path alignment**: primary loads in XY plane (along layers, not across them)
3. **Surface quality**: critical faces perpendicular or parallel to bed
4. **Dimensional accuracy**: critical tolerances in XY (more accurate than Z)

When #1 and #2 conflict, prefer support-free unless the part will experience significant structural loads. In that case, ask the user which trade-off they prefer.

### Designing Orientation Cues Into the Model

- Make one face clearly the "bottom" (largest flat surface)
- All slopes on upper portion should be <45 degrees from vertical
- Consider engraving "PRINT THIS SIDE DOWN" on internal surface

### When to Split Parts

- **Support-heavy geometry that can't be reoriented** — splitting is often better than printing with supports
- Opposing orientation requirements (critical surfaces on top AND bottom)
- L-shaped or branching geometry
- Multiple perpendicular load directions
- Size exceeding build volume

## Support-Free Design Techniques

**Goal: eliminate supports entirely through geometry and orientation choices.** Supports waste material, leave surface marks, risk failures, and add post-processing. Apply these techniques in priority order.

### The 45-Degree Rule

- **≤45° from vertical**: Self-supporting (no supports needed)
- **Conservative target**: 40° (safe on any printer)
- **Aggressive target**: 50-55° (well-tuned printer, good cooling)

### Chamfers Instead of Fillets on Undersides

A 45° chamfer is fully self-supporting. A fillet (concave curve) on the bottom requires support because the tangent at the start is horizontal. **Bottom: chamfer. Top: fillet.**

### Replace Flat Overhangs with Angled Geometry

Flat horizontal overhangs (shelves, ledges, lips) always need support. Replace them:

| Instead of... | Use... | Why |
|---|---|---|
| Flat shelf/ledge | 45° chamfer on underside | Self-supporting, still functional |
| Rectangular pocket (open bottom) | Pocket with chamfered or V-shaped floor | Eliminates horizontal overhang |
| Flat-topped opening/arch | Pointed (gothic) arch or 45° peaked top | Both sides self-supporting |
| Horizontal overhang step | Graduated 45° ramp or staircase of ≤45° steps | Each step self-supports the next |
| Flat ceiling in enclosure | Domed/peaked/bridged ceiling | Eliminates large flat overhang |

### Tapered and Graduated Overhangs

When a feature must extend outward, build it gradually:
- **Staircase**: A series of small steps, each ≤45° overhang from the step below
- **Taper from below**: Start the feature wider at the base, narrow as it extends outward at ≤45°
- **Built-in support ribs**: Add thin vertical ribs under overhanging features that become structural elements of the design

### Gothic Arches Instead of Round Arches

A semicircular arch has a 0° overhang at the top (horizontal). A pointed/gothic arch with ≤45° sides is fully self-supporting. Use `hull()` of two offset circles for smooth gothic arch profiles.

```openscad
// Self-supporting gothic arch profile
module gothic_arch(width, height) {
    r = width / 2;
    intersection() {
        translate([-width/2, 0]) square([width, height]);
        hull() {
            translate([-width/4, 0]) circle(r=r);
            translate([width/4, 0]) circle(r=r);
        }
    }
}
```

### Bridges (Short Spans Without Support)

Maximum reliable bridge by material:
- PLA: 25mm clean, 60mm functional
- PETG: 10-15mm clean, 20mm functional
- ABS: 15mm clean, 30mm functional

Design bridges as short as possible. Add intermediate pillars for long spans. Prefer multiple short bridges over one long one.

### Part Splitting for Support-Free Printing

When a single part has geometry that cannot be made self-supporting:
1. Identify the overhang boundary
2. Split the part along that boundary into two pieces
3. Print each piece with the flat split face on the build plate
4. Join with glue, fasteners, or alignment pins

This often produces a stronger result than printing with supports, since both pieces have optimal layer orientation.

## Advanced Techniques

### Teardrop Holes (for Horizontal Holes)

Standard horizontal holes have a 0-degree overhang at the top. Replace with teardrop profile:
- Bottom half: exact semicircle
- Top half: straight sides converging at 45 degrees to a point
- All surfaces are self-supporting

```openscad
module teardrop_hole(d, h) {
    r = d / 2;
    rotate([90, 0, 0])
        linear_extrude(height=h, center=true)
            union() {
                circle(r=r, $fn=64);
                polygon([[- r, 0], [r, 0], [0, r]]);
            }
}
```

Use when: hole axis parallel to build plate, support-free printing needed, functional holes for bolts/shafts (bolt sits in circular bottom half).

### Elephant Foot Compensation

First layer spreads 0.2-0.5mm wider due to bed squish.

| Material | Chamfer Width |
|----------|--------------|
| PLA | 0.3-0.4mm |
| PETG | 0.4-0.5mm |
| ABS | 0.2-0.3mm |

```openscad
module elephant_foot_chamfer(size, ef=0.4) {
    hull() {
        translate([ef, ef, ef])
            cube([size[0] - 2*ef, size[1] - 2*ef, size[2] - ef]);
        cube([size[0], size[1], 0.01]);
    }
}
```

### Mouse Ears (Built-In Brim Alternative)

Small discs at corners for bed adhesion, easier to remove than slicer brim:

```openscad
module mouse_ear(d=15, h=0.2) {
    cylinder(h=h, d=d, $fn=32);
}
```

- Diameter: 10-20mm, thickness: 1 layer height
- Place at corners of base, 2-4 per part
- Score line between ear and part for easy removal

### Designing for Nozzle Size

Wall thickness should be integer multiples of extrusion width (~1.125x nozzle diameter):

| 0.4mm Nozzle | 0.6mm Nozzle |
|-------------|-------------|
| 0.9mm (2 walls) | 1.35mm (2 walls) |
| 1.35mm (3 walls) | 2.0mm (3 walls) |
| 1.8mm (4 walls) | 2.7mm (4 walls) |

Non-multiple thickness forces weak "gap fill" passes. Always design to multiples.

```openscad
nozzle = 0.4;
extrusion_w = nozzle * 1.125;
walls = 4;
wall_thickness = extrusion_w * walls; // 1.8mm
```

## Dimensional Accuracy

### XY vs Z

| Axis | Typical Accuracy | Well-Tuned |
|------|-----------------|------------|
| XY | +/- 0.1-0.2mm | +/- 0.05mm |
| Z | +/- 0.05-0.15mm | +/- 0.02mm |

### Compensation Rules

- Holes print 0.1-0.2mm undersized — design 0.2-0.3mm oversize
- External features print 0.05-0.1mm oversized
- Z dimensions: use multiples of layer height for exact sizes
  - Example: 10.2mm = 34 layers x 0.3mm (exact) vs 10.0mm = 33.33 layers (rounds to 9.9mm)
- First layer: 10-30% compressed, 0.2-0.5mm wider (elephant foot)

### Staircase Effect on Angled Surfaces

| Angle from Horizontal | Step Height (0.2mm layers) | Assessment |
|----------------------|---------------------------|------------|
| 15 degrees | 0.77mm | Severe stepping |
| 30 degrees | 0.40mm | Noticeable |
| 45 degrees | 0.28mm | Visible at close range |
| 60 degrees | 0.23mm | Slight |
| 75 degrees | 0.21mm | Nearly smooth |
| 90 degrees (vertical) | 0.20mm | Layer line only |

**Design visible surfaces at 60+ degrees from horizontal** for best quality.

## Common Mistakes

### Over-Engineering
- >30% infill: minimal benefit, massive material/time cost
- >5 perimeters: <5% strength gain per additional perimeter
- 100% infill in large sections: use perimeters + 20% infill instead
- Walls >5mm: use ribs instead (far more efficient)

### Under-Engineering
- Missing fillets on internal corners: #1 cause of failure
- Ignoring Z-axis weakness: hook printed upright fails at 30% of expected load
- Uniform thin walls: need variable thickness (thick at stress points)
- Using datasheet properties without safety factor: use 2-3x for XY, 3-5x for Z
- Holes not compensated: design 0.2-0.3mm oversize

### CNC/Injection Molding Habits That Fail in FDM
- Sharp internal corners (crack initiation at layer boundaries)
- Thin walls <0.8mm (FDM can't reliably print)
- Tight tolerances <0.1mm (FDM achieves 0.1-0.2mm)
- Small holes <1.5mm (come out oval or filled)
- Assuming isotropic material (FDM is highly anisotropic)
- Uniform wall thickness (missed optimization opportunity)
