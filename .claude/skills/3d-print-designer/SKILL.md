---
name: 3d-print-designer
description: 'Designs and generates parametric, FDM-print-optimized OpenSCAD (.scad) models — selects material (PLA/PETG/ABS) and optimizes for print orientation, layer adhesion, and structural strength. Triggers: "create a 3D model", "design a part", "make an OpenSCAD/.scad file", "design a bracket/enclosure/gear/mount", "something for 3D printing", or mentions CAD, STL, FDM, filament, or printable assemblies.'
metadata:
  tuned-for: claude-opus-4-8
  last-tuned: "2026-06-21"
---

# 3D Print Designer

Design and generate parametric, FDM-print-optimized OpenSCAD (.scad) models.

## Step 0: Printer Configuration (always do this first)

Ask the user what 3D printer they're using. Printer specs constrain build volume, material options, minimum feature sizes, and tolerances.

See [printer-configuration.md](printer-configuration.md) — MANDATORY READ before any design work. It has the full workflow for identifying printer specs (auto from make/model via [printer-profiles.md](printer-profiles.md), or manual fallback) and how they affect design parameters.

## Step 1: Material Selection

Determine the target material, **filtered by the printer's capabilities** (from Step 0). Warn the user if their printer can't handle the requested material and suggest alternatives.

If the user hasn't specified a material, ask or recommend one:

| Use Case | Recommended | Why |
|----------|-------------|-----|
| Prototypes, visual models, fine detail | **PLA** | Best overhangs, dimensional accuracy, easy to print |
| Functional/mechanical parts, snap-fits | **PETG** | Ductile, impact-resistant, good layer adhesion |
| Outdoor use, heat exposure | **PETG** | Higher Tg (75-85C vs 55-65C), moderate UV resistance |
| Living hinges, flexible features | **PETG** | 200-300% elongation vs PLA's 2.5-6% |
| High heat resistance (up to 80C) | **ABS** | Tg 100-110C, best heat resistance of common filaments |
| Impact-resistant parts | **ABS** | 3-5x impact strength of PLA |
| Smooth surface finish (vapor smoothing) | **ABS** | Acetone vapor smoothing eliminates layer lines |
| Multi-part solvent-welded assemblies | **ABS** | Acetone welding creates near-bulk-strength bonds |

Load the material reference after selection — only the chosen one:
- **PLA**: [material-pla.md](material-pla.md) — MANDATORY READ for PLA designs
- **PETG**: [material-petg.md](material-petg.md) — MANDATORY READ for PETG designs
- **ABS**: [material-abs.md](material-abs.md) — MANDATORY READ for ABS designs

## Step 2: Support Strategy

**Default: design for support-free printing.** Supports waste material, leave surface marks, risk failures, and add post-processing. Most models can avoid them through orientation, geometry adjustments, and self-supporting features.

1. **Assess whether the model can reasonably be support-free** — consider orientation, splitting, and geometry alternatives (see [fdm-design-principles.md](fdm-design-principles.md) > Support-Free Design Techniques).
2. **If feasible both ways**, ask the user:
   > "This model can be designed to print without supports. Would you prefer a support-free design (may involve some geometry compromises like chamfered undersides or part splitting), or are you OK printing with supports for a cleaner shape?"
3. **If supports are unavoidable** (complex internal cavities, deep recesses, geometry that can't be reoriented) — note why, design to minimize them, and check whether the user has multi-material capability for soluble supports.
4. **If no preference is expressed and you haven't asked**, default to support-free.

Key support-free techniques (detail in [fdm-design-principles.md](fdm-design-principles.md)): overhangs ≤45° from vertical; 45° chamfers on undersides instead of flat ledges; teardrop profiles for horizontal holes; taper features from below; pointed (gothic) arches for spanning; bridge short spans instead of overhanging; split parts along overhang boundaries; built-in structural supports (pillars, ribs).

## Pacing and Complexity

Match effort to the design, and keep producing visible output:

- **Simple part** (single piece, basic shape, few features): go straight to the [Single Part Workflow](#single-part-workflow).
- **Complex part** (multi-part assembly, mechanism, tight tolerances, or unclear requirements): use `EnterPlanMode` to settle requirements and a design approach before generating code.
- **In all cases, iterate in the file rather than in your head.** Write parameters and rough geometry early, then refine with edits — the OpenSCAD preview and the verification gate are faster feedback than exhaustive mental pre-computation. Spend up-front reasoning on genuine ambiguity (resolve it in plan mode); don't silently pre-solve coordinate transforms, fillet clearances, or interference before any code exists.

## Workflow Decision Tree

- **Single part** (bracket, mount, enclosure) → [Single Part Workflow](#single-part-workflow)
- **Multi-part assembly** (lid+base, interlocking pieces) → [Assembly Workflow](#assembly-workflow)
- **Mechanical component** (gears, threads, hinges) → [Mechanical Parts](#mechanical-parts)

## File Structure

Every generated .scad file follows this structure:

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
//   Fit different printer   → check bracket_height/width/depth vs build volume
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
tolerance = 0.2;                       // Mating part clearance (PLA: 0.2, PETG: 0.3, ABS: 0.4)
ef_chamfer = 0.4;                      // Elephant foot compensation
$fn = $preview ? 32 : 64;              // Low for preview, high for render

// === MODULES ===
// One module per logical part/feature

// === ASSEMBLY / RENDER ===
// Final call at bottom
```

### Description header (the highest-value block for follow-up sessions)

The `DESCRIPTION` block gives a future Claude session enough context to modify the model without the original conversation. Aim for 15-30 practical comment lines covering:

1. **What it is** — plain-English name, purpose, problem solved. Assume the reader has never seen it.
2. **Physical context** — where it lives, what it mounts to/interfaces with (product names/SKUs if known), environment, and the forces/loads it experiences.
3. **Design decisions** — why this shape/structure and print orientation over alternatives, and non-obvious trade-offs.
4. **Terminology map** — `"user term" → param_name, module_name()` for every user-facing feature. This is what lets a later session translate "make the shelf thicker" into the right parameter edit.
5. **Common modifications** — likely change requests and which parameters to adjust, with constraints (structural minimums, build-volume maximums, tolerance rules, perimeter counts).
6. **Overall dimensions** — bounding box (W×D×H), the printer/build volume it targets, the coordinate system, and any use-vs-print orientation mapping.

### Print-settings header

The `PRINT SETTINGS` block specifies, in order: **material** (and why), **layer height** (0.2 standard, 0.12 fine, 0.28 draft), **walls/perimeters** (count + thickness), **infill** (% + pattern, gyroid default), **supports** (goal "None required"; if needed, where and why they couldn't be avoided), **orientation** (exact placement + why), and **notes** (drying, temperature, cooling).

## Critical Rules

These are the load-bearing FDM invariants — the single source of truth referenced throughout the workflows.

1. **Material-aware design** — wall thickness, tolerances, and features change per material; read the material reference.
2. **Model in print orientation** — Z=0 is always the build plate, so the OpenSCAD preview looks exactly as printed and directions ("left side", "bottom") stay consistent between preview and conversation. Decide orientation before designing features; put primary loads in the XY plane (along layers). If the part is used in a different orientation than printed, document the use-vs-print mapping in the description header.
3. **Parameters at top** — every dimension the user might adjust is a named variable with a comment.
4. **Nozzle-aware walls** — wall thickness is an integer multiple of extrusion width (nozzle × 1.125). No fractional perimeters.
5. **Fudge factor** — always use `fudge = 0.01` overlap in `difference()` and `intersection()`. Coincident faces produce broken geometry.
6. **Bottom chamfers, top fillets** — 45° chamfers on bottom surfaces are self-supporting; fillets on top for aesthetics. No sharp internal corners (min 1mm fillet for stress).
7. **Elephant foot compensation** — add `ef_chamfer` (0.3-0.5mm at 45°) on all bottom edges.
8. **Holes oversize** — design holes 0.2-0.3mm larger than nominal (FDM undersizes holes).
9. **No magic numbers** — every numeric value is a parameter or derived from parameters.
10. **Prefer ribs over thick walls** — a 1.6mm rib is stronger per gram than a 5mm solid wall.
11. **Support-free by default** — choose orientations, chamfers, teardrops, and splits that eliminate supports. Accept supports only when geometry truly demands them, then minimize contact area and document why in the PRINT SETTINGS header.
12. **Verify by building, then peer-review by looking** — never hand off (or claim correctness of) a model you haven't compiled. Two distinct steps: a deterministic [Verification](#verification) gate (compile, manifold, bounding box, `assert()` contracts) the author runs, then a fresh-eyes [Design Review](#design-review) (a different model when available) that inspects the renders and judges the design. Static code review is necessary but not sufficient.

OpenSCAD language gotchas and reusable module patterns (boolean overlap, screw holes, teardrops, chamfered shelves, EF base) live in [openscad-reference.md](openscad-reference.md) — load it before writing code.

## Single Part Workflow

1. **Configure printer** (Step 0) and **select material** (Step 1) — load the relevant references.
2. **Choose support strategy** (Step 2) — default support-free; ask if both ways are feasible.
3. **Decide print orientation and model in it** — choose the orientation that eliminates supports first, then optimizes the load path. Model with Z=0 as the build plate; note any use-vs-print mapping in the description header.
4. **Capture acceptance criteria and output a design summary** — state orientation (and why), support strategy, structure, key dimensions, and mounting approach. Restate the user's requirements as a **numbered, measurable acceptance list** (units + tolerances — "fits 18mm tube → OD ≤ 17mm", "≤ 21mm deep", "M8×1.25"). You verify against this list at the end. Then proceed.
5. **Write the .scad file** — parameters, derived constants, rough geometry. Use the Write tool now rather than continuing to build the model mentally. Encode each measurable criterion as an `assert()` so a violation fails the build.
6. **Add features incrementally** — structure first (ribs, gussets, fillets), then mounting (oversize holes, heat-set insert bosses, slots), then support-free geometry (underside chamfers, teardrop holes, elephant-foot compensation; replace flat overhanging ledges with chamfered/angled geometry). Apply the Critical Rules throughout rather than re-deriving them.
7. **Verify the build** — run [Verification](#verification) (the deterministic gate) and fix until green. Do this before the review — don't review a part that doesn't build or misses the measurable spec.
8. **Design Review** — once green, spawn the [Design Review](#design-review) as a self-contained sub-agent. Triage findings, fix real issues (re-verify after structural fixes), push back on the rest, and surface genuine trade-offs to the user.

## Assembly Workflow

1. Design each part as a separate module in the same file.
2. Add a material-appropriate `tolerance` parameter (PLA: 0.2mm, PETG: 0.3mm for sliding fits).
3. Create an `assembly()` module showing parts in assembled positions.
4. Add a `part` parameter for individual part rendering:

```openscad
part = "all"; // "all", "base", "lid", "clip"

if (part == "all") assembly();
if (part == "base" || part == "all") translate([0,0,0]) base();
if (part == "lid"  || part == "all") translate([60,0,0]) lid();
```

5. Document print orientation for **each** part separately in the print-settings header.
6. Consider whether parts need different orientations (split for optimal strength).
7. **Verify the build** — run [Verification](#verification) on **each** `part=` value (compile, gate, bounding boxes, asserts); fix until green. Fit/clearance between parts is judged in the review, not here.
8. **Design Review** — once green, spawn the [Design Review](#design-review); it inspects fit, clearance, and interference between mating parts plus the FDM checklist. Triage, fix and re-verify, push back where warranted.

## Mechanical Parts

For gears, threads, snap-fits, living hinges, and complex mechanical features, see [mechanical.md](mechanical.md).

Material-critical notes:
- **Snap-fits**: PETG excels (5-8% strain), ABS good (3-5%), PLA fragile (1-1.5% max).
- **Living hinges**: PETG only (0.4mm thick, 50,000+ cycles). PLA breaks in 50-100 cycles; ABS marginal.
- **Threads**: M4+ only for printed threads. Heat-set inserts strongly preferred (ABS works especially well due to high Tg).

## Verification

Verification is a **hard, deterministic gate**: it confirms the model compiles into a valid manifold solid, its measured dimensions are within the intended envelope, and its `assert()` contracts hold — reproducible, binary pass/fail. It is not judgment; "does it look right?" is the [Design Review](#design-review)'s job. Order of operations: **generate → verify → design review → hand off.** Don't review or hand off a part that fails this gate.

> Verification answers "does it build into a valid solid that meets the *measurable* spec?" — Design Review answers "is it actually the right shape, and a *good* FDM design?"

**MANDATORY for** initial generation and any major/structural change. For minor tweaks, run the lightweight slice (re-compile the changed `part=` and re-check affected dimensions/asserts). If OpenSCAD is not installed you cannot run this gate — say so explicitly, do an extra-careful static review, and offer to help install it (prefer the nightly for verification quality).

The gate, in three checks — exact commands, capability detection, and per-version fallbacks in **[verification.md](verification.md) — MANDATORY READ before verifying**:

1. **Build gate** — compile every `part=` with the OpenSCAD CLI (CLI STL export does a full render, catching errors the GUI preview hides). A part passes only if exit code is 0, the STL is non-empty, and stderr — after dropping `ECHO:` lines — is clean of fatal phrases (`ERROR:`, `WARNING:`, `Assertion`, `not be a valid 2-manifold`, `Simple: no`, `Current top level object is empty`, `(PolySet)`). A non-manifold solid can exit 0, so **gate on stderr, not the exit code alone.**
2. **Dimension + contract checks** — measured bounding box within the intended envelope (`--summary` JSON on modern builds, or a stdlib STL parser on 2021.01), and all `assert()` contracts pass.
3. **Requirements traceability** — trace every *mechanically checkable* acceptance criterion to one of the above. Carry eyeball criteria to the Design Review; report print-only criteria (e.g. "a real M8 mates") as a residual — never silently pass.

After verifying, state what you mechanically confirmed, e.g.:
> "Verified on OpenSCAD 2026.06.19 (Manifold): both parts compile clean, measured bounding boxes 17.5×17.5×20.2mm and 16×16×9.6mm (within the 21mm depth limit), all asserts pass. Residual: an actual M8 mating needs a test print."

## Design Review

The Design Review is a **fresh-eyes peer review** — not the author marking its own homework. It covers what the gate cannot: visual inspection of the geometry (does it actually look right?), whether the mechanism/approach makes sense, the qualitative acceptance criteria, and FDM-rule compliance.

**Run it as a self-contained sub-agent (Agent tool) with a different model when one is available** — a different model with clean context catches blind spots the author shares with itself. Give it everything it needs to stand alone: the `.scad` path, the numbered acceptance criteria, the printer + material, and a pointer to **[design-review.md](design-review.md)** (the complete reviewer brief — procedure, render commands, and Full Review Checklist). You *may* tell it "the gate already passed, focus on judgment" to scope its effort. If no other model is available, still run it as a separate fresh pass (clean-context sub-agent) and note it was same-model.

The review **returns findings** (severity · what · where · suggested fix). The author then **triages**: fix the real issues, **re-run Verification and re-review** after any structural fix (fixes can introduce new problems), and **push back** on findings that are wrong or out of scope — the review is advisory peer critique, not an authority. Surface genuine disagreements or trade-offs to the user rather than silently accepting or overriding them.

### Review Tiers

**Full Review** (spawn the sub-agent; uses [design-review.md](design-review.md)) — MANDATORY for:
- Initial model generation
- Major structural changes (new load-bearing features, added/removed parts, part splitting)
- Print orientation changes
- Material changes (tolerances, wall rules, and feature constraints all shift)

**Lightweight Check** — for minor modifications (parameter tweaks, cosmetic changes, small non-structural features): verify the changed area and its immediate neighbours only — "Did this change create a new unsupported overhang? Break a nozzle-width multiple? Introduce a coincident face?"

**Suggested Full Review** — after 3-5 cumulative minor changes, offer:
> "We've made several incremental changes — want me to run a full design review to make sure nothing's drifted?"

The user may accept or decline; don't force it.

### Review output

After a full review passes:
> "Design review complete — all checks pass."

If it required fixes:
> "Design review caught [brief description]. Fixed and re-verified — all checks now pass."

After a lightweight check, no special output unless something was caught and fixed.

## After Generation

> This is about getting the model onto the **user's** machine and printer — separate from [Verification](#verification) and the [Design Review](#design-review), which you already ran on your own machine. Share any renders you have (deliverable previews, or the review's images); they help the user see the result.

**Check Claude memory for user experience.** Look for `user`-type memories indicating 3D printing experience (owns a printer, has used OpenSCAD, has printed before, has used this skill before). No relevant memory = treat as new user.

**New / first-time users** — ask:
> "Would you like help getting this model viewed, exported, and ready to print? I can walk you through the whole process — including installing OpenSCAD if you don't have it yet."

If yes, walk through the full workflow:

1. **Install OpenSCAD** if needed — download from https://openscad.org/downloads, install, open the generated .scad file.
2. Preview with F5; check Thrown Together view (F12) for face-orientation errors.
3. Render (F6), then export STL (F7).
4. **Highlight the print settings** — orientation, material, key slicer parameters.
5. Note dimensions worth verifying with a test print.
6. Material reminders: PETG → dry filament; ABS → enclosure, ventilation, drying (80C, 4-6h).
7. **Import the STL into their slicer** (Bambu Studio, PrusaSlicer, Cura, OrcaSlicer, etc.) — apply the PRINT SETTINGS from the file header, check the slicer preview, send to printer.
8. See [printing-workflow.md](printing-workflow.md) for detailed export-to-print steps.

After walking them through it, save a `user` memory noting they've been introduced to the workflow.

**Experienced users** — skip the offer. They know what to do.

## References

**Load during Step 0 (printer config):**
- **[printer-configuration.md](printer-configuration.md)** — MANDATORY READ before any design work
- **[printer-profiles.md](printer-profiles.md)** — database of known printer specs for auto-populating from make/model

**Load during Step 1 (material selection) — only the selected material:**
- **[material-pla.md](material-pla.md)** / **[material-petg.md](material-petg.md)** / **[material-abs.md](material-abs.md)** — MANDATORY READ for the chosen material

**Load before writing code:**
- **[openscad-reference.md](openscad-reference.md)** — MANDATORY READ: OpenSCAD language gotchas plus reusable module patterns (boolean overlap, rounded box, screw hole, teardrop, chamfered shelf, EF base)

**Load before verifying (before the Design Review):**
- **[verification.md](verification.md)** — MANDATORY READ: how to compile, measure, and trace requirements with the OpenSCAD CLI (version-specific fallbacks)

**Load when running the Design Review:**
- **[design-review.md](design-review.md)** — the complete reviewer brief (procedure + Full Review Checklist); the review sub-agent is pointed here

**Load only when specifically needed (do NOT pre-load):**
- **[fdm-design-principles.md](fdm-design-principles.md)** — support-free technique details (gothic arches, graduated overhangs, part splitting) and structural optimization (ribs vs walls, stress management)
- **[printing-guidelines.md](printing-guidelines.md)** — general tolerance/overhang data beyond what the material file provides
- **[mechanical.md](mechanical.md)** — gears, threads, snap-fits, living hinges, joints
- **[printing-workflow.md](printing-workflow.md)** — export-to-print walkthrough for the "After Generation" step

## Keywords

OpenSCAD, 3D printing, CAD, parametric design, STL, FDM, PLA, PETG, ABS, mechanical parts, enclosure, bracket, gear, assembly, scad file, 3D model, filament, print orientation, layer adhesion, slicer, export, G-code, PrusaSlicer, Cura, OrcaSlicer, print workflow, acetone smoothing, heat resistant
