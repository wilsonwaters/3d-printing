// === DESCRIPTION ===
// PCB mounting plate: a flat plate with four standoffs that hold a 60 x 40 mm
// controller board 5 mm above the plate. The board is fixed with M3 screws into
// brass heat-set inserts pressed into the standoffs, so it can be removed and
// refitted many times.
// Physical context: inside a hobby enclosure; the plate is screwed to the enclosure
//   floor through four corner holes. Loads are small (board weight, cable tugs).
//
// Design decisions:
//   - Heat-set inserts rather than printed threads, for repeated removal.
//   - Printed flat, standoffs pointing up, so the insert holes are vertical.
//
// Terminology → code:
//   "plate"       → plate_x, plate_y, plate_t, plate()
//   "standoffs"   → boss_od, boss_h, boss()
//   "insert hole" → insert_hole_d, insert_depth
//   "board holes" → pcb_hole_dx, pcb_hole_dy
//   "fixing holes"→ fix_d, fix_inset
//
// Common modifications:
//   Other board    → pcb_hole_dx, pcb_hole_dy, plate_x, plate_y
//   Taller gap     → boss_h
//
// Overall dimensions: 70 x 50 x 7.4 mm (fits a Prusa MK4, 250 x 210 x 220)
// Coordinate system: X/Y = plate, Z = height off the bed
// NOTE: Model is in print orientation.

// === PRINT SETTINGS ===
// Material: PLA
// Layer Height: 0.2mm
// Walls/Perimeters: 3
// Infill: 25% gyroid
// Supports: None required
// Orientation: As modeled, plate on the bed
// Notes: Press M3 x 4 heat-set inserts in with a soldering iron at 200-220C

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.2;

plate_x = 70;          // plate length
plate_y = 50;          // plate width
plate_t = 2.4;         // plate thickness
pcb_hole_dx = 54;      // board hole spacing in X
pcb_hole_dy = 34;      // board hole spacing in Y
boss_od = 5.5;         // standoff outside diameter
boss_h = 5;            // standoff height above the plate (board gap)
insert_hole_d = 3.0;   // hole for the M3 heat-set insert
insert_depth = 3.0;    // insert hole depth from the top of the standoff
fix_d = 3.4;           // M3 clearance for the fixing screws
fix_inset = 4;         // fixing hole distance from the plate edges

// === DERIVED CONSTANTS ===
fudge = 0.01;
$fn = $preview ? 32 : 64;

assert(boss_h == 5, "board sits 5 mm above the plate");
assert(pcb_hole_dx + boss_od < plate_x, "standoffs fit on the plate");

// === MODULES ===
module plate()
    difference() {
        cube([plate_x, plate_y, plate_t]);
        for (x = [fix_inset, plate_x - fix_inset], y = [fix_inset, plate_y - fix_inset])
            translate([x, y, -fudge]) cylinder(d = fix_d, h = plate_t + 2 * fudge);
    }

module boss()
    difference() {
        translate([0, 0, plate_t - fudge]) cylinder(d = boss_od, h = boss_h + fudge);
        translate([0, 0, plate_t + boss_h - insert_depth]) cylinder(d = insert_hole_d, h = insert_depth + fudge);
    }

// === ASSEMBLY / RENDER ===
union() {
    plate();
    for (sx = [-1, 1], sy = [-1, 1])
        translate([plate_x / 2 + sx * pcb_hole_dx / 2, plate_y / 2 + sy * pcb_hole_dy / 2, 0]) boss();
}
