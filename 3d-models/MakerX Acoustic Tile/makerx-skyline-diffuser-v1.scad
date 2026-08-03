// === DESCRIPTION ===
// MakerX Skyline Acoustic Diffuser Tile (variant 2 of 3)
//   A 250x250 mm wall tile that scatters reflections in BOTH directions (a
//   2-D diffuser), not just horizontally like the QRD. It is an array of
//   square pillars whose heights follow a 2-D quadratic-residue pattern
//   h(i,j) ~ (s_i + s_j) mod 7. The varying surface height acts as a 2-D
//   phase grating: an incoming wavefront leaves with scrambled phase and the
//   energy spreads over a hemisphere instead of mirroring back. Looks like a
//   city "skyline" — architectural, and the most visually striking variant.
//   Like the QRD it DIFFUSES, it does not absorb.
//
// Physical context:
//   Same as the QRD tile: flat solid back, mounts to a wall/ceiling, tiles on
//   a 250 mm pitch, indoor room temperature, self-weight only.
//
// Design decisions:
//   - Band 4-10 kHz: cell WIDTH <= c/2f_high sets the top; the tallest pillar
//     (= max well depth) sets the bottom. Same shallow ~26 mm depth budget.
//   - 2-D scatter suits a single feature wall / ceiling cloud where the QRD's
//     1-D scatter axis would be arbitrary.
//   - Pillars are vertical square prisms rising from a solid base -> the ideal
//     FDM shape: prints BACK-DOWN, support-free, no bridges. Adjacent pillars
//     overlap by `fudge` so unions never share a coincident face.
//   - Brand: same blue->magenta->gold diagonal gradient + flush solid X
//     logomark (stands proud of the shorter pillars). 4 AMS colour bodies.
//
// Terminology -> code:
//   "the pillars / blocks"  -> field_skyline(), cell, seq2d()
//   "pillar height"         -> step, max_depth (from f_low/N in brand)
//   "the X / logo"          -> mx_x_placed_2d()  (makerx_brand.scad)
//   "gradient zones"        -> mx_color_region_2d()
//   "the frame / rim"       -> frame_w, mx_frame_2d()
//
// Common modifications:
//   Finer / coarser texture -> periods (brand): more periods = smaller cells
//   Lower bottom frequency  -> f_low (brand) down -> taller pillars
//   Bigger/smaller logo     -> mx_logo_w (brand)
//
// Overall dimensions: 250 x 250 x ~26.5 mm  (fits Bambu 256^3)
// Coordinate system: X,Y = tile face; Z = height from build plate.
//   Z=0 is the FLAT BACK (on bed / against wall); +Z faces the ROOM.
//   Model is in print orientation — preview matches the print.

// === PRINT SETTINGS ===
// Material: PETG. Layer Height: 0.2 mm. Perimeters: 3. Infill: 15% gyroid.
// Supports: None — pillars are vertical prisms, no overhang.
// Orientation: As modeled, flat back on the plate, pillars up.
// Notes: 250 mm flat base -> brim + Elephant-Foot Compensation (~0.15 mm),
//   dry PETG, 30-40% fan. Import the 4 part STLs as one object for AMS.

include <makerx_brand.scad>

// === PARAMETERS ===
base_thick = 2.0;                          // solid back plate (mm)
part       = "all";                         // "all"|"black"|"blue"|"magenta"|"gold"

// === DERIVED CONSTANTS ===
field_top = base_thick + max_depth;         // flush top plane (frame, logo, tallest pillar)
cells     = periods * N;                    // pillars per axis (14)
cell      = interior / cells;               // pillar pitch & width
step      = max_depth / (N - 1);            // height quantum (7 levels 0..6)

// 2-D quadratic-residue height index 0..N-1
function seq2d(ix, iy) = (qr_seq(ix % N) + qr_seq(iy % N)) % N;

// === ACCEPTANCE CONTRACTS ===
assert(tile <= 256, "Tile exceeds 256mm Bambu bed");
assert(cell <= max_feat_w, "Cell too wide -> loses the 10 kHz top end");
assert(cell > 4*ew, "Cell too narrow to print/scatter");
assert(step*(N-1) <= max_depth + 0.01, "Pillar stack exceeds depth budget");
echo(VARIANT="SKYLINE", cell=cell, cells=cells, step=step,
     f_high_actual=c_air/(2*cell), tallest=base_thick+step*(N-1), overall_depth=field_top);

// === MODULES ===
module field_skyline() {
    for (ix = [0 : cells-1]) for (iy = [0 : cells-1]) {
        rise = step * seq2d(ix, iy);
        if (rise > 0)
            translate([frame_w + ix*cell, frame_w + iy*cell, base_thick - fudge])
                cube([cell + fudge, cell + fudge, rise + fudge]);
    }
}

module full_skyline() {
    union() {
        cube([tile, tile, base_thick]);                   // flat back plate
        linear_extrude(field_top) mx_frame_2d();          // perimeter rim
        field_skyline();                                  // pillars
        linear_extrude(field_top)                         // flush solid X logo
            intersection() { mx_interior_2d(); mx_x_placed_2d(); }
    }
}

module body(name) {
    intersection() {
        full_skyline();
        translate([0, 0, -fudge])
            linear_extrude(field_top + 2*fudge) mx_color_region_2d(name);
    }
}

module assembly() {
    color(MX_BLACK)   body("black");
    color(MX_BLUE)    body("blue");
    color(MX_MAGENTA) body("magenta");
    color(MX_GOLD)    body("gold");
}

// === RENDER ===
if (part == "all") assembly();
else body(part);
