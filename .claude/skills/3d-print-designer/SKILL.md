---
name: 3d-print-designer
description: Designs and generates parametric, FDM-print-optimized OpenSCAD (.scad) models. Selects material (PLA/PETG/ABS), optimizes for print orientation, layer adhesion, and structural strength. Use when the user asks to create a 3D model, design a part, generate something for 3D printing, create an OpenSCAD file, or mentions CAD, STL, FDM, filament, mechanical parts, enclosures, brackets, gears, or assemblies.
---

# 3D Print Designer

Design and generate parametric, FDM-print-optimized OpenSCAD (.scad) models.

## Step 0: Printer Configuration (ALWAYS do this first)

Ask the user what 3D printer they're using. Printer specs constrain build volume, material options, minimum feature sizes, and tolerances.

See [printer-configuration.md](printer-configuration.md) — MANDATORY READ before any design work. Contains the full workflow for identifying printer specs (auto from make/model via [printer-profiles.md](printer-profiles.md), or manual fallback) and how they affect design parameters.

## Step 1: Material Selection

Determine the target material. **Filter choices by the printer's capabilities** (from Step 0) — warn the user if their printer can't handle the requested material and suggest alternatives.

**If the user hasn't specified a material, ask or recommend one:**

| Use Case | Recommended | Why |
|----------|-------------|-----|
| Prototypes, visual models, fine detail | **PLA** | Best overhangs, dimensional accuracy, easy to print |
| Functional/mechanical parts, snap-fits | **PETG** | Ductile, impact-resistant, good layer adhesion |
| Outdoor use, heat exposure | **PETG** | Higher Tg (75-85C vs 55-65C), moderate UV resistance |
| Living hinges, flexible features | **PETG** | 200-300% elongation vs PLA's 2.5-6% |
| High heat resistance (up to 80C) | **ABS** | Tg 100-110C, best heat resistance of common filaments |
| Impact-resistant parts | **ABS** | 3-5x impact strength of PLA, best of common filaments |
| Smooth surface finish (vapor smoothing) | **ABS** | Acetone vapor smoothing eliminates layer lines |
| Multi-part solvent-welded assemblies | **ABS** | Acetone welding creates near-bulk-strength bonds |

Load the material-specific reference after selection:
- **PLA**: See [material-pla.md](material-pla.md) - MANDATORY READ for PLA designs
- **PETG**: See [material-petg.md](material-petg.md) - MANDATORY READ for PETG designs
- **ABS**: See [material-abs.md](material-abs.md) - MANDATORY READ for ABS designs

## Step 2: Support Strategy (ALWAYS consider)

**Default preference: design for support-free printing.** Supports waste material, leave surface marks, risk print failures, and add post-processing time. Most models can be designed to print without supports through orientation choices, geometry adjustments, and self-supporting feature design.

**Decision flow:**

1. **Assess whether the model can reasonably be made support-free** — consider orientation, splitting, and geometry alternatives (see [fdm-design-principles.md](fdm-design-principles.md) > Support-Free Design Techniques)
2. **If yes (support-free is feasible)** — ask the user:
   > "This model can be designed to print without supports. Would you prefer a support-free design (may involve some geometry compromises like chamfered undersides or part splitting), or are you OK printing with supports for a cleaner shape?"
3. **If no (supports are unavoidable)** — e.g. complex internal cavities, deeply recessed features, geometry that cannot be reoriented — note why supports are needed and design to minimize them. Check if the user has multi-material capability for soluble supports.
4. **If the user hasn't expressed a preference and you haven't asked** — default to support-free design.

**Key support-free techniques** (applied throughout the design):
- Orient the model so all overhangs are ≤45° from vertical
- Use 45° chamfers on undersides instead of flat shelves or ledges
- Use teardrop profiles for horizontal holes
- Taper features from below at ≤45° angles
- Use pointed (gothic) arches instead of round arches for spanning openings
- Bridge short spans (<20mm for PLA) instead of overhanging
- Split parts along overhang boundaries and print each piece flat
- Add built-in structural supports (pillars, ribs) that become part of the design
- Use graduated/stepped overhangs instead of sudden ones

## Complexity Check

Before starting, assess the design complexity:
- **Simple** (single part, basic shape, few features): Proceed directly with Single Part Workflow
- **Complex** (multi-part assembly, mechanical features, tight tolerances, or unclear requirements): Consider using `EnterPlanMode` to explore requirements and write a design plan before generating code. This prevents extended silent reasoning on complex designs.

## Workflow Decision Tree

- **Single part** (bracket, mount, enclosure): See [Single Part Workflow](#single-part-workflow)
- **Multi-part assembly** (lid+base, interlocking pieces): See [Assembly Workflow](#assembly-workflow)
- **Mechanical component** (gears, threads, hinges): See [Mechanical Parts](#mechanical-parts)

## File Structure

Every generated .scad file MUST follow this structure:

```openscad
// === DESCRIPTION ===
// [Name]: [What it is in plain English and what problem it solves]
// [Physical context: where it lives, what it mounts to/interfaces with,
//  environment, forces and loads it experiences]
//
// Design decisions:
//   - [Why this shape/structure was chosen]
//   - [Why this print orientation — e.g. "loads align with XY layer plane"]
//   - [Any non-obvious trade-offs — e.g. "thicker back wall trades material
//     for rigidity under pumping loads"]
//
// Terminology → code:
//   "the shelf"       → shelf_thick, shelf_module()
//   "pump hole"       → tap_hole_dia, tap_hole()
//   "side walls"      → wall_thick, side_wall()
//   "mounting bolts"  → wall_bolt_dia, bolt_hole(), upper_bolt_z, lower_bolt_z
//
// Common modifications:
//   Make shelf thicker     → shelf_thick (min 2*wall_thick for strength)
//   Bigger pump hole       → tap_hole_dia (add 0.3mm for PETG tolerance)
//   Move bolt positions    → upper_bolt_z, lower_bolt_z (keep ≥30mm from edges)
//   Fit different printer  → check bracket_height/width/depth vs build volume
//
// Overall dimensions: [W] × [D] × [H] mm (fits [printer] [build volume])
// Coordinate system: X = [axis], Y = [axis], Z = height from build plate
// NOTE: Model is in print orientation — OpenSCAD preview matches the print.
//   [If use orientation differs: "In use, Z becomes the wall-facing axis"]

// === PRINT SETTINGS ===
// Material: PLA (or PETG, etc.)
// Layer Height: 0.2mm
// Walls/Perimeters: 4 (1.6mm wall thickness)
// Infill: 20% gyroid
// Supports: None required (designed support-free — all overhangs ≤45°, horizontal holes use teardrop profile)
// Orientation: As modeled (Z=0 = build plate). [Use-vs-print note if applicable]
// Notes: [Any special instructions]

// === PARAMETERS ===
// Printer settings
nozzle_diameter = 0.4;
layer_height = 0.2;

// Part dimensions (user-configurable)
// ...

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
wall_thickness = extrusion_width * 4;  // 4 perimeters
fudge = 0.01;                          // Boolean operation overlap
tolerance = 0.2;                        // Mating part clearance (PLA: 0.2, PETG: 0.3, ABS: 0.4)
ef_chamfer = 0.4;                      // Elephant foot compensation
$fn = $preview ? 32 : 64;             // Low for preview, high for render

// === MODULES ===
// One module per logical part/feature

// === ASSEMBLY / RENDER ===
// Final call at bottom
```

## Description Header (MANDATORY)

Every generated file MUST include a `DESCRIPTION` comment block that gives a future Claude session enough context to modify the model confidently without the original conversation. Include:

1. **What it is** — plain English name, purpose, and the problem it solves. Write as if the reader has never seen this model before.
2. **Physical context** — where it lives physically (wall-mounted, sits on desk, inside an enclosure), what it mounts to or interfaces with (specific product names/SKUs if known), the physical environment, and the forces/loads it experiences (e.g. "repeated downward pumping force on top shelf").
3. **Design decisions** — why this shape/structure was chosen over alternatives, why this print orientation, and any non-obvious trade-offs (e.g. "extra back wall thickness trades material weight for rigidity under load").
4. **Terminology map** — map between the natural language a user will use when requesting changes and the actual OpenSCAD parameter names or module names. Format: `"user term" → param_name, module_name()`. Cover every user-facing feature (holes, walls, shelves, ribs, mounting points). This is the most important section for enabling follow-up sessions.
5. **Common modifications** — list the most likely change requests and which parameters/modules to adjust. Include constraints: minimum values for structural integrity, maximum values for build volume, tolerance rules, and perimeter count requirements.
6. **Overall dimensions** — bounding box (W x D x H), printer and build volume it was designed for, and the coordinate system (X, Y, Z — Z is always height from build plate since models are in print orientation). If the part is used in a different orientation than printed, document the mapping (e.g. "In use: mounted vertically, so print-Z becomes wall-facing axis").

**Keep it practical, not exhaustive.** Aim for 15-30 comment lines. The terminology map and common modifications are the highest-value sections — a new Claude session reading these can immediately translate "make the shelf thicker" into the correct parameter edit and know the constraints.

## Print Settings Header (MANDATORY)

Every generated file MUST include a `PRINT SETTINGS` comment block specifying:

1. **Material** — which filament and why (affects all other settings)
2. **Layer height** — 0.2mm standard, 0.12mm for fine detail, 0.28mm for draft
3. **Walls/Perimeters** — minimum count and resulting thickness
4. **Infill** — percentage and pattern (gyroid default for structural)
5. **Supports** — whether needed and where. **Goal: "None required".** If supports are needed, explain why they couldn't be avoided and specify where.
6. **Orientation** — exactly how to place on build plate and why
7. **Notes** — any special instructions (drying PETG, temperature, cooling)

## Critical Rules

1. **Material-aware design** — wall thickness, tolerances, and features change per material. Read the material reference file.
2. **Model in print orientation** — Z=0 is ALWAYS the build plate. The model in OpenSCAD must look exactly as it will be printed, so the user can reference directions ("left side", "bottom") consistently between the OpenSCAD preview and conversation. Decide print orientation BEFORE designing features. Primary loads must be in XY plane (along layers, not across them). If the part is used in a different orientation than it's printed (e.g. a wall bracket printed on its side), note the use-vs-print mapping in the description header.
3. **Parameters at top** — every dimension the user might adjust is a named variable with a comment
4. **Nozzle-aware walls** — wall thickness must be integer multiples of extrusion width (nozzle * 1.125). No fractional perimeters.
5. **Fudge factor** — ALWAYS use `fudge = 0.01` overlap in `difference()` and `intersection()`. Coincident faces produce broken geometry.
6. **Bottom chamfers, top fillets** — chamfers (45 degrees) on bottom surfaces are self-supporting. Fillets on top surfaces for aesthetics. NEVER leave sharp internal corners (minimum 1mm fillet for stress).
7. **Elephant foot compensation** — add `ef_chamfer` (0.3-0.5mm at 45 degrees) on all bottom edges
8. **Holes oversize** — design holes 0.2-0.3mm larger than nominal (FDM undersizes holes)
9. **No magic numbers** — every numeric value is a parameter or derived from parameters
10. **Prefer ribs over thick walls** — a 1.6mm rib is stronger per gram than a 5mm solid wall
11. **Design for support-free printing by default** — choose orientations, chamfers, teardrops, and splits that eliminate supports. Only accept supports when the geometry truly demands them (complex internal cavities, deep undercuts). When supports are unavoidable, minimize their contact area and document why they're needed in the PRINT SETTINGS header.

## Pacing Rules (CRITICAL — prevents 30+ minute stalls)

**Do NOT reason through the entire design in your head before writing code.** Write code early, iterate in the file. Thinking about coordinate transforms, fillet clearances, or dimensional interference for more than 60 seconds without producing visible output means you are overthinking.

1. **Output a design summary BEFORE writing any code** — tell the user your planned approach (orientation, structure, key dimensions) and get implicit confirmation by proceeding
2. **Write the .scad file early** — start with parameters and basic structure, then add features with subsequent edits. Do not mentally pre-compute the entire model.
3. **Iterate in code, not in thought** — OpenSCAD has a preview (F5). Write approximate geometry, note TODOs in comments, refine. This is faster than exhaustive mental pre-analysis.
4. **One concern at a time** — don't simultaneously reason about print orientation, coordinate transforms, stress analysis, and fillet geometry. Handle them sequentially with code output between each.

## Single Part Workflow

1. **Configure printer** (Step 0) — identify printer capabilities, then **select material** (Step 1) — load material reference
2. **Evaluate support strategy** (Step 2) — can this model be designed support-free? If feasible both ways, ask the user their preference. Default to support-free.
3. **Determine print orientation and model in it** — choose orientation that eliminates supports first, then optimizes for load path. Model with Z=0 as the build plate so the OpenSCAD preview matches the printed result. If the part is used differently than printed (e.g. a bracket printed flat but mounted vertically), note the mapping in the description header.
4. **Output design summary to user** — briefly describe: print orientation and why, support strategy (support-free or where supports are needed and why), overall structure, key dimensions, mounting approach. Then proceed.
5. **Write the .scad file** with parameters, derived constants, and basic geometry. Use the Write tool now — do not keep building the model mentally.
6. **Add structural features** — ribs, gussets, fillets. Edit the file incrementally.
7. **Add mounting features** — screw holes (oversize!), heat-set insert bosses, slots
8. **Add support-free features** — 45° chamfers on all undersides (not fillets), teardrop profiles for horizontal holes, tapered features from below, elephant foot compensation on bottom edges. Replace any flat overhanging ledges with chamfered or angled geometry.
9. **Full Design Review** — run the mandatory [Design Review](#design-review) checklist. Fix and re-review until all items pass.

## Assembly Workflow

1. Design each part as a separate module in the same file
2. Add material-appropriate `tolerance` parameter (PLA: 0.2mm, PETG: 0.3mm for sliding fits)
3. Create an `assembly()` module showing parts in assembled positions
4. Add `part = "all"` parameter for individual part rendering:

```openscad
part = "all"; // "all", "base", "lid", "clip"

if (part == "all") assembly();
if (part == "base" || part == "all") translate([0,0,0]) base();
if (part == "lid" || part == "all") translate([60,0,0]) lid();
```

5. Document print orientation for EACH part separately in the print settings header
6. Consider whether parts need different orientations (split for optimal strength)
7. **Full Design Review** — run the mandatory [Design Review](#design-review) checklist. Fix and re-review until all items pass.

## Mechanical Parts

For gears, threads, snap-fits, living hinges, and complex mechanical features, see [mechanical.md](mechanical.md).

**Material-critical notes:**
- Snap-fits: PETG excels (5-8% strain), ABS is good (3-5% strain), PLA is fragile (1-1.5% max strain)
- Living hinges: PETG only (0.4mm thick, 50,000+ cycles). PLA breaks in 50-100 cycles. ABS is marginal.
- Threads: M4+ only for printed threads. Heat-set inserts strongly preferred (ABS works especially well due to high Tg).

## Boolean Operation Pattern

ALWAYS extend cutting shapes beyond the surface:

```openscad
// Pocket (open top)
difference() {
    cube([width, depth, height]);
    translate([wall, wall, wall])
        cube([width - 2*wall, depth - 2*wall, height + fudge]);
}

// Through-hole (extend BOTH directions)
translate([x, y, -fudge])
    cylinder(h = wall + 2*fudge, d = hole_d + tolerance);
```

## Common Module Patterns

### Rounded box
```openscad
module rounded_box(size, radius) {
    minkowski() {
        cube([size[0] - 2*radius, size[1] - 2*radius, size[2]/2]);
        cylinder(r=radius, h=size[2]/2);
    }
}
```

### Screw hole with countersink
```openscad
module screw_hole(h, d, head_d, head_h) {
    translate([0, 0, -fudge]) {
        cylinder(h=h + 2*fudge, d=d + tolerance);
        translate([0, 0, h - head_h])
            cylinder(h=head_h + fudge, d1=d + tolerance, d2=head_d + tolerance);
    }
}
```

### Teardrop hole (for horizontal holes — self-supporting)
```openscad
module teardrop_hole(d, h) {
    r = d / 2;
    rotate([90, 0, 0])
        linear_extrude(height=h, center=true)
            union() {
                circle(r=r);
                polygon([[-r, 0], [r, 0], [0, r]]);
            }
}
```

### Chamfered shelf (support-free underside)
```openscad
// Replaces a flat shelf/ledge with a 45-degree chamfered underside
module chamfered_shelf(width, depth, thick, chamfer) {
    ch = min(chamfer, thick - layer_height);  // Leave at least one layer flat on top
    hull() {
        // Full-width top
        translate([0, 0, thick - layer_height])
            cube([width, depth, layer_height]);
        // Narrower bottom (chamfer removes material from underside)
        translate([ch, ch, 0])
            cube([width - 2*ch, depth - 2*ch, layer_height]);
    }
}
```

### Elephant foot compensation base
```openscad
module ef_base(size, ef=0.4) {
    hull() {
        translate([ef, ef, ef])
            cube([size[0] - 2*ef, size[1] - 2*ef, size[2] - ef]);
        cube([size[0], size[1], 0.01]);
    }
}
```

## Design Review

Every generated or modified .scad file must be reviewed for compliance with this skill's rules. The review intensity depends on the scope of the change.

### Review Tiers

**Full Review — MANDATORY for:**
- Initial model generation
- Major structural changes (new load-bearing features, added/removed parts, part splitting)
- Print orientation changes
- Material changes (tolerances, wall rules, and feature constraints all shift)

**Lightweight Check — for minor modifications:**
- Parameter tweaks (hole size, wall height, spacing adjustments)
- Cosmetic changes (fillets, labels, chamfer size)
- Adding/moving small non-structural features
- Scope: verify the changed area and its immediate neighbors only. Ask: "Did this change create a new unsupported overhang? Break a nozzle-width multiple? Introduce a coincident face?"

**Suggested Full Review — after cumulative minor changes:**
- After 3–5 minor modifications, suggest to the user:
  > "We've made several incremental changes — want me to run a full design review to make sure nothing's drifted?"
- The user may accept or decline. Do not force it.

### How to perform a Full Review

1. **Re-read the .scad file in full** — do not review from memory. Use the Read tool.
2. **Walk through every item in the checklist below.** Determine PASS or FAIL for each.
3. **If ANY item fails:** fix the violation, then **re-read and re-review from step 1** (fixes can introduce new issues).
4. **Repeat until all items pass.**

### Full Review Checklist

**File Structure & Headers:**
- [ ] `DESCRIPTION` block with all 6 sections (what it is, physical context, design decisions, terminology map, common modifications, overall dimensions)
- [ ] `PRINT SETTINGS` block with all 7 fields (material, layer height, walls/perimeters, infill, supports, orientation, notes)
- [ ] `PARAMETERS` section at top with printer settings (nozzle_diameter, layer_height)
- [ ] `DERIVED CONSTANTS` section (extrusion_width, wall_thickness, fudge, tolerance, ef_chamfer, $fn)
- [ ] `MODULES` section — one module per logical part/feature
- [ ] `ASSEMBLY / RENDER` final call at bottom

**Critical Rules:**
- [ ] Material-aware: wall thickness, tolerances, and features match the selected material reference
- [ ] Print orientation: Z=0 is build plate; model is in print orientation; preview matches the print
- [ ] Primary loads in XY plane (along layers, not across layer boundaries)
- [ ] Parameters at top: every user-adjustable dimension is a named variable with a comment — no magic numbers
- [ ] Nozzle-aware walls: all wall thicknesses are integer multiples of extrusion_width (nozzle × 1.125)
- [ ] Fudge factor: every `difference()` and `intersection()` uses `fudge = 0.01` overlap — no coincident faces
- [ ] Bottom chamfers (45°), top fillets; no sharp internal corners (min 1mm fillet for stress)
- [ ] Elephant foot compensation (`ef_chamfer`) on all bottom edges touching the build plate
- [ ] Holes oversized 0.2–0.3mm above nominal
- [ ] Ribs over thick walls where applicable

**Support-Free Compliance:**
- [ ] All overhangs ≤ 45° from vertical (or supports documented and justified in PRINT SETTINGS)
- [ ] Horizontal holes use teardrop profiles
- [ ] No flat unsupported undersides — chamfered or angled
- [ ] Arches use pointed (gothic) profile, not round (if applicable)
- [ ] Short spans use bridging (< material bridge limit), not overhangs
- [ ] If supports ARE needed: documented where and why in PRINT SETTINGS, contact area minimised

**OpenSCAD Correctness:**
- [ ] Boolean cuts extend beyond surfaces on all exit faces
- [ ] No coincident faces between boolean operands
- [ ] `$fn` uses conditional (`$preview ? 32 : 64` or similar)
- [ ] Through-holes extend with `-fudge` on entry and `+fudge` on exit

**Assembly (if multi-part):**
- [ ] Each part is a separate module
- [ ] Material-appropriate tolerance parameter defined
- [ ] `assembly()` module shows parts in assembled positions
- [ ] `part` parameter allows individual part rendering
- [ ] Print orientation documented for EACH part separately

### Review output

After a **full review** passes, tell the user:
> "Design review complete — all checks pass."

If the review required fixes, mention what was caught:
> "Design review caught [brief description]. Fixed and re-verified — all checks now pass."

After a **lightweight check**, no special output is needed unless something was caught and fixed.

## After Generation

**Check Claude memory for user experience.** Look for `user`-type memories indicating 3D printing experience (owns a printer, has used OpenSCAD, has printed before, has used this skill before). No relevant memory = treat as new user.

**New / first-time users** — ask:

> "Would you like help getting this model viewed, exported, and ready to print? I can walk you through the whole process — including installing OpenSCAD if you don't have it yet."

If yes, walk through the full workflow:

1. **Install OpenSCAD** if needed — download from https://openscad.org/downloads, install, and open the generated .scad file
2. Preview with F5, check Thrown Together view (F12) for face orientation errors
3. Render (F6) then export STL (F7)
4. **Highlight the print settings** — orientation, material, key slicer parameters
5. Note dimensions worth verifying with a test print
6. Material reminders: PETG → dry filament; ABS → enclosure, ventilation, drying (80C, 4-6h)
7. **Import STL into their printer's slicer software** (Bambu Studio, PrusaSlicer, Cura, OrcaSlicer, etc.) — apply the PRINT SETTINGS from the file header, check the slicer preview, and send to printer
8. See [printing-workflow.md](printing-workflow.md) for detailed export-to-print steps

After walking them through it, save a `user` memory noting they've been introduced to the workflow.

**Experienced users** — skip the offer. They know what to do.

## References

**Load during Step 0 (printer config):**
- **[printer-configuration.md](printer-configuration.md)** — MANDATORY READ before any design work
- **[printer-profiles.md](printer-profiles.md)** — Database of known printer specs for auto-populating from make/model

**Load during Step 1 (material selection) — only the selected material:**
- **[material-pla.md](material-pla.md)** — MANDATORY READ when designing for PLA
- **[material-petg.md](material-petg.md)** — MANDATORY READ when designing for PETG
- **[material-abs.md](material-abs.md)** — MANDATORY READ when designing for ABS

**Load before writing code (Step 4):**
- **[openscad-reference.md](openscad-reference.md)** — MANDATORY READ: OpenSCAD language gotchas and patterns that prevent broken geometry

**Load only when specifically needed (do NOT pre-load):**
- **[fdm-design-principles.md](fdm-design-principles.md)** — Load for support-free design technique details (gothic arches, graduated overhangs, part splitting), or complex structural optimization (ribs vs walls, stress management). Step 2 above covers the basics.
- **[printing-guidelines.md](printing-guidelines.md)** — Load only if you need specific tolerance/overhang data beyond what the material file provides
- **[mechanical.md](mechanical.md)** — Load only for gears, threads, snap-fits, living hinges, joints
- **[printing-workflow.md](printing-workflow.md)** — Load only during "After Generation" step to walk user through export-to-print

## Keywords

OpenSCAD, 3D printing, CAD, parametric design, STL, FDM, PLA, PETG, ABS, mechanical parts, enclosure, bracket, gear, assembly, scad file, 3D model, filament, print orientation, layer adhesion, slicer, export, G-code, PrusaSlicer, Cura, OrcaSlicer, print workflow, acetone smoothing, heat resistant
