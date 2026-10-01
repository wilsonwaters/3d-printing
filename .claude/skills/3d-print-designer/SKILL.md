---
name: 3d-print-designer
description: 'Designs and generates parametric, FDM-print-optimized OpenSCAD (.scad) models — selects material (PLA/PETG/ABS) and optimizes for print orientation, layer adhesion, and structural strength. Triggers: "create a 3D model", "design a part", "make an OpenSCAD/.scad file", "design a bracket/enclosure/gear/mount", "something for 3D printing", or mentions CAD, STL, 3MF, FDM, filament, or printable assemblies.'
metadata:
  tuned-for: claude-opus-5-5
  last-tuned: "2026-09-29"
---

# 3D Print Designer

Design and generate parametric, FDM-print-optimized OpenSCAD (.scad) models.

## How to work

The expensive failure is reasoning too long before acting. One run thought until it hit the output cap and never wrote a file. So:

- **Compute with tools, not in your head.** Fits, trig, clearances, interference and tolerance stack-ups go into the model as named derived values with `echo()` and `assert()`, or into a one-line `python -c`. Don't hand-derive coordinates in thinking.
- **Write the .scad early.** Once the acceptance list exists (Workflow step 3), write a rough version that compiles, run the gate, then refine with edits. Several short think-act cycles beat one long plan.
- **Pick, don't survey.** Take the simplest approach that meets the acceptance list, and mention alternatives in one line. A genuine ambiguity is a question for the user, not for extended thought.
- **Read only what the step needs.** Each reference below says when to load it. Run the bundled `.py` tools; don't read their source (`--help` lists the options). For a long .scad, grep it or read line ranges rather than re-reading the whole file.

## Step 0: Printer (always first)

If the user hasn't named a printer (or given its build volume and nozzle), **your first reply is only that question**: no files, no design yet. Once you know it, read [printer-configuration.md](printer-configuration.md). It has the known-printer specs table, the manual fallback, and how the specs drive the design. When modifying an existing model, its headers already name the printer and material: see [Modifying an existing model](#modifying-an-existing-model).

## Step 1: Material Selection

Pick the material **within the printer's capabilities**. Warn if the printer can't handle the requested one and suggest an alternative. If the user hasn't specified one, recommend:

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

Then read **only** the chosen material's file: [material-pla.md](material-pla.md), [material-petg.md](material-petg.md) or [material-abs.md](material-abs.md).

## Step 2: Support Strategy

**Default: support-free.** Supports waste material, mark surfaces, risk failures and add post-processing, and most models avoid them through orientation, geometry changes and self-supporting features. The techniques: overhangs ≤45° from vertical; 45° chamfers under ledges; teardrop horizontal holes; features tapered from below; pointed (gothic) arches; short bridges instead of overhangs; splitting at overhang boundaries; built-in ribs and pillars. Details are in [fdm-design-principles.md](fdm-design-principles.md), which you need only for the harder cases.

If the model is feasible both ways, ask: *"This can print without supports (with some compromises like chamfered undersides or a split), or with supports for a cleaner shape. Which do you prefer?"* If supports are unavoidable (internal cavities, deep recesses), say why, minimise them, and check for soluble-support capability. With no answer, go support-free.

## Workflow

The same steps for a single part or an assembly.

1. **Printer, material, supports** (Steps 0-2), loading their references.
2. **Orientation.** Choose the print orientation that removes supports first, then puts the primary loads along the layers (XY). Model in it, with Z=0 as the build plate.
3. **Acceptance list and design summary.** Restate the requirements as a **numbered, measurable list** with units and tolerances ("fits 18mm tube → OD ≤ 17mm", "≤ 21mm deep"), plus orientation, support strategy, structure and key dimensions. For a complex job (a mechanism, several parts, or unclear requirements), settle the open questions first: in plan mode if a user is present, otherwise state your assumptions in one line and go on.
4. **Write the .scad** using the [file structure](#file-structure) below. Read [openscad-reference.md](openscad-reference.md) first. Encode each measurable criterion as an `assert()`.
5. **Add features incrementally:** structure first (ribs, gussets, fillets), then mounting (oversize holes, heat-set bosses, slots), then support-free geometry (underside chamfers, teardrops, elephant-foot chamfer). Apply the Critical Rules as you go.
6. **Verify:** run the gate ([Verification](#verification)) and fix until it's green.
7. **Save the deliverables now:** the gate's `--export .` writes one STL per printable part. **On a Bambu Lab printer, also make the project 3MF now** ([bambu-3mf-export.md](bambu-3mf-export.md)), without waiting to be asked: it opens in Bambu Studio with the print settings applied. Build it from the `.scad`, or with `--mesh` from the STL. Doing this **before** the review means a slow or stalled review can't cost the user their files. Re-export after any fix.
8. **Design review:** spawn it ([Design Review](#design-review)), triage the findings, fix and re-verify.
9. **Hand off** ([After generation](#after-generation)).

**Assemblies:** make each part its own module, with a material-appropriate `tolerance` (PLA 0.2, PETG 0.3, ABS 0.4mm for sliding fits) and an `assembly()` view. Document each part's print orientation separately in PRINT SETTINGS. Add a `clash_*` part for every mating or moving pair (below) so the gate proves they don't collide.

## Modifying an existing model

Read the file's `DESCRIPTION` and `PRINT SETTINGS` headers first (grep or a line range). They give the printer, material, terminology map and common modifications, so don't re-ask Steps 0-2 or reload their references unless the change affects them (a material change does). Make the change through the parameters the header names, keep the asserts, and update the headers (dimensions, what changed). Then run the gate on every part and save the deliverables. Use the review tier that fits the change ([Review tiers](#review-tiers)).

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
// Final review: [YYYY-MM-DD, reviewer model ID, once a final review has run]

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
// A single-part file may skip the selector; otherwise list every value (see Part names)
part = "all"; // "all", "base", "lid", "clash_lid"
if (part == "all")       assembly();
if (part == "base")      base();
if (part == "lid")       lid_print();   // flipped into print orientation, on Z=0
if (part == "clash_lid") intersection() { base(); lid_assembled(); }  // must render empty
```

### Description header (the highest-value block for follow-up sessions)

The `DESCRIPTION` block lets a later session modify the model without the original conversation. Aim for 15-30 practical lines covering:

1. **What it is:** plain-English name, purpose, the problem it solves. Assume the reader has never seen it.
2. **Physical context:** where it lives, what it mounts to or interfaces with (product names and SKUs if known), the environment, and the loads it takes.
3. **Design decisions:** why this shape, structure and print orientation over the alternatives, and any non-obvious trade-offs.
4. **Terminology map:** `"user term" → param_name, module_name()` for every user-facing feature, so a later session can turn "make the shelf thicker" into the right edit.
5. **Common modifications:** likely change requests and the parameters to adjust, with their constraints (structural minimums, build-volume maximums, tolerance rules, perimeter counts).
6. **Overall dimensions:** bounding box (W×D×H), the printer and build volume it targets, the coordinate system, and any use-vs-print orientation mapping.

Every claim in the header must be true of the geometry: the gate checks the dimensions and the bed fit, and asserts check the rest.

### Print-settings header

The `PRINT SETTINGS` block specifies, in order: **material** (and why), **layer height** (0.2 standard, 0.12 fine, 0.28 draft), **walls/perimeters** (count and thickness), **infill** (% and pattern, gyroid by default), **supports** (goal "None required"; if needed, where and why), **orientation** (exact placement and why), and **notes** (drying, temperature, cooling).

### Part names (the gate and the tools read them)

List every value in the comment on the `part =` line. A plain name is a **printed part**, modelled in its print orientation on Z=0 as one connected body. The other values are named by what they are:

- `all`, `assembly*`, `explode*`, `section*`, `view*`: views, which must compile but are never printed.
- `plate_*`, `*_parts`: print layouts with several bodies.
- `clash_*`: interference checks. Each is an `intersection()` of a mating or moving pair in its assembled pose (for a mechanism, at rest, mid-travel and end of travel), and must render empty. Pose parts that rest on each other `fudge` apart: faces that touch still render a sheet.
- `check_*`: your own diagnostics.

## Critical Rules

The load-bearing FDM invariants, referenced throughout.

1. **Material-aware design:** wall thickness, tolerances and features change per material, so read the material reference.
2. **Model in print orientation:** Z=0 is always the build plate, so the preview looks exactly as printed. Decide orientation before designing features, and put primary loads in the XY plane. If the part is used in another orientation, document the mapping in the header.
3. **Parameters at top:** every dimension the user might adjust is a named variable with a comment.
4. **Nozzle-aware walls:** wall thickness is an integer multiple of the extrusion width (nozzle × 1.125). No fractional perimeters.
5. **Fudge factor:** every `difference()` and `intersection()` cutter overshoots the faces it cuts by `fudge = 0.01`. Coincident faces produce broken geometry.
6. **Bottom chamfers, top fillets:** 45° chamfers on bottom surfaces are self-supporting; fillets on top are cosmetic. No sharp internal corners (minimum 1mm fillet for stress).
7. **Elephant-foot compensation:** apply `ef_chamfer` (0.3-0.5mm at 45°) to every bottom edge.
8. **Holes oversize:** a bore is `nominal + hole compensation + fit allowance`, two separate numbers. Measured for PETG on a Bambu X1C with a 0.4mm nozzle: compensation **+0.30mm**; allowance **-0.08** press (it must be interference: 0.00 is a slide, not a press), **+0.15** bearing (shaft rotates in it), **+0.30** free-running. For a 3mm rod: press 3.22, bearing 3.45, running 3.60.
9. **No magic numbers:** every numeric value is a parameter or derived from parameters.
10. **Prefer ribs over thick walls:** a 1.6mm rib is stronger per gram than a 5mm solid wall.
11. **Support-free by default:** choose orientations, chamfers, teardrops and splits that eliminate supports. Accept supports only when the geometry truly needs them, then minimise contact and document why in PRINT SETTINGS.
12. **Assert what you claim:** every measurable acceptance criterion, and every functional claim in a comment or README ("snaps in after 0.8mm", "clears the cam"), has an `assert()` behind it, or is labelled unverified.
13. **Verify by building, then peer-review by looking:** never hand off, or claim correctness of, a model you haven't compiled. The deterministic [gate](#verification) comes first, then a fresh-eyes [Design Review](#design-review). Static code review is necessary but not sufficient.

## Mechanical Parts

For gears, threads, snap-fits, living hinges and joints, see [mechanical.md](mechanical.md). Material-critical notes:

- **Snap-fits:** PETG excels (5-8% strain), ABS is good (3-5%), PLA is fragile (1-1.5% max).
- **Living hinges:** PETG only (0.4mm thick, 50,000+ cycles). PLA breaks within 50-100 cycles; ABS is marginal.
- **Metal fasteners into plastic:** use a heat-set insert, a captive nut, or a plain **self-tap hole at about 50% thread depth**. Don't print a metric thread that a metal screw must mate with. A real print failed that way: a printed M8 thread in PETG didn't form. A self-tapped Ø7.5 hole for M8 held, while Ø7.0 seized. Printed threads suit coarse plastic-to-plastic joints (≥M10, trapezoidal or buttress profile).
- **Flexing features** (fins, barbs, cantilevers, springs) bend **within the layer plane**. Bending across layers delaminates them.

## Verification

A **hard, deterministic gate** that every part must pass before the review and before hand-off:

```sh
python "<skill-dir>/verify-model.py" model.scad --build-volume 256x256x256 --export .
```

It compiles every `part` value and checks each for clean stderr, one body, manifold, on the plate, and fits the build volume. `clash_*` parts must render empty. It prints `GATE: PASS` or the failing parts. If OpenSCAD isn't installed where you're running, install it in your sandbox if you can (verification.md says how). Without it there's no gate and no STL, and a `.scad` alone is not something a slicer can open. **Read [verification.md](verification.md) before your first gate run.** It covers what each failure means, contracts, reporting, and the fallback without Python. Run the gate on initial generation and after any structural change. After a minor tweak, re-run it on just the changed parts (`--parts`).

## Design Review

A **fresh-eyes peer review** by a sub-agent. It covers what the gate can't: whether the geometry looks right in renders, whether the mechanism makes sense, the qualitative criteria, and FDM-rule compliance.

**Which model reviews.** It's fixed, so reviews are consistent from run to run:

- **Every full review runs on `model: "sonnet"`**, including the only review a simple part gets.
- **At most one final review per project runs on `model: "fable"`**, once the design is complete and about to be printed for the first time: every part built, the Sonnet findings fixed, gate green.
  - **Complex projects** get it without asking. Complex means a multi-part assembly, or a mechanism (anything that moves, flexes or latches).
  - **Simple parts** only get it if the user wants it. After the Sonnet review's fixes, ask at hand-off: *"This passed a Sonnet design review. Would you like a deeper second review on Fable before you print? It costs roughly five to seven times as much as the Sonnet review, and catches a little more."* Run it only on a yes. Skip the offer when nobody can answer (an unattended run).
  - **Recording it:** add a line to the DESCRIPTION header with the model ID the reviewer reports (`// Final review: 2026-09-29, claude-fable-5-1`). Later sessions see it: they use Sonnet and don't offer Fable again, unless the user asks.
- **No Fable access:** not everyone can use Fable. If the Agent tool doesn't list `fable`, or the call fails because the model isn't available, run that review on `"sonnet"` instead and tell the user. Never offer a Fable review you can't run.

**Spawn it** with the Agent tool on that model, in the foreground, since the next step needs its findings. Give it:

- the `.scad` path and the OpenSCAD path;
- the numbered acceptance criteria;
- the printer and material;
- the line "Read `<skill-dir>/design-review.md`, your complete brief; the gate has passed."

Don't read design-review.md yourself: it's the reviewer's brief, not yours.

**Triage** the findings (severity, what, where, suggested fix). Fix the real issues, re-run the gate and re-export after any structural fix, and push back on findings that are wrong or out of scope. Surface genuine trade-offs to the user. If the review fails or returns nothing, say so and hand off the verified files with that caveat. Don't loop.

### Review tiers

- **Full review** (the sub-agent, on the model above). Required for initial generation, major structural changes (new load-bearing features, added or removed parts, splitting), orientation changes and material changes.
- **Lightweight check** (yourself, no sub-agent). For parameter tweaks, cosmetic changes and small non-structural features. Re-run the gate on the changed parts and ask: did this create an unsupported overhang, break a nozzle-width multiple, or introduce a coincident face?
- After 3-5 cumulative minor changes, offer a full review. Don't force it.

## After Generation

Hand off the `.scad`, the STLs (and 3MF) saved in Workflow step 7, and any renders. Never hand off only the `.scad`: slicers can't open it. Name the file to open first (the `.3mf` on a Bambu printer, otherwise the STL). Then give a short summary: what the gate verified (its PASS line), what the review changed, and the residuals only a print can confirm.

- **New users** (check memory for 3D-printing experience; none means new): offer help getting the model viewed, exported and printed, including installing OpenSCAD. Walk through [printing-workflow.md](printing-workflow.md) if they accept, then save a `user` memory that they've been introduced.
- **Simple part, Fable available, no final review recorded yet:** offer the Fable review ([Design Review](#design-review)).
- **Bambu Lab printer:** the project 3MF from step 7 is the file to open in Bambu Studio or OrcaSlicer. Without Python, or if the user slices in something else, hand off the STL with the PRINT SETTINGS header for manual entry.

## References

| File | Load when |
|---|---|
| [printer-configuration.md](printer-configuration.md) | Step 0, always |
| [material-pla.md](material-pla.md) / [material-petg.md](material-petg.md) / [material-abs.md](material-abs.md) | Step 1, the chosen material only |
| [openscad-reference.md](openscad-reference.md) | Before writing code: language gotchas, FDM module patterns (teardrop, chamfered shelf, EF base) |
| [verification.md](verification.md) | Before running the gate |
| [design-review.md](design-review.md) | Never yourself: it's the review sub-agent's brief |
| [bambu-3mf-export.md](bambu-3mf-export.md) | When making a Bambu 3MF |
| [fdm-design-principles.md](fdm-design-principles.md) | Only for hard support-free or structural cases |
| [printing-guidelines.md](printing-guidelines.md) | Only for tolerance or overhang data the material file lacks |
| [mechanical.md](mechanical.md) | Only for gears, threads, snap-fits, hinges, joints |
| [printing-workflow.md](printing-workflow.md) | Only for a new user's export-to-print walkthrough |
