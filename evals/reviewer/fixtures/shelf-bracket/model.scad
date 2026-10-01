// === DESCRIPTION ===
// Shelf bracket: an L-bracket that screws to a wall stud and carries one end of a
// 200 mm deep timber shelf of books (about 8 kg per bracket).
// Physical context: indoors, fixed with two 4 mm countersunk wood screws; the
//   shelf board rests on the arm, so the arm is loaded in bending at its root.
//
// Design decisions:
//   - Printed with the wall plate flat on the bed: the biggest flat face gives the
//     best adhesion and the arm rises straight up with no overhang.
//   - A triangular gusset stiffens the arm-to-plate joint.
//   - Screw holes are vertical in print orientation, so they need no teardrop.
//
// Terminology → code:
//   "wall plate"  → plate_w, plate_h, plate_t, wall_plate()
//   "arm"         → arm_len, arm_t, arm()
//   "gusset"      → gusset_len, gusset_t, gusset()
//   "screw holes" → screw_d, head_d, head_depth, screw_hole(), hole_y
//
// Common modifications:
//   Longer arm     → arm_len (keep gusset_len >= arm_len / 3)
//   Thicker parts  → plate_t, arm_t (whole multiples of extrusion_width)
//   Other screws   → screw_d, head_d
//
// Overall dimensions: 40 x 60 x 84.5 mm (fits a Bambu P1S, 256^3)
// Coordinate system: X = bracket width, Y = up the wall in use, Z = height off the bed
// NOTE: Model is in print orientation. In use, Z points out of the wall and the
//   arm is horizontal.

// === PRINT SETTINGS ===
// Material: PETG (tough, won't creep under a constant shelf load like PLA)
// Layer Height: 0.2mm
// Walls/Perimeters: 4 (1.8mm)
// Infill: 40% gyroid
// Supports: None required
// Orientation: As modeled, wall plate flat on the bed, arm pointing up
// Notes: Dry PETG before printing

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.2;

plate_w = 40;          // bracket width
plate_h = 60;          // wall plate height (in use)
plate_t = 4.5;         // wall plate thickness
arm_len = 80;          // arm length (shelf depth support)
arm_t = 5.4;           // arm thickness
gusset_len = 30;       // gusset leg length
gusset_t = 4.5;        // gusset thickness
screw_d = 3.2;         // clearance hole for the 4 mm wood screws
head_d = 8.5;          // countersink diameter at the surface
head_depth = 2.5;      // countersink depth
hole_y = [10, 20];     // screw positions up the plate

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
fudge = 0.01;
ef_chamfer = 0.4;
$fn = $preview ? 32 : 64;

assert(arm_len >= 75, "arm must support a 200 mm shelf at 75 mm or more");
assert(hole_y[1] + head_d / 2 < plate_h - arm_t - gusset_len, "screw heads clear the gusset");

// === MODULES ===
module wall_plate() cube([plate_w, plate_h, plate_t]);

module arm() translate([0, plate_h - arm_t, plate_t - fudge]) cube([plate_w, arm_t, arm_len + fudge]);

module gusset()
    translate([(plate_w - gusset_t) / 2, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(gusset_t)
                polygon([[plate_h - arm_t + fudge, plate_t - fudge],
                         [plate_h - arm_t - gusset_len, plate_t - fudge],
                         [plate_h - arm_t + fudge, plate_t + gusset_len]]);

module screw_hole(y)
    translate([plate_w / 2, y, -fudge]) {
        cylinder(d = screw_d, h = plate_t + 2 * fudge);
        translate([0, 0, plate_t - head_depth + fudge])
            cylinder(d1 = screw_d, d2 = head_d, h = head_depth + fudge);
    }

// === ASSEMBLY / RENDER ===
difference() {
    union() { wall_plate(); arm(); gusset(); }
    for (y = hole_y) screw_hole(y);
}
