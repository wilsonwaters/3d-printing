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
