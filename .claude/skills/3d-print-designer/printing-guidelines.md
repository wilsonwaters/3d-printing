# 3D Printing Guidelines for OpenSCAD

General FDM printing guidelines applicable across all materials. For material-specific rules, see [material-pla.md](material-pla.md) and [material-petg.md](material-petg.md).

## Wall Thickness

Design walls as integer multiples of extrusion width (~1.125x nozzle diameter). Non-multiple thickness forces weak "gap fill" passes.

| Context | Minimum | Recommended |
|---------|---------|-------------|
| Decorative/visual | 0.8mm (2 perimeters) | 1.2mm |
| Light functional | 1.2mm (3 perimeters) | 1.6mm |
| Structural | 1.6mm (4 perimeters) | 2.0mm |
| Heavy-duty / impact | 2.0mm (5 perimeters) | 2.4mm+ |

**Key insight**: Adding 1 perimeter is more effective than doubling infill. Prioritize wall count for strength.

## Tolerances for Mating Parts

| Fit Type | Tolerance | Use Case |
|----------|-----------|----------|
| Press/interference fit | 0.1-0.15mm | Parts that shouldn't move |
| Tight/snug fit | 0.2mm | Lids, caps, snap fits |
| Clearance fit | 0.3-0.5mm | Sliding parts, hinges |
| Loose fit | 0.5-1.0mm | Parts that need to move freely |

Apply tolerance by **adding to holes, subtracting from pegs**:
```openscad
tolerance = 0.2;
cylinder(d = peg_diameter + tolerance);  // Hole
cylinder(d = peg_diameter - tolerance);  // Peg
```

**Holes print 0.1-0.2mm undersized.** Design clearance holes 0.2-0.3mm oversize to compensate.

## Overhangs

### The 45-Degree Rule
- **0-45 degrees from vertical**: Self-supporting on most printers
- **45-60 degrees**: Material-dependent (PLA best, PETG worst)
- **60+ degrees**: Requires support material

### Material-Specific Overhang Limits

| Material | Max Without Support | Notes |
|----------|-------------------|-------|
| PLA | 60-70 degrees | Best due to rapid solidification |
| PETG | 45-50 degrees | Higher temp, less cooling |
| ABS | 40-45 degrees | Poor cooling |

### Design Strategies to Avoid Supports
- Use 45-degree chamfers instead of vertical overhangs
- Split parts along the overhang line and print flat
- Orient the model so overhangs become bridges
- **Bottom edges: chamfer. Top edges: fillet.** (Chamfers are self-supporting)

## Bridging

| Material | Clean Bridge | Functional Bridge | Max Bridge |
|----------|-------------|-------------------|------------|
| PLA | 25mm | 60mm | 80-120mm |
| PETG | 10-15mm | 20mm | 30mm |
| ABS | 15mm | 30mm | 50mm |

Design tips:
- Add 0.5mm ledge at bridge start/end for adhesion
- Design multiple short bridges instead of one long one
- Add intermediate support pillars for long spans
- Keep bridges perpendicular to print direction

## Screw Holes

### Clearance Holes (designed for FDM — already compensated)

| Screw Size | Clearance Hole | Through-Hole |
|------------|----------------|-------------|
| M2 | 2.4mm | 2.6mm |
| M2.5 | 3.0mm | 3.2mm |
| M3 | 3.4mm | 3.6mm |
| M4 | 4.5mm | 4.8mm |
| M5 | 5.5mm | 5.8mm |

### Heat-Set Insert Holes (recommended over printed threads)

| Insert Size | Hole Diameter | Hole Depth | Boss OD |
|-------------|---------------|------------|---------|
| M2 | 3.2mm | 4mm | 6mm |
| M3 | 4.0mm | 5mm | 8mm |
| M4 | 5.6mm | 6mm | 10mm |
| M5 | 6.4mm | 7mm | 12mm |

Heat-set inserts provide 200-600 N pull-out force vs 50-150 N for printed threads. **Always prefer inserts for repeated fastening.**

## Print-in-Place Clearances

| Joint Type | Minimum Clearance | Recommended |
|-----------|-------------------|-------------|
| Rotating (hinge) | 0.3mm radial | 0.4mm |
| Sliding (linear) | 0.2mm per side | 0.3mm per side |
| Ball joint | 0.4mm | 0.5mm |
| Gear mesh (backlash) | 0.3mm total | 0.4mm total |

Clearance must be at least 2x the layer height. At 0.3mm layers, 0.3mm is absolute minimum.

## Dimensional Accuracy

### XY vs Z Accuracy

| Axis | Typical | Well-Tuned |
|------|---------|------------|
| XY (in-plane) | +/- 0.1-0.2mm | +/- 0.05mm |
| Z (layer direction) | +/- 0.05-0.15mm | +/- 0.02mm |

### Critical Compensation Rules

- **Holes**: Design 0.2-0.3mm oversize (holes shrink inward)
- **External features**: Print 0.05-0.1mm oversized
- **Z dimensions**: Use multiples of layer height for exact sizes
- **First layer**: 10-30% compressed, 0.2-0.5mm wider (elephant foot)
- **Elephant foot chamfer**: 0.3-0.5mm at 45 degrees on all bottom edges

### Shrinkage by Material

| Material | Shrinkage | Scale Compensation |
|----------|-----------|-------------------|
| PLA | 0.3-0.5% | 1.003-1.005x |
| PETG | 0.3-0.8% | 1.003-1.008x |
| ABS | 0.8-1.5% | 1.008-1.015x |

## Staircase Effect on Angled Surfaces

| Angle from Horizontal | Step Height (0.2mm layers) | Quality |
|----------------------|---------------------------|---------|
| 0-15 degrees | >0.77mm | Severe — avoid for visible surfaces |
| 15-30 degrees | 0.40-0.77mm | Significant — functional only |
| 30-45 degrees | 0.28-0.40mm | Moderate — acceptable for most |
| 45-60 degrees | 0.23-0.28mm | Mild — good quality |
| 60-90 degrees | 0.20-0.23mm | Minimal — excellent quality |

**Design visible surfaces at 60+ degrees from horizontal.** Use intentional texture (0.2-0.5mm deep) to mask layer lines on angled surfaces.

## Minimum Feature Sizes (0.4mm nozzle)

| Feature | Minimum | Practical |
|---------|---------|-----------|
| Wall thickness | 0.8mm | 1.2mm |
| Pin diameter | 1.5mm | 2.0mm |
| Hole diameter | 1.0mm | 1.5mm |
| Slot width | 0.8mm | 1.2mm |
| Text height | 2.0mm | 3.0mm+ |
| Emboss/engrave depth | 0.3mm | 0.5mm |
| Detail features | 0.4mm | 0.8mm |

## Orientation Decision Checklist

Priority order for choosing print orientation:

1. **Support elimination**: Orient so all overhangs ≤45° — support-free is the default goal
2. **Load path alignment**: Primary loads in XY plane (most important for structural)
3. **Surface quality**: Critical faces perpendicular or parallel to bed
4. **Dimensional accuracy**: Critical tolerances in XY plane
5. **Print time**: Shorter Z-height = faster print

When #1 and #2 conflict, prefer support-free unless the part experiences significant structural loads.
