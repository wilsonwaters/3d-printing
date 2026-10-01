// === DESCRIPTION ===
// Control knob: a 30 mm knob for a 6 mm D-shaft potentiometer on an amplifier
// front panel. It pushes onto the shaft and an M3 grub screw bearing on the shaft's
// flat stops it pulling off.
// Physical context: indoors; the knob is turned by hand, so torque is small but
//   it is fitted and removed whenever the panel is serviced.
//
// Design decisions:
//   - Printed with the knob's top face on the bed, so the face you touch is the
//     smooth bed side and the bore opens upward with no overhang.
//   - A D-shaped bore transmits the torque; the grub screw only retains the knob.
//   - Fine ribs round the skirt give grip.
//
// Terminology → code:
//   "knob"        → knob_d, knob_h, knob_body()
//   "bore"        → shaft_d, shaft_flat, bore_depth, d_bore()
//   "grub screw"  → grub_pilot_d, grub_z, grub_hole()
//   "grip ribs"   → rib_n, rib_w, rib_h, ribs()
//
// Common modifications:
//   Other shaft   → shaft_d, shaft_flat
//   Bigger knob   → knob_d, rib_n
//
// Overall dimensions: 32 x 32 x 15 mm (fits a Bambu P1S, 256^3)
// Coordinate system: Z = up from the knob's top face (upside down as printed)
// NOTE: Model is in print orientation; in use it is flipped over.

// === PRINT SETTINGS ===
// Material: PLA
// Layer Height: 0.16mm
// Walls/Perimeters: 3
// Infill: 50% gyroid
// Supports: None required
// Orientation: As modeled, knob top face on the bed
// Notes: Thread the M3 grub screw into the pilot hole

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height = 0.16;

knob_d = 30;          // knob body diameter
knob_h = 15;          // knob height
shaft_d = 6.0;        // D-shaft diameter
shaft_flat = 4.5;     // D-shaft size across the flat
bore_depth = 12;      // bore depth from the open end
grub_pilot_d = 2.5;   // pilot hole the M3 grub screw threads into
grub_z = 9;           // grub screw height (print Z)
rib_n = 36;           // number of grip ribs
rib_w = 0.6;          // rib width
rib_h = 1.0;          // rib height above the body

// === DERIVED CONSTANTS ===
fudge = 0.01;
$fn = $preview ? 48 : 96;

assert(bore_depth < knob_h - 2, "at least 2 mm of solid top");
assert(grub_z > knob_h - bore_depth, "grub screw meets the bore");

// === MODULES ===
module d_bore()
    translate([0, 0, knob_h - bore_depth])
        linear_extrude(bore_depth + fudge)
            intersection() {
                circle(d = shaft_d);
                translate([-shaft_d / 2, -shaft_d / 2]) square([shaft_d, shaft_flat]);
            }

module knob_body() cylinder(d = knob_d, h = knob_h);

module ribs()
    for (i = [0 : rib_n - 1])
        rotate([0, 0, i * 360 / rib_n])
            translate([knob_d / 2 - fudge, -rib_w / 2, 0]) cube([rib_h + fudge, rib_w, knob_h]);

module grub_hole()
    translate([0, 0, grub_z]) rotate([-90, 0, 0]) cylinder(d = grub_pilot_d, h = knob_d);

// === ASSEMBLY / RENDER ===
difference() {
    union() { knob_body(); ribs(); }
    d_bore();
    grub_hole();
}
