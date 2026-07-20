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

See [verification.md](verification.md) for the edge-count check that catches this deterministically (the build gate alone does not).

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
