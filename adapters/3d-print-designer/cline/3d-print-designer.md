
# 3D Print Designer

Design and generate parametric, FDM-print-optimized OpenSCAD (.scad) models.

## How to work

The expensive failure is reasoning too long before acting. One run thought until it hit the output cap and never wrote a file. So:

- **Compute with tools, not in your head.** Fits, trig, clearances, interference and tolerance stack-ups go into the model as named derived values with `echo()` and `assert()`, or into a one-line `python -c`. Don't hand-derive coordinates in thinking.
- **Write the .scad early.** Once the acceptance list exists (Workflow step 3), write a rough version that compiles, run the gate, then refine with edits. Several short think-act cycles beat one long plan.
- **Pick, don't survey.** Take the simplest approach that meets the acceptance list, and mention alternatives in one line. A genuine ambiguity is a question for the user, not for extended thought.
- **Read only what the step needs.** Each reference below says when to load it. Run the bundled `.py` tools; don't read their source (`--help` lists the options). For a long .scad, grep it or read line ranges rather than re-reading the whole file.

## Step 0: Printer (always first)

If the user hasn't named a printer (or given its build volume and nozzle), **your first reply is only that question**: no files, no design yet. Once you know it, read [printer-configuration.md](#printer-configuration). It has the known-printer specs table, the manual fallback, and how the specs drive the design. When modifying an existing model, its headers already name the printer and material: see [Modifying an existing model](#modifying-an-existing-model).

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

Then read **only** the chosen material's file: [material-pla.md](#material-pla), [material-petg.md](#material-petg) or [material-abs.md](#material-abs).

## Step 2: Support Strategy

**Default: support-free.** Supports waste material, mark surfaces, risk failures and add post-processing, and most models avoid them through orientation, geometry changes and self-supporting features. The techniques: overhangs ≤45° from vertical; 45° chamfers under ledges; teardrop horizontal holes; features tapered from below; pointed (gothic) arches; short bridges instead of overhangs; splitting at overhang boundaries; built-in ribs and pillars. Details are in [fdm-design-principles.md](#fdm-design-principles), which you need only for the harder cases.

If the model is feasible both ways, ask: *"This can print without supports (with some compromises like chamfered undersides or a split), or with supports for a cleaner shape. Which do you prefer?"* If supports are unavoidable (internal cavities, deep recesses), say why, minimise them, and check for soluble-support capability. With no answer, go support-free.

## Workflow

The same steps for a single part or an assembly.

1. **Printer, material, supports** (Steps 0-2), loading their references.
2. **Orientation.** Choose the print orientation that removes supports first, then puts the primary loads along the layers (XY). Model in it, with Z=0 as the build plate.
3. **Acceptance list and design summary.** Restate the requirements as a **numbered, measurable list** with units and tolerances ("fits 18mm tube → OD ≤ 17mm", "≤ 21mm deep"), plus orientation, support strategy, structure and key dimensions. For a complex job (a mechanism, several parts, or unclear requirements), settle the open questions first: in plan mode if a user is present, otherwise state your assumptions in one line and go on.
4. **Write the .scad** using the [file structure](#file-structure) below. Read [openscad-reference.md](#openscad-reference) first. Encode each measurable criterion as an `assert()`.
5. **Add features incrementally:** structure first (ribs, gussets, fillets), then mounting (oversize holes, heat-set bosses, slots), then support-free geometry (underside chamfers, teardrops, elephant-foot chamfer). Apply the Critical Rules as you go.
6. **Verify:** run the gate ([Verification](#verification)) and fix until it's green.
7. **Save the deliverables now:** the gate's `--export .` writes one STL per printable part. **On a Bambu Lab printer, also make the project 3MF now** ([bambu-3mf-export.md](#bambu-3mf-export)), without waiting to be asked: it opens in Bambu Studio with the print settings applied. Build it from the `.scad`, or with `--mesh` from the STL. Doing this **before** the review means a slow or stalled review can't cost the user their files. Re-export after any fix.
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

For gears, threads, snap-fits, living hinges and joints, see [mechanical.md](#mechanical). Material-critical notes:

- **Snap-fits:** PETG excels (5-8% strain), ABS is good (3-5%), PLA is fragile (1-1.5% max).
- **Living hinges:** PETG only (0.4mm thick, 50,000+ cycles). PLA breaks within 50-100 cycles; ABS is marginal.
- **Metal fasteners into plastic:** use a heat-set insert, a captive nut, or a plain **self-tap hole at about 50% thread depth**. Don't print a metric thread that a metal screw must mate with. A real print failed that way: a printed M8 thread in PETG didn't form. A self-tapped Ø7.5 hole for M8 held, while Ø7.0 seized. Printed threads suit coarse plastic-to-plastic joints (≥M10, trapezoidal or buttress profile).
- **Flexing features** (fins, barbs, cantilevers, springs) bend **within the layer plane**. Bending across layers delaminates them.

## Verification

A **hard, deterministic gate** that every part must pass before the review and before hand-off:

```sh
python "<skill-dir>/verify-model.py" model.scad --build-volume 256x256x256 --export .
```

It compiles every `part` value and checks each for clean stderr, one body, manifold, on the plate, and fits the build volume. `clash_*` parts must render empty. It prints `GATE: PASS` or the failing parts. If OpenSCAD isn't installed where you're running, install it in your sandbox if you can (verification.md says how). Without it there's no gate and no STL, and a `.scad` alone is not something a slicer can open. **Read [verification.md](#verification) before your first gate run.** It covers what each failure means, contracts, reporting, and the fallback without Python. Run the gate on initial generation and after any structural change. After a minor tweak, re-run it on just the changed parts (`--parts`).

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

- **New users** (check memory for 3D-printing experience; none means new): offer help getting the model viewed, exported and printed, including installing OpenSCAD. Walk through [printing-workflow.md](#printing-workflow) if they accept, then save a `user` memory that they've been introduced.
- **Simple part, Fable available, no final review recorded yet:** offer the Fable review ([Design Review](#design-review)).
- **Bambu Lab printer:** the project 3MF from step 7 is the file to open in Bambu Studio or OrcaSlicer. Without Python, or if the user slices in something else, hand off the STL with the PRINT SETTINGS header for manual entry.

## References

| File | Load when |
|---|---|
| [printer-configuration.md](#printer-configuration) | Step 0, always |
| [material-pla.md](#material-pla) / [material-petg.md](#material-petg) / [material-abs.md](#material-abs) | Step 1, the chosen material only |
| [openscad-reference.md](#openscad-reference) | Before writing code: language gotchas, FDM module patterns (teardrop, chamfered shelf, EF base) |
| [verification.md](#verification) | Before running the gate |
| [design-review.md](#design-review) | Never yourself: it's the review sub-agent's brief |
| [bambu-3mf-export.md](#bambu-3mf-export) | When making a Bambu 3MF |
| [fdm-design-principles.md](#fdm-design-principles) | Only for hard support-free or structural cases |
| [printing-guidelines.md](#printing-guidelines) | Only for tolerance or overhang data the material file lacks |
| [mechanical.md](#mechanical) | Only for gears, threads, snap-fits, hinges, joints |
| [printing-workflow.md](#printing-workflow) | Only for a new user's export-to-print walkthrough |


---

# Reference Files

<a id="printer-configuration"></a>

## Printer Configuration

# Printer Configuration

How to identify the printer, check the material against it, and turn its specs into design parameters.

## Step 1: Identify the Printer

**Ask: "What 3D printer are you using?"** If the user names a make and model, match it (fuzzily) against the table below. Show the matched specs and ask about non-stock changes, such as a different nozzle or an added enclosure. If the printer isn't listed, collect the specs in the order of the next section.

### Known printers

All use 1.75mm filament and have auto bed leveling, except the Ender 3 / Pro / V2 and the Ankermake M5C. Layer range with a 0.4 nozzle: Bambu 0.08–0.28mm; Prusa, Voron and Ratrig 0.05–0.30mm; the rest 0.10–0.30mm.

| Printer | Build X×Y×Z mm | Stock nozzle (others) | Hotend / bed max °C | Enclosure | Extruder | Multi-material | Notes |
|---|---|---|---|---|---|---|---|
| Bambu X1 Carbon / X1C | 256×256×256 | 0.4 hardened (0.2, 0.6, 0.8) | 300 / 120 | Yes, passive ~50°C | DD | AMS, up to 16 | Hardened nozzle takes CF/abrasives; the best Bambu for engineering materials (ABS, ASA, PA, PC) |
| Bambu P1S | 256×256×256 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | Yes, passive ~45-50°C | DD | AMS, up to 16 | Enclosure enables ABS/ASA; the 100°C bed limits PC; PA with caution |
| Bambu P1P | 256×256×256 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | No | DD | AMS, up to 16 | PLA, PETG, TPU; no ABS/ASA |
| Bambu A1 | 256×256×256 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | No, bed-slinger | DD | AMS Lite, 4 | PLA, PETG, TPU; tall prints wobble |
| Bambu A1 Mini | 180×180×180 | 0.4 stainless (0.2, 0.6, 0.8) | 300 / 100 | No | DD | AMS Lite, 4 | Small parts only |
| Prusa MK4S / MK4 | 250×210×220 | 0.4 brass (0.25, 0.6, 0.8) | 290 / 120 | No (optional) | DD | MMU3, 5 | Asymmetric bed; the 120°C bed handles PC; ABS needs the enclosure |
| Prusa MK3S+ / MK3S | 250×210×210 | 0.4 brass (0.25, 0.6, 0.8) | 280 / 100 | No (optional) | DD | MMU2S, 5 | Asymmetric bed; ABS needs an enclosure |
| Prusa XL | 360×360×360 | 0.4 brass (0.25, 0.6, 0.8) | 290 / 120 | No (optional) | DD, up to 5 toolheads | 5 toolheads, no purge | Segmented bed |
| Prusa Core One | 250×220×270 | 0.4 brass (0.25, 0.6, 0.8) | 290 / 120 | Yes, active airflow | DD | MMU3, 5 | Enclosed CoreXY; all common materials |
| Creality K1C | 220×220×250 | 0.4 hardened (0.6, 0.8) | 300 / 100 | Yes | DD | No | Takes CF; ABS/ASA OK |
| Creality K1 / K1 Max | 220×220×250 / 300×300×300 | 0.4 brass (0.6, 0.8) | 300 / 100 | Yes | DD | No | Brass nozzle: avoid CF |
| Creality Ender 3 V3 / SE / KE | 220×220×250 | 0.4 brass (0.6, 0.8) | 260 / 100 | No | DD (SE: Bowden) | No | 260°C limits it to PLA, PETG, TPU (TPU not on the SE) |
| Creality Ender 3 / Pro / V2 | 220×220×250 | 0.4 brass (0.6, 0.8) | 255 / 100 | No | Bowden | No | PLA, PETG; manual leveling |
| Voron 2.4 | 250², 300² or 350² × 230/280/330 | 0.4, hotend varies (any) | 285-300 / 120 | Yes, ~50-60°C | DD | Optional (ERCF etc.) | A kit, so specs vary: ask for their build size |
| Voron Trident | 250³, 300³ or 350³ | 0.4 (any) | 285-300 / 120 | Yes | DD | Optional | Ask for their build size |
| Voron 0.2 | 120×120×120 | 0.4 (0.2) | 285-300 / 120 | Yes | DD | No | Small, fast parts; layers up to 0.25mm |
| Ankermake M5 / M5C | 235×235×250 | 0.4 brass (0.6, 0.8) | 260 / 100 | No | DD | No | PLA, PETG, TPU |
| Elegoo Neptune 4 Pro / 4 | 225×225×265 | 0.4 brass (0.6, 0.8) | 300 / 110 | No | DD (base 4: Bowden) | No | TPU on the Pro only; ABS limited without an enclosure |
| Ratrig V-Core 4 | 200³ to 500³ | 0.4 (any) | 285-300 / 120 | Optional panels | DD | Optional | A semi-kit: ask for their build size |

### Printer not listed: collect specs manually

In order of importance:

1. **Build volume** (X × Y × Z mm): the maximum single-piece size.
2. **Nozzle diameter** (default 0.4mm): drives every minimum dimension.
3. **Max hotend temperature**, **enclosure**, **max bed temperature**, **extruder type** (direct drive or Bowden): these gate which materials are practical.
4. Only if the design needs them: **auto bed leveling** (large flat parts) and **multi-material** (soluble supports, multi-colour).

Defaults when the user doesn't know: 0.4mm nozzle, 0.2mm layers, 260°C hotend, 100°C bed, no enclosure, direct drive, auto bed leveling, single material.

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

**Bambu X1/P1 front-left exclusion zone** — these printers reserve an **18×28mm front-left corner** of the bed (the `bed_exclude_area` in the machine profile protects the filament-cutter stopper). The real printable square is therefore **~220mm auto-centred** (or ~238mm if the part is shoved fully to the right), NOT the full 256mm — check `bed_exclude_area`, not just build volume, whenever a footprint approaches the bed edges. If the model's footprint would cover that corner:
1. **Preferred:** ask the user to fit Bambu's official stopper-clip mod (a small printed clip that tucks the cutter lever away, per the [full print volume guide](https://wiki.bambulab.com/en/knowledge-sharing/print-volume-limitations)) — this frees the whole 256×256 bed and keeps the design at full size. **Caveat to state every time:** the clip disables the filament cutter, so **AMS / multi-colour cannot be used** on those prints (single-colour only), and the chamber floor must be clear of debris. Bake the cleared bed area into the 3MF (see [bambu-3mf-export.md](bambu-3mf-export.md)).
2. **Fallback:** if the user can't or won't fit the clip (e.g. they need AMS/multi-colour), shrink the footprint to fit the stock exclusion (≤220mm centred) instead.

**Nozzle diameter** — drives minimum dimensions:

| Design Parameter | Formula | 0.4mm Nozzle | 0.6mm Nozzle | 0.2mm Nozzle |
|------------------|---------|-------------|-------------|-------------|
| Extrusion width | nozzle * 1.125 | 0.45mm | 0.675mm | 0.225mm |
| Min wall thickness | 2 * extrusion width | 0.9mm | 1.35mm | 0.45mm |
| Ideal wall multiples | N * extrusion width | 0.9, 1.35, 1.8mm | 1.35, 2.0, 2.7mm | 0.45, 0.9, 1.35mm |
| Min standalone feature | ~4 * extrusion width | ~1.8mm | ~2.7mm | ~0.9mm |
| Hole diameter compensation | +0.3 to +0.4mm | **+0.30mm** (measured, PETG/X1C) | +0.4mm | +0.2mm |
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

- A metal screw never mates with a printed thread (SKILL.md, Mechanical Parts). Use a heat-set insert (pull-out 200-600 N, against 50-150 N for a printed thread), a captive nut, or a self-tap hole at about 50% thread depth. Insert holes are in printing-guidelines.md.
- Printed threads suit coarse plastic-to-plastic joints only: ≥M10, trapezoidal profile, 0.2-0.3mm clearance.

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

- A metal screw never mates with a printed thread (SKILL.md, Mechanical Parts): a printed M8 thread in PETG didn't form in a real print. Use a heat-set insert (iron at 200-220C; PETG flows around it well), a captive nut, or a self-tap hole at about 50% thread depth.
- Printed threads suit coarse plastic-to-plastic joints only (≥M10). Clearance 0.25-0.35mm, more than PLA because PETG flexes. Buttress profiles suit FDM better than metric (45 degree load face, 5 degree relief).

### Clearances and Fits

| Fit Type | Clearance |
|----------|-----------|
| Sliding fit | 0.3-0.4mm |
| Press fit | -0.05 to -0.10mm (interference; 0.00 slides) |
| Snap fit | 0.2mm |
| Thread | 0.25-0.35mm |

**Steel rod in a printed bore** — measured, X1C 0.4mm nozzle:
`bore = rod + 0.30 + allowance`, allowance **-0.08** press / **+0.15** bearing / **+0.30**
free-running. For 3mm rod: **3.22 / 3.45 / 3.60**.

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

### First-Layer Fragmentation (open/skeletal footprints)

Those mitigations all assume the first layer is **one** region. On a part whose footprint is
open — lattices, grids, frames, ribbed or perforated plates, anything printed as walls
rather than slabs — any feature cut down to z=0 (drain channels, notches, slots, relief
cuts) **severs the first layer into disconnected islands with free ends**, and PETG curls
from free ends. A brim is not a reliable rescue: on a cellular part the only sane brim
setting is outer-contour-only (brim inside every cell is worse than the problem), so the
interior islands get nothing, and a ~1cm² island with free ends curls anyway. This is a
geometry bug, not a slicer setting — it will not tune out.

Measured on a 196mm PETG lattice, textured PEI plate:

| | channels cut to z=0 | channels on a sill + flared foot |
|---|---|---|
| First-layer islands | **36** (avg 0.9cm²) | **1** |
| Plate contact area | 32.6cm² | 72.8cm² |
| Outcome | peeled repeatedly, brim on *and* off | prints |

Two parametric rules:

1. **Never cut a through-feature to z=0 on an open footprint.** Stand it on a sill of at
   least 3 layers (0.6-0.8mm) so the bottom stays one connected region. A sill is usually
   invisible to function — water steps over 0.8mm, airflow does not notice it.
2. **Flare the bottom rather than chamfering it**, wherever nothing mates at the plate:
   widen every wall ~0.5-0.8mm per side over that same height, tapering back at 45°. It is
   self-supporting (widest at the bottom) and acts as a brim built into the part, reaching
   interior features no slicer brim can. Set the slicer's elephant-foot compensation to 0
   so it is not shaved back, and drop `ef_chamfer` on that face — squish costs nothing
   where there is no mating surface.

**Verify it, do not assume it.** Slice the exported mesh at half the first layer height and
count connected regions. More than one island on what should be a connected grid — or a
largest island under ~20% of the layer — means it will peel:

```python
# firstlayer.py <mesh.stl> <z>   e.g. python firstlayer.py part.stl 0.1
import struct, sys
from collections import deque
p, z, g = sys.argv[1], float(sys.argv[2]), 0.3           # g = raster step (mm)
f = open(p, 'rb'); f.read(80); (n,) = struct.unpack('<I', f.read(4))
segs = []
for _ in range(n):                                       # mesh x plane -> 2D segments
    d = f.read(50); v = [struct.unpack('<3f', d[12+k*12:24+k*12]) for k in range(3)]
    pts = [(a[0]+(z-a[2])/(b[2]-a[2])*(b[0]-a[0]), a[1]+(z-a[2])/(b[2]-a[2])*(b[1]-a[1]))
           for a, b in [(v[i], v[(i+1) % 3]) for i in range(3)] if (a[2]-z)*(b[2]-z) < 0]
    if len(pts) == 2: segs.append(pts)
assert segs, "no material at that height"
xs = [q[0] for s in segs for q in s]; ys = [q[1] for s in segs for q in s]
nx = int((max(xs)-min(xs))/g)+2; ny = int((max(ys)-min(ys))/g)+2
grid = [bytearray(nx) for _ in range(ny)]
for j in range(ny):                                      # scanline fill, even-odd
    y = min(ys)+(j+0.5)*g
    xc = sorted(a[0]+(y-a[1])*(b[0]-a[0])/(b[1]-a[1]) for a, b in segs if (a[1] > y) != (b[1] > y))
    for k in range(0, len(xc)-1, 2):
        for i in range(max(0, int((xc[k]-min(xs))/g)), min(nx, int((xc[k+1]-min(xs))/g)+1)):
            grid[j][i] = 1
seen = [bytearray(nx) for _ in range(ny)]; comps = []
for j in range(ny):
    for i in range(nx):
        if grid[j][i] and not seen[j][i]:
            q = deque([(i, j)]); seen[j][i] = 1; c = 0
            while q:
                a, b = q.popleft(); c += 1
                for da, db in ((1,0),(-1,0),(0,1),(0,-1)):
                    u, w = a+da, b+db
                    if 0 <= u < nx and 0 <= w < ny and grid[w][u] and not seen[w][u]:
                        seen[w][u] = 1; q.append((u, w))
            comps.append(c*g*g/100)
comps.sort(reverse=True)
print(f"islands={len(comps)}  total={sum(comps):.1f}cm2  largest={comps[0]:.1f}cm2")
```

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

- A metal screw never mates with a printed thread (SKILL.md, Mechanical Parts). Use a heat-set insert, a captive nut, or a self-tap hole at about 50% thread depth.
- Printed threads suit coarse plastic-to-plastic joints only: ≥M10, 0.25-0.35mm clearance (slightly more than PLA).
- **Heat-set brass inserts work especially well in ABS** (high Tg). Take the hole and boss sizes from the insert's datasheet or the table in printing-guidelines.md; the hole is well under the insert's knurl diameter. Insert temperature 230-250C (higher than PETG).

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

3. **Heat-set insert bosses** (sizes from the insert's datasheet, or printing-guidelines.md: M3 is a 4.0 hole in an 8 boss):
```openscad
module heat_set_boss(hole_d, insert_len, boss_od) {
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

Use the `teardrop_hole(d, h, axis)` module in [openscad-reference.md](openscad-reference.md): its point stays at +Z for holes along X or Y.

Use when: hole axis parallel to build plate, support-free printing needed, functional holes for bolts/shafts (bolt sits in circular bottom half).

### Elephant Foot Compensation

First layer spreads 0.2-0.5mm wider due to bed squish.

| Material | Chamfer Width |
|----------|--------------|
| PLA | 0.3-0.4mm |
| PETG | 0.4-0.5mm |
| ABS | 0.2-0.3mm |

Use the `ef_base(size, ef)` module in [openscad-reference.md](openscad-reference.md): the first layers are inset by `ef` at 45° and full size above.

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

### Neighbouring Solids Must Overlap, Never Touch on a Bare Edge

Two solids that meet only along a shared edge or corner (not a face) — e.g. diagonally adjacent cells in a grid — form a **non-manifold edge**: that edge borders the outside on both sides. OpenSCAD's Manifold backend silently self-heals this and the build gate passes, but **slicers (Bambu Studio) reject it** ("N non-manifold edges, may need repair"). Give adjacent solids a real shared volume by overlapping them laterally (extend each by `eps`), then clip the union back to the intended outline with an `intersection()`:

```openscad
// BAD — diagonal neighbours touch only at a corner (non-manifold edge)
translate([0, 0, 0]) cube([10, 10, h]);
translate([10, 10, 0]) cube([10, 10, h]);

// GOOD — overlap by eps so neighbours share volume, then clip to outline
intersection() {
    union() { for (c = cells) translate(c) cube([10 + eps, 10 + eps, h]); }
    cube([tile_w, tile_d, big_h]);   // exact outer boundary
}
```

The gate ([verification.md](verification.md)) counts non-manifold edges on every printed part, so it catches this; OpenSCAD's own render doesn't.

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
- `text()` inherits `$fn` too: at 64, every glyph curve gets 64 segments (one dial face's STL reached 14 MB). Pass `$fn = 12` to `text()`

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

// Teardrop hole — a horizontal hole whose top rises to a 45° point (apex r*sqrt(2) above
// the axis), so it prints without support. axis = "x" or "y" is the hole's direction; the
// point always faces +Z. Position it with translate() and rotations about Z only: rotating
// it about X or Y turns the point sideways.
module teardrop_hole(d, h, axis = "y") {
    r = d / 2;
    rotate([0, 0, axis == "x" ? 90 : 0]) rotate([90, 0, 0])
        linear_extrude(height = h, center = true)
            union() { circle(r = r); rotate(45) square(r); }
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

// Elephant-foot compensation base — the first layers inset by ef at 45°, full size above
// (squish then spreads the first layer back out to the nominal outline)
module ef_base(size, ef=0.4) {
    hull() {
        translate([ef, ef, 0]) cube([size[0] - 2*ef, size[1] - 2*ef, fudge]);
        translate([0, 0, ef]) cube([size[0], size[1], size[2] - ef]);
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

<a id="bambu-3mf-export"></a>

## Bambu 3Mf Export

# Bambu 3MF Export (print settings baked in)

`make-bambu-3mf.py` (in this skill's directory; Python 3.8+ standard library) writes a Bambu Studio **project** `.3mf`: the model plus a lean `project_settings.config` that names the user's own system presets (printer, process, filament) and flags the model's overrides. Opened in Bambu Studio or OrcaSlicer, it binds those presets, shows the overrides as a "(modified)" process, and needs no manual settings entry. It works without Bambu Studio installed, from a built-in table of Bambu's official printer profiles.

**Make it by default** whenever the printer is a Bambu Lab machine and `python --version` (or `python3`) works. Assume the user slices in Bambu Studio or OrcaSlicer unless they say otherwise. Skip it only without Python, or for another slicer, which can't read this format. Then hand off the STL and the PRINT SETTINGS header instead.

**Run it; don't read it.** `--help` lists every flag. The command below covers almost every case.

```sh
python "<skill-dir>/make-bambu-3mf.py" --scad model.scad -D 'part="clip"' --printer P1S \
  --layer-height 0.2 --walls 4 --infill 20 --infill-pattern gyroid --supports off \
  --out model.3mf
```

- **One part per file.** For an assembly, run it once per printable part, or on a `plate_*` layout part.
- **`--printer`** takes a short name (`X1C`, `X1`, `X1E`, `P1S`, `P1P`, `A1`, `"A1 mini"`, `P2S`, `H2D`, `"H2D Pro"`, `H2S`, `H2C`, `X2D`, `A2L`), plus a nozzle size if it isn't 0.4 (`"P1S 0.6"`).
- **Leave `--process` unset.** It defaults to the printer's own 0.20mm preset, and `--layer-height` goes in as an override. Preset names don't follow the printer: there is no `@BBL P1S` process, because the P1S uses the X1C presets.
- **Leave `--filament` unset** unless the user wants a material pinned, e.g. `--filament "Bambu PETG HF @BBL X1C"`. The file then opens on the printer's default filament, which the user switches in Bambu Studio.
- `--openscad` is found automatically; pass it only if the tool says it can't find OpenSCAD.

| PRINT SETTINGS header | Flag |
|---|---|
| Layer Height | `--layer-height 0.2` |
| Walls / Perimeters (count) | `--walls 4` |
| Infill % and pattern | `--infill 20 --infill-pattern gyroid` |
| Supports | `--supports off`, or `on` plus `--support-type "tree(auto)"` |
| Top/bottom layers, brim | `--top-layers N`, `--bottom-layers N`, `--brim outer_only` |
| Anything else | `--set key=value`: a raw Bambu config key; JSON values allowed, e.g. `--set 'nozzle_temperature=["230"]'` |

Pass flags only for values the header specifies; everything else comes from the named presets.

**The tool checks its own output.** It verifies the package structure, then re-imports the file through OpenSCAD's `import()`, which uses lib3mf, the library slicers use. The re-imported size must match. It ends with `verify : OK - ...` (report that line) or `verify : FAILED - ...` with a non-zero exit. Don't hand-edit the zip: anything the format needs has a flag.

**Placement.** Each run puts the part at a random spot on the plate, within its margins, to spread plate wear. `--scatter off` centres it instead, and `--scatter-seed N` makes the spot repeatable.

**Full-bed prints (X1/P1).** These printers reserve an 18×28mm front-left corner for the filament cutter, and the tool warns when a footprint covers it. Above roughly 220mm that can't be avoided. Either shrink the part, or, if the user agrees to fit Bambu's stopper-clip mod, pass `--full-bed`. Say every time that the clip disables the cutter, so no AMS or multi-colour on those prints.

**Fallbacks.** `--mesh part.stl` (or `.3mf`) packs an existing mesh instead of rendering the `.scad`. `--base-3mf existing.3mf` reuses another project's full settings as the baseline, though Bambu may then ask to confirm its embedded G-code. With no Python: *"I can't generate the Bambu 3MF here because Python isn't available, so I've exported the STL. Import it into Bambu Studio and apply the PRINT SETTINGS header (layer height, walls, infill, supports)."*

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

A trapezoid approximation, fine for looks and light-duty hand-turned drives. It isn't an involute, so the contact ratio and backlash vary as it turns. For gears that must mesh under load or run continuously, use BOSL2 `spur_gear()`, or generate the involute and check undercut (about 17 teeth minimum at 20°, fewer with profile shift) and a contact ratio above 1.2.
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

For plastic-to-plastic threads only (coarse, ≥M10, trapezoidal is best). A metal screw goes into a heat-set insert, a captive nut, or a plain self-tap hole at about 50% thread depth (Ø7.5 for M8 in PETG): a printed M8 thread failed to form in a real print.
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

# Verification: the deterministic build gate

The gate answers "does every part build into a valid, printable solid that meets the *measurable* spec?". It's binary and reproducible. Whether it's the right shape and a good FDM design is the [Design Review](design-review.md)'s job.

## Run the gate

```sh
python "<skill-dir>/verify-model.py" model.scad --build-volume 256x256x256 --export .
```

It finds OpenSCAD (`$OPENSCAD`, PATH, then the usual install folders, newest first; `--openscad PATH` overrides). It full-renders every value of the `part` selector, prints any `echo()` output once, then prints one PASS/FAIL line per part and a final `GATE: PASS` or `GATE: FAIL`. Exit status 0 means every part passed. **Run it; don't read it.** Its `--help` covers the flags: `--parts a,b`, `-D 'name=value'`, `-j N`.

What it checks, by part name (the naming convention in SKILL.md):

| Part | Passes when |
|---|---|
| printable (plain name) | Compiles clean, is **one connected body**, **manifold** (every edge shared by exactly two faces), **rests on Z=0**, fits the build volume |
| `plate_*`, `*_parts`, `*_coupons` | As printable, but several bodies are allowed |
| `clash_*`, `*interference*`, `fit` | Renders **empty**. Any overlap is a collision, and faces that only touch fail too: pose resting parts `fudge` apart in the clash part, so empty proves there's no overlap |
| `check_*`, `verify_*`, `debug_*` | Compiles; may be empty |
| `all`, `assembly*`, `explode*`, `section*`, `view*` | Compiles |

"Compiles clean" means exit 0 and no `ERROR:`, `WARNING:`, failed `assert()`, CGAL or manifold message on stderr. `ECHO:` lines are ignored. For printable parts it also reports sloped overhang past 45° and flat ceiling area. These don't fail the gate, since short ceilings bridge and some designs accept supports, but a non-zero overhang on a "support-free" part needs a reason. `--export DIR` writes each passing printable or layout part as a binary STL deliverable, named `<model>-<part>.stl`.

Fix failures in the model, not in a slicer:

- **Several bodies:** a feature floats free, e.g. teeth not overlapping their hub, or text not sunk into the face. Overlap it by `fudge`.
- **Non-manifold edges:** solids meet only along an edge or corner. Overlap them, then clip to the outline (openscad-reference.md, "Neighbouring Solids Must Overlap").
- **Not on the plate:** the part isn't modelled in print orientation at Z=0.
- **Collision:** mating parts overlap in that pose.

## Contracts: assert what you claim

Encode every measurable acceptance criterion, and every functional claim a comment or README makes ("snaps in after 0.8mm", "clears the cam by 1mm"), as an `assert()` on derived values. A violated contract then fails the gate. Compare floats with a tolerance (`abs(a - b) < 1e-6`, not `a == b`). Values are constants evaluated in file order, so a top-level variable used above its assignment is `undef`.

```openscad
assert(insert_len <= tube_depth_max, "too deep for tube");
echo(env_d = relaxed_crest_d, env_h = insert_len);   // shown in the gate's ECHO block
```

For a mechanism, sample the motion in functions: positions and clearances at rest, mid-travel and end of travel. Assert the timing and the minimum clearances, and add `clash_*` parts that intersect each moving pair in those poses.

## Traceability and reporting

Trace each acceptance criterion to a gate result: a bbox, an assert or a clash part. Carry the eyeball criteria to the Design Review. Report the print-only ones ("a real M8 mates") as residuals, never silently passed. Then state what you confirmed, e.g.:

> "Verified on OpenSCAD 2026.09.27: both parts compile clean, one body each, manifold, on the plate; 17.5×17.5×20.2mm and 16×16×9.6mm (within the 21mm depth limit); all asserts pass; clash_lid empty. Residual: an actual M8 mating needs a test print."

**Lightweight re-check** after a minor tweak: `--parts` with just the changed parts.

## Without Python (manual fallback)

Compile each `part` value and gate on stderr, not the exit code alone: a non-manifold result can exit 0.

```sh
openscad --hardwarnings --export-format asciistl -o out.stl -D 'part="lid"' model.scad 2> render.log; echo "exit $?"
grep -v '^ECHO:' render.log | grep -iE '^ERROR:|^WARNING:|^EXPORT-WARNING:|Assertion|CGAL error|not be a valid 2-manifold|may need repair|Simple:[[:space:]]*no|Current top level object is empty'
```

Any grep output fails the part, except "top level object is empty" on a `clash_*` part, where empty is the pass. `(PolySet)` is not a failure: current builds print it for any bare primitive. On 2024+ builds, `--summary all --summary-file s.json` gives the measured `geometry.bounding_box.size`. Neither the exit code nor stderr catches edge-only contact or a part in several bodies: the Manifold backend self-heals the first, and Bambu Studio flags it later. Without the script, check both by eye in the review's renders. Binary STL rounds coordinates to float32 and fakes non-manifold edges, so count edges only on ASCII STL.

**If OpenSCAD isn't installed where you're running:** in a sandbox or container you control, install it before designing. On Linux, `apt-get install openscad` (the 2021.01 stable, which the gate supports) or the nightly AppImage from `files.openscad.org/snapshots/`. If FUSE is missing, run the AppImage with `--appimage-extract` and use `squashfs-root/AppRun`. The nightly needs `libegl1`, `libgl1` and `libglu1-mesa`. On the user's own machine, ask before installing anything. If it truly can't be installed, say so plainly and do an extra-careful static review. Hand off the `.scad` with the export steps: open it in OpenSCAD, F6 to render, F7 to save an STL, then open the STL in the slicer. Don't present the `.scad` as the printable file.

Write scratch renders and logs to a temp directory, not the model folder. In PowerShell use `2> render.log`, `$LASTEXITCODE` and `Select-String`. Quote paths that contain spaces.

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

<a id="design-review"></a>

## Design Review

# Design Review — fresh-eyes peer review of a generated model

**Loading**: the reviewer sub-agent's complete brief. The author spawns the Design Review as a sub-agent and points it here. This file stands alone: to do the job you need only this file, the `.scad` path, the numbered acceptance criteria, the printer and material, and the OpenSCAD path. Don't invoke the 3d-print-designer skill or read its other files.

**Budget:** one pass, about 6-8 renders and 25 tool calls, then return. Incomplete findings returned on time beat a complete list that never arrives, so stop and report if you're running long. The author has already run the build gate: every part compiles, is one manifold body, sits on the plate and fits the printer, and every `clash_*` part is empty. Don't repeat that.

The Design Review covers what a deterministic gate cannot: **visual inspection** of the geometry (does it actually look right?), whether the mechanism/approach makes sense, the qualitative acceptance criteria, and compliance with the skill's FDM rules. It is peer critique, not the author marking its own homework: you render your own views and judge them. The gate's measurements (see [verification.md](verification.md)) are settled, and your job is everything they can't see.

You are multimodal: render the images and actually look at them. Static review of the code is necessary but not sufficient.

## How to perform a Full Review

1. **Read the `.scad` file.** Review the actual code, not a memory of it. For a long file, read the header, parameters and modules that matter, not every line.
2. **Render the views you need and look at them** (commands in [Rendering the views](#rendering-the-views) below). At minimum:
   - **ThrownTogether** — any pink/purple = winding/manifold tell.
   - **An ortho/iso set** — proportion, overall shape, feature presence and counts.
   - **A section/cutaway** — internal features: do bores go all the way through? wall thickness? thread engagement? fit/interference between mating parts?
3. **Confirm the qualitative acceptance criteria** — the ones needing an eyeball rather than a measurement (correct shape, sensible mechanism, looks like what the user asked for).
4. **Walk every checklist item below**, recording PASS/FAIL with a one-line reason.
5. **Return findings** — each: severity · what · where · suggested fix.

## Rendering the views

You render these yourself, then judge them. Image pixels are not a measurement: dimensions come from the gate. Use the OpenSCAD path from your brief as `$OSCAD`, quoted, since it may contain spaces. Without one, try `command -v openscad`, then `C:\Program Files\OpenSCAD*` or `/Applications/OpenSCAD*.app`, and prefer the newest build. 768px images are enough to judge geometry and cost about half as many tokens as 1024px.

The `--camera` gimbal form is `transx,transy,transz,rotx,roty,rotz,dist`; with `--viewall` the distance auto-fits, so only the rotation triple matters.

```sh
# ThrownTogether: back/CCW faces render pink, reversed faces purple (winding/manifold tells)
"$OSCAD" --preview=throwntogether --viewall --autocenter --imgsize=768,768 --camera=0,0,0,55,0,25,0 -o tt.png model.scad

# Orthographic front / top / right + an isometric (ortho keeps proportion true)
V="--render --projection=ortho --viewall --autocenter --imgsize=768,768"
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
"$OSCAD" --render --viewall --imgsize=768,768 -D section=1 --camera=0,0,0,90,0,0,0 -o section.png model.scad
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
- [ ] Fudge factor, **checked cutter by cutter**: for each `difference()`, compare every cutter's start and end coordinates with the faces it passes through. A cutter that ends exactly on a face (starts at `0`, or has a length equal to the wall) is a coincident face, even if the file defines `fudge`. Unused `fudge` is a tell.
- [ ] Bottom chamfers (45°), top fillets; no sharp internal corners (min 1mm fillet for stress)
- [ ] Elephant foot compensation, **checked in the code**: find where `ef_chamfer` (or equivalent) is applied to the plate-contact outline. A parameter that is defined but never used is a FAIL.
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

**Mechanisms (if anything moves, flexes or latches):**
- [ ] Every moving part is held in all six directions; nothing can tip, lift or slide out of its guide
- [ ] Each part has a way into place: an assembly order, with nothing that has to pass through a solid
- [ ] End stops exist, and the travel described in comments matches the geometry (clash parts or asserts at each end of travel)
- [ ] Springs and flexures are free along their whole bending length (not fused to a neighbour), and their force beats friction and ramp angles. A ramp self-locks when steeper than about 90° − 2·atan(μ)
- [ ] No moving part sweeps through another part's volume anywhere along its travel
- [ ] Functional claims in comments are backed by an `assert()`, or are flagged as unverified

**Visual / shape correctness (render and inspect — this is the review's core job):**
- [ ] ThrownTogether shows no pink/purple faces (no winding/manifold tells)
- [ ] Geometry matches intent — correct overall shape, proportions, and feature counts (holes, ribs, slots, teeth)
- [ ] Section/cutaway confirms internal features: bores go all the way through, walls aren't paper-thin, threads/mechanisms engage
- [ ] Multi-part: assembled view shows correct fit — no interference, no excessive gap at mating interfaces
- [ ] Qualitative acceptance criteria met (the eyeball ones); any unmet or print-only criteria reported to the user

## Return format

Start with the exact model ID you run as (from your system prompt), or `unknown`. Then return a findings list, each: **severity · what · where · suggested fix**. State findings as critique, not commands — the author triages, fixing real issues and pushing back on findings that are wrong or out of scope. Flag any acceptance criterion that only a real print can confirm as a residual rather than passing or failing it.

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

Heat-set inserts provide 200-600 N pull-out force vs 50-150 N for printed threads. **Any metal screw goes into an insert, a captive nut or a self-tap hole, never a printed thread.**

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
