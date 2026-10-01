# OpenSCAD Language Reference — Gotchas and Non-Obvious Behaviors

Behaviours that produce incorrect code if forgotten, plus print-aware module patterns. The language itself is in the [OpenSCAD User Manual](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/The_OpenSCAD_Language).

## 1. Mandatory Rules (broken geometry if violated)

### Epsilon Overlap for Boolean Operations

Coincident faces in `union()` produce undefined behavior. Cutting objects in `difference()` must extend past the surface being cut. This is **not optional**.

```openscad
fudge = 0.01; // ALWAYS define this (the file template does)

// union: overlap by fudge (BAD: translate([0, 0, 10]) puts a face exactly at z=10)
union() {
    cube([10, 10, 10]);
    translate([0, 0, 10 - fudge]) cube([5, 5, 5 + fudge]);
}

// difference: extend the cutter beyond BOTH faces (BAD: translate([2, 2, 0]) cube([6, 6, 10]) is flush)
difference() {
    cube([10, 10, 10]);
    translate([2, 2, -fudge]) cube([6, 6, 10 + 2*fudge]);
}
```

### Never Mix 2D and 3D in Boolean Operations

Subtracting a 2D shape from a 3D object produces undefined results. Always extrude 2D shapes before boolean operations.

### Neighbouring Solids Must Overlap, Never Touch on a Bare Edge

Two solids that meet only along a shared edge or corner (not a face) — e.g. diagonally adjacent cells in a grid — form a **non-manifold edge**: that edge borders the outside on both sides. OpenSCAD's Manifold backend silently self-heals this and the build gate passes, but **slicers (Bambu Studio) reject it** ("N non-manifold edges, may need repair"). Give adjacent solids a real shared volume by overlapping them laterally (extend each by `fudge`), then clip the union back to the intended outline with an `intersection()`:

```openscad
// BAD — diagonal neighbours touch only at a corner (non-manifold edge)
translate([0, 0, 0]) cube([10, 10, h]);
translate([10, 10, 0]) cube([10, 10, h]);

// GOOD — overlap by fudge so neighbours share volume, then clip to outline
intersection() {
    union() { for (c = cells) translate(c) cube([10 + fudge, 10 + fudge, h]); }
    cube([tile_w, tile_d, big_h]);   // exact outer boundary
}
```

The gate ([verification.md](verification.md)) counts non-manifold edges on every printed part, so it catches this; OpenSCAD's own render doesn't.

### Polyhedron Faces Must Be Clockwise from Outside

Wrong winding = non-manifold geometry. Use F12 "Thrown Together" mode to check — pink faces have wrong winding. Validate by unioning with any cube and rendering (F6) — if it disappears, winding is wrong.

## 2. Language Notes

- **Variables are constants.** A second assignment in the same scope silently replaces the first everywhere, earlier lines included (last wins), so there is no `a = a + 1`: accumulate with recursion or list comprehensions.
- **Circles are inscribed polygons**: they never reach the nominal radius between vertices, so a coarse `$fn` makes holes undersize. Use `$fn` divisible by 4 for axis-aligned extents.
- `text()` inherits `$fn` too: at 64, every glyph curve gets 64 segments (one dial face's STL reached 14 MB). Pass `$fn = 12` to `text()`.
- `assert()` returns its children, so validations chain inside functions: `function f(a) = assert(a > 0, "a must be positive") a * 2;`

### Preview vs Render Conditional

```openscad
$fn = $preview ? 32 : 64;
// $preview is true in F5, false in F6 and CLI STL export
// render() does NOT affect $preview
```

## 3. FDM Module Patterns

Reusable, print-aware modules. They assume the derived constants from the file template (`fudge`, `tolerance`, `layer_height`). Screw holes, self-tap pilots, insert bosses and nut pockets are in [pattern-fasteners.md](pattern-fasteners.md).

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

## 4. Performance Rules

- `minkowski()` costs O(N*M) in the segment counts of both children: reduce `$fn` on both. Compound (multi-object) children may be treated as separate inputs, so always wrap them in `union()`: `minkowski() { cube(10); union() { sphere(2); cylinder(1, 2, 2); } }`, never bare braces.
- `resize()` runs full CGAL even in preview: use `scale()` while iterating.
- `render()` forces full CSG in preview: use it only when preview artifacts are unacceptable.
- `hull()` in 3D is slow: prefer `hull()` in 2D + `linear_extrude`.
- Keep `$fn` <= 64 for most uses, 128 max: higher can freeze the system.

## 5. Extrusion Gotchas

### linear_extrude and rotate_extrude

Both operate on the **XY-plane projection** of the 2D object. Transforms before extrusion affect the projection.

### rotate_extrude Specifically

- Z translation of 2D polygon: **no effect**
- X translation: increases diameter of result
- Y translation: shifts result in Z
- The 2D profile must be entirely on ONE side of the Y-axis
