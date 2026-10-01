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

"Compiles clean" means exit 0 and no `ERROR:`, `WARNING:`, failed `assert()`, CGAL or manifold message on stderr. `ECHO:` lines are ignored. For printable parts it also reports sloped overhang past 45° and flat ceiling area. These don't fail the gate, since short ceilings bridge and some designs accept supports, but a non-zero overhang on a "support-free" part needs a reason. It also reports the first layer's separate regions at Z=0.1 and their areas, with a `WARN` line (never a FAIL) when small islands could lift. `--export DIR` writes each passing printable or layout part as a binary STL deliverable, named `<model>-<part>.stl`.

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
