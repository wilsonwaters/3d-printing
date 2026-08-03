// === DESCRIPTION ===
// Gate Latch Lever v4 — lets you operate a gate latch from the far side of the
// gate. A mounting bracket screws to the BACK of the gate; the lever pivots on
// that bracket in a plane PARALLEL to the gate face; pushing the handle swings
// the lever, and a latch connector rod (driven by the lever's extension end)
// pulls the latch open.
//
// Physical context:
//   - Outdoor gate. Bracket bolts to gate back (timber ~25mm deep).
//   - Pivot axis points straight out from the gate face (perpendicular to it).
//   - The handle and arm sit in a shallow gap alongside the gate: ~7mm of room
//     in the direction perpendicular to the gate face ("impact direction"), and
//     the arm swings within a ~5mm-wide channel ("swing-width" direction).
//   - Hardware: M4 bolts (pivot + latch joint), self-tapping screws (bracket).
//
// Failure this version fixes (reported on v2a/v3):
//   The thin 5x5mm arm snapped when the handle was knocked SIDEWAYS — i.e. a
//   blow perpendicular to the gate face (the impact direction), typically
//   mid-arm / near the handle. Normal use is fine because pushing the handle in
//   the swing plane lets the lever ROTATE and pass the load to the latch (the
//   load is relieved by motion). A sideways knock cannot rotate the lever — it
//   becomes a rigid cantilever off the pivot bolt, so an impact dumps its full
//   energy into bending the slender arm with no relief. NOTE: v3's header
//   *claimed* the arm was thickened to 7mm but the parameter was never changed
//   (it stayed at 5) — so v3 was effectively still the weak v2a arm.
//
// Design decisions (v4):
//   - Impact-direction thickness raised 5 -> 7mm (impact_thick). Bending strength
//     scales with thickness^3, so this alone is ~2.7x stronger against the knock,
//     using the full ~7mm clearance the user confirmed is available.
//   - That 7mm is UNIFORM across arm, pivot pad AND handle, so there is no step
//     (stress riser) in the impact direction anywhere along the load path.
//   - The 5mm arm blends into each 15mm disc through tangent "necks" (hull),
//     removing the sharp re-entrant corners where v3 stepped 5->15mm. Sharp
//     corners are a 4-10x stress multiplier in FDM; a gradual blend is ~1.1-1.3x.
//   - Material changed ASA -> PETG: tougher / more impact-resistant, far better
//     layer adhesion, and better UV than ABS. (ASA wins only on UV; PETG is the
//     right call for an impact failure and prints reliably on a Bambu.)
//   - Print orientation kept FLAT and support-free: the pivot axis is vertical,
//     so the discs print as clean pucks and the bolt holes print vertically.
//     Bending neutral axis sits parallel to the layers and the tension face is a
//     continuous in-layer extrusion, so the flat orientation is strong in
//     bending despite layers stacking through the impact thickness.
//
// Terminology -> code:
//   "the arm / lever section" -> the bar between pivot and handle (cube in lever_solid())
//   "impact direction / sideways" -> impact_thick  (perpendicular to gate; the 7mm)
//   "swing / actuation direction" -> swing_width    (in-plane motion; the 5mm)
//   "pivot"                   -> pivot_x, pivot_pad_dia, pivot_hole_dia
//   "handle"                  -> handle_x (derived), handle_dia
//   "smooth shoulder"         -> neck_len, neck()
//   "latch end / extension"   -> conn_x, ext_rod_dia, ext_rod_len, truss
//   "bracket"                 -> mounting_bracket()
//   "latch connector rod"     -> latch_connector()
//
// Common modifications:
//   Stronger against the knock   -> raise impact_thick (cubic gain). Limited by
//                                   the perpendicular-to-gate clearance (~7mm).
//   It rubs the gate             -> drop impact_thick ~0.5mm (e.g. 6.5).
//   Arm too wide for the channel -> lower swing_width (currently 5mm; weak axis,
//                                   keep >=4mm).
//   Different bolt               -> pivot_hole_dia / conn_hole_dia (+0.3mm PETG).
//   Must fit existing bracket    -> DO NOT change pivot_x, conn_x, or their 50mm
//                                   spacing, or the handle reach (handle_x).
//   Different printer            -> check lever_length+handle_dia vs build volume.
//
// Overall dimensions (lever): ~110 (X) x 7 (impact) x 15 (disc) mm.
//   Bracket and connector print alongside. Fits any current Bambu (>=180mm bed).
// Coordinate system (PRINT orientation, Z=0 = build plate via print_layout()):
//   In the part modules: X = length (pivot<->handle), Y = impact direction,
//   Z = swing-width. print_layout() lays the lever so Y (impact) becomes the
//   vertical build axis. IN USE the whole assembly is rotated onto the gate:
//   the impact/Y axis becomes horizontal & perpendicular to the gate face.

// === PRINT SETTINGS ===
// Material: PETG (impact-tough, ductile, great layer adhesion, OK outdoors).
//   Dry 60-65C / 4-6h before printing. Use a light colour for better UV life.
// Layer Height: 0.2mm
// Walls/Perimeters: 5 (~2.25mm) — perimeters carry the bending load; cheaper and
//   stronger than infill for a small solid section.
// Infill: 30% gyroid (equal strength all directions, no weak plane).
// Supports: None required — designed support-free (discs print as pucks, bolt
//   holes vertical, all overhangs <=45deg).
// Orientation: As laid out by print_layout(): lever flat (impact thickness
//   vertical), bracket mounting-plate flat on bed, connector flat.
// Notes:
//   - Enable slicer Elephant-Foot compensation ~0.15-0.2mm (PETG squishes wide).
//   - Nozzle 240-245C for max layer bond; fan 30-40% (NOT 100% — kills adhesion).
//   - Light-sand the pivot/connection holes for free rotation.
//   - Hardware: M4 bolt+nut (pivot, ~15mm grip), M4 bolt+nut (latch joint),
//     self-tapping screws for the bracket.

// === PARAMETERS ===
// Printer / process
nozzle_diameter = 0.4;
layer_height    = 0.2;

// Lever geometry (X positions are the MECHANISM interface — keep to fit bracket)
lever_length    = 80;     // handle tip reach datum
conn_x          = -35;    // latch-connection / extension end (X)
pivot_x         = 15;     // pivot bolt centre (X)  -> 50mm from conn_x
handle_dia      = 15;     // handle grip disc diameter
pivot_pad_dia   = 15;     // pivot reinforcement disc diameter

// THE strength parameters
impact_thick    = 7;      // Y: thickness in the knock direction (was 5). KEY: ^3 on strength.
swing_width     = 5;      // Z: width in the swing/actuation plane (gate channel limit)

// Transitions
neck_len        = 12;     // length over which the 5mm arm blends into a 15mm disc

// Latch / extension end (interface to latch_connector — preserved from v3)
ext_rod_dia     = 8;      // extension rod diameter
ext_rod_len     = 25;     // extension rod length (reaches toward the latch)
truss_inner_x   = -5;     // where the truss web ties back into the lever body (X)

// Holes (M4, PETG tolerance)
pivot_hole_dia  = 4.3;    // M4 clearance (4.0 + 0.3 PETG)
conn_hole_dia   = 4.3;    // M4 clearance
self_tap_hole_diameter = 2.5; // bracket pilot holes
gate_timber_depth = 25;

// === DERIVED CONSTANTS ===
// (Elephant-foot is handled in the slicer — see PRINT SETTINGS — because the
//  curved disc/neck geometry makes a modelled EF chamfer impractical here.)
fudge      = 0.01;                        // boolean overlap
handle_x   = lever_length - handle_dia/2; // = 72.5, handle disc centre
arm_len    = handle_x - conn_x;           // central bar length
$fn = $preview ? 32 : 64;

// === CONTRACTS (acceptance criteria as asserts) ===
assert(impact_thick <= 7.0, "impact_thick exceeds the ~7mm perpendicular-to-gate clearance");
assert(impact_thick >= 5.0, "impact_thick below the original 5mm — would be weaker, not stronger");
assert(swing_width <= 5.0, "swing_width exceeds the ~5mm gate channel");
assert(pivot_x - conn_x == 50, "pivot<->connection spacing changed (must stay 50mm to fit the bracket/latch)");
assert(handle_x > pivot_x, "handle must be outboard of the pivot");
assert(pivot_hole_dia >= 4.2 && pivot_hole_dia <= 4.6, "pivot hole not an M4 clearance fit");
assert(conn_hole_dia  >= 4.2 && conn_hole_dia  <= 4.6, "connection hole not an M4 clearance fit");
assert(lever_length + handle_dia < 180, "lever too long for the smallest Bambu bed (180mm)");

// === MODULES ===

// A pivot/handle disc: axis along Y (the pivot axis), spanning the full impact_thick.
module disc(x, dia) {
    translate([x, impact_thick, swing_width/2])
        rotate([90, 0, 0])
            cylinder(d=dia, h=impact_thick);
}

// Tangent "neck": smoothly blends the narrow arm into a disc over neck_len,
// eliminating the sharp 5->15mm step. dir = +1 (blend toward +X) or -1 (toward -X).
module neck(x, dia, dir) {
    hull() {
        disc(x, dia);
        translate([x + dir*neck_len, 0, 0])
            cube([fudge, impact_thick, swing_width]);   // a thin slice of the arm
    }
}

// The complete lever solid (before holes).
module lever_solid() {
    // Central bar: uniform impact_thick (Y) x swing_width (Z), full length.
    // Also forms the body of the connection end.
    translate([conn_x, 0, 0])
        cube([arm_len, impact_thick, swing_width]);

    // Pivot pad — bar passes through it, so blend on BOTH sides.
    disc(pivot_x, pivot_pad_dia);
    neck(pivot_x, pivot_pad_dia, +1);
    neck(pivot_x, pivot_pad_dia, -1);

    // Handle — bar ends at its centre, so blend on the arm (left) side only.
    disc(handle_x, handle_dia);
    neck(handle_x, handle_dia, -1);

    // --- Connection / latch end (preserved interface) ---
    // Extension rod the latch connector bolts to.
    translate([conn_x, impact_thick, swing_width/2])
        rotate([90, 0, 0])
            cylinder(d=ext_rod_dia, h=ext_rod_len);

    // Triangular truss web tying the extension rod back to the lever body.
    hull() {
        translate([truss_inner_x, 0, 0])          cube([fudge, impact_thick, swing_width]);
        translate([conn_x, -ext_rod_len/2, 0])    cube([fudge, fudge, swing_width]);
        translate([conn_x, 0, 0])                 cube([fudge, impact_thick, swing_width]);
    }
}

module gate_latch_lever() {
    difference() {
        lever_solid();

        // Pivot hole (M4 clearance), through the pad along Y.
        translate([pivot_x, impact_thick + fudge, swing_width/2])
            rotate([90, 0, 0])
                cylinder(d=pivot_hole_dia, h=impact_thick + 2*fudge);

        // Connection hole through the extension rod + truss along Y.
        translate([conn_x, impact_thick + fudge, swing_width/2])
            rotate([90, 0, 0])
                cylinder(d=conn_hole_dia, h=ext_rod_len + impact_thick + 1);
    }
}

// L-shaped mounting bracket (screws to gate back; carries the pivot). Unchanged
// from v3 apart from picking up pivot_hole_dia. The lever's 7mm pad and the
// bracket pivot arm simply stack along the M4 bolt — no interference.
module mounting_bracket() {
    bracket_length    = 20;
    bracket_width     = gate_timber_depth + 5;
    bracket_thickness = 4;
    extension_length  = 15;
    protrusion_width  = 8;

    difference() {
        union() {
            cube([bracket_length, bracket_thickness, bracket_width]);

            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width - protrusion_width)/2])
                cube([extension_length, 10, protrusion_width]);

            translate([0, bracket_thickness + 10, (bracket_width - protrusion_width)/2])
                cube([bracket_length, 6, protrusion_width]);

            // Fillet supports (strength at the right-angle junctions)
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width - protrusion_width)/2 - 3])
                hull() {
                    cube([extension_length, 0.1, 3]);
                    translate([0, 6, 3]) cube([extension_length, 0.1, 2]);
                }
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width + protrusion_width)/2])
                hull() {
                    cube([extension_length, 0.1, 3]);
                    translate([0, 6, -3]) cube([extension_length, 0.1, 2]);
                }
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width - protrusion_width)/2])
                hull() {
                    cube([2, 0.1, protrusion_width]);
                    translate([-2, -bracket_thickness, -2]) cube([2, bracket_thickness, protrusion_width + 4]);
                }
            translate([bracket_length/2 + extension_length/2 - 2, bracket_thickness, (bracket_width - protrusion_width)/2])
                hull() {
                    cube([2, 0.1, protrusion_width]);
                    translate([2, -bracket_thickness, -2]) cube([2, bracket_thickness, protrusion_width + 4]);
                }
        }

        // Pivot hole through the whole bracket width.
        translate([bracket_length/2, bracket_thickness + 13, bracket_width/2])
            rotate([0, 90, 0])
                cylinder(d=pivot_hole_dia, h=bracket_length + 2, center=true);

        // 4 countersunk pilot holes for self-tapping screws.
        hole_offset_x = 4;
        hole_offset_z = 6;
        countersink_diameter = 5.5;
        countersink_depth = 1.5;
        for (sx = [hole_offset_x, bracket_length - hole_offset_x],
             sz = [hole_offset_z, bracket_width - hole_offset_z])
            translate([sx, bracket_thickness + 0.1, sz])
                rotate([90, 0, 0]) {
                    cylinder(d=self_tap_hole_diameter, h=bracket_thickness + 0.2);
                    cylinder(d1=self_tap_hole_diameter, d2=countersink_diameter, h=countersink_depth);
                }
    }
}

// Latch connector rod (lever extension -> latch mechanism). Unchanged from v3.
module latch_connector() {
    connector_length    = 35;
    connector_width     = swing_width;
    connector_thickness = 3;

    difference() {
        union() {
            hull() {
                translate([2, connector_thickness/2, connector_width/2])
                    rotate([90, 0, 0]) cylinder(d=connector_width, h=connector_thickness, center=true);
                translate([connector_length - 2, connector_thickness/2, connector_width/2])
                    rotate([90, 0, 0]) cylinder(d=connector_width, h=connector_thickness, center=true);
            }
            translate([0, connector_thickness/2, connector_width/2])
                rotate([90, 0, 0]) cylinder(d=connector_width + 2, h=connector_thickness, center=true);
            translate([connector_length, connector_thickness/2, connector_width/2])
                rotate([90, 0, 0]) cylinder(d=connector_width + 2, h=connector_thickness, center=true);
        }
        translate([0, connector_thickness + 0.5, connector_width/2])
            rotate([90, 0, 0]) cylinder(d=conn_hole_dia, h=connector_thickness + 1);
        translate([connector_length, connector_thickness + 0.5, connector_width/2])
            rotate([90, 0, 0]) cylinder(d=conn_hole_dia, h=connector_thickness + 1);
    }
}

// === ASSEMBLY / RENDER ===

// Illustrative assembled view (not the print layout).
module assembly() {
    translate([-5, -5, -2]) color("brown", 0.3) cube([4, 35, gate_timber_depth + 4]);
    color("lightblue") mounting_bracket();

    translate([10 - 15, 16, 12.5])
        rotate([90, 0, 0]) rotate([0, 0, -10]) gate_latch_lever();

    translate([10 - 15 + 75, 13, 12.5])
        rotate([90, 0, 0]) rotate([0, 0, -10]) color("orange") latch_connector();

    translate([75, 20, 15]) color("red")
        rotate([0, 0, 90]) linear_extrude(1)
            polygon([[0,0],[5,2],[3,2],[3,8],[-3,8],[-3,2],[-5,2]]);
}

// Print layout: every part flat on the bed, support-free.
module print_layout() {
    // Lever: lay flat so the impact thickness (Y) becomes the vertical build axis.
    translate([0, 0, impact_thick])
        rotate([90, 180, 0])
            gate_latch_lever();

    // Mounting bracket: mounting plate flat on the bed.
    translate([0, -40, 0])
        rotate([90, 0, 0])
            mounting_bracket();

    // Latch connector: flat side down.
    translate([60, 0, 0])
        rotate([90, 0, 0])
            latch_connector();
}

// Choose what to render (override from the CLI with -D 'part="lever"' etc.):
part = "layout"; // "layout", "assembly", "lever", "bracket", "connector"

if (part == "layout")    print_layout();
if (part == "assembly")  assembly();
if (part == "lever")     gate_latch_lever();
if (part == "bracket")   mounting_bracket();
if (part == "connector") latch_connector();
