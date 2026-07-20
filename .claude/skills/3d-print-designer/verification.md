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

### 1g. Slicer-manifold check (edge-only contact)

The Manifold backend **self-heals edge-only contact** (solids meeting on a bare edge/corner rather than a face — e.g. diagonally adjacent grid cells), so 1a passes, but **Bambu Studio still flags it** ("N non-manifold edges, may need repair"). Run this stdlib check (no install) on every exported STL whenever the model tiles/arrays solids: in a watertight 2-manifold mesh **every undirected edge is shared by exactly two triangles**, so any count ≠ 2 is a defect.

```sh
python - "$@" <<'PY'
import sys
def check(path):
    tris, edges = 0, {}
    verts = []
    for line in open(path):
        s = line.split()
        if s[:1] == ['vertex']:
            verts.append(tuple(s[1:4]))          # exact text = exact match
            if len(verts) == 3:
                tris += 1
                for i in range(3):
                    a, b = verts[i], verts[(i+1) % 3]
                    k = (a, b) if a <= b else (b, a)
                    edges[k] = edges.get(k, 0) + 1
                verts = []
    bad = sum(1 for c in edges.values() if c != 2)
    print(("OK  " if bad == 0 else "BAD ") + f"{path}  tris={tris} non-manifold-edges={bad}")
for p in sys.argv[1:]: check(p)
PY
```

(ASCII STL parser; on the modern tier export ASCII or drop `--export-format binstl`.) A non-zero count means the fix belongs in the model — overlap the touching solids and clip to outline per [openscad-reference.md](openscad-reference.md) "Neighbouring Solids Must Overlap" — not in a slicer repair.

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
- **Manifold backend self-heals** (2026): the old "two cubes sharing one edge" no longer warns (it reports `Genus: -1` though) — so on modern builds, prefer measured/topology checks over expecting a build failure. This is exactly why edge-only contact escapes the gate but **Bambu Studio later flags it non-manifold** — run the edge-count check (1g) on arrayed/tiled models.
- **Default STL is ASCII on 2021.01** — force `--export-format binstl` before byte-parsing.
- **Preview ≠ render**: only trust full-render export, never `$preview` geometry.
- **Exclude `ECHO:` lines** from the stderr gate, or intentional messages cause false fails.
