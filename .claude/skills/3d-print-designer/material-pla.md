# PLA Material Reference for OpenSCAD Design

## Material Properties

| Property | Value | Design Impact |
|----------|-------|---------------|
| Tensile strength | 47-70 MPa (bulk), 25-50 MPa (printed Z-axis) | Use XY orientation for tensile loads |
| Flexural strength | 80-110 MPa | Good for bending in XY plane |
| Young's modulus | 2.7-4.1 GPa | Stiff but brittle |
| Elongation at break | 2.5-6% | Very low — snaps without warning |
| Impact (Izod, notched) | 2.0-4.6 kJ/m^2 | One of the most brittle filaments |
| Glass transition (Tg) | 55-65C | Deforms in hot cars, direct sunlight |
| Heat deflection (HDT) | 50-55C at 0.45 MPa | Max continuous use: 40-45C |
| Shrinkage | 0.3-0.5% | Low — best dimensional accuracy of common filaments |

## Anisotropy (Z/XY Strength Ratios)

| Property | Z/XY Ratio | Implication |
|----------|------------|-------------|
| Tensile strength | 0.50-0.75 | 25-50% weaker across layers |
| Modulus | 0.70-0.90 | Stiffness less affected |
| Impact | 0.30-0.50 | Extremely weak Z-axis impact |
| Fatigue life | 0.20-0.40 | Never cycle-load across layers |

## PLA-Specific Design Rules

### Wall Thickness

| Use Case | Minimum | Recommended |
|----------|---------|-------------|
| Visual/decorative | 0.8mm | 1.2mm |
| Light handling | 1.2mm | 1.6mm |
| Structural | 1.6mm | 2.0mm+ |
| Impact-resistant | 2.4mm | 3.0mm+ |

Design walls as integer multiples of nozzle diameter (0.4mm nozzle: 0.8, 1.2, 1.6, 2.0mm).

### Minimum Feature Sizes (0.4mm nozzle)

| Feature | Minimum | Practical |
|---------|---------|-----------|
| Pin diameter | 1.5mm | 2.0mm |
| Hole diameter | 1.0mm | 1.5mm |
| Text stroke width | 0.5mm | 0.8mm |
| Slot width | 0.5mm | 0.8mm |
| Emboss/engrave depth | 0.3mm | 0.5mm |

### Overhang and Bridging

- **Safe overhang angle**: 45 degrees from vertical (universal)
- **PLA-optimized**: 60-70 degrees achievable with good cooling
- **Clean bridges**: up to 25mm
- **Functional bridges**: up to 60mm
- **Maximum bridges**: 80-120mm (100% fan, slow speed, optimized settings)

PLA has the **best overhang and bridging performance** of any common filament due to rapid solidification with fan cooling.

### Infill

- **Best general pattern**: Gyroid (3D isotropy, impact resistance)
- **Sweet spot**: 20-40% infill with 3-4 perimeters
- **Key insight**: Adding 1 perimeter is roughly equivalent to doubling infill percentage for strength. Prioritize wall count over infill.

### Snap-Fit Design (PLA is BRITTLE — special rules apply)

PLA's low elongation (2.5-6%) makes it the worst common filament for snap fits.

| Parameter | PLA | ABS (for comparison) |
|-----------|-----|----------------------|
| Max design strain | 1.0-1.5% | 3-5% |
| Cantilever L:T ratio | 10:1 minimum | 5:1 |
| Max undercut depth | 0.3-0.5mm | 0.8-1.5mm |
| Root fillet | 1mm minimum | 0.5mm |

**Design strategies for PLA snap-fits:**
- Prefer annular snap-fits over cantilever (distribute stress)
- Use compliant mechanisms where possible
- Add generous root fillets (minimum 1mm, prefer 2mm)
- Design for single-use or very gentle engagement
- Print snap features parallel to layer lines
- Consider PETG instead if repeated snap engagement needed

### Thread Design

- Printable at **M4 and above** only
- Use coarse pitch threads
- Add 0.2-0.3mm clearance
- Prefer trapezoidal profiles over standard metric
- For **M5 and below**: strongly recommend heat-set brass inserts
  - Insert pull-out: 200-600 N vs printed thread: 50-150 N

### Creep and Sustained Loads

- Measurable creep above 10-15 MPa at room temperature
- Design sustained loads at **<25-30% of ultimate tensile strength**
- For printed parts: keep sustained stress **under 12-15 MPa**
- PLA is unsuitable for long-term structural loads (springs, clamps, constant-tension applications)

## Slicer Parameters Affecting Design

### Temperature

| Purpose | Range | Notes |
|---------|-------|-------|
| General use | 200-210C | Standard balance |
| Maximum Z-strength | 215-225C | More stringing |
| Best overhangs | 190-200C | Better solidification |

### Layer Height

- **Optimal balance**: 0.16-0.20mm
- **Best XY strength/surface**: 0.10mm (slow)
- **Above 0.28mm**: reduced Z-strength, avoid for structural

### Cooling

- **100% fan for everything** except first layer (0%)
- PLA demands aggressive cooling more than any other filament
- Reduce to 50-70% only when prioritizing Z-strength over surface quality

### Speed

- General: 40-70 mm/s
- Volumetric flow limit: 10-12 mm^3/s (standard hotend)
- Above 100 mm/s: Z-strength drops 10-20%

## PLA Failure Modes

### Brittle Fracture (Primary Failure Mode)
- **Sudden failure without warning** — no visible deformation before break
- Highly notch-sensitive: sharp corners reduce impact strength 60-80%
- **Mitigation**: Fillet ALL internal corners (minimum R=0.5mm, prefer 1-2mm)
- Holes create stress concentration factors of 2.5-3.0x

### Layer Delamination
- Most common structural failure in Z-axis loading
- Caused by: Z-axis tension/shear, impacts, thermal cycling
- **Mitigation**: Orient correctly, increase perimeters, use wider extrusion width, print hotter/slower for critical parts

### Warping
- PLA warps less than most materials but still shows 0.1-0.5mm corner lift on 150mm+ parts
- **Mitigation**: Mouse ears, rounded corners, chamfered bottom edges
- Elephant's foot: 0.1-0.3mm, compensate with bottom chamfer

### Environmental Degradation
- **UV**: Noticeable in 2-6 months outdoors, 10-30% strength loss in 6-12 months
- **Heat**: Parts deform above 55C (hot car, direct sunlight in summer)
- **Not suitable for**: Outdoor use, hot environments, dishwashers

## Print Orientation for PLA

**Critical rule**: Orient so primary failure load does NOT pull layers apart.

| Load Type | Orientation Rule |
|-----------|-----------------|
| Tension | Load along layers (XY), never across (Z) |
| Compression | Most forgiving — Z-axis compression is acceptable |
| Impact | Impact surfaces parallel to layer planes |
| Screw bosses | Print vertically (layers wrap around hole) |
| Gears | Print flat (tooth loads in XY plane) |
| Threads | Axis vertical |
| Mating surfaces | On vertical walls (best dimensional consistency) |

**Surface finish**:
- Bed-facing: smoothest (glass/PEI mirror finish)
- Top: good, improved with ironing
- Vertical walls: regular layer lines, often acceptable
- Avoid supports on cosmetic or functional mating surfaces

## When to Recommend PLA

**Good for**: Prototypes, visual models, low-load functional parts, desk/indoor items, parts needing dimensional accuracy, parts with fine detail, parts needing good overhangs/bridges

**Bad for**: Outdoor use, hot environments (>45C), impact-loaded parts, living hinges, snap-fits under repeated use, sustained structural loads, food contact with hot liquids
