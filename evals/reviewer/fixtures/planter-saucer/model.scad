// === DESCRIPTION ===
// Planter saucer: a round tray that sits under a 150 mm terracotta pot on a
// windowsill and catches the water that drains out after watering.
// Physical context: indoors on painted timber; it must hold up to ~150 ml of water
//   without leaking, and has a rim lip so it can be lifted with wet fingers.
//
// Design decisions:
//   - Printed upright, floor on the bed, so the inside surface is smooth.
//   - Thin walls and floor keep the print fast and light.
//   - A flat lip round the rim gives a grip to lift it.
//
// Terminology → code:
//   "tray"      → tray_d, tray_h, wall_t, floor_t, tray()
//   "lip"       → lip_w, lip_t, lip()
//
// Common modifications:
//   Bigger pot    → tray_d (keep tray_d <= 220 on an X1C with the cutter corner)
//   Deeper tray   → tray_h
//
// Overall dimensions: 184 x 184 x 20 mm (fits a Bambu X1C, 256^3)
// Coordinate system: X/Y = plan, Z = height off the bed
// NOTE: Model is in print orientation.

// === PRINT SETTINGS ===
// Material: PETG (water-resistant)
// Layer Height: 0.2mm
// Walls/Perimeters: 3
// Infill: 15% grid
// Supports: None required
// Orientation: As modeled, floor on the bed
// Notes: Dry PETG first

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.2;

tray_d = 160;       // tray outside diameter
tray_h = 20;        // tray height
wall_t = 1.5;       // side wall thickness
floor_t = 0.8;      // floor thickness (4 layers)
lip_w = 12;         // lip width beyond the wall
lip_t = 2;          // lip thickness

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
fudge = 0.01;
ef_chamfer = 0.4;
$fn = $preview ? 64 : 180;

assert(tray_d + 2 * lip_w <= 220, "fits inside the X1C's cutter-corner limit");
assert(tray_h <= 25, "no taller than 25 mm");

// === MODULES ===
module tray()
    difference() {
        cylinder(d = tray_d, h = tray_h);
        translate([0, 0, floor_t]) cylinder(d = tray_d - 2 * wall_t, h = tray_h);
    }

module lip()
    translate([0, 0, tray_h - lip_t])
        difference() {
            cylinder(d = tray_d + 2 * lip_w, h = lip_t);
            translate([0, 0, -fudge]) cylinder(d = tray_d - 2 * wall_t, h = lip_t + 2 * fudge);
        }

// === ASSEMBLY / RENDER ===
union() { tray(); lip(); }
