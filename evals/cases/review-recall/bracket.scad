// === DESCRIPTION ===
// Shelf Bracket: an L-shaped bracket that screws to a wall stud and holds up
// one end of a small shelf (books, plants, about 5 kg per bracket).
//
// Design decisions:
//   - Modelled the way it hangs on the wall so the preview matches the room.
//   - A triangular gusset stiffens the corner.
//
// Terminology -> code:
//   "wall plate"  -> plate_h, plate_w, wall
//   "shelf arm"   -> arm_len, wall
//   "screw holes" -> screw_d, screw_z1, screw_z2
//   "gusset"      -> gusset_len
//
// Common modifications:
//   Longer arm     -> arm_len
//   Bigger screws  -> screw_d
//
// Overall dimensions: 40 x 84 x 60 mm (fits the X1C 256 mm bed)
// Coordinate system: X = width, Y = out from the wall, Z = up the wall

// === PRINT SETTINGS ===
// Material: PETG
// Layer Height: 0.2mm
// Walls/Perimeters: 4
// Infill: 30% gyroid
// Supports: None required
// Orientation: As modelled, wall plate standing on the bed
// Notes: Dry PETG before printing

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.2;

plate_w = 40;      // bracket width (X)
plate_h = 60;      // wall plate height (Z)
arm_len = 80;      // shelf arm reach from the wall (Y)
wall = 1.5;        // plate and arm thickness
screw_d = 4.5;     // wood screw clearance
screw_z1 = 15;     // lower screw height
screw_z2 = 45;     // upper screw height
gusset_len = 30;   // gusset leg length

// === DERIVED CONSTANTS ===
$fn = 100;

// === MODULES ===
module wall_plate() {
    difference() {
        cube([plate_w, wall + 2, plate_h]);
        // recess for the screw heads, flush with the bottom face
        translate([plate_w / 2 - 6, 0, 0]) cube([12, 1, plate_h]);
        for (z = [screw_z1, screw_z2])
            translate([plate_w / 2, -1, z]) rotate([-90, 0, 0]) cylinder(d = screw_d, h = wall + 4);
    }
}

module shelf_arm() {
    translate([0, 0, plate_h - wall]) cube([plate_w, arm_len + wall + 2, wall]);
}

module gusset() {
    translate([plate_w / 2 - wall / 2, wall + 2, plate_h - wall])
        rotate([0, 90, 0])
            linear_extrude(wall)
                polygon([[0, 0], [gusset_len, 0], [0, gusset_len]]);
}

// === ASSEMBLY / RENDER ===
wall_plate();
shelf_arm();
gusset();
