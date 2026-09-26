// === DESCRIPTION ===
// Land Rover Discovery 4 phone-charger bracket: a one-piece stand that plugs into the
// recessed vertical notch on the dash immediately left of the instrument binnacle
// (right-hand-drive, Australian 2013 D4 / L319), between the round face-level vent and
// the cluster surround, directly under the leather binnacle hood. It carries a
// LISEN W116 Qi2.2 25W magnetic wireless charger on a standard 17mm ball, holding the
// phone ~4cm out from the notch and ~5cm above the hood line, where the driver wanted it.
// Lisen's own adhesive base can't go here (they rule out leather, seams and uneven
// surfaces), which is why this exists.
//
// Physical context: the notch is a box — floor = top of the lower dash panel, back =
// flat matte trim face, ceiling = underside of the leather hood, sides = the vent
// surround's angled return and the cluster surround. Load is a ~0.45kg charger + phone
// (in a case) cantilevered out on the ball; the design case is 4g peak vertical on
// corrugations / washouts (four-wheel driving), plus a hot parked cabin in Australian
// sun (dash surfaces well over 70C).
//
// Design decisions:
//   - Wedge block, no holes: the block sits on the floor ledge, a closed-cell EPDM strip
//     on its top presses up against the hood underside, and 3M VHB holds the back face.
//     Whichever way the phone's leverage tries to rock it, something hard pushes back:
//     rocking about the front-bottom lifts the back-top into the hood (and loads the
//     tape in SHEAR, its strong mode); rocking about the back-bottom drives the
//     front-bottom into the floor. The tape only has to stop it sliding out, so two
//     small patches do — which keeps it removable (rip-cord groove across the back).
//   - Printed lying on its side (the side profile is flat on the plate). The phone's
//     weight bends the block, upright, neck and ball stalk in the side-profile plane,
//     so every bending stress runs ALONG the layers — nothing is loaded across a layer
//     line. Lateral (cornering) bending also puts axial stress along the layers.
//   - Integral 17mm ball, not a vent clip: shortest, stiffest load path; no clip jaws
//     to rattle loose off-road. The ball's bed-side cap is cut flat (ball_flat, <=1mm
//     so the socket's contact ring stays on the sphere). The ball is oversized by
//     asa_shrink so it shrinks to a true 17mm.
//   - Neck: Ø14 root -> long gentle taper -> Ø10 only for the last few mm before the ball,
//     where the socket fingers need it slim. The stress check is taken where the Ø10
//     section starts (its highest-moment point), with the hollow infill core allowed for.
//     Cross-sections are teardrops: the root runs down to the plate (support-free), the
//     rest is cut flat underneath and prints as a ~9mm bridge. The keel/flat side is the
//     plate side = the vent (left) side for beam_side="left", which the collar never
//     swings toward when you angle the charger right, toward the driver. (For
//     beam_side="right" the keel lands on the driver side and limits rightward swing.)
//   - The upright rides on the vent side of the block (beam_side) so the charger stays
//     clear of the gauges; it rises from the block top, not from the floor, so it is
//     a short, stiff cantilever (~57mm) instead of a long one.
//   - Notch sides: each side's angled return is its own [inset, depth] (vent_return,
//     cluster_return) — photos suggest they differ. The plate-side cut is kept <=45deg
//     (support-free) by cutting a little extra if the measured return is steeper.
//   - Cable clip: a snap-in groove down the upright's driver-facing face tidies the
//     USB-C lead so it doesn't flog about off-road.
//   - Clearance note: with the phone square to the charger its bottom edge clears the
//     upright by ~30mm; tilting the screen up past ~25deg brings it onto the upright.
//
// Terminology -> code:
//   "the notch"                 -> notch_h, notch_w, vent_return, cluster_return
//   "the hood / leather lip"    -> hood_over (front edge), hood_t (lip thickness), top_pad
//   "the floor ledge"           -> floor_depth (context/echo only)
//   "the block / base / wedge"  -> block_h, block_w, back_cuts(), profile_block()
//   "the upright / post"        -> up_d, beam_w, upright_offset, y_top, profile_frame()
//   "how far out"               -> upright_offset  (notch back face -> upright inner face)
//   "how high"                  -> rise            (notch top / hood underside -> ball centre:
//                                                   how much higher than a charger clipped
//                                                   straight into the notch)
//   "the ball / 17mm ball"      -> ball_d, asa_shrink, ball_flat, ball_mount()
//   "the neck / stalk"          -> neck_d, neck_start, root_d, neck_len, ball_pitch
//   "cable clip / groove"       -> cable_d, cable_groove()
//   "rip cord / removal"        -> rip_y, rip_groove()
//   "gauges / templates"        -> part = "gauge" (side template + plan template)
//   "ball test"                 -> part = "ball_test"
//
// Common modifications:
//   Doesn't fit the notch       -> notch_h, notch_w, vent_return, cluster_return, hood_over
//                                  (MEASURE — defaults are estimates from photos). Print
//                                  part="gauge" first.
//   Charger further out / in    -> upright_offset (must stay >= hood_over + hood_clear)
//   Charger higher / lower      -> rise (from the notch top = hood underside, where a charger
//                                  clipped straight into the notch would sit; the echo also
//                                  reports height above the hood top using hood_t)
//   Charger aimed higher        -> ball_pitch (the ball joint gives more on top)
//   Upright on the other side   -> beam_side = "right" (see keel note above)
//   Ball too tight / loose      -> asa_shrink (1.004 looser ... 1.008 tighter), or ball_d
//   Thicker cable               -> cable_d
//   Heavier phone               -> design_mass_kg; the stress asserts fail if it no longer
//                                  stacks up, and say which section
//   Slicer walls / infill       -> walls, infill (the stress check uses them)
//
// Overall dimensions (defaults): 85 x 129 x 38 mm (X x Y x Z as printed), ~85g ASA;
//   fits the X1C bed with room to spare, clear of the front-left cutter exclusion zone.
// Coordinate system (as printed): X = out of the notch toward the driver (for
//   beam_side="left" the model is mirrored so "out" runs toward -X), Y = up in the car,
//   Z = across the car. Z=0 (the plate) is the side the upright rides on — the LEFT
//   (vent) side in the car for the default beam_side.
// NOTE: Model is in print orientation — OpenSCAD preview matches the print.
//   In use, rotate it so the big flat face that was on the plate faces the vent, the
//   block goes into the notch and the ball points at the driver.

// === PRINT SETTINGS ===
// Material: ASA (automotive grade: Tg ~100C, UV-stable, tough). PETG would creep in a
//   parked car in summer; PLA would sag within a day.
// Layer Height: 0.2mm
// Walls/Perimeters: 6 (2.7mm) — the neck and ball are mostly perimeter
// Infill: 20% gyroid (stresses are tiny in the block; the walls carry the neck)
// Top/bottom shells: 5 layers
// Supports: None required. All overhangs <=45deg; the neck underside is a ~9mm bridge;
//   the ball's cut-flat cap is the one steep spot (6-8 layers at the plate, like any
//   printed ball on its side).
// Orientation: bracket and ball_test as modelled — lying on the side, the upright's flat
//   face on the plate. gauge: flat (2.4mm plates).
// Notes: Enclosed printer, door and lid closed. Part fan off except bridges (30-50%
//   burst for the neck bridge — Bambu's ASA profiles already do this). ASA gives off
//   styrene: print in a ventilated room or with a filtered enclosure. Dry filament
//   (80C / 4-6h). 8mm outer brim. Set slicer elephant-foot compensation to 0 (it's
//   built into the model). Bambu X1C: Generic ASA, textured PEI, bed 100C.

// === PARAMETERS ===
part = "bracket";      // "bracket" | "gauge" (side + plan fit templates) | "ball_test"
beam_side = "left";    // side of the notch the upright rides on, seen from the driver's seat
show_context = false;  // preview only: ghost the notch floor, back face and hood

// Printer settings
// Printer: Bambu Lab X1 Carbon (256 x 256 x 256 mm)
nozzle_diameter = 0.4;
layer_height = 0.2;
build_x = 256;
build_y = 256;
build_z = 256;
bed_margin = 20;       // keep clear of the edges / front-left cutter exclusion

// --- Notch measurements (MEASURE THESE — defaults are estimated from photos) ---
notch_h = 70;          // floor ledge -> underside of the leather hood, at the back face
notch_w = 40;          // notch width across its mouth
vent_return = [8, 8];  // vent-side wall: [how far it steps in by the back face, how deep that angled bit runs]
cluster_return = [2, 2]; // cluster-side wall, same meaning ([0, 0] = square corner)
hood_over = 34;        // how far the hood's front lip overhangs the notch back face
hood_t = 20;           // hood lip thickness, underside -> top of the leather (reporting only)
floor_depth = 60;      // how far the floor ledge runs out from the back face (reporting only)

// --- Where the charger goes ---
upright_offset = 40;   // notch back face -> dash-side face of the upright ("4 cm out")
rise = 50;             // ball centre above the notch top / hood underside — i.e. 5cm higher than
                       // the charger would sit clipped straight into the top of the notch ("5 cm up")
ball_pitch = 10;       // neck tilted up (deg), a head start on aiming at the driver's eyes
hood_clear = 3;        // minimum gap between the upright and the hood's front lip

// --- Fixing ---
tape_t = 1.1;          // 3M VHB 5952 on the back face
top_pad = 2.0;         // closed-cell EPDM strip on the block top, compressed thickness
side_clear = 1.0;      // lateral clearance per side in the notch
rip_y_from_top = 6;    // rip-cord groove: distance below the block top
rip_d = 1.2;           // rip-cord groove depth into the back face
rip_h = 1.6;           // rip-cord groove height
min_tape_w = 15;       // narrowest back face worth taping

// --- Structure ---
up_d = 18;             // upright depth (out direction) — sets fore/aft stiffness
beam_w = 16;           // upright lateral width (Z as printed)
gusset = 6;            // 45deg gusset where the upright's open side meets the block top
corner_r = 3;          // convex corner radius on the side profile
fillet_r = 4;          // concave fillet where the upright meets the block top
top_ch = 1.0;          // 45deg chamfer round the top (as printed) faces — no sharp edges by the hand

// --- 17mm ball ---
ball_d = 17;           // standard car-mount ball
asa_shrink = 1.006;    // ASA shrinks ~0.6%: model oversize so it prints true
ball_flat = 1.0;       // depth of the flat on the plate side of the ball (<= 1.0)
neck_d = 10;           // slender neck by the ball (standard-ish; bigger limits socket swing)
neck_start = 11;       // upright face -> start of the slender Ø10 section (taper before it)
root_d = 14;           // neck root at the upright
neck_len = 20;         // upright face -> ball centre, along the neck (collar swing room)
root_len = 3;          // full-diameter root beyond the upright face, down to the plate
neck_v_depth = 0.8;    // teardrop tip below the round neck before it is cut flat (bridge)
stem_w = 1.2;          // keel width at the plate if a small root teardrop can't reach it
max_taper = 25;        // steepest neck taper half-angle (deg) — keeps the shoulder gentle

// --- Cable clip ---
cable_d = 4.0;         // USB-C lead diameter
cable_play = 0.4;      // bore oversize for the lead
cable_snap = 0.6;      // mouth narrower than the lead by this much (snap-in)

// --- Gauges (fit templates) and ball test ---
gauge_t = 2.4;         // template thickness
gauge_border = 6;      // solid border width around the template window
gauge_gap = 10;        // space between the side and plan templates on the plate
tick_d = 2;            // depth of the hood-lip tick on the side template
vent_mark_d = 5;       // hole marking the vent side of the plan template
test_block = 24;       // ball_test base block size

// --- Preview context ghost (never exported) ---
ctx_wall = 10;         // ghost back-face thickness
ctx_margin = 30;       // ghost extends this far beyond the part

// --- Design check (strength) ---
design_mass_kg = 0.45; // charger (~0.15) + big phone in a case (~0.30)
design_g = 4;          // peak vertical acceleration incl. gravity (corrugations, washouts)
design_g_lat = 1.5;    // peak lateral (cornering + side-slope jolts)
cg_offset = 25;        // ball centre -> combined charger+phone centre of mass
asa_xy_mpa = 30;       // printed ASA tensile strength along layers
hot_derate = 0.6;      // strength retained in a hot parked cabin (~70C)
safety = 2.5;          // on top of the 4g design case
walls = 6;             // slicer perimeters (matches PRINT SETTINGS)
infill = 0.20;         // slicer infill fraction (matches PRINT SETTINGS)
max_bridge = 10;       // longest bridge ASA does cleanly (fan burst)
min_collar_room = 18;  // upright face -> ball centre needed for the socket collar to swing

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;   // 0.45
wall_thickness = extrusion_width * walls;     // 6 perimeters = 2.7mm
fudge = 0.01;                                 // boolean overlap
tolerance = 0.4;                              // ASA/ABS clearance (not used for mating here)
ef_chamfer = 0.4;                             // elephant-foot relief on the plate face
ef_steps = round(ef_chamfer / layer_height);  // relief applied one layer at a time
top_steps = round(top_ch / layer_height);     // top chamfer applied one layer at a time
big = 1000;                                   // "infinite" for 2D half-plane cuts
clip_pad = 10;                                // margin round the part for the plate clip
$fn = $preview ? 48 : 96;

// Notch-derived block (part frame: back face at X=0, floor at Y=0)
block_h = notch_h - top_pad;                  // wedges under the hood with the pad
block_w = notch_w - 2 * side_clear;           // lateral (Z) width
hood_x = hood_over - tape_t;                  // hood lip in part coordinates
up_x0 = upright_offset - tape_t;              // upright inner face
up_x1 = up_x0 + up_d;                         // upright outer (driver-side) face
rip_y = block_h - rip_y_from_top;             // rip-cord groove height

// Back-corner cuts [inset (Z), depth (X)] on the plate side (Z=0) and the top side.
// Plate side must stay <=45deg (inset >= depth); a steeper return gets a 45deg cut of
// size = depth, which still clears it.
plate_ret = beam_side == "left" ? vent_return : cluster_return;
top_ret = beam_side == "left" ? cluster_return : vent_return;
plate_cut = [max(plate_ret[0], plate_ret[1]), plate_ret[1]];
top_cut = top_ret;
back_face_w = block_w - plate_cut[0] - top_cut[0];

// Ball + neck
ball_dm = ball_d * asa_shrink;                // modelled ball diameter
ball_r = ball_dm / 2;
neck_r = neck_d / 2;
root_r = root_d / 2;
z_c = ball_r - ball_flat;                     // neck/ball axis height above the plate
neck_t = neck_r + neck_v_depth;               // neck underside (flat bridge) below the axis
step_len = z_c - neck_t;                      // root underside climbs to the bridge at 45deg
taper_s0 = root_len + step_len;               // taper Ø14 -> Ø10 runs from here...
taper_angle = atan((root_r - neck_r) / (neck_start - taper_s0)); // ...to neck_start
s_junction = sqrt(ball_r * ball_r - neck_r * neck_r);        // ball centre -> neck junction
ball_y = notch_h + rise;                      // ball centre height above the floor
root_y = ball_y - neck_len * sin(ball_pitch); // neck crosses the upright's outer face here
ball_x = up_x1 + neck_len * cos(ball_pitch);
y_top = root_y + root_r + corner_r + 1;       // upright top: straight face covers the root

// Cable groove on the upright's outer face
cable_r = (cable_d + cable_play) / 2;
cable_mouth = cable_d - cable_snap;
cable_depth = sqrt(cable_r * cable_r - (cable_mouth / 2) * (cable_mouth / 2)); // bore centre inside the face
cable_z = beam_w / 2;
cable_top = root_y - root_r - 2;

// Overall extents (raw, before mirroring)
part_len_x = ball_x + ball_r;
part_len_y = max(y_top, ball_y + ball_r);

// === DESIGN CHECKS ===
// Stress in the load path at the design case (N, mm, MPa). Sections are printed shells:
// `walls` of solid perimeter round a core that is only `infill` dense.
function core(d) = max(0, d - 2 * wall_thickness);
function z_round(d) = PI * (pow(d, 4) - (1 - infill) * pow(core(d), 4)) / (32 * d);
function z_rect(b, h) = (b * pow(h, 3) - (1 - infill) * core(b) * pow(core(h), 3)) / (6 * h);
g = 9.81;
f_vert = design_mass_kg * g * design_g;
f_lat = design_mass_kg * g * design_g_lat;
allow_mpa = asa_xy_mpa * hot_derate / safety;
lever_neck = cg_offset + neck_len - neck_start;        // start of the Ø10 section (worst)
sigma_neck = f_vert * lever_neck / z_round(neck_d);
sigma_root = f_vert * (cg_offset + neck_len) / z_round(root_d);
sigma_upright = f_vert * (up_d / 2 + neck_len * cos(ball_pitch) + cg_offset) / z_rect(beam_w, up_d);
sigma_neck_lat = f_lat * lever_neck / z_round(neck_d);
bridge_span = neck_len - sqrt(ball_r * ball_r - neck_t * neck_t) - taper_s0;

echo(block_h = block_h, block_w = block_w, back_face_w = back_face_w,
     plate_cut = plate_cut, top_cut = top_cut);
echo(upright_inner_from_notch = up_x0 + tape_t, ball_from_notch = ball_x + tape_t,
     ball_above_hood_underside = ball_y - notch_h, ball_above_hood_top = ball_y - notch_h - hood_t,
     ball_above_floor = ball_y);
echo(sigma_neck = sigma_neck, sigma_root = sigma_root, sigma_upright = sigma_upright,
     sigma_neck_lat = sigma_neck_lat, allow_mpa = allow_mpa, bridge_span = bridge_span,
     taper_angle = taper_angle);
echo(bbox_raw = [part_len_x, part_len_y, block_w]);
if (floor_depth < up_x1 + tape_t)
    echo(str("NOTE: floor ledge (", floor_depth, "mm) stops short of the block front (",
             up_x1 + tape_t, "mm) — the rocking pivot moves back to the ledge edge"));

// Fit
assert(upright_offset - hood_over >= hood_clear,
       str("upright would rub the hood lip: gap ", upright_offset - hood_over,
           "mm < hood_clear ", hood_clear, "mm. Raise upright_offset."));
assert(up_x0 - fillet_r >= hood_x + 1,
       "upright fillet reaches under the hood lip: lower fillet_r or raise upright_offset");
assert(block_h >= 30, "notch_h too small for a wedge block");
assert(block_w >= beam_w + gusset, "notch too narrow for the upright + gusset");
assert(back_face_w >= min_tape_w,
       str("back face only ", back_face_w, "mm wide after the side cuts — check vent_return / cluster_return"));
assert(plate_cut[1] < up_x0 && top_cut[1] < up_x0, "side return deeper than the block");
assert(rip_y - rip_h / 2 > 0 && rip_y_from_top - rip_h / 2 > corner_r,
       "rip-cord groove runs into the rounded top edge of the back face");
// Ball joint
assert(neck_d <= ball_d - 6, "neck too fat for the socket fingers to wrap the ball");
assert(neck_len >= min_collar_room, "ball too close to the upright for the collar to swing");
assert(ball_flat <= 1.0 + fudge, "ball_flat > 1mm puts the flat under the socket's contact ring");
assert(neck_t > neck_r && neck_t < neck_r * sqrt(2), "neck_v_depth out of range");
assert(neck_t >= root_r / sqrt(2), "root too fat: its flat underside would lose the 45deg sides");
assert(z_c - neck_t >= 2 * layer_height, "neck bridge too close to the plate");
assert(z_c + root_r <= beam_w, "neck root wider than the upright");
assert(neck_start > taper_s0 && taper_angle <= max_taper,
       str("neck taper too abrupt (", taper_angle, "deg) — raise neck_start"));
assert(neck_start <= neck_len - s_junction, "neck_start is inside the ball");
assert(bridge_span <= max_bridge,
       str("neck bridge ", bridge_span, "mm > ", max_bridge, "mm: shorten neck_len or lengthen root_len"));
// Strength (design case: design_mass_kg at design_g, hot, with safety factor)
assert(sigma_neck <= allow_mpa,
       str("neck overstressed: ", sigma_neck, " > ", allow_mpa, " MPa — raise neck_start or neck_d"));
assert(sigma_root <= allow_mpa, str("neck root overstressed: ", sigma_root, " MPa"));
assert(sigma_upright <= allow_mpa, str("upright overstressed: ", sigma_upright, " MPa — raise up_d"));
assert(sigma_neck_lat <= allow_mpa, str("neck overstressed sideways: ", sigma_neck_lat, " MPa"));
// Printer
assert(part_len_x <= build_x - 2 * bed_margin && part_len_y <= build_y - 2 * bed_margin
       && block_w <= build_z, "bracket exceeds the X1C build volume");

// === MODULES ===

// Linear extrude with a stepped elephant-foot relief on the plate face and a stepped 45deg
// chamfer on the top face (one step per layer, so the slicer prints exactly this).
module chamfer_extrude(h) {
    for (i = [0 : ef_steps - 1])
        translate([0, 0, i * layer_height])
            linear_extrude(layer_height + fudge)
                offset(delta = -ef_chamfer * (ef_steps - i) / ef_steps) children();
    translate([0, 0, ef_steps * layer_height])
        linear_extrude(h - ef_steps * layer_height - top_ch + fudge) children();
    for (i = [1 : top_steps])
        translate([0, 0, h - top_ch + (i - 1) * layer_height])
            linear_extrude(layer_height + (i < top_steps ? fudge : 0))
                offset(delta = -i * top_ch / top_steps) children();
}

// Side profile of the block alone (full lateral width).
module profile_block() {
    offset(r = corner_r) offset(delta = -corner_r) square([up_x1, block_h]);
}

// Side profile of block + upright, with the inner corner filleted.
module profile_frame() {
    offset(r = corner_r) offset(delta = -corner_r)
        offset(r = -fillet_r) offset(delta = fillet_r)
            union() {
                square([up_x1, block_h]);
                translate([up_x0, 0]) square([up_d, y_top]);
            }
}

// Plan (looking down into the notch) of the block: X = depth, Y = lateral (print Z).
module profile_plan() {
    difference() {
        square([up_x1, block_w]);
        corner_cut_2d(0, 1, plate_cut);
        corner_cut_2d(block_w, -1, top_cut);
    }
}

// Triangle removed from a back corner: inset along the lateral axis, depth along X.
// Its long side lies exactly on the line through (0, z0 + dir*inset) and (depth, z0).
module corner_cut_2d(z0, dir, cut) {
    if (cut[0] > 0 && cut[1] > 0)
        polygon([[-fudge, z0 - dir * fudge],
                 [cut[1] * (1 + fudge / cut[0]), z0 - dir * fudge],
                 [-fudge, z0 + dir * cut[0] * (1 + fudge / cut[1])]]);
}

// Back-corner cuts as prisms running the full height of the block.
module back_cuts() {
    translate([0, part_len_y + 1, 0])
        rotate([90, 0, 0])
            linear_extrude(part_len_y + 2) {
                corner_cut_2d(0, 1, plate_cut);
                corner_cut_2d(block_w, -1, top_cut);
            }
}

// Rip-cord groove straight across the back face (a vertical channel as printed): lay
// braided fishing line in it before taping; pulling the ends down saws through the tape.
module rip_groove() {
    translate([-fudge, rip_y - rip_h / 2, -fudge])
        cube([rip_d + fudge, rip_h, block_w + 2 * fudge]);
}

// 2D teardrop in a neck cross-section (x = across the neck in the side-profile plane,
// y = print Z). Runs down to the plate (y = -zc) with <=45deg sides whatever r is.
module td_bed(r, zc) {
    intersection() {
        translate([-big / 2, -zc]) square([big, big]);
        hull() {
            circle(r);
            translate([0, -r * sqrt(2)]) square(fudge, center = true);
            translate([-stem_w / 2, -zc]) square([stem_w, fudge]);
        }
    }
}

// 2D teardrop cut flat at y = -t (the flat underside prints as a bridge).
module td_flat(r, t) {
    intersection() {
        translate([-big / 2, -t]) square([big, big]);
        hull() {
            circle(r);
            translate([0, -r * sqrt(2)]) square(fudge, center = true);
        }
    }
}

// Thin slab of a 2D section, perpendicular to local +X at distance s.
module slab(s) {
    translate([s, 0, 0]) rotate([90, 0, 90]) linear_extrude(fudge) children();
}

// Neck + 17mm ball in a local frame: origin where the neck axis crosses the upright's
// outer face, axis along +X, Z = print Z (origin sits z_c above the plate).
module ball_mount(inner = up_d / 2) {
    // root: from inside the upright out to root_len, reaching the plate
    hull() {
        slab(-inner) td_bed(root_r, z_c);
        slab(root_len) td_bed(root_r, z_c);
    }
    // underside climbs from the plate to the bridge height at 45deg, still full root size
    hull() {
        slab(root_len) td_bed(root_r, z_c);
        slab(taper_s0) td_flat(root_r, neck_t);
    }
    // gentle taper Ø14 -> Ø10 (no shoulder at the highest-stress section)
    hull() {
        slab(taper_s0) td_flat(root_r, neck_t);
        slab(neck_start) td_flat(neck_r, neck_t);
    }
    // slender neck: round where the socket sits, flat underneath (bridge)
    hull() {
        slab(neck_start) td_flat(neck_r, neck_t);
        slab(neck_len) td_flat(neck_r, neck_t);
    }
    translate([neck_len, 0, 0]) sphere(d = ball_dm);
}

// Snap-in cable groove down the upright's outer face; teardrop ceiling (support-free).
module cable_groove() {
    translate([up_x1 - cable_depth, cable_top, cable_z])
        rotate([90, 0, 0])
            linear_extrude(cable_top + fudge)
                hull() {
                    circle(cable_r);
                    translate([0, cable_r * sqrt(2)]) square(fudge, center = true);
                }
}

// Gusset where the upright's open side meets the block top (top-facing 45deg slope).
module lateral_gusset() {
    translate([up_x0 + fillet_r, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(up_x1 - up_x0 - fillet_r - corner_r)
                polygon([[block_h - fudge, beam_w - fudge],
                         [block_h + gusset, beam_w - fudge],
                         [block_h - fudge, beam_w + gusset]]);
}

// Keeps everything at Z >= 0 (cuts the ball's flat). Sized to the part, not "huge", so
// preview --viewall still frames the model.
module plate_clip() {
    translate([-clip_pad, -clip_pad, 0])
        cube([part_len_x + 2 * clip_pad, part_len_y + 2 * clip_pad, block_w + clip_pad]);
}

module bracket_raw() {
    intersection() {
        difference() {
            union() {
                chamfer_extrude(block_w) profile_block();
                chamfer_extrude(beam_w) profile_frame();
                lateral_gusset();
                translate([up_x1, root_y, z_c]) rotate([0, 0, ball_pitch]) ball_mount();
            }
            back_cuts();
            rip_groove();
            cable_groove();
        }
        plate_clip();   // everything sits on the plate: the ball's flat is made here
    }
}

// Full-size fit templates, one print:
//  - side template: stand it in the notch (back edge on the back face, bottom on the
//    ledge). Top edge should sit ~top_pad under the hood; the tick on the top edge marks
//    where the hood's lip should be; the upright must clear the lip; disc = ball centre.
//  - plan template: slide it flat into the notch at mid height. It should reach the back
//    face without binding on the angled sides. The hole marks the vent side.
module gauge() {
    linear_extrude(gauge_t) {
        difference() {
            union() {
                profile_frame();
                translate([up_x1, root_y]) rotate(ball_pitch) {
                    hull() {
                        translate([-up_d / 2, 0]) circle(root_r);
                        translate([neck_len, 0]) circle(neck_r);
                    }
                    translate([neck_len, 0]) circle(ball_r);
                }
            }
            offset(r = gauge_border / 2)
                offset(delta = -gauge_border * 1.5) square([up_x1, block_h]);
            translate([hood_x, block_h + fudge])
                polygon([[-tick_d, 0], [tick_d, 0], [0, -tick_d]]);
        }
        translate([part_len_x + gauge_gap, 0])
            difference() {
                profile_plan();
                vent_z = beam_side == "left" ? 0 : block_w;
                translate([up_x1 - gauge_border - vent_mark_d / 2,
                           vent_z + (beam_side == "left" ? 1 : -1) * (gauge_border + vent_mark_d / 2)])
                    circle(d = vent_mark_d);
            }
    }
}

// Quick print to check the socket clamps on the printed ball (same orientation/flat).
module ball_test() {
    intersection() {
        union() {
            chamfer_extrude(beam_w)
                offset(r = corner_r) offset(delta = -corner_r) square([test_block, test_block]);
            translate([test_block, test_block / 2, z_c]) ball_mount(test_block / 2);
        }
        plate_clip();
    }
}

module place_side() {
    if (beam_side == "left") translate([part_len_x, 0, 0]) mirror([1, 0, 0]) children();
    else children();
}

// Preview-only ghost of the car around the bracket (never exported).
module context() {
    ctx_w = block_w + 2 * ctx_margin;
    color("gray", 0.35) {
        translate([-tape_t - ctx_wall, -ctx_margin, -ctx_margin])
            cube([ctx_wall, notch_h + hood_t + ctx_margin, ctx_w]);
        translate([-tape_t, -ctx_wall, -ctx_margin]) cube([floor_depth, ctx_wall, ctx_w]);
        translate([-tape_t, notch_h, -ctx_margin]) cube([hood_over, hood_t, ctx_w]);
    }
}

// === ASSEMBLY / RENDER ===
if (part == "bracket") {
    place_side() {
        bracket_raw();
        if (show_context && $preview) %context();
    }
} else if (part == "gauge") {
    gauge();
} else if (part == "ball_test") {
    ball_test();
}
