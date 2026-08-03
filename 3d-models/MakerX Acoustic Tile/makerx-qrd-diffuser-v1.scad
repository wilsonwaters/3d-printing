// === DESCRIPTION ===
// MakerX QRD Acoustic Diffuser Tile (variant 1 of 3)
//   A 250x250 mm wall tile that scatters mid/high-frequency sound reflections
//   instead of bouncing them back specularly. It is a 1-D Schroeder QUADRATIC-
//   RESIDUE DIFFUSER (QRD): a row of wells whose depths follow the sequence
//   s_n = n^2 mod 7, so an incoming wavefront is re-radiated with a spread of
//   phases and the energy is spattered across angles rather than mirrored.
//   This does NOT "absorb" sound (a rigid panel can't) — it removes the harsh
//   specular reflection / flutter echo that makes rooms sound boxy.
//
// Physical context:
//   Mounts flat to a wall or ceiling (flat solid back, adhesive / Command
//   strips / optional keyhole). Tiles butt edge-to-edge on a 250 mm pitch to
//   cover larger areas. Lives indoors at room temperature; the only "load" is
//   its own weight + handling, so structure is light.
//
// Design decisions:
//   - Band 4-10 kHz (user target): well WIDTH sets the top (f=c/2w) and well
//     DEPTH sets the bottom (Schroeder). Both come out small -> a shallow,
//     fast-printing tile (~26 mm) unlike a bass diffuser (would be 80mm+).
//   - 1-D wells run full-length in Y; depth steps along X. Scatters strongly
//     in the horizontal plane (the usual flutter-echo axis between walls).
//   - Print BACK-DOWN: wells open upward, dividers are tall thin VERTICAL
//     walls (ideal FDM) — zero supports, no bridges.
//   - Brand: signature blue->magenta->gold diagonal gradient across the field
//     + the angular X logomark as a flush, solid (non-welled) inlay. Exported
//     as 4 colour bodies for AMS (see "part").
//
// Terminology -> code:
//   "the wells / grooves"  -> field_qrd(), pitch, well_opening, qr_seq()
//   "the dividers / fins"  -> fin_t
//   "well depth"           -> depth_unit, max_depth (from f_low/N in brand)
//   "the X / logo"         -> mx_x_placed_2d()  (in makerx_brand.scad)
//   "gradient zones"       -> mx_color_region_2d()  (blue/magenta/gold)
//   "the frame / rim"      -> frame_w, mx_frame_2d()
//   "back plate"           -> base_thick
//
// Common modifications:
//   Lower bottom frequency  -> f_low (brand) down; max_depth grows (deeper)
//   Raise top frequency     -> f_high up; needs narrower wells (more cells)
//   More scatter cells      -> periods (brand) 2->3 (narrower wells)
//   Bigger/smaller logo     -> mx_logo_w (brand)
//   Thicker wall mount       -> base_thick
//   Print as one colour     -> just export part="all" geometry / paint in slicer
//
// Overall dimensions: 250 x 250 x ~26.5 mm  (fits Bambu 256^3 with ~3mm/side)
// Coordinate system: X,Y = tile face; Z = height from build plate.
//   Z=0 is the FLAT BACK (on the bed / against the wall); +Z faces the ROOM.
//   Model is in print orientation — OpenSCAD preview matches the print.

// === PRINT SETTINGS ===
// Material: PETG (per user default; ductile, won't shatter, fine indoors)
// Layer Height: 0.2 mm
// Walls/Perimeters: 3 (fins are 2.0 mm = ~4 perimeters, print solid)
// Infill: 15% gyroid (back plate only; fins print as solid walls)
// Supports: None — wells open up, dividers are vertical, no overhang >45deg
// Orientation: As modeled. Flat back on the plate, wells pointing up.
// Notes:
//   - 250 mm flat base on PETG: use a brim (5-8 mm) + clean bed; enable the
//     slicer's Elephant-Foot Compensation (~0.15 mm) so tiles butt flush
//     (EFC is REQUIRED for a flush tile-to-tile joint — it is not modelled).
//   - Dry PETG (60-65C/4-6h). 30-40% part cooling fan.
//   - Mounting: flat back takes adhesive / removable mounting strips.
//   - Scatter axis: this 1-D QRD scatters in the plane PERPENDICULAR to the
//     wells. Mount with the wells running VERTICALLY to break up horizontal
//     flutter echo between facing walls (the usual case); rotate 90 deg for
//     vertical-plane scatter.
//   - 4 colours via AMS: import the 4 part STLs together as ONE object
//     (black/blue/magenta/gold) and assign a filament to each.

include <makerx_brand.scad>

// === PARAMETERS ===
base_thick = 2.0;                         // solid back plate thickness (mm)
part       = "all";                        // "all" | "black" | "blue" | "magenta" | "gold"

// === DERIVED CONSTANTS ===
field_top = base_thick + max_depth;        // flush top plane of fins / frame / logo
pitch     = interior / (periods * N);      // well pitch along X
well_opening = pitch - fin_t;

// === ACCEPTANCE CONTRACTS (fail the build if violated) ===
assert(tile <= 256, "Tile exceeds 256mm Bambu bed");
assert(well_opening <= max_feat_w, "Well too wide -> loses the 10 kHz top end");
assert(well_opening > 4*ew, "Well too narrow to print/scatter");
assert(fin_t >= 4*ew, "Divider thinner than 4 perimeters");
assert(max_depth > 0, "Degenerate well depth");
echo(VARIANT="QRD", pitch=pitch, well_opening=well_opening, max_depth=max_depth,
     f_high_actual=c_air/(2*well_opening), overall_depth=field_top);

// === MODULES ===
// The welled field: a solid block with QR-depth slots cut from the top.
module field_qrd() {
    difference() {
        translate([frame_w, frame_w, base_thick])
            cube([interior, interior, max_depth]);
        for (i = [0 : periods*N - 1]) {
            d = qr_seq(i % N) * depth_unit;            // this well's depth
            if (d > 0)
                translate([frame_w + i*pitch + fin_t/2, frame_w - fudge, field_top - d])
                    cube([pitch - fin_t, interior + 2*fudge, d + fudge]);
        }
    }
}

// The complete tile as a single manifold solid (colour-agnostic).
module full_qrd() {
    union() {
        cube([tile, tile, base_thick]);                       // flat back plate
        linear_extrude(field_top) mx_frame_2d();              // perimeter rim
        field_qrd();                                          // QRD wells
        linear_extrude(field_top)                             // flush solid X logo
            intersection() { mx_interior_2d(); mx_x_placed_2d(); }
    }
}

// One colour body = full solid intersected with that colour's 2D region.
module body(name) {
    intersection() {
        full_qrd();
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
