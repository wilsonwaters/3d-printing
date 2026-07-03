
# 3D Print Designer

Design and generate parametric, FDM-print-optimized OpenSCAD (.scad) models.

## Step 0: Printer Configuration (always do this first)

Ask the user what 3D printer they're using. Printer specs constrain build volume, material options, minimum feature sizes, and tolerances.

See [printer-configuration.md](#printer-configuration) — MANDATORY READ before any design work. It has the full workflow for identifying printer specs (auto from make/model via [printer-profiles.md](#printer-profiles), or manual fallback) and how they affect design parameters.

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
- **PLA**: [material-pla.md](#material-pla) — MANDATORY READ for PLA designs
- **PETG**: [material-petg.md](#material-petg) — MANDATORY READ for PETG designs
- **ABS**: [material-abs.md](#material-abs) — MANDATORY READ for ABS designs

## Step 2: Support Strategy

**Default: design for support-free printing.** Supports waste material, leave surface marks, risk failures, and add post-processing. Most models can avoid them through orientation, geometry adjustments, and self-supporting features.

1. **Assess whether the model can reasonably be support-free** — consider orientation, splitting, and geometry alternatives (see [fdm-design-principles.md](#fdm-design-principles) > Support-Free Design Techniques).
2. **If feasible both ways**, ask the user:
   > "This model can be designed to print without supports. Would you prefer a support-free design (may involve some geometry compromises like chamfered undersides or part splitting), or are you OK printing with supports for a cleaner shape?"
3. **If supports are unavoidable** (complex internal cavities, deep recesses, geometry that can't be reoriented) — note why, design to minimize them, and check whether the user has multi-material capability for soluble supports.
4. **If no preference is expressed and you haven't asked**, default to support-free.

Key support-free techniques (detail in [fdm-design-principles.md](#fdm-design-principles)): overhangs ≤45° from vertical; 45° chamfers on undersides instead of flat ledges; teardrop profiles for horizontal holes; taper features from below; pointed (gothic) arches for spanning; bridge short spans instead of overhanging; split parts along overhang boundaries; built-in structural supports (pillars, ribs).

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

OpenSCAD language gotchas and reusable module patterns (boolean overlap, screw holes, teardrops, chamfered shelves, EF base) live in [openscad-reference.md](#openscad-reference) — load it before writing code.

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

For gears, threads, snap-fits, living hinges, and complex mechanical features, see [mechanical.md](#mechanical).

Material-critical notes:
- **Snap-fits**: PETG excels (5-8% strain), ABS good (3-5%), PLA fragile (1-1.5% max).
- **Living hinges**: PETG only (0.4mm thick, 50,000+ cycles). PLA breaks in 50-100 cycles; ABS marginal.
- **Threads**: M4+ only for printed threads. Heat-set inserts strongly preferred (ABS works especially well due to high Tg).

## Verification

Verification is a **hard, deterministic gate**: it confirms the model compiles into a valid manifold solid, its measured dimensions are within the intended envelope, and its `assert()` contracts hold — reproducible, binary pass/fail. It is not judgment; "does it look right?" is the [Design Review](#design-review)'s job. Order of operations: **generate → verify → design review → hand off.** Don't review or hand off a part that fails this gate.

> Verification answers "does it build into a valid solid that meets the *measurable* spec?" — Design Review answers "is it actually the right shape, and a *good* FDM design?"

**MANDATORY for** initial generation and any major/structural change. For minor tweaks, run the lightweight slice (re-compile the changed `part=` and re-check affected dimensions/asserts). If OpenSCAD is not installed you cannot run this gate — say so explicitly, do an extra-careful static review, and offer to help install it (prefer the nightly for verification quality).

The gate, in three checks — exact commands, capability detection, and per-version fallbacks in **[verification.md](#verification) — MANDATORY READ before verifying**:

1. **Build gate** — compile every `part=` with the OpenSCAD CLI (CLI STL export does a full render, catching errors the GUI preview hides). A part passes only if exit code is 0, the STL is non-empty, and stderr — after dropping `ECHO:` lines — is clean of fatal phrases (`ERROR:`, `WARNING:`, `Assertion`, `not be a valid 2-manifold`, `Simple: no`, `Current top level object is empty`, `(PolySet)`). A non-manifold solid can exit 0, so **gate on stderr, not the exit code alone.**
2. **Dimension + contract checks** — measured bounding box within the intended envelope (`--summary` JSON on modern builds, or a stdlib STL parser on 2021.01), and all `assert()` contracts pass.
3. **Requirements traceability** — trace every *mechanically checkable* acceptance criterion to one of the above. Carry eyeball criteria to the Design Review; report print-only criteria (e.g. "a real M8 mates") as a residual — never silently pass.

After verifying, state what you mechanically confirmed, e.g.:
> "Verified on OpenSCAD 2026.06.19 (Manifold): both parts compile clean, measured bounding boxes 17.5×17.5×20.2mm and 16×16×9.6mm (within the 21mm depth limit), all asserts pass. Residual: an actual M8 mating needs a test print."

## Design Review

The Design Review is a **fresh-eyes peer review** — not the author marking its own homework. It covers what the gate cannot: visual inspection of the geometry (does it actually look right?), whether the mechanism/approach makes sense, the qualitative acceptance criteria, and FDM-rule compliance.

**Run it as a self-contained sub-agent (Agent tool) with a different model when one is available** — a different model with clean context catches blind spots the author shares with itself. Give it everything it needs to stand alone: the `.scad` path, the numbered acceptance criteria, the printer + material, and a pointer to **[design-review.md](#design-review)** (the complete reviewer brief — procedure, render commands, and Full Review Checklist). You *may* tell it "the gate already passed, focus on judgment" to scope its effort. If no other model is available, still run it as a separate fresh pass (clean-context sub-agent) and note it was same-model.

The review **returns findings** (severity · what · where · suggested fix). The author then **triages**: fix the real issues, **re-run Verification and re-review** after any structural fix (fixes can introduce new problems), and **push back** on findings that are wrong or out of scope — the review is advisory peer critique, not an authority. Surface genuine disagreements or trade-offs to the user rather than silently accepting or overriding them.

### Review Tiers

**Full Review** (spawn the sub-agent; uses [design-review.md](#design-review)) — MANDATORY for:
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
7. **Import the STL into their slicer** (Bambu Studio, PrusaSlicer, Cura, OrcaSlicer, etc.) — apply the PRINT SETTINGS from the file header, check the slicer preview, send to printer. **On a Bambu Lab printer, offer the settings-baked-in 3MF instead** (next step) — it skips the manual settings entry.
8. See [printing-workflow.md](#printing-workflow) for detailed export-to-print steps.

After walking them through it, save a `user` memory noting they've been introduced to the workflow.

**Bambu Lab printers (any experience level) — offer a settings-baked-in 3MF.** Offer this only when **all** hold: the printer from Step 0 is a Bambu Lab machine, the user slices in Bambu Studio (or OrcaSlicer), **and Python is available on the machine** (the generator is a Python script — check with `python --version` / `python3 --version`). When they do, generate a Bambu *project* `.3mf` that opens with layer height, walls, infill, and supports **already applied** — eliminating the manual settings entry (filament is left for the user to select unless they ask to bake it in). The helper `make-bambu-3mf.py` (Python stdlib only — no pip installs) builds it from the OpenSCAD mesh plus the model's PRINT SETTINGS header, sourcing settings from Bambu's official profiles. See [bambu-3mf-export.md](#bambu-3mf-export).

**If Python isn't available, don't attempt the 3MF** — say so plainly, hand off the STL, and tell the user to import it into Bambu Studio and apply the PRINT SETTINGS header manually (offer to help install Python for next time). For non-Bambu printers/slicers, the settings-in-3MF format doesn't apply, so the STL path above is the only option.

**Experienced users** — skip the walkthrough offer. Still offer the Bambu 3MF if they're on a Bambu Lab printer; it saves them dialing settings in by hand.

## References

**Load during Step 0 (printer config):**
- **[printer-configuration.md](#printer-configuration)** — MANDATORY READ before any design work
- **[printer-profiles.md](#printer-profiles)** — database of known printer specs for auto-populating from make/model

**Load during Step 1 (material selection) — only the selected material:**
- **[material-pla.md](#material-pla)** / **[material-petg.md](#material-petg)** / **[material-abs.md](#material-abs)** — MANDATORY READ for the chosen material

**Load before writing code:**
- **[openscad-reference.md](#openscad-reference)** — MANDATORY READ: OpenSCAD language gotchas plus reusable module patterns (boolean overlap, rounded box, screw hole, teardrop, chamfered shelf, EF base)

**Load before verifying (before the Design Review):**
- **[verification.md](#verification)** — MANDATORY READ: how to compile, measure, and trace requirements with the OpenSCAD CLI (version-specific fallbacks)

**Load when running the Design Review:**
- **[design-review.md](#design-review)** — the complete reviewer brief (procedure + Full Review Checklist); the review sub-agent is pointed here

**Load only when specifically needed (do NOT pre-load):**
- **[fdm-design-principles.md](#fdm-design-principles)** — support-free technique details (gothic arches, graduated overhangs, part splitting) and structural optimization (ribs vs walls, stress management)
- **[printing-guidelines.md](#printing-guidelines)** — general tolerance/overhang data beyond what the material file provides
- **[mechanical.md](#mechanical)** — gears, threads, snap-fits, living hinges, joints
- **[printing-workflow.md](#printing-workflow)** — export-to-print walkthrough for the "After Generation" step
- **[bambu-3mf-export.md](#bambu-3mf-export)** — Bambu-only: generate a project `.3mf` with print settings baked in (via the bundled `make-bambu-3mf.py`); load in the "After Generation" step when the user has a Bambu Lab printer

## Keywords

OpenSCAD, 3D printing, CAD, parametric design, STL, 3MF, FDM, PLA, PETG, ABS, mechanical parts, enclosure, bracket, gear, assembly, scad file, 3D model, filament, print orientation, layer adhesion, slicer, export, G-code, PrusaSlicer, Cura, OrcaSlicer, Bambu Studio, Bambu project 3mf, print settings baked in, print workflow, acetone smoothing, heat resistant


---

# Reference Files

<a id="printer-configuration"></a>

## Printer Configuration

# Printer Configuration Guide

How to collect, validate, and apply printer-specific specs to OpenSCAD model design.

## Step 1: Identify the Printer

**Ask: "What 3D printer are you using?"**

### If the user provides a make and model:

1. Look up the printer in [printer-profiles.md](printer-profiles.md)
2. Present the matched specs and ask: "I found specs for your [printer]. Does this look right? Are you using any non-stock modifications (different nozzle size, enclosure mod, etc.)?"
3. Apply any user corrections (e.g., "I swapped to a 0.6mm nozzle", "I added an enclosure")

### If the printer is not in the database:

Collect specs manually in order of importance:

**Must-have (affects model geometry directly):**

1. **Build volume** (X x Y x Z mm) — determines max single-piece part size
2. **Nozzle diameter** (mm) — affects all minimum dimensions (default: 0.4mm if unknown)

**Important (affects material and feature choices):**

3. **Max hotend temperature** (C) — gates which materials are available
4. **Enclosure** (yes/no) — gates whether ABS/ASA/Nylon/PC are practical
5. **Max bed temperature** (C) — supports or limits material adhesion
6. **Extruder type** (direct drive / bowden) — affects TPU capability and stringing

**Ask only if relevant to the current design:**

7. **Auto bed leveling** (yes/no) — affects first-layer strategy for large flat parts
8. **Multi-material capability** (AMS, MMU, etc.) — affects multi-color/soluble support designs

### Sensible defaults (when user doesn't know a spec):

| Spec | Default | Rationale |
|------|---------|-----------|
| Nozzle diameter | 0.4mm | Stock on nearly all consumer printers |
| Layer height | 0.2mm | Good balance of speed and quality |
| Max hotend temp | 260C | Conservative; covers PLA/PETG safely |
| Max bed temp | 100C | Common for mid-range printers |
| Enclosure | No | Most consumer printers are open frame |
| Extruder | Direct Drive | Standard on modern printers (2022+) |
| ABL | Yes | Standard on modern printers |
| Multi-material | No | Most setups are single material |

## Step 2: Validate Material Compatibility

Cross-reference the user's printer capabilities with the requested material:

| Material | Min Hotend | Min Bed | Enclosure | Extruder Notes |
|----------|-----------|---------|-----------|----------------|
| PLA | 200C | 50C (or none) | Not needed | Any |
| PETG | 230C | 70C | Not needed | Any |
| TPU | 220C | 50C | Not needed | Direct drive strongly preferred |
| ABS | 240C | 90C | **Required** | Any |
| ASA | 240C | 90C | **Required** | Any |
| Nylon (PA) | 260C | 80C | Preferred | Direct drive preferred; dry storage critical |
| Polycarbonate | 280C | 110C | **Required** | Direct drive; hardened nozzle recommended |
| CF composites | 240C+ | 80C+ | Preferred | **Hardened nozzle required** (steel/ruby) |

**If the user's printer can't handle the requested material:**
- Warn them clearly: "Your [printer] maxes at [temp]C / has no enclosure — [material] will likely warp/fail."
- Suggest the best alternative their printer supports
- If they want to proceed anyway, note the risk in the PRINT SETTINGS header

## Step 3: Apply Specs to Design Parameters

Printer specs flow into the `// Printer settings` block in every generated .scad file:

```openscad
// === PRINTER ===
// Printer: Bambu Lab P1S (or "Custom / Unknown")
// Build Volume: 256 x 256 x 256 mm

// === PARAMETERS ===
// Printer settings
nozzle_diameter = 0.4;
layer_height = 0.2;
build_x = 256;
build_y = 256;
build_z = 256;
```

### How each spec drives design decisions:

**Build volume** — the hard constraint:
- If any part dimension exceeds build volume, the part MUST be split into a multi-part assembly with joints, fasteners, or alignment features
- Leave 5-10mm margin from bed edges for adhesion reliability
- For bed-slinger printers (e.g., Bambu A1, Ender 3), tall prints are more prone to wobble — prefer wider/shorter orientations

**Nozzle diameter** — drives minimum dimensions:

| Design Parameter | Formula | 0.4mm Nozzle | 0.6mm Nozzle | 0.2mm Nozzle |
|------------------|---------|-------------|-------------|-------------|
| Extrusion width | nozzle * 1.125 | 0.45mm | 0.675mm | 0.225mm |
| Min wall thickness | 2 * extrusion width | 0.9mm | 1.35mm | 0.45mm |
| Ideal wall multiples | N * extrusion width | 0.9, 1.35, 1.8mm | 1.35, 2.0, 2.7mm | 0.45, 0.9, 1.35mm |
| Min standalone feature | ~4 * extrusion width | ~1.8mm | ~2.7mm | ~0.9mm |
| Hole diameter compensation | +0.3 to +0.4mm | +0.3mm | +0.4mm | +0.2mm |
| Sliding fit clearance (per side) | ~0.5 * nozzle | 0.2mm | 0.3mm | 0.1mm |
| Min embossed text line width | ~6 * nozzle | 2.5mm | 3.0mm | 1.5mm |
| Min engraved text line width | ~2.5 * nozzle | 1.0mm | 1.5mm | 0.5mm |
| Max layer height | ~0.75 * nozzle | 0.3mm | 0.45mm | 0.15mm |

**Enclosure** — affects material viability and warping:
- No enclosure: stick to PLA/PETG/TPU. For large flat PLA/PETG parts, consider adding chamfered first-layer edges and avoid sharp corners on the base
- With enclosure: ABS/ASA/Nylon/PC become viable. Note: PLA can soften in enclosed printers if chamber exceeds ~50C

**Extruder type** — affects flexible material design:
- Bowden: TPU possible but tricky (15-20mm/s max). Design TPU parts with thicker walls (min 3x nozzle). Minimize disconnected features on same layer (stringing)
- Direct drive: TPU prints well (25-35mm/s). Standard wall thickness rules apply

**Multi-material** — unlocks advanced techniques:
- Soluble supports (PVA/BVOH): design can include aggressive overhangs, internal cavities, and features that would otherwise need support
- Multi-color: design separate bodies per color, exported as aligned STLs
- Multi-material interfaces: add interlocking geometry at material boundaries

---

<a id="printer-profiles"></a>

## Printer Profiles

# Printer Profiles Database

Known printer specifications for auto-populating printer settings. When a user provides a make and model, look up the specs here. If the printer is not listed, ask the user for manual specs.

## How to Use This File

1. Match the user's printer to a profile below (case-insensitive, fuzzy match OK)
2. Present the matched specs to the user for confirmation ("I found specs for your Bambu Lab P1S -- does this look right?")
3. If no match, fall back to [Manual Spec Collection](#manual-spec-collection)
4. Apply the specs to the design parameters

## Bambu Lab

### Bambu Lab X1 Carbon / X1C

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm hardened steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | Yes (passive, ~50C chamber) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor + LiDAR) |
| Multi-Material | Optional AMS (up to 4 units, 16 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC, PVA, CF composites |
| Notes | Hardened nozzle handles abrasive filaments. Best Bambu for engineering materials. |

### Bambu Lab P1S

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | Yes (passive, ~45-50C chamber) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS (up to 4 units, 16 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PVA, PA (with caution) |
| Notes | 100C bed limits PC printing. Enclosure enables ABS/ASA. |

### Bambu Lab P1P

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS (up to 4 units, 16 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | No enclosure -- ABS/ASA not recommended. Otherwise same platform as P1S. |

### Bambu Lab A1

| Spec | Value |
|------|-------|
| Build Volume | 256 x 256 x 256 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame, bed-slinger) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS Lite (up to 4 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | Bed-slinger design. No enclosure limits to PLA/PETG/TPU. AMS Lite has fewer slots than full AMS. |

### Bambu Lab A1 Mini

| Spec | Value |
|------|-------|
| Build Volume | 180 x 180 x 180 mm |
| Stock Nozzle | 0.4mm stainless steel |
| Supported Nozzles | 0.2, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.08 - 0.28mm (0.4mm nozzle) |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (force sensor) |
| Multi-Material | Optional AMS Lite (up to 4 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | Small build volume. Good for small parts only. |

## Prusa

### Prusa MK4S / MK4

| Spec | Value |
|------|-------|
| Build Volume | 250 x 210 x 220 mm |
| Stock Nozzle | 0.4mm brass (Nextruder) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 290C |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | No (optional aftermarket / Prusa Enclosure) |
| Extruder Type | Direct Drive (Nextruder) |
| Auto Bed Leveling | Yes (load cell / strain gauge) |
| Multi-Material | Optional MMU3 (5 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS (with enclosure), ASA (with enclosure), PA, PC |
| Notes | 120C bed handles PC. Lack of stock enclosure limits ABS in practice. Asymmetric bed (250x210). |

### Prusa MK3S+ / MK3S

| Spec | Value |
|------|-------|
| Build Volume | 250 x 210 x 210 mm |
| Stock Nozzle | 0.4mm brass (E3D V6) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 280C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (optional aftermarket / Prusa Enclosure) |
| Extruder Type | Direct Drive (Bondtech) |
| Auto Bed Leveling | Yes (PINDA probe) |
| Multi-Material | Optional MMU2S (5 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS (with enclosure) |
| Notes | Legacy but still very popular. Asymmetric bed (250x210). |

### Prusa XL (Single/Multi-Tool)

| Spec | Value |
|------|-------|
| Build Volume | 360 x 360 x 360 mm |
| Stock Nozzle | 0.4mm brass (Nextruder) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 290C |
| Max Bed Temp | 120C |
| Heated Bed | Yes (segmented) |
| Enclosure | No (optional aftermarket / Prusa Enclosure) |
| Extruder Type | Direct Drive (Nextruder, up to 5 toolheads) |
| Auto Bed Leveling | Yes (load cell per toolhead) |
| Multi-Material | Up to 5 independent toolheads (no purge waste) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS (with enclosure), ASA (with enclosure), PA, PC |
| Notes | Large build volume. Multi-tool = no purge tower waste. Segmented bed heats only area in use. |

### Prusa Core One

| Spec | Value |
|------|-------|
| Build Volume | 250 x 220 x 270 mm |
| Stock Nozzle | 0.4mm brass (Nextruder) |
| Supported Nozzles | 0.25, 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 290C |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | Yes (fully enclosed with active airflow) |
| Extruder Type | Direct Drive (Nextruder) |
| Auto Bed Leveling | Yes (load cell) |
| Multi-Material | Optional MMU3 (5 slots) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC |
| Notes | Prusa's first enclosed CoreXY. Handles all materials well. |

## Creality

### Creality K1C

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm |
| Stock Nozzle | 0.4mm hardened steel |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | Yes |
| Extruder Type | Direct Drive (all-metal, dual-gear) |
| Auto Bed Leveling | Yes (LiDAR + strain sensor) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, CF composites |
| Notes | Hardened nozzle for CF. Enclosed for ABS. No multi-material. |

### Creality K1 / K1 Max

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm (K1) / 300 x 300 x 300 mm (K1 Max) |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 300C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | Yes |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA |
| Notes | K1 Max has larger build volume. Brass nozzle -- avoid CF filaments. |

### Creality Ender 3 V3 / V3 SE / V3 KE

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 260C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive (V3/KE) / Bowden (V3 SE) |
| Auto Bed Leveling | Yes (CR Touch or strain sensor) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU (direct drive models only) |
| Notes | Budget printer. 260C hotend limits material options. No enclosure. V3 SE uses Bowden -- limited TPU. |

### Creality Ender 3 / Ender 3 Pro / Ender 3 V2

| Spec | Value |
|------|-------|
| Build Volume | 220 x 220 x 250 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 255C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Bowden |
| Auto Bed Leveling | No (manual, upgradeable) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG |
| Notes | Legacy budget printer. Bowden limits TPU. No ABL stock. Very popular -- millions sold. Highly moddable. |

## Voron (Self-Sourced Kits)

### Voron 2.4

| Spec | Value |
|------|-------|
| Build Volume | 250x250x230 / 300x300x280 / 350x350x330 mm (varies by build) |
| Stock Nozzle | 0.4mm (E3D V6, Revo, or Dragon hotend) |
| Supported Nozzles | Any (user choice) |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C (AC silicone heater) |
| Heated Bed | Yes (AC-powered) |
| Enclosure | Yes (fully enclosed, ~50-60C chamber) |
| Extruder Type | Direct Drive (Stealthburner/Clockwork2) |
| Auto Bed Leveling | Yes (Quad Gantry Leveling + probe or Tap) |
| Multi-Material | Optional (ERCF, Tradrack, etc.) |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC, CF composites |
| Notes | Self-sourced kit -- specs vary by build. CoreXY with 4 independent Z motors. Largest option for enclosed printing. Ask user for their specific build size. |

### Voron Trident

| Spec | Value |
|------|-------|
| Build Volume | 250x250x250 / 300x300x300 / 350x350x350 mm |
| Stock Nozzle | 0.4mm (user choice) |
| Supported Nozzles | Any |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C |
| Heated Bed | Yes (AC-powered) |
| Enclosure | Yes (fully enclosed) |
| Extruder Type | Direct Drive (Stealthburner/Clockwork2) |
| Auto Bed Leveling | Yes (3-point Z leveling + probe or Tap) |
| Multi-Material | Optional |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC, CF composites |
| Notes | Similar to 2.4 but with 3-point Z bed leveling instead of QGL. Slightly simpler build. |

### Voron 0.2

| Spec | Value |
|------|-------|
| Build Volume | 120 x 120 x 120 mm |
| Stock Nozzle | 0.4mm |
| Supported Nozzles | 0.2, 0.4mm |
| Layer Height Range | 0.05 - 0.25mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C |
| Heated Bed | Yes |
| Enclosure | Yes (fully enclosed) |
| Extruder Type | Direct Drive (Mini Stealthburner) |
| Auto Bed Leveling | Yes (probe or Tap) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS, ASA, PA, PC |
| Notes | Very small build volume. Designed for small, fast parts. Fully enclosed despite size. |

## Ankermake

### Ankermake M5 / M5C

| Spec | Value |
|------|-------|
| Build Volume | 235 x 235 x 250 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 260C |
| Max Bed Temp | 100C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (M5) / No (M5C) |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU |
| Notes | 260C limit restricts to PLA/PETG/TPU. No enclosure. |

## Elegoo

### Elegoo Neptune 4 Pro / Neptune 4

| Spec | Value |
|------|-------|
| Build Volume | 225 x 225 x 265 mm |
| Stock Nozzle | 0.4mm brass |
| Supported Nozzles | 0.4, 0.6, 0.8mm |
| Layer Height Range | 0.10 - 0.30mm |
| Max Hotend Temp | 300C |
| Max Bed Temp | 110C |
| Heated Bed | Yes |
| Enclosure | No (open frame) |
| Extruder Type | Direct Drive (Pro) / Bowden (base) |
| Auto Bed Leveling | Yes |
| Multi-Material | No |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU (Pro only), ABS (limited without enclosure) |
| Notes | Neptune 4 Pro has direct drive; base Neptune 4 is Bowden. |

## Ratrig

### Ratrig V-Core 4

| Spec | Value |
|------|-------|
| Build Volume | 200x200x200 / 300x300x300 / 400x400x400 / 500x500x500 mm |
| Stock Nozzle | 0.4mm (user choice of hotend) |
| Supported Nozzles | Any |
| Layer Height Range | 0.05 - 0.30mm |
| Max Hotend Temp | 285-300C (depends on hotend) |
| Max Bed Temp | 120C |
| Heated Bed | Yes (AC or DC) |
| Enclosure | Optional (panels available) |
| Extruder Type | Direct Drive |
| Auto Bed Leveling | Yes (Beacon or similar) |
| Multi-Material | Optional |
| Filament Diameter | 1.75mm |
| Printable Materials | PLA, PETG, TPU, ABS/ASA (with enclosure), PA, PC (with enclosure) |
| Notes | Semi-kit. Very large build options (up to 500mm). Ask user for their specific build size. |

---

## Manual Spec Collection

When the user's printer is not listed above, collect these specs in order of importance:

### Must-Have (affects model geometry directly)

1. **Build volume** (X x Y x Z in mm) -- "What is your printer's build volume / bed size?"
2. **Nozzle diameter** (mm) -- "What nozzle size are you using?" (default: 0.4mm)

### Important (affects material and feature choices)

3. **Max hotend temperature** (C) -- "What's the maximum hotend/nozzle temperature?"
4. **Enclosure** (yes/no) -- "Does your printer have an enclosure?"
5. **Max bed temperature** (C) -- "What's the maximum bed temperature?"
6. **Extruder type** (direct drive / bowden) -- "Is your extruder direct drive or Bowden?"

### Nice-to-Have (affects advanced features)

7. **Auto bed leveling** (yes/no) -- "Does it have auto bed leveling?"
8. **Multi-material** (yes/no, type) -- "Does it support multi-material printing (AMS, MMU, etc.)?"

### Sensible Defaults (when user doesn't know)

| Spec | Default | Rationale |
|------|---------|-----------|
| Nozzle diameter | 0.4mm | Standard on nearly all printers |
| Layer height | 0.2mm | Good balance of speed and quality |
| Max hotend temp | 260C | Conservative; covers PLA/PETG |
| Max bed temp | 100C | Common for mid-range printers |
| Enclosure | No | Most consumer printers are open frame |
| Extruder | Direct Drive | Increasingly standard on modern printers |
| ABL | Yes | Standard on modern printers |
| Multi-material | No | Most setups are single material |
| Filament diameter | 1.75mm | Near-universal standard |

---

<a id="material-pla"></a>

## Material Pla

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

---

<a id="material-petg"></a>

## Material Petg

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

---

<a id="material-abs"></a>

## Material Abs

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

---

<a id="fdm-design-principles"></a>

## Fdm Design Principles

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

---

<a id="openscad-reference"></a>

## Openscad Reference

# OpenSCAD Language Reference — Gotchas and Non-Obvious Behaviors

Curated reference focusing on behaviors that produce incorrect code if forgotten. Based on the [OpenSCAD User Manual](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/The_OpenSCAD_Language).

## 1. Mandatory Rules (broken geometry if violated)

### Epsilon Overlap for Boolean Operations

Coincident faces in `union()` produce undefined behavior. Cutting objects in `difference()` must extend past the surface being cut. This is **not optional**.

```openscad
eps = 0.01; // ALWAYS define this

// BAD — coincident top face
union() {
    cube([10, 10, 10]);
    translate([0, 0, 10]) cube([5, 5, 5]); // face exactly at z=10
}

// GOOD — epsilon overlap
union() {
    cube([10, 10, 10]);
    translate([0, 0, 10 - eps]) cube([5, 5, 5 + eps]);
}

// BAD — flush cut
difference() {
    cube([10, 10, 10]);
    translate([2, 2, 0]) cube([6, 6, 10]); // flush top and bottom
}

// GOOD — extend beyond both faces
difference() {
    cube([10, 10, 10]);
    translate([2, 2, -eps]) cube([6, 6, 10 + 2*eps]);
}
```

### Never Mix 2D and 3D in Boolean Operations

Subtracting a 2D shape from a 3D object produces undefined results. Always extrude 2D shapes before boolean operations.

### Polyhedron Faces Must Be Clockwise from Outside

Wrong winding = non-manifold geometry. Use F12 "Thrown Together" mode to check — pink faces have wrong winding. Validate by unioning with any cube and rendering (F6) — if it disappears, winding is wrong.

## 2. Variable System (most common source of confusion)

### Variables Are Constants

OpenSCAD variables cannot be changed after assignment. A second assignment **retroactively replaces** the first — both echos below print `2`:

```openscad
a = 1;   // never actually executed
echo(a); // 2
a = 2;   // replaces the first assignment
echo(a); // 2
```

There is no `a = a + 1`. Use recursion or list comprehensions for accumulation.

**Exception (by design)**: A second assignment in the main file overrides one in an `include` file without warning. This is the intended mechanism for overriding library defaults. Same for `-D` command-line options and Customizer values.

### Scope Rules

- Braces `{}` after operators (if/for/module) create new scopes — variables inside are invisible outside.
- **Bare braces `{}` are NOT scopes** — variables leak out.
- `$`-prefixed variables are **dynamically scoped** (pass through module calls). Regular variables use lexical scope and do NOT pass through:

```openscad
regular  = "global";
$special = "global";
module show() echo(regular, $special);
// show() always sees "global" for regular
// show() sees the calling scope's $special
```

## 3. Parameter Cheat Sheet (easy to get wrong)

### Primitives

- `cube(size, center)` — size can be scalar or `[x,y,z]`. **Not centered by default** — corner at origin, first octant.
- `sphere(r|d)` — `sphere(20)` sets r=20, NOT d=20. Use `sphere(d=20)` for diameter.
- `cylinder(h, r1, r2, center)` — positional order is h, r1, r2. **If any parameter is named, all following must be named.**
  - `cylinder(10, 5, 3)` — OK (h=10, r1=5, r2=3)
  - `cylinder(h=10, 5, 3)` — ERROR
  - `cylinder(10, r1=5, r2=3)` — OK

### Circles

- Circles are **inscribed polygons** (fit inside the specified radius, never reach it at segment midpoints)
- For axis-aligned integer bounding boxes, use `$fn` divisible by 4
- `$fn` > 128 not recommended for performance

### Resolution Pattern

```openscad
$fn = $preview ? 32 : 64; // Low for preview (F5), high for render (F6)
```

### Transformation Order

Transforms apply **right-to-left** (innermost first):

```openscad
translate([10, 0, 0]) rotate([0, 0, 45]) cube(5);
// First rotates, THEN translates

rotate([0, 0, 45]) translate([10, 0, 0]) cube(5);
// First translates, THEN rotates (arc motion!) — DIFFERENT result
```

### rotate() Axis Order

`rotate([ax, ay, az])` applies as **X then Y then Z**:

```openscad
rotate([ax, ay, az]) obj;
// equivalent to:
rotate([0, 0, az]) rotate([0, ay, 0]) rotate([ax, 0, 0]) obj;
```

A single scalar rotates around Z only: `rotate(45) square(10);`

## 4. Common Patterns

### Rounded 2D Shapes Using offset()

```openscad
// Fillet (round inside/concave corners):
offset(r=-R) offset(delta=+R) shape();
// WARNING: holes smaller than 2*R diameter will vanish

// Round (round outside/convex corners):
offset(r=+R) offset(delta=-R) shape();
// WARNING: walls thinner than 2*R will vanish
```

### Rounded Box

```openscad
module rounded_box(size, r) {
    minkowski() {
        cube([size.x - 2*r, size.y - 2*r, size.z/2]);
        cylinder(r=r, h=size.z/2);
    }
}
```

### FDM module patterns

Reusable, print-aware modules. They assume the derived constants from the file template (`fudge`, `tolerance`, `layer_height`).

```openscad
// Through-hole / pocket: extend cutting shapes beyond every surface they exit
// Pocket (open top):
difference() {
    cube([width, depth, height]);
    translate([wall, wall, wall])
        cube([width - 2*wall, depth - 2*wall, height + fudge]);
}
// Through-hole (extend BOTH directions):
translate([x, y, -fudge])
    cylinder(h = wall + 2*fudge, d = hole_d + tolerance);

// Screw hole with countersink
module screw_hole(h, d, head_d, head_h) {
    translate([0, 0, -fudge]) {
        cylinder(h=h + 2*fudge, d=d + tolerance);
        translate([0, 0, h - head_h])
            cylinder(h=head_h + fudge, d1=d + tolerance, d2=head_d + tolerance);
    }
}

// Teardrop hole — self-supporting horizontal hole (no support material)
module teardrop_hole(d, h) {
    r = d / 2;
    rotate([90, 0, 0])
        linear_extrude(height=h, center=true)
            union() {
                circle(r=r);
                polygon([[-r, 0], [r, 0], [0, r]]);
            }
}

// Chamfered shelf — replaces a flat shelf/ledge with a 45° chamfered (support-free) underside
module chamfered_shelf(width, depth, thick, chamfer) {
    ch = min(chamfer, thick - layer_height);  // leave at least one layer flat on top
    hull() {
        translate([0, 0, thick - layer_height])        // full-width top
            cube([width, depth, layer_height]);
        translate([ch, ch, 0])                          // narrower bottom (chamfer removes underside material)
            cube([width - 2*ch, depth - 2*ch, layer_height]);
    }
}

// Elephant-foot compensation base — taper the first layers inward
module ef_base(size, ef=0.4) {
    hull() {
        translate([ef, ef, ef])
            cube([size[0] - 2*ef, size[1] - 2*ef, size[2] - ef]);
        cube([size[0], size[1], 0.01]);
    }
}
```

### Preview vs Render Conditional

```openscad
$fn = $preview ? 32 : 64;
// $preview is true in F5, false in F6 and CLI STL export
// render() does NOT affect $preview
```

## 5. Performance Rules

| Operation | Cost | Mitigation |
|-----------|------|------------|
| `minkowski()` | O(N*M) on segment counts of both children | Reduce $fn on both. Wrap compound children in `union()`. |
| `resize()` | Full CGAL even in preview | Avoid in iterative design. Use scale() instead when possible. |
| `render()` | Forces full CSG in preview | Only use when preview artifacts are unacceptable. |
| `hull()` on 3D | Slow | Prefer hull() on 2D + linear_extrude. |
| `$fn > 128` | Can freeze the system | Keep $fn <= 64 for most uses, 128 max. |

**minkowski() trap**: Compound (multi-object) children may be treated as separate inputs. Always wrap in `union()`:

```openscad
// BAD — may produce incorrect result
minkowski() {
    cube(10);
    { sphere(2); cylinder(1, 2, 2); }
}

// GOOD
minkowski() {
    cube(10);
    union() { sphere(2); cylinder(1, 2, 2); }
}
```

## 6. Extrusion Gotchas

### linear_extrude and rotate_extrude

Both operate on the **XY-plane projection** of the 2D object. Transforms before extrusion affect the projection.

### rotate_extrude Specifically

- Z translation of 2D polygon: **no effect**
- X translation: increases diameter of result
- Y translation: shifts result in Z
- The 2D profile must be entirely on ONE side of the Y-axis

## 7. Debugging Modifiers

| Modifier | Effect | CSG Participation | Common Trap |
|----------|--------|-------------------|-------------|
| `%` (Background) | Transparent gray | **EXCLUDED** from CSG | Using as first child of `difference()` removes the base — nothing to subtract from |
| `#` (Debug) | Transparent pink | Normal | Safe for debugging boolean operations |
| `!` (Root) | Only shows this subtree | Parent transforms don't apply | Position changes when toggled |
| `*` (Disable) | Completely hidden | Ignored | Like commenting out a subtree |

## 8. Newer Features (likely training data gaps)

### Function Literals (2021.01+)

```openscad
func = function (x) x * x;
echo(func(5)); // 25

// Higher-order
selector = function (which)
    which == "add" ? function (x) x + x : function (x) x * x;
```

No arrow operator — syntax is `function (params) expression`.

### Tail Recursion (functions only)

Non-tail: limited to ~thousands of calls. Tail-recursive: up to 1,000,000. The recursive call must be the final operation:

```openscad
// NOT tail-recursive (+ happens after recursive call)
function sum(n) = n == 0 ? 0 : n + sum(n - 1);

// Tail-recursive (recursive call IS the return value)
function sum(n, acc=0) = n == 0 ? acc : sum(n - 1, acc + n);
```

Modules do NOT benefit from tail-recursion elimination.

### assert() Chaining (2019.05+)

`assert()` returns its children, enabling chained validation:

```openscad
function f(a, b) =
    assert(a < 0, "a must be negative")
    assert(b > 0, "b must be positive")
    let(c = a + b)
    assert(c != 0, "sum must not be zero")
    a * b;
```

### Objects / Dicts (Development Snapshot)

```openscad
data = import("config.json");
echo(data.width);   // dot-access
echo(data["width"]); // bracket-access
```

### Numeric Edge Cases

- Ranges `[0:10]` use **colons**, not commas — they are NOT vectors
- Float step danger: `[0:0.2:1]` may give wrong element count. Use power-of-2 fractions.
- `0/false` is `undef`. `0/0` is `nan`. `undef == undef` is true.
- `1/0` is `inf`. `atan(1/0)` is 90. Many functions handle infinities per IEEE 754.

---

<a id="mechanical"></a>

## Mechanical

# Mechanical Parts Patterns for OpenSCAD

## Gears

### Recommended Libraries
- **BOSL2** (preferred): `include <BOSL2/std.scad>` + `include <BOSL2/gears.scad>` — most complete
- **PolyGear**: Lightweight, involute profile gears
- **MCAD**: `include <MCAD/involute_gears.scad>` — basic but widely available

### Gear Parameters
```openscad
// Key parameters
teeth = 20;          // Number of teeth
mod = 1.5;           // Module (tooth size) — larger = bigger teeth
pressure_angle = 20; // Standard: 20 degrees
backlash = 0.2;      // Play between meshing gears (print tolerance)
```

### Spur Gear Without Libraries
```openscad
module spur_gear(teeth, mod, thickness, pressure_angle=20, backlash=0) {
    pitch_r = teeth * mod / 2;
    addendum = mod;
    dedendum = 1.25 * mod;
    outer_r = pitch_r + addendum;
    inner_r = pitch_r - dedendum;
    tooth_angle = 360 / teeth;

    linear_extrude(height=thickness)
        union() {
            circle(r=inner_r);
            for (i = [0:teeth-1])
                rotate([0, 0, i * tooth_angle])
                    polygon([
                        [inner_r * cos(-tooth_angle/4 + backlash/2),
                         inner_r * sin(-tooth_angle/4 + backlash/2)],
                        [outer_r * cos(-tooth_angle/8 + backlash/2),
                         outer_r * sin(-tooth_angle/8 + backlash/2)],
                        [outer_r * cos(tooth_angle/8 - backlash/2),
                         outer_r * sin(tooth_angle/8 - backlash/2)],
                        [inner_r * cos(tooth_angle/4 - backlash/2),
                         inner_r * sin(tooth_angle/4 - backlash/2)]
                    ]);
        }
}
```

### Meshing Two Gears
```openscad
teeth1 = 20;
teeth2 = 40;
mod = 1.5;
center_distance = (teeth1 + teeth2) * mod / 2;

spur_gear(teeth1, mod, 5);
translate([center_distance, 0, 0])
    rotate([0, 0, 180/teeth2])  // Offset by half a tooth
        spur_gear(teeth2, mod, 5);
```

## Threads

### Simple Thread Module
```openscad
module thread(d, pitch, length, internal=false) {
    tol = internal ? tolerance : 0;
    r = d/2 + tol;
    starts = 1;

    linear_extrude(height=length, twist=-360*length/pitch, slices=length/pitch*20)
        translate([r - pitch*0.65, 0, 0])
            circle(d=pitch*0.5, $fn=3);
}
```

For production threads, use BOSL2 `trapezoidal_threaded_rod()` or `threaded_rod()`.

## Snap Fits

### Cantilever Snap Fit
```openscad
module snap_hook(length, width, thickness, overhang) {
    // Beam
    cube([thickness, width, length]);
    // Hook
    translate([0, 0, length])
        hull() {
            cube([thickness, width, 0.01]);
            translate([overhang, 0, -overhang])
                cube([0.01, width, 0.01]);
        }
}

module snap_catch(width, depth, overhang) {
    translate([0, 0, 0])
        cube([overhang + tolerance, width + 2*tolerance, depth]);
}
```

### Snap Fit Design Rules
- Beam length: 5-10x thickness for flexibility
- Overhang: 0.5-1.5mm typical
- Add 45-degree entry ramp for easy insertion
- Wall behind catch must be thick enough to resist force

## Living Hinges

```openscad
module living_hinge(width, segments=5, gap=0.5, bridge=0.8) {
    segment_width = (width - (segments-1) * gap) / segments;
    for (i = [0:segments-1]) {
        translate([i * (segment_width + gap), 0, 0])
            cube([segment_width, bridge, wall_thickness]);
    }
}
```

- Print with PETG or TPU for flexibility
- PLA living hinges break after few cycles
- Minimum bridge width: 0.8mm

## Pin Joints / Hinges

```openscad
module hinge_knuckle(od, id, height) {
    difference() {
        cylinder(d=od, h=height);
        translate([0, 0, -fudge])
            cylinder(d=id + tolerance, h=height + 2*fudge);
    }
}

module hinge_pin(d, length) {
    cylinder(d=d - tolerance, h=length);
}
```

Interleave knuckles from two parts, insert pin through all.

## Dovetail Joints

```openscad
module dovetail_male(width, height, length, angle=15) {
    linear_extrude(height=length)
        polygon([
            [-width/2 + height*tan(angle), 0],
            [width/2 - height*tan(angle), 0],
            [width/2, height],
            [-width/2, height]
        ]);
}

module dovetail_female(width, height, length, angle=15) {
    translate([0, 0, -fudge])
        linear_extrude(height=length + 2*fudge)
            polygon([
                [-width/2 + height*tan(angle) - tolerance, -fudge],
                [width/2 - height*tan(angle) + tolerance, -fudge],
                [width/2 + tolerance, height + tolerance],
                [-width/2 - tolerance, height + tolerance]
            ]);
}
```

## Bearing Seats

```openscad
// Common bearing dimensions: 608 (skateboard bearing)
bearing_id = 8;    // Inner diameter
bearing_od = 22;   // Outer diameter
bearing_h = 7;     // Height

module bearing_seat(od, h, press_fit=true) {
    tol = press_fit ? -0.1 : tolerance;
    cylinder(d=od + tol, h=h);
}
```

## Standoffs and Bosses

```openscad
module standoff(od, id, height) {
    difference() {
        cylinder(d=od, h=height);
        translate([0, 0, -fudge])
            cylinder(d=id, h=height + 2*fudge);
    }
}

module screw_boss(od, screw_d, height) {
    difference() {
        union() {
            cylinder(d=od, h=height);
            // Reinforcement ribs
            for (a = [0:90:270])
                rotate([0, 0, a])
                    translate([0, -1, 0])
                        cube([od/2 + 2, 2, height]);
        }
        translate([0, 0, -fudge])
            cylinder(d=screw_d, h=height + 2*fudge);
    }
}
```

---

<a id="verification"></a>

## Verification

# Model Verification (deterministic build gate)

How an AI agent **empirically and deterministically verifies** a generated `.scad` model: it compiles, it produces a valid manifold solid, its measured dimensions match the spec, and its `assert()` contracts hold. These are reproducible, binary pass/fail checks — any run gives the same answer.

This is distinct from the [Design Review](SKILL.md#design-review), which is the judgment-based, fresh-eyes pass (including LLM visual inspection of renders). **Verification is the hard gate; the review is peer critique.** Run verification first; only review/hand off a model that passes it.

> Verification answers "does it build into a valid solid that meets the *measurable* spec?" — Design Review answers "is it actually the right shape, and a *good* FDM design?"

Rendering and inspecting views belongs to the Design Review, not this gate — those commands live in [design-review.md](design-review.md). Verification never renders images or judges appearance.

---

## Step 0 — Locate OpenSCAD, pick the best binary, detect capabilities

The binary is often NOT on PATH (especially on Windows). Find every install, and if both a stable and a newer/nightly build are present, **prefer the newest** — it has far better verification (Manifold backend, `--summary` JSON). Fall back to whatever exists.

```sh
# Look on PATH and in common install locations (newest first):
command -v openscad
ls -d "/c/Program Files"/OpenSCAD* "/Applications/OpenSCAD.app/Contents/MacOS" 2>/dev/null
# e.g. stable: "/c/Program Files/OpenSCAD/openscad.exe"
#      nightly: "/c/Program Files/OpenSCAD-2026.06.19-x86-64/openscad.exe"  (prefer this)
OSCAD="<newest resolved path>"
"$OSCAD" --version 2>&1                                   # e.g. 2021.01  or  2026.06.19
"$OSCAD" --help 2>&1 | grep -E "backend|summary|hardwarnings|preview|export-format"
```

Detect the tier from `--help`: if `--summary` and `--backend` are present you're on the **modern tier** (2024+/nightly); if absent you're on the **stable 2021.01 tier**. The two tiers verify differently — see 1b. If OpenSCAD is not installed at all, you cannot run this gate: say so explicitly, do an extra-careful static review, and offer to help the user install it (prefer the nightly for verification quality).

### Capability matrix

| Feature | Flag / behaviour | Stable 2021.01 | Modern 2024+/nightly |
|---|---|---|---|
| Full render + STL export | `-o out.stl` (CLI export always full-renders) | ✓ | ✓ |
| Default mesh engine | — | CGAL | **Manifold** (robust, self-heals minor issues) |
| Choose backend | `--backend=manifold\|CGAL` | ✗ | ✓ |
| Measured bbox / topology as JSON | `--summary all --summary-file x.json` | ✗ | ✓ |
| Stop on language warnings | `--hardwarnings` | ✓ (misses CGAL manifold warnings) | ✓ |
| Default STL encoding | — | **ASCII** (force `--export-format binstl` to byte-parse) | binary-capable |
| ThrownTogether PNG, camera, ortho | `--preview=throwntogether`, `--camera`, `--projection` | ✓ | ✓ |

---

## Part 1 — The deterministic build gate

### 1a. Cross-version base gate (always do this)

Compile every `part=` value. CLI STL export performs a **full render** (not preview), so it catches geometry errors the GUI preview hides.

```sh
"$OSCAD" --hardwarnings -o out.stl -D 'part="collet"' model.scad 2> render.log; ec=$?
```

A part PASSES the base gate only if ALL hold:
- `ec` is 0 (a hard error such as an empty top-level object or a failed `assert()` gives exit 1), AND
- `out.stl` exists and is non-empty (`[ -s out.stl ]`), AND
- `render.log`, **after dropping `ECHO:` lines**, is clean of fatal phrases:

```sh
PAT='^ERROR:|^WARNING:|^EXPORT-WARNING:|Assertion|CGAL error|not be a valid 2-manifold|may need repair|Simple:[[:space:]]*no|Current top level object is empty|\(PolySet\)'
grep -v '^ECHO:' render.log | grep -iE "$PAT"     # ANY output => FAIL
```

Notes baked in from testing both versions:
- **Gate on stderr, not the exit code alone.** A non-manifold solid can exit 0. On 2021.01 it prints `WARNING: ... not be a valid 2-manifold` / `Simple: no`; `--hardwarnings` does *not* catch these, so the grep is essential.
- **Exclude `ECHO:` lines** or an intentional echo containing a word like "empty" causes a false fail.
- `(PolySet)` in the top-level-object line means a raw `polyhedron()` was passed through without manifold validation (a yellow flag that the solid was never checked). A clean CSG result reports `(manifold)` (modern) or a plain facet summary (2021.01).

### 1b. Tier-specific checks

**Modern tier (preferred — recommend power users install the nightly):** the Manifold backend is the default and is robust, so the build rarely "fails" on minor issues; lean on JSON measurement and contracts instead.

```sh
# Exact measured bounding box + topology, no STL parsing:
"$OSCAD" -o out.stl -D 'part="collet"' --summary all --summary-file sum.json model.scad 2> render.log
python -c "import json;b=json.load(open('sum.json'))['geometry']['bounding_box'];print('size',b['size'])"
# Optional belt-and-braces: render with both engines and require both to succeed/agree:
"$OSCAD" --backend=manifold -o m.stl model.scad 2> m.log
"$OSCAD" --backend=CGAL     -o c.stl model.scad 2> c.log
```

`sum.json` schema (verified): `geometry.bounding_box.{min,max,size}` (mm), plus `geometry.{facets,convex,dimensions}`. Compare `size` to the intended envelope with ~0.1 mm slack.

**Stable 2021.01 tier (fallback):** no `--summary`/`--backend`; rely on the stderr grep (1a) for CGAL manifold warnings and a stdlib bounding box on a **binary** STL.

```sh
"$OSCAD" --hardwarnings --export-format binstl -o out.stl -D 'part="collet"' model.scad 2> render.log
python bbox.py out.stl          # bbox.py below; default STL is ASCII so binstl is required
```

### 1c. Design-by-contract: `assert()` + `echo()`

Bake measurable acceptance criteria into the model so a violated constraint **fails the build** (caught by 1a on every version):

```openscad
assert(insert_len <= tube_depth_max, "too deep for tube");
assert(relaxed_crest_d < tube_id_max, "won't fit the loosest tube");
echo(env_d = relaxed_crest_d, env_h = insert_len);     // ECHO: <values> to stderr
```

Read echoed values back with `grep '^ECHO:' render.log`.

### 1d. Bounding-box check (the envelope test)

Use `--summary` JSON on the modern tier (1b). On 2021.01, this stdlib binary-STL parser needs no dependencies:

```sh
cat > bbox.py <<'PY'
import struct,sys
f=open(sys.argv[1],'rb'); f.read(80); (n,)=struct.unpack('<I',f.read(4))
mn=[1e9]*3; mx=[-1e9]*3
for _ in range(n):
    d=f.read(50)
    if len(d)<50: break
    for k in range(3):
        x,y,z=struct.unpack('<3f',d[12+k*12:24+k*12])
        for i,v in enumerate((x,y,z)): mn[i]=min(mn[i],v); mx[i]=max(mx[i],v)
print(f"X={mx[0]-mn[0]:.2f} Y={mx[1]-mn[1]:.2f} Z={mx[2]-mn[2]:.2f}")
PY
python bbox.py out.stl
```

Faceting note: OpenSCAD circles are *inscribed* polygons, so a Ø17.6 feature may measure ~17.5 — small under-reads are expected, not a defect.

### 1e. Optional external mesh validation (only if installed)

Independent watertight/winding opinion; bonus, not required (often absent):

```sh
admesh out.stl | grep -E 'disconnected|Backwards edges|Number of parts|Volume'
python -c "import trimesh;m=trimesh.load('out.stl');print(m.is_watertight,m.is_winding_consistent,m.volume)"
```

### 1f. Regression (multi-version work)

Hash the evaluated CSG tree (stable across tessellation) to detect unintended changes between iterations: `"$OSCAD" -o tree.csg model.scad && sha256sum tree.csg`.

### Gate result

A part is **verified** when: it compiles (exit 0, non-empty STL), stderr is clean per 1a, its measured bounding box is within the intended envelope, and all `assert()` contracts pass. Trace each *measurable* acceptance criterion to one of these results. Report anything that can't be checked mechanically (e.g. "a real M8 mates") as a residual to confirm by print — never silently pass.

---

## Cross-platform notes

- Commands above are POSIX sh (Git-Bash on Windows, macOS, Linux). In PowerShell use `2>render.log`, `$LASTEXITCODE`, and `Select-String` instead of `grep`.
- Quote any binary path containing spaces (`"C:\Program Files\OpenSCAD-2026.06.19-x86-64\openscad.exe"`).
- Write all render/log/png/json artifacts to a scratch/temp dir, not the model folder, and clean them up — keep only the deliverable STLs and any preview images you intend to ship.

## Pitfalls (verified on 2021.01 and 2026.06.19)

- **Exit code is not a sufficient gate** — a non-manifold or PolySet result can exit 0. Gate on stderr (and on `--summary` topology where available) too.
- **`--hardwarnings` misses CGAL manifold warnings** (2021.01). Still use it for language warnings, but don't rely on it alone.
- **Manifold backend self-heals** (2026): the old "two cubes sharing one edge" no longer warns (it reports `Genus: -1` though) — so on modern builds, prefer measured/topology checks over expecting a build failure.
- **Default STL is ASCII on 2021.01** — force `--export-format binstl` before byte-parsing.
- **Preview ≠ render**: only trust full-render export, never `$preview` geometry.
- **Exclude `ECHO:` lines** from the stderr gate, or intentional messages cause false fails.

---

<a id="design-review"></a>

## Design Review

# Design Review — fresh-eyes peer review of a generated model

**Loading**: the reviewer sub-agent's complete brief. The author spawns the Design Review as a sub-agent (Agent tool, a different model when available) and points it here. This file stands alone — to do the job you need only this file, the `.scad` path, the numbered acceptance criteria, and the printer + material.

The Design Review covers what a deterministic gate cannot: **visual inspection** of the geometry (does it actually look right?), whether the mechanism/approach makes sense, the qualitative acceptance criteria, and compliance with the skill's FDM rules. It is peer critique, not the author marking its own homework, and it is **independent of [Verification](verification.md)** — do not consume, re-check, or assume verification's results. You render your own views and judge.

You are multimodal: render the images and actually look at them. Static review of the code is necessary but not sufficient.

## How to perform a Full Review

1. **Read the `.scad` file in full** (Read tool) — review the actual code, not a memory of it.
2. **Render the views you need and look at them** (commands in [Rendering the views](#rendering-the-views) below). At minimum:
   - **ThrownTogether** — any pink/purple = winding/manifold tell.
   - **An ortho/iso set** — proportion, overall shape, feature presence and counts.
   - **A section/cutaway** — internal features: do bores go all the way through? wall thickness? thread engagement? fit/interference between mating parts?
3. **Confirm the qualitative acceptance criteria** — the ones needing an eyeball rather than a measurement (correct shape, sensible mechanism, looks like what the user asked for).
4. **Walk every checklist item below**, recording PASS/FAIL with a one-line reason.
5. **Return findings** — each: severity · what · where · suggested fix.

You may be told "the build/manifold/dimension gate already passed, focus on judgment." Treat that as scoping only — not something you must verify.

## Rendering the views

You render these yourself, then judge them. Keep camera and `--imgsize` fixed across iterations so image diffs are meaningful. Image pixels are not a measurement — dimensions come from the verification gate, not from these renders.

**Find the OpenSCAD binary first** — it's often not on PATH (especially on Windows). Look in common install dirs and prefer the newest build; quote any path containing spaces. (POSIX sh below; in PowerShell use `2>$null` and `Select-String`.)

```sh
command -v openscad
ls -d "/c/Program Files"/OpenSCAD* "/Applications/OpenSCAD.app/Contents/MacOS" 2>/dev/null
OSCAD="<newest resolved path>"   # e.g. "/c/Program Files/OpenSCAD/openscad.exe"
```

The `--camera` gimbal form is `transx,transy,transz,rotx,roty,rotz,dist`; with `--viewall` the distance auto-fits, so only the rotation triple matters.

```sh
# ThrownTogether: back/CCW faces render pink, reversed faces purple (winding/manifold tells)
"$OSCAD" --preview=throwntogether --viewall --autocenter --imgsize=1024,1024 --camera=0,0,0,55,0,25,0 -o tt.png model.scad

# Orthographic front / top / right + an isometric (ortho keeps proportion true)
V="--render --projection=ortho --viewall --autocenter --imgsize=1024,1024"
"$OSCAD" $V --camera=0,0,0,0,0,0,0   -o top.png   model.scad
"$OSCAD" $V --camera=0,0,0,90,0,0,0  -o front.png model.scad
"$OSCAD" $V --camera=0,0,0,90,0,90,0 -o right.png model.scad
"$OSCAD" $V --camera=0,0,0,55,0,25,0 -o iso.png   model.scad
```

Section/cutaway is the only way to *see* internal features (bores, wall thickness, thread engagement, mating clearance). Drive it with `-D`:

```openscad
section = 0;  // 0 = whole, 1 = cut at the Y=0 plane
if (section == 0) model();
else difference() { model(); translate([0,-500,-1]) cube(1000); }
```
```sh
"$OSCAD" --render --viewall --imgsize=1024,1024 -D section=1 --camera=0,0,0,90,0,0,0 -o section.png model.scad
```

For assemblies, also render an **assembled** view, an **exploded** view (`-D explode=20`), and give each part a distinct `color()` so fit/interference is visible. A `%cube(10);` reference cube adds a known scale bar. Write all png/log artifacts to a scratch/temp dir, not the model folder, and clean them up — keep only images you intend to ship.

## Full Review Checklist

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

**Visual / shape correctness (render and inspect — this is the review's core job):**
- [ ] ThrownTogether shows no pink/purple faces (no winding/manifold tells)
- [ ] Geometry matches intent — correct overall shape, proportions, and feature counts (holes, ribs, slots, teeth)
- [ ] Section/cutaway confirms internal features: bores go all the way through, walls aren't paper-thin, threads/mechanisms engage
- [ ] Multi-part: assembled view shows correct fit — no interference, no excessive gap at mating interfaces
- [ ] Qualitative acceptance criteria met (the eyeball ones); any unmet or print-only criteria reported to the user

## Return format

Return a findings list, each: **severity · what · where · suggested fix**. State findings as critique, not commands — the author triages, fixing real issues and pushing back on findings that are wrong or out of scope. Flag any acceptance criterion that only a real print can confirm as a residual rather than passing or failing it.

---

<a id="printing-workflow"></a>

## Printing Workflow

# Printing Workflow: OpenSCAD to Physical Print

Guide users from finished .scad model to successful 3D print.

## 1. Export from OpenSCAD

### Standard Export (GUI)

1. **F6** — Full CGAL render (required before export; may take minutes for complex models)
2. Wait for "Rendering finished" in status bar
3. **F7** — Export as STL (or File > Export > Export as STL)

**Format choice:**
- **STL** — Universal compatibility, works with all slicers
- **3MF** — Modern alternative (OpenSCAD 2019.05+), smaller files, recommended for PrusaSlicer/OrcaSlicer/Bambu Studio
- **Bambu project 3MF (settings baked in)** — for Bambu Lab printers, generate a `.3mf` that opens in Bambu Studio with all print settings pre-applied, skipping the manual translation in step 4. See [bambu-3mf-export.md](bambu-3mf-export.md).

### Export Resolution

The skill's standard `$fn = $preview ? 32 : 64` handles most cases. For models with many small curves:

```openscad
// Alternative: dynamic resolution for export
$fa = $preview ? 12 : 2;   // angle per segment
$fs = $preview ? 2 : 0.5;  // minimum segment length (mm)
```

**Rule of thumb:** `$fa=2, $fs=0.5` gives excellent print quality without excessive file size.

### Command-Line Export (Batch/Automation)

```bash
# Basic export
openscad -o output.stl input.scad

# Override parameters
openscad -D "width=100" -D "height=50" -o box.stl box.scad

# Batch: export multiple sizes (bash)
for size in 10 20 30 40 50; do
    openscad -D "size=$size" -o "part_${size}.stl" parametric_part.scad
done
```

**Windows batch:**
```batch
FOR %%s IN (10,20,30,40,50) DO (
    openscad -D "size=%%s" -o part_%%s.stl parametric_part.scad
)
```

### Common Export Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Non-manifold geometry | Coincident faces in boolean ops | Use `fudge = 0.01` overlap (skill already enforces this) |
| Model disappears after difference() | Zero-thickness result | Ensure cutting shapes don't exactly match outer geometry |
| "Polyhedron conversion failed" | Complex boolean chain | Break into simpler operations; wrap with `render()` |
| Angular small features | Global $fn too low for small radii | Set $fn locally on small cylinders/spheres |

## 2. STL Validation

**Check before slicing** — open STL in slicer and look for:
- Missing faces or holes in the mesh
- Inverted normals (inside-out surfaces)
- Non-manifold warnings from slicer

**OpenSCAD tip:** Use Thrown Together view (F12) to spot face orientation issues before export.

### Repair Tools (if needed)

| Tool | Platform | Best For |
|------|----------|----------|
| **PrusaSlicer** (Right-click > Fix through Netfabb) | All | Quick in-workflow fix |
| **Microsoft 3D Builder** | Windows | One-click auto-repair, beginner-friendly |
| **Meshmixer** | Win/Mac | Best all-around: auto + manual repair |
| **MeshLab** | All | Advanced users, scripting, Linux |

**Note:** Well-designed OpenSCAD models (using fudge overlap, no coincident faces) rarely need repair.

## 3. Slicer Import

All major slicers accept STL via drag-and-drop or Ctrl+I/Cmd+I:
- **PrusaSlicer / OrcaSlicer / Bambu Studio** — STL, 3MF, OBJ, STEP
- **Cura** — STL, 3MF, OBJ (STEP via plugin)

### Slicer Recommendations

| User | Recommended Slicer |
|------|--------------------|
| Beginners / any printer | **Cura** — 1500+ printer profiles, easiest UI |
| Prusa owners / power users | **PrusaSlicer** — three-tier UI (Simple/Advanced/Expert) |
| Bambu Lab owners | **Bambu Studio** or **OrcaSlicer** |
| Calibration-focused users | **OrcaSlicer** — best built-in calibration tools |

## 4. Translate Print Settings to Slicer

> **Bambu Lab users can skip this section.** Generate a settings-baked-in project 3MF ([bambu-3mf-export.md](bambu-3mf-export.md)) and Bambu Studio applies these settings automatically on open.

The PRINT SETTINGS header in every generated .scad file maps directly to slicer settings:

### Setting Mapping

| Print Settings Header | PrusaSlicer Location | Cura Location |
|-----------------------|---------------------|---------------|
| **Material** | Filament dropdown (top bar) | Material dropdown (top bar) |
| **Layer Height** | Print Settings > Layers and perimeters > Layer height | Quality > Layer Height |
| **Walls/Perimeters** | Print Settings > Layers and perimeters > Perimeters | Shell > Wall Line Count |
| **Infill** (density) | Print Settings > Infill > Fill density | Infill > Infill Density |
| **Infill** (pattern) | Print Settings > Infill > Fill pattern | Infill > Infill Pattern |
| **Supports** | Print Settings > Support material > Generate support | Support > Generate Support |
| **Orientation** | Rotate tool (R key) or right-click > Place on face | Rotate tool (R key) or right-click > Lay flat |

### Infill Pattern Quick Reference

| Pattern | Use Case |
|---------|----------|
| **Gyroid** | Default for structural parts (best strength-to-weight) |
| **Grid** | General purpose |
| **Triangular** | Maximum strength |
| **Lightning** | Maximum speed, decorative parts |

### Temperature (from material reference)

| Material | Nozzle (C) | Bed (C) |
|----------|-----------|---------|
| PLA | 190-220 | 50-60 |
| PETG | 230-250 | 70-85 |

**Always calibrate with a temperature tower for your specific filament brand/color.**

### Orientation in Slicer

The PRINT SETTINGS header specifies orientation. To apply in slicer:
- **PrusaSlicer/OrcaSlicer:** Right-click model > Place on face > click the specified face
- **Cura:** Right-click > Lay flat, then rotate if needed
- Verify: Primary load paths should be in XY plane (along layers, not across them)

## 5. Preview Validation Checklist

After slicing (PrusaSlicer: F5, then Preview tab; Cura: Preview button), check:

- [ ] **Walls** — Correct thickness, no gaps or missing perimeters
- [ ] **Infill** — Pattern connects to walls, density matches settings
- [ ] **Supports** — Present under overhangs >45 degrees, not excessive
- [ ] **Bridges** — Spans <20mm, anchored on both sides
- [ ] **First layer** — Full coverage, adequate bed contact area
- [ ] **Top surface** — Solid layers complete, no infill showing through
- [ ] **Travel moves** — Enable "Show travels" to check for stringing risk

**Layer-by-layer navigation:** Use Up/Down arrows (single layer), Page Up/Down (10 layers), Home/End (first/last).

### Red Flags

| What You See | Fix |
|--------------|-----|
| Single-line perimeters | Model too thin for nozzle; increase wall count or redesign |
| Gaps between infill and walls | Increase infill/perimeter overlap |
| Floating sections without support | Enable supports, lower overhang angle threshold |
| Infill pattern visible on top | Add more top solid layers |
| Massive support structures | Reorient model or switch to tree supports |

## 6. Pre-Print Checklist

### Printer Preparation
- [ ] Bed leveled at operating temperature (paper test or ABL routine)
- [ ] Z-offset calibrated (first layer not too squished or gapped)
- [ ] Build plate cleaned with IPA (isopropyl alcohol 70%+)
- [ ] Nozzle clean (no burnt filament buildup)

### Material
- [ ] Filament dried if needed (PETG: 65C for 4-6h; PLA: 45C for 4-6h, never >60C)
- [ ] Spool rotates freely, no tangles
- [ ] Enough filament for print + 20% buffer (check slicer estimate)

### Bed Adhesion

| Surface | PLA | PETG |
|---------|-----|------|
| **PEI (smooth/textured)** | Excellent, no adhesive needed | Use glue stick as RELEASE agent (PETG bonds too strongly) |
| **Glass** | Use glue stick or hairspray | Use glue stick |
| **Painter's tape** | Good | Not recommended |

### Slicer Verification
- [ ] Correct printer and filament profiles selected
- [ ] Print settings match the .scad PRINT SETTINGS header
- [ ] Preview checked (no red flags)
- [ ] Orientation matches the .scad recommendation

### First Layer Settings (for best adhesion)
- First layer speed: 15-20 mm/s
- First layer height: 0.24mm (60% of 0.4mm nozzle)
- Fan: OFF for first layer
- First layer temp: +5-10C above normal

## 7. Calibration (One-Time Per Filament)

Before printing critical parts with a new filament, run these calibrations:

### Temperature Tower
1. Print temperature tower model (available on Printables)
2. Configure temperature changes per section (OrcaSlicer has this built-in under Calibration menu)
3. Evaluate each section for: layer adhesion, surface finish, stringing, bridging
4. Save optimal temperature in a filament profile

### Flow Rate Calibration
1. Print single-wall cube (1 perimeter, 0% infill, 0 top layers)
2. Measure wall thickness with calipers at 6-10 points
3. Calculate: `New Flow = Current Flow x (Nozzle Diameter / Measured Thickness)`
4. Save per-filament (OrcaSlicer has built-in flow calibration under Calibration menu)

## Remind Users

After generating a model, include these steps:
1. Preview in OpenSCAD (F5), check Thrown Together view (F12)
2. Render (F6) and export STL (F7)
3. Import into slicer, apply the PRINT SETTINGS from the file header
4. Check slicer preview (walls, supports, first layer)
5. Run pre-print checklist
6. Print!

---

<a id="bambu-3mf-export"></a>

## Bambu 3Mf Export

# Bambu 3MF Export (print settings baked in)

Generate a Bambu Studio **project** `.3mf` that opens with all print settings already applied — so the user never has to re-dial layer height, walls, infill, supports, or material in Bambu Studio. This is a **Bambu-only convenience**; for other printers/slicers the STL path in [printing-workflow.md](printing-workflow.md) stays the default.

## Contents
- [When to use this](#when-to-use-this)
- [What a Bambu project 3MF contains](#what-a-bambu-project-3mf-contains)
- [The tool: make-bambu-3mf.py](#the-tool-make-bambu-3mfpy)
- [Mapping the PRINT SETTINGS header to flags](#mapping-the-print-settings-header-to-flags)
- [Choosing profile names](#choosing-profile-names)
- [Workflow](#workflow)
- [Verified behaviour and caveats](#verified-behaviour-and-caveats)
- [Fallbacks and graceful degradation](#fallbacks-and-graceful-degradation)

## When to use this

Offer it only when **all** of these hold:

1. The printer (from Step 0) is a **Bambu Lab** machine, **and**
2. the user slices in **Bambu Studio** (or OrcaSlicer, which reads the same project format), **and**
3. **Python 3.8+ is available** on the machine — the generator is a Python script (`python --version` / `python3 --version`).

If any of these fails, **do not generate a 3MF** — hand off the STL and the PRINT SETTINGS header for manual import instead (see [Fallbacks](#fallbacks-and-graceful-degradation)).

**Why Bambu-only:** the settings-in-3MF *project* format (`project_settings.config` + `different_settings_to_system`) is specific to Bambu Studio / OrcaSlicer, and this tool resolves Bambu's own (BBL) profiles. PrusaSlicer, Cura, and other slicers don't read this format, so for a non-Bambu printer the STL path is the only option. (An OrcaSlicer user on a non-Bambu printer could in principle use it by pointing `--profiles-dir` at Orca's own profiles with the matching preset names, but that's out of scope — treat the feature as Bambu-only.)

## What a Bambu project 3MF contains

A `.3mf` is a ZIP of XML. There are two flavours, and the difference is the whole point:

| | Geometry-only 3MF (OpenSCAD / STL) | Bambu **project** 3MF |
|---|---|---|
| Parts inside | `[Content_Types].xml`, `_rels/.rels`, `3D/3dmodel.model` | those **plus** `Metadata/project_settings.config`, `model_settings.config`, `slice_info.config` |
| Print settings | none — opens with slicer defaults | **`project_settings.config`** — a flat JSON of ~450–540 keys (layer height, walls, infill, supports, temps, G-code, …) |

OpenSCAD's own 3MF export (and any STL) is geometry-only, so opening it drops the part on the plate with default settings. A project 3MF carries the configuration; Bambu Studio restores it on open. This tool builds a **lean** project 3MF: rather than dumping a full slicer config, it writes just the preset *names* plus the settings the model overrides, and lets Bambu bind your installed system presets by name. That keeps the file small, uses your own trusted presets, and avoids Bambu's "customized preset — confirm the G-code is safe" warning (which fires whenever an embedded preset isn't byte-identical to your installed one).

## The tool: make-bambu-3mf.py

`make-bambu-3mf.py` lives in this skill's directory. It needs only **Python 3.8+** (standard library — no pip installs) and does not require Bambu Studio to be running. (On macOS/Linux the command is often `python3` rather than `python`.) It:

1. Renders the mesh (`--scad model.scad --openscad <path>`) or loads an existing mesh (`--mesh model.stl|.3mf`).
2. Reads Bambu's **official** profile JSONs (`machine` + `process`, auto-detected) *only* to look up identity values (the printer's declared default filament, bed size) and to decide which overrides genuinely differ from the process preset — it does not copy them into the file.
3. Writes the identity ids + the model's overrides, **flagging each changed key in `different_settings_to_system`**. This is essential: on open, Bambu binds the named preset and resets any key that isn't flagged back to the preset default, so an override that isn't flagged is silently discarded.
4. Assembles a Bambu-openable project `.3mf` (correct container, part centred on the plate, base resting on Z=0).

Basic invocation (forward slashes work on all platforms; quote paths with spaces):

```bash
python .claude/skills/3d-print-designer/make-bambu-3mf.py \
  --scad "3d-models/my-part/my-part.scad" \
  --openscad "C:/Program Files/OpenSCAD-2026.06.19-x86-64/openscad.exe" \
  --printer "Bambu Lab P1S 0.4 nozzle" \
  --process "0.20mm Standard @BBL X1C" \
  --layer-height 0.2 --walls 4 --infill 20 --infill-pattern gyroid --supports off \
  --out "3d-models/my-part/my-part.3mf"
```

By default no specific filament is pinned — the file uses the **printer's declared default filament** (a real system preset, freely changeable in Bambu Studio). Pass `--filament "Bambu PETG HF @BBL X1C"` to pin a specific material instead (repeat for multi-material).

Run `python .claude/skills/3d-print-designer/make-bambu-3mf.py --help` for the full flag list.

## Mapping the PRINT SETTINGS header to flags

Translate the model's `PRINT SETTINGS` header (see [SKILL.md](SKILL.md) > Print-settings header) into flags. Only pass flags for values the model actually specifies; everything else inherits from the chosen official profiles.

| PRINT SETTINGS header | Flag | Notes |
|---|---|---|
| Material (PLA/PETG/ABS) | `--filament` (optional) | Omit → uses the printer's default filament (changeable in Bambu Studio); pass it to pin a specific material |
| Layer Height | `--layer-height 0.2` | mm |
| Walls / Perimeters (count) | `--walls 4` | perimeter count, not thickness |
| Infill (density) | `--infill 20` | percent; `20` or `20%` both work |
| Infill (pattern) | `--infill-pattern gyroid` | e.g. gyroid, grid, honeycomb |
| Supports | `--supports off` / `--supports on` | add `--support-type "tree(auto)"` if on |
| — top/bottom solids | `--top-layers` / `--bottom-layers` | optional |
| Anything else | `--set key=value` | raw `project_settings.config` key; value may be JSON, e.g. `--set 'nozzle_temperature=["230"]'` |

`--printer` and `--process` come from the printer/quality choice, not the header — see below.

## Choosing profile names

The three identity flags must name presets the user actually has installed, so Bambu binds them cleanly on open.

- **`--printer`** — the machine preset for the printer from Step 0, e.g. `Bambu Lab X1 Carbon 0.4 nozzle`, `Bambu Lab P1S 0.4 nozzle`, `Bambu Lab A1 0.4 nozzle`.
- **`--process`** — the quality preset, suffixed by printer family: `0.20mm Standard @BBL X1C`, `0.20mm Standard @BBL P1S`, etc. Match the layer height to the model.
- **`--filament`** *(optional)* — omit it (recommended) and the file uses the printer's declared default filament, freely changeable in Bambu Studio. Pass it only to pin a specific material, e.g. `Bambu PETG HF @BBL X1C`; repeat for multi-material.

The `@BBL X1C` / `@BBL P1S` suffix is the printer-family the preset is tuned for. To see the exact names available, list the profile directory (auto-detected locations below):

```bash
ls "C:/Program Files/Bambu Studio/resources/profiles/BBL/machine"   # printer presets
ls "C:/Program Files/Bambu Studio/resources/profiles/BBL/process"    # quality presets
ls "C:/Program Files/Bambu Studio/resources/profiles/BBL/filament"   # material presets
```

The tool auto-detects the profiles directory on Windows (`C:\Program Files\Bambu Studio\...`), macOS, and Linux. If it's installed elsewhere (custom drive, OrcaSlicer), pass `--profiles-dir "<.../resources/profiles/BBL>"`. A misspelt preset name fails fast with a clear `... preset not found` message — fix the name and re-run.

## Workflow

Run this **after** the model has passed [Verification](SKILL.md#verification) and the [Design Review](SKILL.md#design-review) — the 3MF is a delivery step, not a design step.

1. **Check preconditions.** Confirm (a) the printer is Bambu Lab and the user slices in Bambu Studio/OrcaSlicer, and (b) Python is available — run `python --version` (or `python3 --version`). If either fails, stop here and use the fallback ([Fallbacks](#fallbacks-and-graceful-degradation)): hand off the STL + PRINT SETTINGS header for manual import. Use whichever `python`/`python3` command resolved for the run in step 4.
2. Resolve the printer preset (from Step 0) and process preset (by layer height). Leave filament unset unless the user asks to pin a specific material — by default the file uses the printer's default filament, changeable in Bambu Studio. If a name is ambiguous, list the profile dir and confirm with the user.
3. Map the model's PRINT SETTINGS header to override flags (table above).
4. Run `make-bambu-3mf.py`, writing the `.3mf` next to the `.scad`.
5. Tell the user: the file opens in Bambu Studio with settings applied — review on the plate, then Slice → Print.

## Verified behaviour and caveats

Confirmed by opening a generated file in Bambu Studio (X1 Carbon · 0.20mm Standard · default PLA):

- The named system presets bind on open, the flagged overrides show as a **"(modified)"** process preset, the printer's **default filament** is selected, and **no "customized preset — confirm the G-code" warning** appears (the lean file embeds no G-code to trigger it).
- The output is also a structurally valid 3MF — it re-imports cleanly through OpenSCAD's lib3mf and matches the container structure Bambu Studio itself writes.

**Caveat:** the preset names you pass must exist in the user's install. A misspelt or absent id makes Bambu fall back to a generic profile (the overrides still load, but the dropdown won't bind cleanly) — when unsure, list the profile dir (above) to confirm exact names.

## Fallbacks and graceful degradation

- **Profiles not found** → pass `--profiles-dir`, or fall back to `--base-3mf "<an existing Bambu project .3mf>"` to reuse that project's `project_settings.config` as the baseline (the tool still swaps in the new mesh and applies overrides).
- **3MF render unavailable / prefer STL** → `--mesh model.stl` (binary or ASCII; vertices are de-duplicated) instead of `--scad`.
- **Python not available** (no `python`/`python3` on PATH) → the generator can't run, and there's no reliable non-Python way to assemble the container, so **don't attempt it**. Tell the user plainly and fall back to the STL path — e.g.:
  > "I can't auto-generate the Bambu 3MF here because Python isn't available on this machine. I've exported the STL instead — import it into Bambu Studio and apply the settings from the PRINT SETTINGS header (layer height, walls, infill, supports). If you'd like the one-click settings-baked-in 3MF next time, install Python from python.org and I can set it up."

  Then follow the STL → slicer steps in [printing-workflow.md](printing-workflow.md).
- **Not a Bambu setup** (non-Bambu printer, or a slicer other than Bambu Studio/OrcaSlicer) → the project format doesn't apply; use the STL → slicer path in [printing-workflow.md](printing-workflow.md).
- **Want a directly-printable file** (optional power route) → Bambu Studio and OrcaSlicer have a headless CLI (`--load-settings machine.json;process.json --load-filaments f.json --slice --export-3mf out.gcode.3mf model.3mf`) that emits a *pre-sliced* `.gcode.3mf`. That skips the on-plate review and needs the slicer installed; prefer the project 3MF above unless the user explicitly wants slice-and-send automation.

---

<a id="printing-guidelines"></a>

## Printing Guidelines

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

---
