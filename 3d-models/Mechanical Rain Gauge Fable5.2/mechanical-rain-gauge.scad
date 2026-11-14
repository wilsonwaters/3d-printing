// === DESCRIPTION ===
// Mechanical Rain Gauge (Fable 5.2): a fully mechanical tipping-bucket rain gauge that totals rainfall in
// millimetres on four clock-dial pointers (x1000, x100, x10, x1 mm), like an old gas or electricity meter.
// It reads 0 to 9999 mm, resets to zero with one lift of a tab, and needs no electronics: the falling water
// does the counting.
//
// Physical context: lives outdoors on a level post or board, standing on three 20 mm feet (screws pass
// through the ears and feet) so the drains run free and the calibration screws stay reachable; rim about
// 1 m up, clear of splash and shelter. Rain falls into a 200 cm2 collector (159.6 mm orifice, the
// WMO / Hellmann standard size), runs down a 47-degree funnel and drips from a 6 mm nozzle into a see-saw
// bucket. Every 10 ml (0.5 mm of rain) the bucket tips, pours through the drain slots and swings an anchor
// that steps a 10-pin wheel half a pitch, so 20 tips turn the x1 pointer once (10 mm). Loads are grams.
//
// Design decisions:
//   - 200 cm2 orifice: 1 mm of rain = 20 ml, so the bucket volume is a round 10 ml and calibration is a
//     kitchen-scale job (200 ml poured slowly must read 10.0 mm).
//   - 0.5 mm per tip rather than the meteorological 0.2 mm: a 10 g charge has the torque to drive a printed
//     register; a 4 g one does not, reliably.
//   - Anchor-and-pin-wheel drive (an escapement run backwards) instead of a ratchet: no springs or pawls,
//     and the over-travel dwell means the stop screws can be adjusted without changing the step.
//   - Knife-edge pivots printed on the bed, a flat bucket floor and a solid ballast mast: the bucket
//     prints flat with no support and its tipping point is set by mass that the slicer cannot vary.
//   - Compound 10:1 stages (8:25 then 10:32, module 1) fit a 28 mm dial pitch inside the 160 mm skirt and
//     turn every pointer clockwise. Three gear planes (C, A, B from the front) keep neighbours apart.
//   - Each pointer rides its gear through a friction clutch (a cantilever in the gear web), so a heart cam
//     and roller behind every dial can return it to zero while the gears stay put. The cam is Archimedean
//     (2.9 mm of lift per radian everywhere) and the follower is a roller, so the push still turns the cam
//     at a friction coefficient of 0.35; a log-spiral cam or a plain pin would stall near zero.
//   - Collector printed rim-down in one piece: the funnel closes like a dome, the skirt and its register
//     window need no support, and nothing leaks at a joint.
//   - Every pinion stands on a shroud disc of its own tip radius: its teeth print on the disc instead of
//     over air, and the shroud overlaps the mating gear, which limits end float to 0.5 mm.
//
// How each turning part is held endways (all float about 0.5 mm):
//   rotors: cam against the dial plate in front, pointer hub against the dial card's boss behind it.
//   clusters: rotor collar in front, back-plate boss behind.  pin wheel: collar in front, thrust pad behind.
//   idlers 0 and 1: dial-plate post shoulder in front, a neighbouring big gear's web behind.
//   idler 2: back-plate post shoulder behind, the web of the x100 gear in front (its post cannot be longer).
//   rocker (bucket + anchor): the anchor hub between the back plate and the dial plate's centre post.
//   The bucket cannot lift out of its pivots once the collector is on: the nozzle stops the mast first.
//
// Assembly order (README has the full steps): build the register face down on the dial card and plate:
//   pointers and rotors, rollers and reset bar, gears from plane C back to B, anchor, pin wheel, back plate,
//   three screws. Push the bucket's neck through the back plate into the anchor hub (a 5-degree taper),
//   lower register and bucket onto the base together, two screws from below. To take the bucket out, lift
//   that unit off and pull the bucket backwards: the hub bears on the back plate, not on the pallets.
//
// Terminology -> code:
//   "collector / funnel / rim"   -> collector(), collector_area_cm2, funnel_slope, rim_wall_h, wall_t
//   "nozzle"                     -> nozzle_id, nozzle_z
//   "tipping bucket"             -> bucket(), bk_L, bk_W, bk_mast_t, bk_mast_h (ballast sets the tip volume)
//   "pivot / knife edge"         -> key2d(), vee2d(), knife_half, pivot_z
//   "calibration screws / stops" -> stop_x, boss_top_z, tilt_nom, tilt_min, tilt_max
//   "anchor / pallets"           -> anchor(), pallet1_pts(), pallet2_pts(), esc_* (and calc/escapement.py)
//   "pin wheel"                  -> units_wheel(), esc_rp, esc_n, esc_pin_d
//   "gears / gear train"         -> cluster(), idler(), z_p1, z_g1, z_p2, z_g2, gear_m, gear_backlash
//   "dials / pointers"           -> dial_card(), pointer(), dial_pitch, dial_face_r
//   "reset tab / reset bar"      -> slide(), roller(), rotor() (heart cam), cam_rmin, cam_rmax, reset_travel
//   "clutch"                     -> clutch_cut(), clutch_beam(), clutch_L, clutch_t, clutch_defl
//   "register frame"             -> back_plate(), dial_plate(), so_low, so_top, foot_x
//   "base / drains / ears"       -> base(), drain_slots2d(), ear_r, upstand_h
//   "leaf guard"                 -> leaf_guard(), guard_r, guard_spokes (optional; lifts out by its knob)
//   "feet"                       -> foot(), foot_h (one under each ear)
//
// Common modifications:
//   Different collector size     -> collector_area_cm2 (then rerun calc/bucket.py: tip volume = area x 0.5 mm)
//   Tip volume off after printing-> turn the two M3 calibration screws; if out of range change bk_mast_h
//                                   (about 0.25 ml per mm) and rerun calc/bucket.py
//   Stiffer / softer clutch      -> clutch_defl (0.4 to 0.8) or clutch_L; stiffer needs more reset force
//   Looser gears                 -> gear_backlash (0.2 to 0.3); do not add mesh_slack (contact ratio drops)
//   Any esc_* change             -> rerun calc/escapement.py, paste the new esc_table and esc_done_deg
//   Anchor or pallet shape       -> rerun calc/balance.py and retune cw_r / cw_a0 / cw_a1 to zero the bias
//   Taller funnel wall           -> rim_wall_h (collector must stay under 250 mm)
//
// Overall dimensions: 163 mm diameter (177 x 183 mm over the mounting ears) x 233 mm tall on its feet.
//   Largest prints: collector 163 x 163 x 211 mm, base 177 x 183 x 48 mm (Bambu X1C, 256 mm cube; both
//   fit the 220 mm area that clears the front-left exclusion zone).
// Coordinate system (assembly): X = right as you face the dials, Y = back, Z = up from the base floor.
// NOTE: every printable part is modelled in its print orientation with Z = 0 on the bed. The collector
//   prints rim-down; the dial plate, rotors, pointers and anchor print front-face-down (front_down()).
//
// Files: rg-lib.scad (gears, helpers), rg-register.scad (dial register), rg-wet.scad (bucket, base,
//   collector), rg-assembly.scad (poses, clash checks, contracts), calc/ (calibration and kinematics).

// === PRINT SETTINGS ===
// Material: PETG for every part (outdoor use, ductile clutch beams, good layer bond). White or a light
//   colour for the collector and base (UV, heat); any contrasting colour for the pointers.
// Layer Height: 0.2 mm; 0.16 mm for plate_register (gears, rotors, pointers, rollers).
// Walls/Perimeters: 4 (1.8 mm). The 1.8 mm collector wall is exactly four perimeters.
// Infill: 20 % gyroid for base, back_plate, dial_plate, slide, dial_card.
//   100 % for bucket and anchor (their mass and balance set the calibration) and for plate_register.
// Supports: None required. Every overhang is 45 degrees or less (funnel 43, knife edges 30); the only
//   bridges are 6.5 mm screw recesses, 2.8 mm pilot holes and the 2.5 mm clutch-pocket roofs. The funnel's
//   rain side is the overhang side, so it prints slightly rough: rub it smooth if drops cling.
// Orientation: as modelled (Z = 0 on the bed) for every part.
// Notes:
//   - collector: prints rim-down on a 0.9 mm rim, 211 mm tall. Use an 8 mm outer brim, slow outer walls,
//     and trim the brim flush so the rim stays sharp.
//   - dial_card: change filament at 1.2 mm (layer 7) so the raised numerals print in a contrasting colour.
//   - bucket: knife edges print as a single first-layer line; no brim there, and do not sand them.
//   - Dry PETG (65 C, 4-6 h) before the gears and the collector; stringing between gear teeth must be cleaned.
//   - Hardware: M3 x 10 pan head x 3 (dial plate), M3 x 10 countersunk x 2 (register feet),
//     M3 x 20 socket head cap x 2 (calibration stops, 2.5 mm hex key), M3 x 8 pan head x 3 (collector skirt),
//     3 mounting screws about 4 x 40 mm (they pass through the 20 mm feet).

// === PRINTER ===
// Printer: Bambu Lab X1 Carbon, 0.4 mm nozzle. Build volume 256 x 256 x 256 mm.

// === PARAMETERS ===
// Printer settings
nozzle_diameter = 0.4;
layer_height = 0.2;
build_x = 256; build_y = 256; build_z = 256;
bed_free = 220;            // centred square that clears the X1C front-left exclusion zone

// --- Measurement ---
collector_area_cm2 = 200;  // WMO / Hellmann standard orifice area (diameter 159.6 mm)
tip_mm = 0.5;              // rainfall per bucket tip; 20 tips = one turn of the x1 pointer (10 mm)

// --- Fits (PETG, measured on a Bambu X1C; SKILL Rule 8) ---
hole_comp = 0.30;          // printed holes come out this much small
fit_press = -0.08;         // press fit allowance
fit_run = 0.30;            // free-running allowance
tolerance = 0.3;           // sliding clearance between mating PETG parts

// --- Gears (involute, 20 degree) ---
gear_m = 1.0;              // module: 1.0 is the smallest that prints reliably with a 0.4 nozzle
gear_pa = 20;
gear_backlash = 0.20;      // tooth thinning per gear (all the running clearance: centre distances are standard)
gear_t = 3.5;              // face width of every gear
gear_gap = 1.0;            // axial gap between gear planes: 0.5 shroud under each pinion + 0.5 running clearance
shroud_t = 0.5;            // disc under each pinion (tooth tips' radius): the teeth print on it, and it limits end float
z_p1 = 8;  z_g1 = 25;      // stage 1: dial pinion -> idler gear   (3.125 : 1)
z_p2 = 10; z_g2 = 32;      // stage 2: idler pinion -> next dial   (3.2 : 1)   product = 10 exactly
x_pin = 0.5;               // profile shift of both pinions (the gears get -x_pin, centre distance stays standard)
pin_short = 0.25;          // pinion tip shortening so the tip land stays printable
mesh_slack = 0;             // extra centre distance (any more drops the contact ratio below 1.2)

// --- Register layout (front view: x right, y up from the base floor) ---
dial_pitch = 28;           // spacing of the four dial arbors
pivot_z = 36;              // height of the bucket knife-edge pivot above the base floor
arbor_d = 4.0;             // rotor arbor (carries the gear clusters)
post_d = 4.0;              // idler posts
stub_d = 4.0;              // pointer stub = front journal of each rotor (small: journal friction resists the reset)
collar_d = 8.0;            // rotor collar that spaces the cluster off the cam

// --- Layer stack, measured forward from the back plate's rear face (f) ---
bp_t = 2.4;                // back plate
disc_t = 2.4;              // pin wheel disc (holds the x1 clutch beam)
pin_h = 4.5;               // pin height = pallet depth
anchor_t = 2.5;            // anchor plate
slide_t = 1.6;             // reset bar
cam_t = 3.5;               // heart cam
dp_t = 2.4;                // dial plate
card_t = 1.2;              // dial card (numerals stand 0.6 proud of it)
card_relief = 0.6;
ptr_t = 2.0;               // pointer

// --- Escapement: 10-pin wheel on the x1 cluster, driven by an anchor on the bucket ---
esc_n = 10;                // pins; each tip moves the wheel half a pitch
esc_rp = 21;               // pin circle radius
esc_pin_d = 4.0;
esc_span = 126;            // wheel angle between the two pallets = 3.5 pin pitches
esc_c = 0.6;               // pallet-to-pin clearance when locked
esc_blade = 4.5;           // lead-in blade length, pallet 2 (locking face inside)
esc_blade1 = 3.5;          // pallet 1 (locking face outside): shorter, so its tip clears the wheel sleeve
esc_ramp = 7.0;            // impulse ramp length
esc_dwell = 5.5;           // dead (locking) length for over-travel
esc_lead = 1.5;            // blade tip past the pin centre at mid-swing, pallet 2
esc_lead1 = 0.5;           // same for pallet 1 (blade - lead is equal for both, so the push timing matches)
esc_tip_w = 1.0;           // blade thickness
// Pose table from calc/escapement.py for the parameters above: [stroke, anchor_deg, wheel_advance_deg]
esc_table = [[0,-21,0.425], [0,-18,0.425], [0,-15,0.425], [0,-12,0.425], [0,-9,0.425], [0,-6,0.425], [0,-3,0.425],
             [0,0,0.425], [0,3,0.425], [0,6,3.305], [0,9,8.825], [0,12,14.045], [0,15,17.525], [0,18,17.525], [0,21,17.525],
             [1,18,17.525], [1,15,17.525], [1,12,17.525], [1,9,17.525], [1,6,17.525], [1,3,17.525], [1,0,17.525],
             [1,-3,17.525], [1,-6,21.385], [1,-9,27.185], [1,-12,32.445], [1,-15,35.545], [1,-18,35.585], [1,-21,35.585]];

// --- Tipping bucket (flat see-saw with a heavy mast; printed solid) ---
tilt_nom = 20;             // rest tilt for 10 ml per tip (set by the two calibration screws)
tilt_min = 18.5; tilt_max = 21.5;   // calibration range the mechanism accepts
bk_L = 48;                 // floor half-length (pivot to pouring edge)
bk_W = 36;                 // inside width along the pivot axis
bk_floor = 1.6;
bk_wall = 1.35;            // end walls (3 perimeters)
bk_mast_t = 6.0;           // divider / ballast mast thickness
bk_mast_h = 48;             // mast height above the floor
bk_end_h = 4;              // end wall height at the pouring edge
bk_end_peak = 26;          // end wall height at the mast
knife_half = 30;           // knife edge half angle (degrees from vertical)
knife_r = 0.3;             // edge radius (what a first layer really prints)
key_w = 6.0;               // neck / trunnion width
key_h = 9.0;               // neck / trunnion height above the edge
key_taper = 5;             // taper (degrees per side) of the neck where the anchor seats
stop_x = 32;               // calibration screw distance from the pivot

// --- Reset (heart cam + roller) ---
cam_rmin = 4.0;            // heart cam radius at the cusp (pointer at 0)
cam_rmax = 13.0;           // radius at the tip (pointer at 5); Archimedean in between: constant lift per degree
roller_d = 8.0;
roller_post_d = 2.5;       // small post under a big roller keeps the roller's own friction low
reset_mu = 0.35;           // friction coefficient the reset must still work at (dry PETG on PETG)
roller_gap = 1.0;          // roller clear of the cam tip at rest

// --- Collector and base ---
wall_t = 1.8;              // collector wall (4 perimeters)
rim_wall_h = 35;           // vertical wall above the funnel (splash guard)
funnel_slope = 47;         // funnel slope from horizontal (WMO: at least 45)
funnel_t = 1.8;            // 4 perimeters
nozzle_id = 6.0;
nozzle_len = 8;
nozzle_z = 87;             // nozzle tip height above the base floor
base_t = 3.0;
upstand_h = 8;
ear_r = 93; ear_hole = 4.5;

// --- Pose (assembly and clash checks) ---
pose_stroke = 0;           // 0: bucket tipping right-side-down, 1: back again
pose_anchor = -20;         // anchor angle in the escapement frame (see esc_table)
pose_count_mm = 0;         // register reading shown in the assembly
pose_reset = 0;            // 0 rest .. 1 reset bar fully up

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
fudge = 0.01;
ef_chamfer = 0.4;
$fn = $preview ? 32 : 64;

orifice_d = sqrt(4 * collector_area_cm2 * 100 / PI);
tip_volume_ml = collector_area_cm2 * tip_mm / 10;
tips_per_rev = 2 * esc_n;

// gears
a1 = (z_p1 + z_g1) * gear_m / 2 + mesh_slack;     // dial -> idler centre distance
a2 = (z_p2 + z_g2) * gear_m / 2 + mesh_slack;     // idler -> next dial
ra_p1 = gear_ra(z_p1, x_pin, pin_short); ra_g1 = gear_ra(z_g1, -x_pin);
ra_p2 = gear_ra(z_p2, x_pin, pin_short); ra_g2 = gear_ra(z_g2, -x_pin);
idler_ang = acos((a1 * a1 + dial_pitch * dial_pitch - a2 * a2) / (2 * a1 * dial_pitch));

// escapement geometry (escapement frame: anchor pivot at origin, wheel centre on +x)
esc_psi = 90 - esc_span / 2;                        // 27 degrees
esc_d = esc_rp / sin(esc_psi);                      // pivot to wheel centre
esc_lt = esc_d * cos(esc_psi);                      // pivot to pallet (tangent length)
esc_w = 2 * esc_rp * sin(180 / esc_n) - esc_pin_d - esc_c;   // pallet width
esc_len = esc_blade + esc_ramp + esc_dwell;
esc_len1 = esc_blade1 + esc_ramp + esc_dwell;

// register positions (front view)
dial_x = [1.5 * dial_pitch, 0.5 * dial_pitch, -0.5 * dial_pitch, -1.5 * dial_pitch];   // x1, x10, x100, x1000
dial_z = pivot_z + sqrt(esc_d * esc_d - dial_x[0] * dial_x[0]);
pw_ang = atan2(dial_z - pivot_z, dial_x[0]);        // direction pivot -> pin wheel
function dial_pos(i) = [dial_x[i], dial_z];
function idler_pos(i) = dial_pos(i) + a1 * [-cos(idler_ang), sin(idler_ang)];   // idler i sits between dial i and i+1, above the row
pivot_pos = [0, pivot_z];

// layer stack (f = distance in front of the back plate's rear face)
f_disc = bp_t + 0.5;
f_pins = f_disc + disc_t;
f_anchor = f_pins + pin_h + 0.5;                    // rear face of the anchor plate
f_B = f_anchor + anchor_t + 1.0;                   // 1 mm so a drifting idler never rubs the anchor
f_A = f_B + gear_t + gear_gap;
f_C = f_A + gear_t + gear_gap;
f_slide = f_C + gear_t + 0.4;
f_cam = f_slide + slide_t + 0.3;
f_dp = f_cam + cam_t + 0.3;                         // rear face of the dial plate
f_card = f_dp + dp_t;
f_ptr = f_card + card_t + card_relief + 0.5;
reg_depth = f_ptr + ptr_t;

// reset cam
cam_k = (cam_rmax - cam_rmin) / PI;                 // lift per radian = the cam's torque arm for the roller's push
roller_rest = cam_rmax + roller_d / 2 + roller_gap;         // roller centre below the dial axis at rest
function cam_r(a) = cam_rmin + cam_k * abs(a) * PI / 180;        // a = angle from the cusp, -180..180
// torque arm left after friction (roller on its post, rotor in its journals) at cam radius r, in mm per newton of push
function reset_arm(r) = cam_k - reset_mu * (roller_post_d / roller_d) * r - reset_mu * (stub_d + hole_comp + fit_run) / 2;

// collector
orifice_r = orifice_d / 2;
skirt_ro = orifice_r + wall_t;
funnel_h = (orifice_r - nozzle_id / 2 - funnel_t) * tan(funnel_slope);
funnel_top_z = nozzle_z + nozzle_len + funnel_h;    // where the cone meets the wall
rim_z = funnel_top_z + rim_wall_h;                  // collector rim height above the base floor
reg_front_y = -58;                                  // y of the dial plate's front face
bp_rear_y = reg_front_y + f_card;                   // y of the back plate's rear face
notch_half = 57.5; notch_top = 79;

include <rg-lib.scad>
include <rg-register.scad>
include <rg-wet.scad>
include <rg-assembly.scad>

// === ASSEMBLY / RENDER ===
P_view = [pose_stroke, pose_anchor, pose_count_mm, pose_reset];
part = "all"; // "all", "assembly_open", "section", "view_train", "view_escapement", "base", "collector", "bucket", "anchor", "back_plate", "dial_plate", "dial_card", "units_wheel", "cluster", "idler", "rotor_long", "rotor_short", "pointer", "slide", "roller", "leaf_guard", "foot", "plate_register", "plate_extras", "clash_rest", "clash_handover", "clash_push", "clash_end", "clash_return", "clash_reset", "clash_esc_a", "clash_esc_b", "clash_esc_c", "clash_esc_d", "clash_guard", "check_pair"
if (part == "all") assembly(P_view);
if (part == "assembly_open") assembly(P_view, [4]);                                   // collector removed
if (part == "section") difference() { assembly(P_view); translate([0, -200, -50]) cube([200, 400, 400]); }
if (part == "view_train") assembly(P_view, [1, 2, 3, 4, 18, 19, 20, 21]);                // gear train, cams and reset bar seen from the front
if (part == "view_escapement") assembly(P_view, [1, 2, 3, 4, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]);
if (part == "base") base();
if (part == "collector") collector();
if (part == "bucket") translate([0, 0, knife_r]) bucket();
if (part == "anchor") anchor();
if (part == "back_plate") back_plate();
if (part == "dial_plate") dial_plate();
if (part == "dial_card") dial_card();
if (part == "units_wheel") units_wheel();
if (part == "cluster") cluster();
if (part == "idler") idler();
if (part == "rotor_long") rotor(collar_long);
if (part == "rotor_short") rotor(collar_short);
if (part == "pointer") pointer();
if (part == "slide") slide();
if (part == "roller") roller();
if (part == "leaf_guard") leaf_guard();
if (part == "foot") foot();
if (part == "plate_register") plate_register();
if (part == "plate_extras") { for (k = [0:2]) translate([k * 26, 0, 0]) foot(); translate([26, 36, 0]) leaf_guard(); }   // three feet and the leaf guard
// whole-assembly pairwise interference at six poses: [stroke, anchor angle, reading in mm, reset 0..1]
if (part == "clash_rest") clash_all([0, -21.5, 0, 0]);
if (part == "clash_handover") clash_all([0, 0, 1234.5, 0]);
if (part == "clash_push") clash_all([0, 9, 2718, 0]);
if (part == "clash_end") clash_all([0, 21.5, 6789.3, 0]);
if (part == "clash_return") clash_all([1, -9, 4321, 0]);
if (part == "clash_reset") clash_all([1, -21.5, 0, 1]);
// escapement alone at the in-between angles
if (part == "clash_esc_a") clash_esc([0, 6, 0, 0]);
if (part == "clash_esc_b") clash_esc([0, 12, 0, 0]);
if (part == "clash_esc_c") clash_esc([1, -6, 0, 0]);
if (part == "clash_esc_d") clash_esc([1, -12, 0, 0]);
if (part == "clash_guard") clash_guard();
// diagnostics: one pair of elements at one pose (used by calc/find-clash.sh)
ci = 0; cj = 1; cP = [0, -21, 0, 0];
if (part == "check_pair") intersection() { elem(ci, cP); elem(cj, cP); }
