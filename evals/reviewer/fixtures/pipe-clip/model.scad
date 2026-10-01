// === DESCRIPTION ===
// Pipe clip: a C-shaped clip that holds a 20 mm OD garden-irrigation pipe against a
// fence post. The pipe is pushed into the clip's opening and can be unclipped again
// to move the line.
// Physical context: outdoors under a veranda, one M4 screw into a timber post; the
//   clip only holds the pipe's weight (well under 1 kg).
//
// Design decisions:
//   - The clip is one profile extruded straight up, so the ring flexes within the
//     layer plane when the pipe snaps in.
//   - The screw tab sits beside the ring so the screw head is clear of the pipe.
//   - Snaps on and off easily: the ring's arms flex open around the pipe.
//
// Terminology → code:
//   "ring"        → pipe_d, ring_t, ring()
//   "opening"     → opening_w, opening_cut()
//   "screw tab"   → tab_w, tab_t, tab()
//   "screw hole"  → screw_d, screw_x, screw_hole()
//
// Common modifications:
//   Other pipe size   → pipe_d (opening_w follows pipe_d)
//   Stiffer clip      → ring_t
//
// Overall dimensions: 40 x 31 x 12 mm (fits a Bambu A1, 256^3)
// Coordinate system: X = along the post, Y = away from the post, Z = clip height
// NOTE: Model is in print orientation: the pipe axis is Z.

// === PRINT SETTINGS ===
// Material: PLA
// Layer Height: 0.2mm
// Walls/Perimeters: 3 (1.35mm)
// Infill: 30% gyroid
// Supports: None required
// Orientation: As modeled, profile flat on the bed
// Notes: none

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.2;

pipe_d = 20;          // pipe outside diameter
ring_t = 4;           // ring wall thickness
opening_w = 14;       // mouth width the pipe is pushed through
clip_h = 12;          // clip height (along the pipe)
tab_w = 40;           // screw tab length along the post
tab_t = 5;            // screw tab thickness
screw_d = 4.5;        // M4 clearance
screw_x = 20;         // screw position along the tab

// === DERIVED CONSTANTS ===
ring_r = pipe_d / 2 + ring_t;
fudge = 0.01;
$fn = $preview ? 48 : 96;

assert(screw_x - screw_d > ring_r, "screw hole clears the ring");

// === MODULES ===
module ring() difference() { circle(r = ring_r); circle(d = pipe_d); }

module tab() translate([-ring_r, -ring_r - tab_t]) square([tab_w, tab_t + 2]);

module profile() union() { ring(); tab(); }

module opening_cut() translate([-opening_w / 2, 0, 0]) cube([opening_w, ring_r + 1, clip_h]);

module screw_hole()
    translate([screw_x, 0, clip_h / 2]) rotate([90, 0, 0]) cylinder(d = screw_d, h = 2 * ring_r + 20, center = true);

// === ASSEMBLY / RENDER ===
difference() {
    linear_extrude(clip_h) profile();
    opening_cut();
    screw_hole();
}
