// === DESCRIPTION ===
// Coat hook: a single J-hook screwed to a wall for a heavy winter coat or a bag
// (up to about 3 kg hanging at the hook).
// Physical context: indoors, fixed to a stud with two 4 mm pan-head wood screws.
//   The load hangs in the hook's curve and bends the arm; the back plate presses
//   against the wall below and the top screw carries the pull-out load.
//
// Design decisions:
//   - Printed lying on its side: the hook's side profile is extruded along Z, so
//     the arm bends within the layer plane (along the layers), not across them.
//   - Screw holes are horizontal in this orientation, so they are teardrops with
//     the point up, sized 4 mm + 0.3 compensation + 0.3 free fit.
//   - Inside corners have 3 mm fillets and outside corners 1.5 mm rounds.
//   - The first 0.4 mm is inset in two steps for elephant-foot compensation.
//
// Terminology → code:
//   "back plate"   → plate_t, plate_h, profile()
//   "arm"          → arm_len, arm_t
//   "tip"          → tip_h, tip_t
//   "screw holes"  → screw_d, screw_y, teardrop_hole()
//   "hook width"   → hook_w
//
// Common modifications:
//   Wider hook       → hook_w
//   Heavier load     → arm_t (check bend_stress assert)
//   Deeper hook      → arm_len
//
// Overall dimensions: 36 x 70 x 20 mm (fits a Bambu P1S, 256^3)
// Coordinate system: X = out from the wall, Y = up the wall in use, Z = hook width
// NOTE: Model is in print orientation (on its side). In use, Y is vertical.

// === PRINT SETTINGS ===
// Material: PETG (tough; little creep at room temperature under a 3 kg load)
// Layer Height: 0.2mm
// Walls/Perimeters: 4 (1.8mm)
// Infill: 40% gyroid
// Supports: None required (teardrop holes, profile extruded straight up)
// Orientation: As modeled, lying on its side
// Notes: Dry PETG first; set slicer elephant-foot compensation to 0 (modelled in)

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.2;

hook_w = 20;          // hook width (print Z)
plate_h = 70;         // back plate height
plate_t = 5.4;        // back plate thickness (12 extrusion widths)
arm_len = 36;         // hook depth out from the wall
arm_t = 6.3;          // arm thickness (14 extrusion widths)
tip_h = 22;           // tip height
tip_t = 5.4;          // tip thickness
screw_nominal = 4;    // wood screw size
screw_y = [44, 62];   // screw heights
fillet_r = 3;         // inside corner fillet
round_r = 1.5;        // outside corner round
load_kg = 3;          // design load at the hook

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
fudge = 0.01;
hole_comp = 0.3;                                    // measured hole compensation
screw_d = screw_nominal + hole_comp + 0.3;          // free-running clearance
ef_chamfer = 0.4;
bend_stress = (load_kg * 9.81 * arm_len) / (hook_w * arm_t * arm_t / 6);   // MPa at the arm root
$fn = $preview ? 32 : 64;

assert(abs(plate_t / extrusion_width - round(plate_t / extrusion_width)) < 1e-6, "plate is whole perimeters");
assert(abs(arm_t / extrusion_width - round(arm_t / extrusion_width)) < 1e-6, "arm is whole perimeters");
assert(bend_stress < 12, "arm root stress stays well under PETG's ~50 MPa");
assert(screw_y[0] - screw_d / 2 > arm_t + fillet_r + 5, "screws clear the arm");
echo(bend_stress_MPa = bend_stress, screw_d = screw_d);

// === MODULES ===
module teardrop_hole(d, h, axis = "y") {
    r = d / 2;
    rotate([0, 0, axis == "x" ? 90 : 0]) rotate([90, 0, 0])
        linear_extrude(height = h, center = true)
            union() { circle(r = r); rotate(45) square(r); }
}

module raw_profile()
    union() {
        square([plate_t, plate_h]);                                // back plate
        square([arm_len, arm_t]);                                  // arm
        translate([arm_len - tip_t, 0]) square([tip_t, tip_h]);    // tip
    }

module profile()
    offset(r = round_r) offset(delta = -round_r)
        offset(r = -fillet_r) offset(delta = fillet_r)
            raw_profile();

module body()
    union() {
        linear_extrude(layer_height) offset(delta = -ef_chamfer) profile();
        translate([0, 0, layer_height - fudge]) linear_extrude(layer_height + fudge) offset(delta = -ef_chamfer / 2) profile();
        translate([0, 0, 2 * layer_height - fudge]) linear_extrude(hook_w - 2 * layer_height + fudge) profile();
    }

// === ASSEMBLY / RENDER ===
difference() {
    body();
    for (y = screw_y) translate([plate_t / 2, y, hook_w / 2]) teardrop_hole(screw_d, plate_t + 2, axis = "x");
}
