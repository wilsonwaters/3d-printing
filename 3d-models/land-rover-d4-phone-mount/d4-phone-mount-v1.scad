// === DESCRIPTION ===
// Land Rover Discovery 4 phone-charger bracket: a one-piece stand that plugs into the
// recessed vertical notch on the dash immediately left of the instrument binnacle
// (right-hand-drive, Australian 2013 D4 / L319), between the round face-level vent and
// the cluster surround, directly under the leather binnacle hood. It carries a
// LISEN W116 Qi2.2 25W magnetic wireless charger on a standard 17mm ball, holding the
// phone ~5cm higher than a charger clipped straight into the notch, on an upright that
// leans back toward the windscreen once it clears the hood lip (test-fitted, then revised).
// Lisen's own adhesive base can't go here (they rule out leather, seams and uneven
// surfaces), which is why this exists.
//
// Physical context: the notch is a box — floor = top of the lower dash panel (a ~30mm
// ledge that slopes down toward the driver), back = matte trim face that bulges ~4mm
// toward the driver top-to-bottom, ceiling =
// underside of the leather hood (overhangs 40mm), sides = the vent surround's angled
// return and the cluster surround. Load is a ~0.45kg charger + phone
// (in a case) cantilevered out on the ball; the design case is 4g peak vertical on
// corrugations / washouts (four-wheel driving), plus a hot parked cabin in Australian
// sun (dash surfaces well over 70C).
//
// Design decisions:
//   - Wedge block, no holes: seen from the side it is a wedge — its bottom follows the
//     sloping ledge out to block_bottom_d (the whole ~30mm ledge), its front face climbs
//     to the upright 65mm out at the top, a closed-cell EPDM strip on its top presses up
//     against the hood underside, and 3M VHB holds the back face. The phone tries to tip
//     it forward about the bottom's FRONT edge; the hood contact behind that edge pushes
//     back (tape in shear, its strong mode). That lever is only as long as the bottom is
//     deep, which is why the bottom uses the whole ledge: at 10mm the pad would see
//     ~13x the pressure (asserted via pad_mpa). A flat bottom on a sloping ledge would
//     touch only at its back corner and leave the tape holding the phone in peel. The tape
//     only has to stop it sliding out, so two small patches do — which keeps it
//     removable (rip-cord groove across the back). The back is dished (back_sag, a
//     circular arc) to sit on the bulging trim face instead of rocking on it.
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
//     Cross-sections are teardrops: the root runs down to the plate (support-free), then
//     the neck is cut flat underneath and prints as a ~9mm bridge. This is the exact neck
//     that test-fitted well: the LISEN collar nut sits within ~5mm of the upright face, so
//     a longer keel there fouls it (keel_end, collar_min_s). The keel/flat side is the
//     plate side = the vent (left) side for beam_side="left", which the collar never
//     swings toward when you angle the charger right, toward the driver. (For
//     beam_side="right" the keel lands on the driver side and limits rightward swing.)
//   - The upright rides on the vent side of the block (beam_side) so the charger stays
//     clear of the gauges; it rises from the block top, not from the floor, so it is
//     a short, stiff cantilever instead of a long one. It rises vertically until it clears
//     the hood lip, then leans back toward the windscreen by upright_lean (the knee is put
//     as low as the lip allows, from hood_t), and the neck comes straight out of the
//     leaning face, so the charger sits further back and faces up by the same angle.
//   - Notch sides: each side's angled return is its own [inset, depth] (vent_return,
//     cluster_return) — photos suggest they differ. The plate-side cut is kept <=overhang_max
//     (support-free) by cutting a little extra if the measured return is steeper.
//   - Cable clip: a snap-in groove down the upright's driver-facing face tidies the
//     USB-C lead so it doesn't flog about off-road.
//   - Clearance note: the neck already points 25deg up, so the charger starts reclined;
//     the phone's bottom edge clears the wedge front by ~60mm at that angle.
//
// Terminology -> code:
//   "the notch"                 -> notch_h, notch_w, vent_return, cluster_return
//   "the hood / leather lip"    -> hood_over (front edge), hood_t (lip thickness), top_pad
//   "the floor ledge"           -> floor_depth, floor_drop (its slope)
//   "the block / base / wedge"  -> block_h, block_w, block_bottom_d, wedge_pts, profile_block()
//   "rocking / pad load"        -> pad_force, pad_mpa, max_pad_mpa
//   "the upright / post"        -> up_d, beam_w, upright_gap, upright_pts, profile_frame()
//   "lean / knee"               -> upright_lean, y_knee (from hood_t, lean_clear)
//   "dished back / curve"       -> back_sag, back_x(), back_pts
//   "how far out"               -> upright_gap  (hood lip -> upright inner face)
//   "where measurements start"  -> hood_over / floor_depth: from the trim where it meets the
//                                  hood / ledge (back_x() behind the bulge at x = 0)
//   "how high"                  -> rise            (notch top / hood underside -> ball centre:
//                                                   how much higher than a charger clipped
//                                                   straight into the notch)
//   "the ball / 17mm ball"      -> ball_d, asa_shrink, ball_flat, ball_mount()
//   "the neck / stalk"          -> neck_d, neck_start, root_d, neck_len, neck_tilt, neck_pitch
//   "cable clip / groove"       -> cable_d, cable_groove()
//   "rip cord / removal"        -> rip_y, rip_groove()
//   "gauges / templates"        -> part = "gauge" (side template + plan template)
//   "ball test"                 -> part = "ball_test"
//
// Common modifications:
//   Doesn't fit the notch       -> notch_h, hood_over (measured), notch_w, vent_return,
//                                  cluster_return, floor_drop (still estimates). Print
//                                  part="gauge" first.
//   Wedge rocks on the ledge    -> floor_drop (bottom slope); over-estimate by <=1mm so it
//                                  lands on the ledge's front edge, not its back corner
//   Shorter wedge bottom        -> block_bottom_d (the pad_mpa assert says how short is safe)
//   Charger further out / in    -> upright_gap (>= hood_clear)
//   Charger higher / lower      -> rise (from the notch top = hood underside, where a charger
//                                  clipped straight into the notch would sit; the echo also
//                                  reports height above the hood top using hood_t)
//   Charger further back / fwd  -> upright_lean (0 = vertical); how far it can lean from how
//                                  low depends on hood_t — measure it
//   Charger aimed higher / lower-> neck_tilt (relative to straight out of the leaning upright)
//   Back face curve             -> back_sag (0 = flat)
//   Upright on the other side   -> beam_side = "right" (see keel note above)
//   Ball too tight / loose      -> asa_shrink (1.004 looser ... 1.008 tighter), or ball_d
//   Thicker cable               -> cable_d
//   Heavier phone               -> design_mass_kg; the stress asserts fail if it no longer
//                                  stacks up, and say which section
//   Slicer walls / infill       -> walls, infill (the stress check uses them)
//
// Overall dimensions (defaults): ~84 x 130 x 38 mm (X x Y x Z as printed), ~75g ASA;
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
// Supports: None required, and leave them OFF. Every overhang is <=40deg (overhang_max), so
//   a 45deg support threshold in the slicer flags nothing except the two spots any ball
//   printed on its side has: the ~9mm bridge under the neck (as test-printed), and the ball's
//   first ~2mm above its flat. Both print fine unsupported.
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
overhang_max = 40;     // steepest overhang anywhere (deg from vertical) — margin under a 45deg
                       // slicer support threshold, which flags faces at exactly 45deg

// --- Notch measurements (MEASURE THESE — defaults are estimated from photos) ---
notch_h = 65;          // floor ledge -> underside of the leather hood, at the back face (measured)
notch_w = 40;          // notch width across its mouth
vent_return = [8, 8];  // vent-side wall: [how far it steps in by the back face, how deep that angled bit runs]
cluster_return = [2, 2]; // cluster-side wall, same meaning ([0, 0] = square corner)
hood_over = 40;        // hood's front lip -> the back face where it meets the hood (measured)
hood_t = 20;           // hood lip thickness, underside -> top of the leather (ESTIMATE) — sets how
                       // low the upright can start leaning without hitting the lip
back_sag = 4;          // back face bulges toward you: a ruler held up-and-down rocks on it with
                       // this gap at each end (measured). The wedge's back is dished to match.
back_n = 16;           // segments in the dished back
floor_depth = 30;      // ledge's front edge -> the back face where it meets the ledge (measured, approx)
floor_drop = 6;        // how much lower the ledge is at floor_depth than at the back face (ESTIMATE)
block_bottom_d = floor_depth; // how much of the ledge the wedge's sloped bottom sits on
bottom_overrun = 3;    // the bottom may run this far past the ledge edge (harmless)

// --- Where the charger goes ---
upright_gap = 5;       // hood lip -> dash-side face of the upright (the upright stands just clear of it)
rise = 50;             // ball centre above the notch top / hood underside — i.e. 5cm higher than
                       // the charger would sit clipped straight into the top of the notch ("5 cm up")
upright_lean = 25;     // upright leans back toward the windscreen above the hood lip (deg)
neck_tilt = 0;         // neck angle relative to straight out of the leaning upright (+ = up)
hood_clear = 3;        // minimum gap between the upright and the hood's front lip
lean_clear = 5;        // gap between the leaning part and the lip's top corner (hood_t is a guess)

// --- Fixing ---
tape_t = 1.1;          // 3M VHB 5952 on the back face
top_pad = 2.0;         // closed-cell EPDM strip on the block top, compressed thickness
side_clear = 1.0;      // lateral clearance per side in the notch
rip_y_from_top = 6;    // rip-cord groove: distance below the block top
rip_d = 1.2;           // rip-cord groove depth into the back face
rip_h = 1.6;           // rip-cord groove height
min_tape_w = 15;       // narrowest back face worth taping

// --- Structure ---
up_d = 20;             // upright depth (out direction) — sets fore/aft stiffness; top of wedge = 65
beam_w = 16;           // upright lateral width (Z as printed)
gusset = 6;            // 45deg gusset where the upright's open side meets the block top
corner_r = 3;          // convex corner radius on the side profile
fillet_r = 3;          // concave fillet where the upright meets the block top (2mm clear of the lip)
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
keel_end = 3;          // upright face -> where the neck's plate-reaching keel stops (= root_len:
                       // the neck shape that test-fitted well; longer fouls the collar nut)
collar_min_s = 5;      // the collar nut sits this close to the upright face (test fit)
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
max_pad_mpa = 0.15;    // peak pressure on the EPDM under the hood (closed-cell EPDM ~50% squashed)
min_collar_room = 18;  // upright face -> ball centre needed for the socket collar to swing

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;   // 0.45
wall_thickness = extrusion_width * walls;     // 6 perimeters = 2.7mm
fudge = 0.01;                                 // boolean overlap
tolerance = 0.4;                              // ASA/ABS clearance (not used for mating here)
ef_chamfer = 0.3;                             // elephant-foot relief on the plate face
ef_steps = ceil(ef_chamfer / (layer_height * tan(overhang_max))); // steps no steeper than overhang_max
td_k = 1 / sin(overhang_max);                 // teardrop apex distance / radius
top_steps = round(top_ch / layer_height);     // top chamfer applied one layer at a time
big = 1000;                                   // "infinite" for 2D half-plane cuts
clip_pad = 10;                                // margin round the part for the plate clip
$fn = $preview ? 48 : 96;

// Notch-derived block (part frame: back face at X=0, floor at Y=0)
block_h = notch_h - top_pad;                  // wedges under the hood with the pad
block_w = notch_w - 2 * side_clear;           // lateral (Z) width
// Dished back: a circular arc matching the bulging back face. x = 0 is where a ruler
// touches the bulge; the ends sit back_sag further back. hood_over and floor_depth are
// measured from the trim where it meets the hood / ledge, i.e. from back_x() of those points.
back_R = back_sag > 0 ? (pow(notch_h / 2, 2) + back_sag * back_sag) / (2 * back_sag) : 0;
function back_x(y) = back_sag <= 0 ? 0
    : let(yc = min(max(y, 0), notch_h) - notch_h / 2) -(back_R - sqrt(back_R * back_R - yc * yc));
hood_x = hood_over + back_x(notch_h) - tape_t; // hood lip (measured from where the back meets the hood)
up_x0 = hood_x + upright_gap;                 // upright inner face
up_x1 = up_x0 + up_d;                         // upright outer (driver-side) face
rip_y = block_h - rip_y_from_top;             // rip-cord groove height
// Wedge: sloped bottom sits on the ledge out to bottom_x, then the front face climbs to
// the upright's outer face at block-top height.
floor_edge_x = floor_depth + back_x(0) - tape_t; // ledge's front edge (measured from where the back meets it)
bottom_x = block_bottom_d + back_x(0) - tape_t; // front edge of the wedge's bottom
bottom_drop = floor_drop * block_bottom_d / floor_depth; // ledge drop at that point
back_pts = [for (i = [back_n : -1 : 0]) [back_x(block_h * i / back_n), block_h * i / back_n]];
wedge_pts = concat([[bottom_x, -bottom_drop], [up_x1, block_h]], back_pts);

// Back-corner cuts [inset (Z), depth (X)] on the plate side (Z=0) and the top side.
// Plate side must stay <=overhang_max; a steeper return gets a cut widened to that angle,
// which still clears it.
plate_ret = beam_side == "left" ? vent_return : cluster_return;
top_ret = beam_side == "left" ? cluster_return : vent_return;
plate_cut = [max(plate_ret[0], plate_ret[1] / tan(overhang_max)), plate_ret[1]];
top_cut = top_ret;
back_face_w = block_w - plate_cut[0] - top_cut[0];

// Ball + neck
ball_dm = ball_d * asa_shrink;                // modelled ball diameter
ball_r = ball_dm / 2;
neck_r = neck_d / 2;
root_r = root_d / 2;
z_c = ball_r - ball_flat;                     // neck/ball axis height above the plate
neck_t = neck_r + neck_v_depth;               // neck underside (flat bridge) below the axis
step_len = (z_c - neck_t) * tan(overhang_max); // keel underside climbs to the bridge this steeply
bridge_s0 = keel_end + step_len;              // flat-bottomed (bridged) neck starts here
taper_angle = atan((root_r - neck_r) / (neck_start - root_len)); // Ø14 at root_len -> Ø10 at neck_start
function neck_r_at(s) = s <= root_len ? root_r
                      : s >= neck_start ? neck_r
                      : root_r - (root_r - neck_r) * (s - root_len) / (neck_start - root_len);
s_junction = sqrt(ball_r * ball_r - neck_r * neck_r);        // ball centre -> neck junction
ball_y = notch_h + rise;                      // ball centre height above the floor
// Leaning upright: vertical from the wedge top to the knee, then leaning back by
// upright_lean. The knee is as low as it can be while the leaning inner face still clears
// the hood lip's top-front corner by lean_clear.
lean = upright_lean;
neck_pitch = lean + neck_tilt;                // absolute neck angle above horizontal
up_u = [-sin(lean), cos(lean)];               // up the leaning part
up_n = [cos(lean), sin(lean)];                // out of its driver-side face
x_c = up_x0 + up_d / 2;                       // upright centreline below the knee
knee_h2 = up_d / 2 * tan(lean / 2);           // knee corners sit this far above/below the centreline knee
hood_corner_y = notch_h + hood_t;
knee_min = lean > 0 ? hood_corner_y + knee_h2 - (up_x0 - hood_x - lean_clear) / tan(lean) : block_h;
y_knee = max(block_h + fillet_r + 1, knee_min);
knee_c = [x_c, y_knee];
// place the neck so the ball centre lands at ball_y, straight out of the leaning face
t_root = (ball_y - neck_len * sin(neck_pitch) - up_d / 2 * sin(lean) - y_knee) / cos(lean);
neck_o = knee_c + t_root * up_u + up_d / 2 * up_n; // neck axis leaves the driver-side face here
ball_x = neck_o[0] + neck_len * cos(neck_pitch);
t_top = t_root + root_r + corner_r + 1;       // leaning part extends this far past the knee
up_top_o = knee_c + t_top * up_u + up_d / 2 * up_n;
up_top_i = knee_c + t_top * up_u - up_d / 2 * up_n;
upright_pts = [[up_x0, block_h - 1], [up_x1, block_h - 1], [up_x1, y_knee + knee_h2],
               up_top_o, up_top_i, [up_x0, y_knee - knee_h2]];

// Cable groove on the upright's outer face
cable_r = (cable_d + cable_play) / 2;
cable_mouth = cable_d - cable_snap;
cable_depth = sqrt(cable_r * cable_r - (cable_mouth / 2) * (cable_mouth / 2)); // bore centre inside the face
cable_z = beam_w / 2;
cable_s_top = t_root - root_r - 2;           // groove stops below the neck root (along the lean)
// the groove runs down until it leaves the part through the wedge's sloping front
cable_exit_x = up_x1 - cable_depth - cable_r;
cable_bottom = (cable_exit_x - bottom_x) / (up_x1 - bottom_x) * (block_h + bottom_drop) - bottom_drop - 1;

// Overall extents (raw, before mirroring)
part_len_x = max(ball_x + ball_r, up_x1);
part_len_y = max(up_top_o[1], up_top_i[1], ball_y + ball_r);
part_min_y = -bottom_drop;                   // the sloped bottom dips below the floor datum

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
sigma_upright = f_vert * (ball_x + cg_offset * cos(neck_pitch) - x_c) / z_rect(beam_w, up_d);
sigma_neck_lat = f_lat * lever_neck / z_round(neck_d);
bridge_span = neck_len - sqrt(ball_r * ball_r - neck_t * neck_t) - bridge_s0;
// Rocking: the phone tries to tip the wedge forward about the bottom's front edge. Only the
// hood contact BEHIND that edge pushes back, so its lever is short and the pad sees the load.
x_cg = ball_x + cg_offset * cos(neck_pitch);  // combined charger + phone centre of mass
pivot_x = min(bottom_x, floor_edge_x);        // a bottom longer than the ledge pivots on its edge
pad_x0 = back_x(block_h);                     // the dished top reaches back to here...
pad_x1 = min(pivot_x, hood_x);                // ...and only the part behind the pivot pushes back
pad_d0 = pivot_x - pad_x1;                    // pad's distance range from the pivot
pad_d1 = pivot_x - pad_x0;
// The rigid wedge squashes the pad in proportion to distance from the pivot, so pressure is
// triangular, peaking at the back edge: p(x) = k * (pivot_x - x).
pad_k = f_vert * (x_cg - pivot_x) / (block_w * (pow(pad_d1, 3) - pow(pad_d0, 3)) / 3);
pad_force = pad_k * block_w * (pad_d1 * pad_d1 - pad_d0 * pad_d0) / 2;
pad_mpa = pad_k * pad_d1;                     // peak, at the back edge of the pad

echo(block_h = block_h, block_w = block_w, back_face_w = back_face_w,
     plate_cut = plate_cut, top_cut = top_cut);
echo(knee_above_hood_underside = y_knee - notch_h, lean = lean, neck_pitch = neck_pitch,
     back_sag = back_sag);
echo(upright_from_bulge = up_x0 + tape_t, ball_from_bulge = ball_x + tape_t,
     ball_from_hood_lip = ball_x - hood_x, pivot_from_bulge = pivot_x + tape_t,
     ball_above_hood_underside = ball_y - notch_h, ball_above_hood_top = ball_y - notch_h - hood_t,
     ball_above_floor = ball_y);
echo(sigma_neck = sigma_neck, sigma_root = sigma_root, sigma_upright = sigma_upright,
     sigma_neck_lat = sigma_neck_lat, allow_mpa = allow_mpa, bridge_span = bridge_span,
     taper_angle = taper_angle);
echo(pad_force_design_N = pad_force, pad_force_static_N = pad_force / design_g, pad_mpa = pad_mpa,
     max_pad_mpa = max_pad_mpa);
echo(bbox_raw = [part_len_x, part_len_y - part_min_y, block_w]);
assert(block_bottom_d <= floor_depth + bottom_overrun, "block_bottom_d runs well past the ledge");
assert(pad_mpa <= max_pad_mpa,
       str("wedge too shallow at the bottom: the EPDM under the hood would see ", pad_mpa,
           " MPa peak in a 4g bump (limit ", max_pad_mpa, ") and the bracket would rock. ",
           "Raise block_bottom_d toward floor_depth."));

// Fit
assert(upright_gap >= hood_clear,
       str("upright would rub the hood lip: gap ", upright_gap, "mm < hood_clear ", hood_clear, "mm"));
assert(up_x0 - fillet_r >= hood_x + 1 - fudge,
       "upright fillet reaches under the hood lip: lower fillet_r or raise upright_gap");
assert(block_h >= 30, "notch_h too small for a wedge block");
assert(t_root >= root_r + fillet_r + 1,
       str("the ball is too low for this lean: the neck would start at the knee. Raise rise, ",
           "lower upright_lean, or measure hood_t (knee is ", y_knee - notch_h, "mm above the hood underside)"));
assert(back_sag < notch_h / 4, "back_sag looks too big — check the measurement");
assert(block_w >= beam_w + gusset, "notch too narrow for the upright + gusset");
assert(back_face_w >= min_tape_w,
       str("back face only ", back_face_w, "mm wide after the side cuts — check vent_return / cluster_return"));
assert(plate_cut[1] < bottom_x && top_cut[1] < bottom_x, "side return deeper than the wedge bottom");
assert(rip_y - rip_h / 2 > 0 && rip_y_from_top - rip_h / 2 > corner_r,
       "rip-cord groove runs into the rounded top edge of the back face");
// Ball joint
assert(neck_d <= ball_d - 6, "neck too fat for the socket fingers to wrap the ball");
assert(neck_len >= min_collar_room, "ball too close to the upright for the collar to swing");
assert(ball_flat <= 1.0 + fudge, "ball_flat > 1mm puts the flat under the socket's contact ring");
assert(neck_t > neck_r && neck_t < neck_r * td_k, "neck_v_depth out of range");
assert(neck_t >= root_r * sin(overhang_max), "root too fat: its flat underside would lose the V sides");
assert(keel_end >= root_len && bridge_s0 <= neck_start, "keel_end must sit inside the neck taper");
assert(bridge_s0 <= collar_min_s, "neck keel reaches where the socket collar swings");
assert(z_c - neck_t >= 2 * layer_height, "neck bridge too close to the plate");
assert(z_c + root_r <= beam_w, "neck root wider than the upright");
assert(neck_start > root_len && taper_angle <= max_taper,
       str("neck taper too abrupt (", taper_angle, "deg) — raise neck_start"));
assert(neck_start <= neck_len - s_junction, "neck_start is inside the ball");
assert(bridge_span <= max_bridge,
       str("neck bridge ", bridge_span, "mm > ", max_bridge, "mm: raise keel_end or shorten neck_len"));
// Strength (design case: design_mass_kg at design_g, hot, with safety factor)
assert(sigma_neck <= allow_mpa,
       str("neck overstressed: ", sigma_neck, " > ", allow_mpa, " MPa — raise neck_start or neck_d"));
assert(sigma_root <= allow_mpa, str("neck root overstressed: ", sigma_root, " MPa"));
assert(sigma_upright <= allow_mpa, str("upright overstressed: ", sigma_upright, " MPa — raise up_d"));
assert(sigma_neck_lat <= allow_mpa, str("neck overstressed sideways: ", sigma_neck_lat, " MPa"));
// Printer
assert(part_len_x + back_sag <= build_x - 2 * bed_margin && part_len_y - part_min_y <= build_y - 2 * bed_margin
       && block_w <= build_z, "bracket exceeds the X1C build volume");

// === MODULES ===

// Linear extrude with a stepped elephant-foot relief on the plate face (steps no steeper
// than overhang_max) and a stepped 45deg
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
    offset(r = corner_r) offset(delta = -corner_r) polygon(wedge_pts);
}

// Side profile of block + upright, with the inner corner filleted.
module profile_frame() {
    offset(r = corner_r) offset(delta = -corner_r)
        offset(r = -fillet_r) offset(delta = fillet_r)
            union() {
                polygon(wedge_pts);
                polygon(upright_pts);
            }
}

// Plan (looking down into the notch) of the block: X = depth, Y = lateral (print Z).
module profile_plan() {
    difference() {
        square([bottom_x, block_w]);
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

// Back-corner cuts, following the dished back up the full height of the block. Each corner
// is hulled slice-to-slice separately (hulling both together would fill the whole back).
module back_cut_slice(y, z0, dir, cut) {
    translate([back_x(y), y, 0]) rotate([90, 0, 0])
        linear_extrude(fudge, center = true) corner_cut_2d(z0, dir, cut);
}
module back_cuts() {
    y0 = part_min_y - 1;
    y1 = block_h + 1;
    for (c = [[0, 1, plate_cut], [block_w, -1, top_cut]])
        for (i = [0 : back_n - 1])
            hull() {
                back_cut_slice(y0 + (y1 - y0) * i / back_n, c[0], c[1], c[2]);
                back_cut_slice(y0 + (y1 - y0) * (i + 1) / back_n, c[0], c[1], c[2]);
            }
}

// Rip-cord groove straight across the back face (a vertical channel as printed): lay
// braided fishing line in it before taping; pulling the ends down saws through the tape.
module rip_groove() {
    translate([back_x(rip_y) - fudge, rip_y - rip_h / 2, -fudge])
        cube([rip_d + fudge, rip_h, block_w + 2 * fudge]);
}

// 2D teardrop in a neck cross-section (x = across the neck in the side-profile plane,
// y = print Z). Runs down to the plate (y = -zc) with sides <= overhang_max whatever r is.
module td_bed(r, zc) {
    intersection() {
        translate([-big / 2, -zc]) square([big, big]);
        hull() {
            circle(r);
            translate([0, -r * td_k]) square(fudge, center = true);
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
            translate([0, -r * td_k]) square(fudge, center = true);
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
    // gentle taper Ø14 -> Ø10 starts; the keel still reaches the plate out to keel_end
    hull() {
        slab(root_len) td_bed(root_r, z_c);
        slab(keel_end) td_bed(neck_r_at(keel_end), z_c);
    }
    // keel underside climbs to the bridge height, no steeper than overhang_max
    hull() {
        slab(keel_end) td_bed(neck_r_at(keel_end), z_c);
        slab(bridge_s0) td_flat(neck_r_at(bridge_s0), neck_t);
    }
    // taper finishes (no shoulder at the highest-stress section), flat underneath
    hull() {
        slab(bridge_s0) td_flat(neck_r_at(bridge_s0), neck_t);
        slab(neck_start) td_flat(neck_r, neck_t);
    }
    // slender neck: round where the socket sits, flat underneath (bridge)
    hull() {
        slab(neck_start) td_flat(neck_r, neck_t);
        slab(neck_len) td_flat(neck_r, neck_t);
    }
    translate([neck_len, 0, 0]) sphere(d = ball_dm);
}

// Snap-in cable groove down the upright's driver-side face: down the leaning part, round the
// knee, then down the vertical part until it leaves through the wedge's sloping front. Its
// roof is a pointed arch no steeper than overhang_max (support-free) with a sharp ridge.
module cable_run(p, ang, len) {
    translate([p[0], p[1], cable_z]) rotate([0, 0, ang]) translate([-cable_depth, 0, 0])
        rotate([90, 0, 0])
            linear_extrude(len)
                hull() {
                    circle(cable_r);
                    // tip sliver lies exactly on the arch's sides, so it adds no steeper facet
                    polygon([[-fudge, cable_r * td_k - fudge / tan(overhang_max)],
                             [fudge, cable_r * td_k - fudge / tan(overhang_max)],
                             [0, cable_r * td_k]]);
                }
}
module cable_groove() {
    knee_o = [up_x1, y_knee + knee_h2];        // outer knee corner
    if (cable_s_top > -knee_h2)
        cable_run(knee_c + cable_s_top * up_u + up_d / 2 * up_n, lean, cable_s_top + knee_h2 + 1);
    cable_run(knee_o + [0, 1], 0, knee_o[1] + 1 - cable_bottom);
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
    translate([-back_sag - clip_pad, part_min_y - clip_pad, 0])
        cube([part_len_x + back_sag + 2 * clip_pad, part_len_y - part_min_y + 2 * clip_pad,
              block_w + clip_pad]);
}

module bracket_raw() {
    intersection() {
        difference() {
            union() {
                chamfer_extrude(block_w) profile_block();
                chamfer_extrude(beam_w) profile_frame();
                lateral_gusset();
                translate([neck_o[0], neck_o[1], z_c]) rotate([0, 0, neck_pitch]) ball_mount();
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
                translate(neck_o) rotate(neck_pitch) {
                    hull() {
                        translate([-up_d / 2, 0]) circle(root_r);
                        translate([neck_len, 0]) circle(neck_r);
                    }
                    translate([neck_len, 0]) circle(ball_r);
                }
            }
            offset(r = gauge_border / 2)
                offset(delta = -gauge_border * 1.5) polygon(wedge_pts);
            translate([hood_x, block_h + fudge])
                polygon([[-tick_d, 0], [tick_d, 0], [0, -tick_d]]);
        }
        translate([part_len_x + back_sag + gauge_gap, 0])
            difference() {
                profile_plan();
                vent_z = beam_side == "left" ? 0 : block_w;
                translate([bottom_x - gauge_border - vent_mark_d / 2,
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
        translate([-tape_t, 0, -ctx_margin]) linear_extrude(ctx_w)       // bulging back face
            polygon(concat([for (i = [0 : back_n]) [back_x(notch_h * i / back_n), notch_h * i / back_n]],
                           [[-back_sag - ctx_wall, notch_h + hood_t], [-back_sag - ctx_wall, -ctx_margin],
                            [back_x(0), -ctx_margin]]));
        translate([back_x(0) - tape_t, 0, -ctx_margin]) linear_extrude(ctx_w)
            polygon([[0, 0], [floor_depth, -floor_drop], [floor_depth, -floor_drop - ctx_wall],
                     [0, -ctx_wall]]);
        translate([back_x(notch_h) - tape_t - ctx_wall, notch_h, -ctx_margin])
            cube([hood_over + ctx_wall, hood_t, ctx_w]);
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
