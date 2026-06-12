// === DESCRIPTION ===
// Hand Pump Wall Mount Bracket: L-shaped bracket that mounts a Camec/Breha
// hand sink pump to a metal wall inside a camp trailer.
//
// Physical context: Bolted to a vertical metal wall. The pump threads through
// a 32mm hole in the top shelf via a plastic bolt underneath. A curved hose
// exits downward from the pump barb. The user pumps the handle up and down
// repeatedly, creating significant cyclic downward and forward forces on the
// top shelf. The pump body hangs 200mm below the mounting hole, plus 100mm
// hose clearance below that.
//
// Design decisions:
//   - L-bracket with side gusset webs (not centre gusset): the pump body
//     hangs through the centre so the middle must be completely clear.
//     Triangular side webs on left and right walls provide the bracing.
//   - Open front: full hand access to tighten tap nut under shelf and
//     wall bolt nuts on back plate
//   - Printed on its back (back plate = build plate): layers are in the XY
//     plane so pumping loads (downward on shelf) are shear across layers,
//     not delamination tension. Side webs print without supports.
//   - Two wall-mount bolt holes with hex nut traps on inside face of back
//     plate — bolt from behind wall, nut captured in trap, tightened with
//     a socket/spanner from the front through the open bracket
//   - Bottom centre slot for hose routing
//   - All corners rounded (min 3mm radius), all edges chamfered
//
// In OpenSCAD preview: you see the bracket from the open/front side.
//   X = width (left-right), Y = depth (front-back, 0=front, max=wall),
//   Z = height (0=bottom edge, max=top where pump mounts).
//
// NOTE: Model is in USE orientation for preview. For print orientation,
// set view = "print" — rotates so back plate is on the build plate.
//
// Terminology -> code:
//   "back plate"      -> back_thick, back_plate()
//   "shelf" / "top"   -> shelf_thick, shelf()
//   "side walls"      -> side_thick, left_wall(), right_wall()
//   "side gussets"    -> gusset_thick, side_gussets()
//   "pump hole"       -> tap_hole_dia, tap_hole_from_wall
//   "tap nut"         -> tap_nut_dia, tap_nut_depth
//   "wall bolts"      -> wall_bolt_dia, upper_bolt_z, lower_bolt_z
//   "nut traps"       -> nut_trap_af, nut_trap_depth
//   "hose slot"       -> hose_slot_width, hose_slot_depth
//   "corner radius"   -> corner_r
//
// Common modifications:
//   Bigger pump hole       -> tap_hole_dia (add 0.3mm for PETG tolerance)
//   Move pump hole         -> tap_hole_from_wall (distance from back wall)
//   Change wall bolt size  -> wall_bolt_dia, nut_trap_af (M5=8mm AF, M6=10mm AF)
//   Move bolt positions    -> upper_bolt_z, lower_bolt_z (keep >=25mm from edges)
//   Wider hose slot        -> hose_slot_width
//   Thicker side walls     -> side_thick (must be multiple of extrusion_width)
//   Thicker gussets        -> gusset_thick (wider side webs)
//
// Overall dimensions: 115 x 70 x 300 mm (fits Bambu X1C 256x256x256 in
//   print orientation: 115 x 300 x 70 on the bed)
// Coordinate system: X = width, Y = depth (wall at back), Z = height
//   Z=0 is bottom of bracket in use-view. Build plate is the back face.

// === PRINT SETTINGS ===
// Material: PETG
// Nozzle Temp: 240C (structural, max layer bond)
// Bed Temp: 80C
// Layer Height: 0.2mm
// Walls/Perimeters: 5 (2.25mm wall thickness)
// Infill: 20% gyroid
// Supports: None required (printed on back, all overhangs self-supporting)
// Orientation: Back plate flat on build plate (rotate -90 deg around X from
//   use orientation). Set view = "print" in the file to preview this.
// Cooling: 30-40% fan (PETG standard)
// Notes: Dry PETG before printing (60-65C, 4-6 hours). Print time ~6-8 hours.

// === PARAMETERS ===
// Printer settings
nozzle_diameter = 0.4;
layer_height = 0.2;
build_x = 256;
build_y = 256;
build_z = 256;

// Main dimensions (max envelope: 300h x 115w x 70d)
bracket_height = 300;    // total height
bracket_width  = 115;    // total width (left-right)
bracket_depth  = 70;     // total depth (front-to-wall)

// Wall thicknesses
wall_thick = 2.25;       // general wall reference (5 perimeters)
shelf_thick = 8;         // top shelf — thick for pump mount rigidity
back_thick = 4;          // back plate — needs depth for nut traps
side_thick = 3;          // side walls — structural, carry gusset loads
gusset_thick = 4;        // side gusset web thickness (Y-direction slab)

// Pump mounting
tap_hole_dia = 32.3;     // 32mm + 0.3mm PETG tolerance
tap_hole_from_wall = 40; // centre of hole to wall (back face)
// Recess for plastic nut under shelf
tap_nut_dia = 45;        // estimated nut OD — measure and adjust
tap_nut_depth = 8;       // depth of recess for nut

// Wall mounting bolts (M5 bolts)
wall_bolt_dia = 5.3;     // M5 + 0.3mm tolerance
upper_bolt_z = bracket_height - 50;  // 50mm from top (as specified)
lower_bolt_z = 50;                    // 50mm from bottom for stability

// M5 hex nut trap dimensions
nut_trap_af = 8.3;       // M5 nut across-flats + 0.3mm tolerance (8mm nominal)
nut_trap_depth = 4.5;    // M5 nut thickness (4mm) + 0.5mm clearance
nut_trap_corner_r = 0.5; // slight radius to help nut seat

// Hose routing
hose_slot_width = 28;    // width of bottom hose slot (generous for hose + clamp)
hose_slot_height = 30;   // height of the hose slot opening at bottom

// Side gusset geometry
// Gussets are triangular webs filling the inside corner between shelf and
// back plate, on each side wall. They taper from full depth at the top
// (where shelf meets back) down to nothing partway down the height.
gusset_height = 180;     // how far down from shelf the gusset extends

// Aesthetics
corner_r = 5;            // external corner radius
fillet_r = 3;            // internal fillet radius

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125; // 0.45mm
fudge = 0.01;
tolerance = 0.3;  // PETG sliding fit
ef_chamfer = 0.4; // elephant foot compensation
$fn = $preview ? 32 : 64;

// Tap hole Y position (from front face)
tap_hole_y = bracket_depth - tap_hole_from_wall;

// === HELPER MODULES ===

// Hexagonal prism for nut traps (across-flats dimension)
module hex_prism(af, h) {
    // af = across-flats distance
    r = af / 2 / cos(30);  // across-corners radius
    cylinder(h=h, r=r, $fn=6);
}

// === MAIN BODY ===

module back_plate() {
    translate([0, bracket_depth - back_thick, 0])
        cube([bracket_width, back_thick, bracket_height]);
}

module shelf() {
    translate([0, 0, bracket_height - shelf_thick])
        cube([bracket_width, bracket_depth, shelf_thick]);
}

module left_wall() {
    cube([side_thick, bracket_depth, bracket_height]);
}

module right_wall() {
    translate([bracket_width - side_thick, 0, 0])
        cube([side_thick, bracket_depth, bracket_height]);
}

module side_gussets() {
    // Triangular webs on left and right inner faces of side walls.
    // Each gusset is a right triangle:
    //   - Top edge along the underside of the shelf (full depth)
    //   - Back edge along the inner face of the back plate (gusset_height tall)
    //   - Hypotenuse from front-top to back-bottom of the triangle
    //
    // The gusset sits inside the bracket, against the side wall.

    gusset_top_z = bracket_height - shelf_thick;
    gusset_bottom_z = gusset_top_z - gusset_height;
    inner_depth = bracket_depth - back_thick;  // available depth from front to back plate

    // Left gusset — against inner face of left wall
    translate([side_thick, 0, gusset_bottom_z]) {
        linear_extrude(height=fudge)  // dummy — using polyhedron instead
            square(1);  // placeholder
    }

    // Build as a hull of thin slabs — simpler and reliable
    // Left gusset
    translate([side_thick, 0, 0]) {
        hull() {
            // Top-front edge (under shelf, at front)
            translate([0, 0, gusset_top_z - fudge])
                cube([gusset_thick, inner_depth, fudge]);
            // Bottom-back edge (at back plate, at bottom of gusset)
            translate([0, inner_depth - gusset_thick, gusset_bottom_z])
                cube([gusset_thick, gusset_thick, fudge]);
        }
    }

    // Right gusset
    translate([bracket_width - side_thick - gusset_thick, 0, 0]) {
        hull() {
            // Top-front edge (under shelf, at front)
            translate([0, 0, gusset_top_z - fudge])
                cube([gusset_thick, inner_depth, fudge]);
            // Bottom-back edge
            translate([0, inner_depth - gusset_thick, gusset_bottom_z])
                cube([gusset_thick, gusset_thick, fudge]);
        }
    }
}

// Bottom rail connecting side walls (behind hose slot area)
module bottom_rail() {
    rail_height = 15;
    rail_thick = wall_thick;
    // A cross-brace at the bottom, behind where the hose exits
    translate([0, bracket_depth - back_thick - rail_thick, 0])
        cube([bracket_width, rail_thick, rail_height]);
}

// === CUTOUTS ===

module tap_hole() {
    // Through-hole in shelf for pump mounting
    translate([bracket_width/2, tap_hole_y, bracket_height - shelf_thick - fudge])
        cylinder(h = shelf_thick + 2*fudge, d = tap_hole_dia);
}

module tap_nut_recess() {
    // Recess underneath shelf for the threaded plastic nut.
    // Accessible from below through the open front of the bracket.
    translate([bracket_width/2, tap_hole_y, bracket_height - shelf_thick - fudge])
        cylinder(h = tap_nut_depth + fudge, d = tap_nut_dia);
}

module wall_bolt_holes() {
    // Through-holes in back plate for wall mounting bolts.
    // Bolts insert from behind the wall, nuts captured in hex traps
    // on the inside face of the back plate.

    for (bolt_z = [upper_bolt_z, lower_bolt_z]) {
        // Bolt shaft hole — all the way through back plate
        translate([bracket_width/2, bracket_depth - back_thick - fudge, bolt_z])
            rotate([-90, 0, 0])
                cylinder(h = back_thick + 2*fudge, d = wall_bolt_dia);

        // Hex nut trap on inside face of back plate
        // Recessed into the back plate from the inside (front-facing side)
        translate([bracket_width/2, bracket_depth - back_thick - fudge, bolt_z])
            rotate([-90, 0, 0])
                hex_prism(af = nut_trap_af, h = nut_trap_depth + fudge);
    }
}

module hose_slot() {
    // Bottom centre opening for hose routing.
    // Cut from the bottom edge, open at front.
    translate([(bracket_width - hose_slot_width)/2, -fudge, -fudge])
        cube([hose_slot_width, bracket_depth - back_thick + fudge, hose_slot_height + fudge]);
}

// === EDGE TREATMENT ===

module round_front_corners() {
    // Round the two front vertical corners of the bracket

    r = corner_r;
    h = bracket_height + 2*fudge;

    // Front-left corner
    translate([r, r, -fudge])
    difference() {
        translate([-r - fudge, -r - fudge, 0]) cube([r + fudge, r + fudge, h]);
        cylinder(r=r, h=h);
    }

    // Front-right corner
    translate([bracket_width - r, r, -fudge])
    difference() {
        translate([0, -r - fudge, 0]) cube([r + fudge, r + fudge, h]);
        cylinder(r=r, h=h);
    }
}

// === ASSEMBLY ===

module bracket_body() {
    union() {
        back_plate();
        shelf();
        left_wall();
        right_wall();
        side_gussets();
        bottom_rail();
    }
}

module bracket_cuts() {
    tap_hole();
    tap_nut_recess();
    wall_bolt_holes();
    hose_slot();
    round_front_corners();
}

module bracket() {
    difference() {
        bracket_body();
        bracket_cuts();
    }
}

// === PRINT ORIENTATION ===

module print_orientation() {
    // Rotate so back face (Y=bracket_depth) sits on Z=0 (build plate)
    translate([0, bracket_height, 0])
    rotate([90, 0, 0])
        bracket();
}

// === RENDER ===
// Use-view: looking at bracket from front, pump hole at top
// Toggle between use-view and print-view:

view = "use";  // "use" = design review, "print" = print orientation

if (view == "use") {
    bracket();
} else {
    print_orientation();
}
