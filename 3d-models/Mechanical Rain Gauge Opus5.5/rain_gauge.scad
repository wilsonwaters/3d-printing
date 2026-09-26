// === DESCRIPTION ===
// Mechanical Rain Gauge (Opus 5.5): a fully mechanical tipping-bucket rain gauge with an
// "old style" four-dial clock register like an electricity/water meter. Rain falls into a
// standard 200 cm^2 (Ø159.6 mm, Hellmann / WMO size) sharp-rimmed collector, runs down a 50°
// funnel onto a see-saw tipping bucket that tips every 10 mL (0.5 mm of rain), and every
// bucket CYCLE (two tips = 20 mL = exactly 1.0 mm of rain) a gravity pawl on the bucket arm
// pushes a face ratchet on the units arbor one tooth. Four pointer dials (×1000, ×100, ×10,
// ×1 mm), geared 10:1 like a power meter (adjacent dials turn opposite ways), read 0–9999 mm.
// A push-plunger on the right side resets every pointer to 0 (heart cams + hammer fingers).
//
// Physical context: lives outdoors on a post top (rim 0.3–1 m above ground, dead level). The
// only loads are water weight (~30 g) and the reset push (<5 N). No springs in the counting
// path: pawls work by gravity; the hammers, lock and slide return are PETG flexures.
//
// Design decisions:
//   - 200 cm^2 orifice: WMO-No.8 recommends 200–500 cm^2 and 200 cm^2 is the most common national
//     gauge in the world. 1 mm of rain = exactly 20 mL, which makes calibration trivial.
//   - 0.5 mm per tip (as JMA and the fully-mechanical Perin R05 recorder) because a mechanical
//     register needs the energy of a bigger tip; counting ONE per cycle (2 tips) cancels unequal
//     tips and small tilt to first order and gives a robust single-acting ratchet.
//   - Bucket axle along X (bucket rocks front/back) resting ROLLING on flat seats: +2 % tip error
//     from friction instead of +14 % for a pin in a hole (modelled). Stop screws = calibration.
//   - Crossed-axis drive: the register arbors run front-to-back (Y); the bucket arm moves in YZ, so
//     the ratchet is a FACE ratchet (teeth on its rear face) and both pawls pivot on X-parallel
//     pins – they stay in the arm's plane at every bucket angle.
//   - Ratchet count is grid-locked to the pawl's top position (stroke = 1.74 teeth), so a small
//     back-drag or forward nudge self-corrects next cycle; the click pawl limits back-drag.
//   - Reset: pointer+heart assemblies are friction-fit on their arbors, so only the pointers slip.
//     A V-lock drops into a star on the units arbor BEFORE the hammers touch so the train can't be
//     dragged. Hammers are narrow noses on compliant fingers (a flat hammer jams within ±17° of the
//     heart's dead point; the nose within ~2°, simulated). Pointers can always be nudged by hand.
//   - Every part is modelled in its print orientation, support-free, walls in 0.45 mm lines.
//
// Terminology → code:
//   "collector / rim / funnel"   → rim_d, splash_h, funnel_deg, collector()
//   "nozzle" (drip tube)          → nozzle_*, nozzle()        "leaf screen" → screen()
//   "bucket" (tipper)             → bk_*, bucket(), tip volume → tip_volume_ml()
//   "stop screws" (calibration)   → stop_*, housing_base()
//   "drive arm / drive pawl"      → arm_*, arm(), drive_pawl()   "click pawl" → click_pawl()
//   "ratchet" (face ratchet)      → rt_*, ratchet_U()
//   "dials / register"            → dial_*, gear params gm/zp/zw, wheel_T/H/K(), pinion_U()
//   "front frame / back plate"    → ff_*, bp_*, front_frame(), back_plate()
//   "dial face" (numerals)        → dial_face()      "pointers" → pointer()
//   "hearts" (reset cams)         → ht_*, heart()    "hammer fingers / slide" → sl_*, slide()
//   "lock star / lock"            → star_*, lock_star(), lock flexure in front_frame()
//   "reset plunger"               → plunger()        "housing" → housing_base(), housing_lid()
//   "bezel / window"              → bezel()
//
// Common modifications:
//   Tip size            → bk_theta0 (0.5 mL per degree) or the stop screws; keep tip_volume_ml()
//                         = area×0.5 mm (asserted within ±5 %).
//   Collector size      → area_cm2 (also scales tip target); shrink_pct for your PETG.
//   Gear fit            → wheel_thin / pin_thin (backlash); never open the centre distance.
//   Pointer grip        → grip_interf (0.2–0.35 mm); reset stroke → sl_rest_clear.
//   Fit a different printer → bed; the housing (222 × 180 mm) is the largest part.
//
// Overall: ~222 W × 186 D × ~260 H mm assembled (housing 222 × 186 × 100, collector Ø172 × 146).
// Coordinate system (assembly): X right (seen from the front), Y toward the BACK, Z up, origin =
//   collector axis at ground level. The dials face −Y.
// NOTE: every part() is modelled in PRINT orientation (Z = build plate normal). assembly()
//   places them in use orientation.

// === PRINT SETTINGS ===
// Material: PETG (outdoor: Tg ~80 °C, OK UV, ductile flexures). White/light colours for UV.
//   Dry filament 65 °C 4–6 h. Stainless rods/screws (plain steel rolling seats pit outdoors).
// Layer height: 0.2 mm structural parts; 0.12 mm gears, hearts, ratchet, star, pawls, pointers.
// Walls: 4 perimeters (1.8 mm) default; housing/collector walls are 5–6 lines as modelled.
// Infill: 20 % gyroid; 100 % for pawls, hearts, pointers, star, slide, gears (small parts).
// Supports: NONE required – overhangs ≤ 45°, horizontal holes are teardrops, funnel is 50°.
// Orientation (per part, as modelled): collector rim-UP (skirt + nozzle socket on bed, the
//   critical rim prints last – no elephant foot); housing base upright; lid flat; bucket upright
//   on its flat floor; gears/hearts/pointers/plates flat; dial face numerals UP (colour change
//   at the numeral layer for black-on-white).
// Notes: Slicer elephant-foot compensation 0.15 mm. PTFE dry lube on hearts, pawls, rolling seats.

// === PARAMETERS ===
part = "assembly";      // assembly | collector | screen | nozzle | housing_base | housing_lid |
                        // bezel | plunger | bucket | arm | drive_pawl | click_pawl | front_frame |
                        // back_plate | dial_face | slide | wheel_T | wheel_H | wheel_K | pinion_U |
                        // ratchet_U | lock_star | heart | pointer | small_parts | test_coupons
explode   = 0;          // assembly: pull the parts apart (mm)
pose_tip  = 28;         // assembly: bucket angle, + = front compartment raised (filling), ±bk_theta0
reset_pos = 0;          // assembly: reset slide travel 0..1 (fraction of stroke)
show_shell = true;      // assembly: show housing, lid, bezel, collector
cut_x      = 999;       // assembly: hide everything with x > cut_x (section view), 999 = off

// Printer (Bambu Lab X1C, 0.4 mm nozzle)
nozzle   = 0.4;
layer_h  = 0.2;
bed      = [256, 256, 256];
bed_excl = [18, 28];    // X1/P1 front-left cutter exclusion (x, y)

// Fits – measured PETG / X1C: bore = nominal + hole_comp + allowance
hole_comp = 0.30;
fit_press = -0.08;      // interference – gears on arbors, pins
fit_bear  = 0.15;       // arbor turning in a plate
fit_run   = 0.30;       // free running (pawls, sleeves)
rod_d     = 3.0;        // stainless rod: arbors, bucket axle
m3_nut_af = 5.5;
m3_nut_t  = 2.4;
m3_head_d = 5.6;
m3_head_h = 3.0;

// Collector
area_cm2    = 200;      // orifice area (WMO 200–500; 200 = Hellmann, most common worldwide)
shrink_pct  = 0.3;      // PETG shrink compensation on the rim diameter (%) – measure & adjust
splash_h    = 50;       // vertical splash wall above the funnel
funnel_deg  = 50;       // funnel slope from horizontal (40° overhang when printed rim-up)
throat_d    = 8;        // funnel outlet bore (nozzle plugs in)
throat_stub = 10;       // throat tube: nozzle plugs in below, leaf screen spigot above
col_tabs    = 3;        // screw tabs at the skirt foot

// Bucket (see tip_volume_ml(); values chosen with the statics model in the README)
z_b          = 40;      // bucket axle height
bk_L         = 34;      // compartment length (divider face → open end)
bk_W         = 44;      // inside width (along the axle)
bk_vb        = -8;      // floor top relative to the axle centre
bk_Hd        = 30;      // divider top above the axle
bk_side_h    = 6;       // side-wall height at the open ends above the floor
bk_theta0    = 28;      // rest angle each side (set by the stop screws)
bk_ballast_g = 6;       // printed ballast block on the divider top (raises CG)
tip_mm       = 0.5;     // rain per tip

// Drive
arm_r      = 14;        // drive-pawl pivot radius from the bucket axle
pawl_rise  = 12;        // pawl pivot → ratchet contact height at mid stroke
rc_mid     = 10.8;      // contact radius on the face ratchet at mid stroke
pawl_lean  = 4.5;       // pawl tip ahead (−Y) of its pivot at mid stroke (gravity preload)
click_backlash = 0.2;   // click pawl clearance behind a tooth at grid positions (teeth)

// Register
dial_pitch = 44;
gm   = 1.0;             // gear module
zp   = 8;   zw = 80;    // 1:10 single-mesh stages (Westinghouse used 14:140)
xp   = 0.55; xw = -0.55;// profile shift (x1+x2 = 0 keeps the centre distance at 44.0)
pa   = 20;              // pressure angle
pin_ra     = 5.3;       // pinion tip radius (tip land ≥ 0.4)
pin_thin   = 0.05;      // tooth thinning for backlash (circular, at pitch)
wheel_thin = 0.25;
gface = 4;  ggap = 1;   // gear face width, gap between gear planes

// Reset
ht_r0   = 3.0;          // heart cusp radius (bottom of the notch)
ht_rmax = 18;           // heart tip radius
ht_tip  = 168;          // tip angle from the notch (asymmetric: dead point off the units steps)
ht_t    = 3.2;
notch_psi = 55;         // notch flanks: steep log spiral (pressure angle) = self-centring 70° V
notch_a   = 10;         // steep notch flank span each side (deg)
notch_blend = 6;        // growth-rate blend from the notch flank into the main flank (deg, no corner)
mu_design = 0.35;       // PETG/PETG with PTFE dry lube (dry can reach 0.45 – lube the hearts)
nose_r    = 0.6;        // hammer nose radius
nose_e    = 0;          // nose path passes through the arbor axis (push along the notch axis)
sl_rest_clear = 1.5;    // nose clearance outside rmax at rest (lock engages within ~1.2 mm)
sl_overtravel = 1.5;    // finger preload when seated
grip_interf   = 0.25;   // pointer grip finger interference on the arbor
star_n  = 10;  star_r = 7;  star_depth = 2.2;  star_t = 3.0;  star_v = 60;   // lock star slots

// === DERIVED CONSTANTS ===
nozzle_diameter = nozzle;  layer_height = layer_h;  // (skill naming)
ew    = nozzle*1.125;               // 0.45 extrusion width
extrusion_width = ew;
w2 = 2*ew; w3 = 3*ew; w4 = 4*ew; w5 = 5*ew; w6 = 6*ew;
fudge = 0.01;
ef    = 0.4;                        // elephant-foot chamfer
ef_chamfer = ef;
tolerance  = fit_run + hole_comp;   // sliding/running clearance on a bore (PETG)
$fn   = $preview ? 40 : 72;
RHO   = 1.27e-3;                    // PETG g/mm^3
RHO_W = 1.0e-3;                     // water g/mm^3
G     = 9.81e-3;                    // N per gram

bore_press = rod_d + hole_comp + fit_press;   // 3.22
bore_bear  = rod_d + hole_comp + fit_bear;    // 3.45
bore_run   = rod_d + hole_comp + fit_run;     // 3.60
m3_clear   = 3.0 + hole_comp + 0.2;           // 3.5
m3_tap     = 2.5;
m3_run     = 3.0 + hole_comp + fit_run;       // pawl pivots on M3 screws

// collector
rim_d_nom  = 2*sqrt(area_cm2*100/PI);         // 159.58
rim_d      = rim_d_nom*(1 + shrink_pct/100);
rim_r      = rim_d/2;
rim_wall   = w5;
col_od     = rim_d + 2*rim_wall;
funnel_h   = (rim_r - throat_d/2)*tan(funnel_deg);
z_cone_top = throat_stub + funnel_h;          // print-frame height where the cone meets the wall
col_h      = z_cone_top + splash_h;
throat_bore= throat_d + hole_comp + fit_press;
area_mm2   = PI*rim_d_nom*rim_d_nom/4;
tip_target_ml = area_mm2*tip_mm/1000;          // 10.0 mL

// register geometry
dial_x   = [for (i = [0:3]) (i - 1.5)*dial_pitch];   // K, H, T, U
dial_dir = [-1, 1, -1, 1];                           // +1 = clockwise seen from the front
dial_lbl = ["1000", "100", "10", "1"];
dial_z   = z_b + pawl_rise;                          // 52
ctr_dist = gm*(zp + zw)/2;                           // 44
rp_p = zp*gm/2;  rb_p = rp_p*cos(pa);  rf_p = rp_p - gm*(1.25 - xp);
rp_w = zw*gm/2;  rb_w = rp_w*cos(pa);  rf_w = rp_w - gm*(1.25 - xw);  ra_w = rp_w + gm*(1 + xw);
dial_d   = 40;

// Y stack (use frame, +Y = back). Back plate sits just in front of the bucket chamber.
ch_front_in = -40;                                   // chamber front wall inner face
ch_wall     = w6;
y_bp_back   = ch_front_in - ch_wall - 0.3;           // back plate stops 0.3 mm off the chamber wall
bp_t        = 3.6;
y_bp_front  = y_bp_back - bp_t;                      // -47.6
function gp_back(k)  = y_bp_front - ggap - (3 - k)*(gface + ggap);   // k = 1..3 (1 = front plane)
function gp_front(k) = gp_back(k) - gface;
y_ff_back   = gp_front(1) - ggap;                    // -63.6
ff_t        = 3.6;
y_ff_front  = y_ff_back - ff_t;                      // -67.2
y_star_back = y_ff_front - 0.4;
y_star_front= y_star_back - star_t;
y_ht_back   = y_star_front - 0.4;
y_ht_front  = y_ht_back - ht_t;
y_dial_back = y_ht_front - 0.4;
dial_t      = 2.4;
num_h       = 0.6;                                   // raised numerals (colour change)
y_dial_front= y_dial_back - dial_t;
ptr_t       = 1.8;
y_ptr_back  = y_dial_front - num_h - 0.6;
y_ptr_front = y_ptr_back - ptr_t;
y_base_front= y_dial_front - 0.4;                    // housing base front face
bz_depth    = 8.6;                                   // bezel depth in front of the base
y_front     = y_base_front - bz_depth;               // overall front (bezel face)

// housing
hs_wall   = w6;
hs_in_x   = dial_x[0] - ra_w - 1.8;                  // inside half width set by the K wheel sweep
hs_half_w = -hs_in_x + hs_wall;
hs_back_r = 100;
hs_h      = 97;                                      // base wall height (lid on top)
lid_t     = 3;
floor_t   = 2.4;
pl_z0     = 7.5;                                     // movement plates' bottom edge (bezel sill below)
pl_z1     = hs_h - 2;                                // movement plates' top edge

// ratchet & drive
rt_n = 10;  rt_r_in = 8.5;  rt_r_out = 14.5;  rt_h = 2.2;  rt_base = 2.0;
rt_pitch_ang  = 360/rt_n;
stroke_S      = 2*arm_r*sin(bk_theta0);
rt_stroke_ang = 2*atan((stroke_S/2)/rc_mid);
sigma         = rt_stroke_ang/rt_pitch_ang;          // pawl stroke in teeth
rc_end        = sqrt(rc_mid*rc_mid + (stroke_S/2)*(stroke_S/2));
y_rt_face     = -arm_r - pawl_lean;                  // ratchet tooth tips (face) plane
x_contact     = dial_x[3] - rc_mid;                  // drive-pawl contact line

// heart
ht_ks = tan(notch_psi);                              // notch flank growth
// ln r grows at ht_ks for notch_a, blends linearly to the main rate over notch_blend, then
// holds it to the tip at ht_rmax (solved so each flank lands exactly on ht_rmax)
function ht_kmain(span) = (ln(ht_rmax/ht_r0) - ht_ks*(notch_a + notch_blend/2)*PI/180)
                          /((span - notch_a - notch_blend/2)*PI/180);
ht_k1 = ht_kmain(ht_tip);
ht_k2 = ht_kmain(360 - ht_tip);
function ht_lnr(b, km) = let(r = PI/180, a1 = notch_a, ab = notch_blend)
    b <= a1 ? ht_ks*b*r :
    b <= a1 + ab ? ht_ks*a1*r + ht_ks*(b - a1)*r - (ht_ks - km)*pow((b - a1)*r, 2)/(2*ab*r) :
    ht_ks*(a1 + ab/2)*r + km*(ab/2)*r + km*(b - a1 - ab)*r;
ht_r1 = ht_r0*exp(ht_lnr(notch_a, ht_k1));           // radius where the steep notch flank ends
ht_psi_min = min(atan(ht_k1), atan(ht_k2));          // main flank pressure angle (deg)
r_seat   = ht_r0 + nose_r/sin(90 - notch_psi);       // nose centre radius when seated (≈)
x_seat   = sqrt(r_seat*r_seat - nose_e*nose_e);
notch_ang= atan2(nose_e, x_seat);                    // notch direction at zero (front view)
ptr_off  = 90 - notch_ang;                           // pointer relative to the notch
x_nose_rest = ht_rmax + nose_r + sl_rest_clear;
reset_stroke = x_nose_rest - x_seat + sl_overtravel;

// === FUNCTIONS ===
function inv_r(a) = tan(a) - a*PI/180;               // involute, a in deg → rad
// half tooth angle (deg) at radius r
function g_half(z, m, x, thin, r) =
    let(rp = z*m/2, rb = rp*cos(pa),
        psi = ((PI/2 + 2*x*tan(pa))*m - thin)/(2*rp))
    (psi + inv_r(pa) - inv_r(acos(min(1, rb/max(r, rb)))))*180/PI;
function tip_land(z, m, x, thin, ra) = 2*ra*sin(g_half(z, m, x, thin, ra));
function gear_pts(z, m, x, thin, ra, rf, n = 6) =
    let(rb = z*m/2*cos(pa), r0 = max(rb, rf),
        fl = [for (i = [0:n]) r0 + (ra - r0)*i/n],
        h0 = g_half(z, m, x, thin, r0))
    [for (t = [0:z - 1]) let(c = t*360/z) each concat(
        [[rf*cos(c - h0), rf*sin(c - h0)]],
        [for (r = fl) let(a = c - g_half(z, m, x, thin, r)) [r*cos(a), r*sin(a)]],
        [for (i = [n:-1:0]) let(r = fl[i], a = c + g_half(z, m, x, thin, r)) [r*cos(a), r*sin(a)]],
        [[rf*cos(c + h0), rf*sin(c + h0)]])];
function contact_ratio(ra1, rb1, ra2, rb2, a) =
    (sqrt(ra1*ra1 - rb1*rb1) + sqrt(ra2*ra2 - rb2*rb2) - a*sin(pa))/(PI*gm*cos(pa));

function heart_r(a) = let(b = ((a % 360) + 360) % 360, c = 360 - b)
    b <= ht_tip ? ht_r0*exp(ht_lnr(b, ht_k1)) : ht_r0*exp(ht_lnr(c, ht_k2));
heart_pts = [for (a = [0:1:359]) heart_r(a)*[cos(a), sin(a)]];

// polygon area / centroid (shoelace)
function p_area(p) = 0.5*sum_([for (i = [0:len(p)-1]) let(j = (i+1) % len(p))
                                   p[i][0]*p[j][1] - p[j][0]*p[i][1]]);
function p_cx(p) = sum_([for (i = [0:len(p)-1]) let(j = (i+1) % len(p))
                   (p[i][0] + p[j][0])*(p[i][0]*p[j][1] - p[j][0]*p[i][1])])/(6*p_area(p));
function p_cy(p) = sum_([for (i = [0:len(p)-1]) let(j = (i+1) % len(p))
                   (p[i][1] + p[j][1])*(p[i][0]*p[j][1] - p[j][0]*p[i][1])])/(6*p_area(p));
function sum_(v, i = 0, acc = 0) = i >= len(v) ? acc : sum_(v, i + 1, acc + v[i]);

// --- bucket statics (same model as the README's Python sim, flat floors) ---
bk_tw = w4;  bk_td = w4;
bk_lip_v = bk_vb;                                    // flat floor: lip at floor height
bk_side_poly = [[bk_td/2, bk_vb - bk_tw], [bk_L, bk_vb - bk_tw], [bk_L, bk_vb + bk_side_h],
                [bk_td/2, bk_Hd]];
bk_bal_w  = 9;                                       // ballast block width (along the bucket)
bk_bal_top= bk_Hd + 3;                               // block top 3 mm above the divider
bk_bal_ch = (bk_bal_w - bk_td)/2;                    // 45° chamfer height under the block
bk_bal_hr = (bk_ballast_g/(RHO*bk_W) - (bk_bal_w + bk_td)/2*bk_bal_ch)/bk_bal_w;
bk_bal_poly = [[-bk_bal_w/2, bk_bal_top], [bk_bal_w/2, bk_bal_top], [bk_bal_w/2, bk_bal_top - bk_bal_hr],
               [bk_td/2, bk_bal_top - bk_bal_hr - bk_bal_ch], [-bk_td/2, bk_bal_top - bk_bal_hr - bk_bal_ch],
               [-bk_bal_w/2, bk_bal_top - bk_bal_hr]];
bk_bal_v  = p_cy(bk_bal_poly);
bk_hub_g  = 1.5;
function bk_mass_cg() =
    let(fl_m = (bk_L - bk_td/2)*bk_tw*bk_W*RHO, fl_v = bk_vb - bk_tw/2,
        sd_m = 2*abs(p_area(bk_side_poly))*bk_tw*RHO, sd_v = p_cy(bk_side_poly),
        dv_m = (bk_Hd - (bk_vb - bk_tw))*bk_td*bk_W*RHO, dv_v = (bk_Hd + bk_vb - bk_tw)/2,
        M = 2*fl_m + 2*sd_m + dv_m + bk_hub_g + bk_ballast_g,
        V = (2*fl_m*fl_v + 2*sd_m*sd_v + dv_m*dv_v + bk_ballast_g*bk_bal_v)/M)
    [M, V];
// water wedge in the raised compartment: h = level above the floor corner
function bk_water_moment(h, th) =
    let(ra = rod_d/2, cx = (bk_td/2)*cos(th) - (bk_vb + ra)*sin(th),
        area = h*h/sin(2*th), xc = cx + h*(1/tan(th) - tan(th))/3)
    area*bk_W*RHO_W*G*xc;
function bk_restore(th) = let(mc = bk_mass_cg()) mc[0]*G*(mc[1] + rod_d/2)*sin(th);
function bk_solve_h(th, lo = 0, hi = 40, n = 0) =
    n > 40 ? (lo + hi)/2 :
    let(mid = (lo + hi)/2)
    bk_water_moment(mid, th) < bk_restore(th) ? bk_solve_h(th, mid, hi, n + 1)
                                               : bk_solve_h(th, lo, mid, n + 1);
function tip_volume_ml(th = bk_theta0) = let(h = bk_solve_h(th)) h*h/sin(2*th)*bk_W/1000;
function tip_wet_len(th = bk_theta0) = bk_solve_h(th)/sin(th);   // water reach along the floor

// === CONTRACTS (fail the build if a design rule is broken) ===
tipV = tip_volume_ml();
assert(abs(area_mm2/100 - area_cm2) < 0.01, "orifice area");
assert(abs(rim_d_nom*(1 + shrink_pct/100) - rim_d) < 1e-6);
assert(abs(tipV - tip_target_ml)/tip_target_ml <= 0.05,
       str("bucket tips at ", tipV, " mL, target ", tip_target_ml));
assert(tip_wet_len() < bk_L - bk_td/2 - 2, "water would reach the bucket lip before tipping");
assert(bk_theta0 > 12, "dumping floor must fall outward");
assert(abs(2*tip_mm - 1.0) < 1e-9, "one ratchet tooth must equal 1.0 mm (2 tips)");
// ratchet quantisation (grid-locked to the pawl top): p+m <= S <= 2p-m, S-p >= backlash+margin
assert(sigma >= 1.2 && sigma <= 1.8, str("pawl stroke ", sigma, " teeth"));
assert(sigma - 1 >= click_backlash + 0.2, "back-drag recovery margin");
assert(rc_end < rt_r_out - 1 && rc_mid > rt_r_in + 1, "pawl stays on the ratchet teeth");
// gears
assert(abs(ctr_dist - dial_pitch) < 1e-9, "gear centre distance = dial pitch");
assert(abs(xp + xw) < 1e-9, "x1 + x2 = 0");
assert(sqrt(ra_w*ra_w - rb_w*rb_w) < ctr_dist*sin(pa) - 0.1, "wheel tip interferes with pinion flank");
assert(tip_land(zp, gm, xp, pin_thin, pin_ra) >= 0.4, "pinion tip land");
assert(tip_land(zw, gm, xw, wheel_thin, ra_w) >= 0.4, "wheel tip land");
assert(rf_p - bore_press/2 >= 1.2, "pinion wall over the arbor bore");
assert(contact_ratio(pin_ra, rb_p, ra_w, rb_w, ctr_dist + 0.1) >= 1.1, "contact ratio (worst case)");
assert(dial_pitch - ra_w - rod_d/2 >= 1.5, "wheel tip clears the next-but-one arbor");
assert(ctr_dist - ra_w > rf_p + 0.1 && ctr_dist - pin_ra > rf_w + 0.1, "tip/root clearance");
// hearts / reset
assert(ht_psi_min - atan(mu_design) >= 3, str("heart flank angle ", ht_psi_min, " too low for PETG"));
assert(90 - notch_psi > 0 && notch_psi - atan(0.45) >= 20, "notch self-centres even dry");
assert(abs(heart_r(ht_tip) - ht_rmax) < 0.01 && abs(heart_r(ht_tip + 0.001) - ht_rmax) < 0.05, "heart flanks meet at the tip");
// units dial rests every 36° CW from zero; the tip must not face the nose there (dead point)
assert(min([for (k = [1:9]) abs(((ht_tip - 36*k) % 360 + 540) % 360 - 180)]) >= 10,
       "heart dead point coincides with a units-dial rest position");
assert(ht_rmax + nose_r + w4 < dial_pitch/2, "fingers fit between hearts");
assert(abs(nose_e) < r_seat - 0.5, "nose offset");
assert(star_r + 2 < ht_rmax, "star hidden behind heart");
// hammer fingers: at rest clear of the NEXT heart's swept circle; at full stroke the riser and
// diagonal stay outside the zeroed heart's own outline (only the nose touches it)
assert(dial_d <= dial_pitch - 2, "dial faces");
// housing & bed
assert(2*hs_half_w <= bed[0] - 20 && (hs_back_r - y_front) <= bed[1] - bed_excl[1] - 8,
       "housing footprint on the X1C bed (place it at the back to miss the cutter corner)");
assert(col_od + 2*12 <= bed[0] - 20, "collector with tabs fits");
assert(col_h <= bed[2] - 10, "collector height");

echo(str("DESIGN: orifice Ø", rim_d_nom, " (modelled Ø", rim_d, ") = ", area_cm2, " cm²; ",
         "1 mm = ", area_mm2/1000, " mL; tip ", tipV, " mL (target ", tip_target_ml, ")"));
echo(str("DESIGN: bucket ", bk_mass_cg()[0], " g, CG ", bk_mass_cg()[1], " mm above axle, restoring ",
         bk_restore(bk_theta0), " N·mm; 0.5 mL/deg"));
echo(str("DESIGN: pawl stroke ", stroke_S, " mm = ", sigma, " teeth; contact r ", rc_mid, "..", rc_end));
echo(str("DESIGN: gears ", zp, ":", zw, " m", gm, " ε=", contact_ratio(pin_ra, rb_p, ra_w, rb_w, ctr_dist),
         " pinion land ", tip_land(zp, gm, xp, pin_thin, pin_ra),
         " wheel land ", tip_land(zw, gm, xw, wheel_thin, ra_w)));
echo(str("DESIGN: heart flanks ", atan(ht_k1), "/", atan(ht_k2), "°, notch at ", notch_ang,
         "°, reset stroke ", reset_stroke, " mm"));
echo(str("DESIGN: housing ", 2*hs_half_w, " × ", hs_back_r - y_front, " mm"));

// === 2D PROFILES ===
module pinion2d() polygon(gear_pts(zp, gm, xp, pin_thin, pin_ra, rf_p));
module wheel2d()  polygon(gear_pts(zw, gm, xw, wheel_thin, ra_w, rf_w));
module teardrop2d(d) { circle(d = d); rotate(45) square(d/2); }   // point up (+Y)

// heart outline in its zero pose seen from the front: notch toward the hammer (notch_ang)
module heart2d() {
    rotate(notch_ang) mirror([0, ht_side < 0 ? 1 : 0]) polygon(heart_pts);
}
ht_side = 1;                         // +1: tip 162° CCW of the notch (see README / sim)

module star2d() difference() {
    circle(r = star_r, $fn = 60);
    for (i = [0:star_n - 1]) rotate(i*360/star_n)
        polygon([[star_r - star_depth, 0],
                 [star_r + 1, (star_depth + 1)*tan(star_v/2)],
                 [star_r + 1, -(star_depth + 1)*tan(star_v/2)]]);
}

// === REGISTER PARTS (print orientation) ===
wheel_web = 1.8;
module wheel_body() {
    difference() {
        union() {
            linear_extrude(gface) difference() { wheel2d(); circle(r = rf_w - 3); }
            cylinder(r = rf_w - 2.9, h = wheel_web);
            cylinder(d = 10, h = gface);
        }
        for (i = [0:5]) rotate(i*60 + 30) translate([(rf_w + 8)/2, 0, -fudge])
            cylinder(d = rf_w - 14, h = gface + 2*fudge);
    }
}
// compound: wheel (bed side) + pinion + collar; lengths from the Y stack
module compound(pin_len, collar_len) {
    difference() {
        union() {
            wheel_body();
            if (pin_len > 0) translate([0, 0, gface - fudge]) linear_extrude(pin_len + fudge) pinion2d();
            translate([0, 0, gface + pin_len - fudge]) cylinder(d = 2*rf_p - 0.4, h = collar_len + fudge);
        }
        translate([0, 0, -fudge]) cylinder(d = bore_press, h = 60);
        translate([0, 0, -fudge]) cylinder(d1 = bore_press + 2*ef, d2 = bore_press, h = ef);
    }
}
coll_end = y_bp_front - 0.3;                         // rear collars stop 0.3 short of the back plate
module wheel_T() compound(gp_back(2) - gp_back(1), coll_end - gp_back(2));  // pinion into plane 2
module wheel_H() compound(gp_back(3) - gp_back(2), coll_end - gp_back(3));  // pinion into plane 3
module wheel_K() compound(0, coll_end - gp_back(3));
module pinion_U() {
    pl = gp_back(1) - (y_ff_back + 0.3);
    difference() {
        union() {
            linear_extrude(pl) pinion2d();
            translate([0, 0, pl - fudge]) cylinder(d = 2*rf_p - 0.4, h = coll_end - gp_back(1) + fudge);
        }
        translate([0, 0, -fudge]) cylinder(d = bore_press, h = 60);
    }
}

// face ratchet: disk on the bed, sawtooth teeth up (toward the rear). Front-view angles: each
// tooth rises CCW and drops at a drive face that faces CCW (the pawl pushes it CW).
module ratchet_U() {
    hub_d = 8;
    difference() {
        union() {
            cylinder(r = rt_r_out + 0.5, h = rt_base);
            for (k = [0:rt_n - 1]) let(a0 = k*rt_pitch_ang)
                hull() for (f = [0, 0.5, 1]) let(a = a0 + f*(rt_pitch_ang - 0.6), h = 0.3 + f*(rt_h - 0.3))
                    rotate(a) translate([rt_r_in, -0.01, rt_base - fudge]) cube([rt_r_out - rt_r_in, 0.02, h + fudge]);
            cylinder(d = hub_d, h = rt_base + rt_h);
        }
        translate([0, 0, -fudge]) cylinder(d = bore_press, h = 20);
        translate([0, 0, -fudge]) cylinder(d1 = bore_press + 2*ef, d2 = bore_press, h = ef);
    }
}

module lock_star() difference() {
    linear_extrude(star_t) star2d();
    translate([0, 0, -fudge]) cylinder(d = bore_press, h = star_t + 2*fudge);
}

// heart cam + sleeve + in-plane grip finger. Plate on the bed = rear; sleeve up = toward the front.
sl_od    = 5.4;
sl_flat  = 1.9;                                      // D-flat distance from the axis
sl_len   = y_ht_back - y_ptr_front;                  // plate back → pointer front
r_bb     = bore_bear/2;
pad_x    = -(2*(rod_d/2) - r_bb) + grip_interf;      // free pad face (arbor pushed to +X)
grip_ft = w2;  grip_gap = 0.7;  grip_len = 8;  grip_pad = [-1.3, 1.5];   // pad span along Y
// U-shaped slot freeing a cantilever finger (along +Y, root at grip_len) whose tip pad presses the
// arbor from -X. Local frame: notch along +X. Bends in the print plane (layers not loaded).
module heart_grip_cut() {
    x_in = pad_x;  x_out = pad_x - grip_ft;  y0 = grip_pad[0];
    translate([x_out - grip_gap, y0 - grip_gap]) square([grip_gap, grip_len - y0 + grip_gap]);  // outer
    translate([x_out - grip_gap, y0 - grip_gap]) square([x_in - x_out + grip_gap + 0.6, grip_gap]); // tip
    translate([x_in, 1.0]) square([grip_gap, grip_len - 1.0]);                                   // inner
}
module heart() {
    difference() {
        union() {
            linear_extrude(ht_t) difference() {
                heart2d();
                // lightening window in the tip lobe (keeps the cam edge 2 mm thick)
                intersection() { offset(r = -2.2) heart2d(); rotate(notch_ang + ht_side*ht_tip) translate([9, -30]) square(60); }
            }
            cylinder(d = sl_od, h = sl_len);
        }
        // bore: bearing fit everywhere except the grip pad
        translate([0, 0, -fudge]) linear_extrude(sl_len + 2*fudge) difference() {
            circle(r = r_bb, $fn = 48);
            rotate(notch_ang) translate([pad_x - 5, grip_pad[0]]) square([5, grip_pad[1] - grip_pad[0]]); // pad
        }
        // the finger sits on the side AWAY from the notch (heart body is big there)
        rotate(notch_ang) translate([0, 0, -fudge]) linear_extrude(ht_t + 2*fudge) heart_grip_cut();
        // D flat for the pointer on the top 1.8 mm (flat faces -Y = away from pointer direction)
        translate([-5, -sl_flat - 5, sl_len - ptr_t - 0.3]) cube([10, 5, 5]);
        translate([0, 0, -fudge]) cylinder(d1 = r_bb*2 + 2*ef, d2 = r_bb*2, h = ef);
    }
}

// pointer: printed face-up (front), points +Y (= up on the dial at zero)
ptr_len = 12.5;  ptr_tail = 6;  ptr_w = 2.4;
module pointer() difference() {
    linear_extrude(ptr_t) union() {
        circle(d = 8.4);
        hull() { circle(d = ptr_w + 1); translate([0, ptr_len - 1.2]) circle(d = 1.2); }
        translate([0, ptr_len]) polygon([[-1.6, -2.4], [1.6, -2.4], [0, 0.6]]);        // arrow tip
        hull() { circle(d = ptr_w); translate([0, -ptr_tail]) circle(d = 4.2); }        // counterweight tail
    }
    translate([0, 0, -fudge]) linear_extrude(ptr_t + 2*fudge) intersection() {
        circle(d = sl_od + hole_comp + fit_press);
        translate([-5, -(sl_flat + hole_comp/2)]) square([10, 10]);
    }
}

// === MOVEMENT FRAME (front view XZ; printed flat) ===
pl_x0 = hs_in_x + 0.6;  pl_x1 = -hs_in_x - 0.6;                  // plate outline (x)
posts = [[-104, 12], [-104, 90], [104, 12], [104, 90], [0, 12], [-44, 12], [66, 90]];
post_d = 7;
hz_depth = y_ff_front - y_dial_back;                             // heart zone depth (7.6)
// slide geometry (front view)
sl_z0 = dial_z + ht_rmax + 2.5;  sl_h = 8;  sl_x0 = -52;  sl_x1 = -hs_in_x - 2.2;
sl_pin_x = [-25, 18, 62];  sl_pin_z = sl_z0 + sl_h/2;  sl_pin_d = 3;
fing_t = w4;  fing_beak = 3.5;  fing_riser = 5.5;  fing_dx = 9;    // beak → riser → diagonal to bar
// finger centreline (front view) relative to the nose centre at rest
function fing_path() = [[0, 0], [fing_beak, 0], [fing_beak, fing_riser],
                        [fing_beak + fing_dx, sl_z0 + 0.5 - (dial_z + nose_e)]];
function seg_pts(a, b, n = 12) = [for (i = [0:n]) a + (b - a)*i/n];
function fing_samples() = let(p = fing_path())
    [for (k = [0:len(p) - 2]) each seg_pts(p[k], p[k + 1])];
// lock flexure (star plane, UNDER the units star): V tooth points up into the star's bottom slot.
// Modelled free (1 mm preload past engagement); at rest the slide's tab holds its tip down.
lk_vh   = star_depth + 0.2;                                     // V tooth height
lk_top  = dial_z - (star_r - star_depth) - lk_vh + 1.0;         // beam top surface, free
lk_t    = w3;
lk_x_anchor = 95;  lk_x_tip = dial_x[3] - 13;  lk_L = lk_x_anchor - lk_x_tip;
lk_a    = lk_x_anchor - dial_x[3];                              // anchor → V distance
lk_vdrop = (lk_top + lk_vh) - (dial_z - star_r - 0.3);          // V must drop this far to clear
lk_tipdrop = lk_vdrop/(lk_a*lk_a*(3*lk_L - lk_a)/(2*pow(lk_L, 3)));  // tip deflection needed
lk_overlap = 0.8;                                               // tab over the beam tip at rest
// return leaf (star plane, left)
lf_x_free = -42;  lf_z0 = 20;  lf_z1 = 72;  lf_t = w4;  lf_pre = 8;

module plate2d() difference() {
    translate([pl_x0, pl_z0]) square([pl_x1 - pl_x0, pl_z1 - pl_z0]);
    for (p = posts) translate(p) circle(d = m3_clear);
}
module arbor_holes2d() for (x = dial_x) translate([x, dial_z]) circle(d = bore_bear);

module front_frame() {
    zf = ff_t;                                                    // front face (print top)
    difference() {
        union() {
            linear_extrude(ff_t) difference() { plate2d(); arbor_holes2d(); }
            // spacer tubes for the dial face (screws pass through)
            for (p = posts) translate([p[0], p[1], zf - fudge]) difference() {
                cylinder(d = post_d, h = hz_depth + fudge);
                cylinder(d = m3_clear, h = hz_depth + 1);
            }
            // slide guide pins with shoulders (bar rides between shoulder and dial face)
            for (x = sl_pin_x) translate([x, sl_pin_z, zf - fudge]) {
                cylinder(d = sl_pin_d + 2.4, h = (y_ff_front - y_ht_back) + fudge);
                cylinder(d = sl_pin_d, h = hz_depth - 0.3 + fudge);
            }
            // lock flexure: anchor block + beam + V tooth pointing up (all in the star plane)
            translate([0, 0, zf - fudge]) linear_extrude(star_t + 0.4 - 0.2 + fudge) {
                translate([lk_x_anchor, lk_top - lk_t - 4]) square([6, lk_t + 7]);
                translate([lk_x_tip, lk_top - lk_t]) square([lk_L + 1, lk_t]);
                translate([dial_x[3], lk_top - fudge])
                    polygon([[-lk_vh*tan(star_v/2), 0], [lk_vh*tan(star_v/2), 0], [0, lk_vh]]);
            }
            // return leaf spring (free, vertical) + root block
            translate([0, 0, zf - fudge]) linear_extrude(star_t + 0.4 - 0.2 + fudge) {
                translate([lf_x_free - 3, lf_z0 - 6]) square([6 + lf_t, 6]);
                translate([lf_x_free, lf_z0 - fudge]) square([lf_t, lf_z1 - lf_z0]);
            }
        }
        for (x = dial_x) translate([x, dial_z, -fudge]) cylinder(d1 = bore_bear + 2*ef, d2 = bore_bear, h = ef);
    }
}

module back_plate() {
    post_len = y_bp_front - y_ff_back;                            // 16
    difference() {
        union() {
            linear_extrude(bp_t) difference() { plate2d(); arbor_holes2d(); }
            for (p = posts) translate([p[0], p[1], bp_t - fudge]) cylinder(d = post_d, h = post_len + fudge);
        }
        for (p = posts) translate([p[0], p[1], -fudge]) cylinder(d = m3_tap, h = bp_t + post_len + 1);
        for (p = posts) translate([p[0], p[1], -fudge]) cylinder(d = m3_clear + 2.6, h = 1.2);   // screw-head relief at rear? none
    }
}

// dial face: printed numerals-up; front view coordinates
num_size = 4.6;  num_r = 15.4;  tick_r = [18.4, 19.6];
module dial_marks2d(i) {
    d = dial_dir[i];
    translate([dial_x[i], dial_z]) {
        difference() { circle(r = dial_d/2); circle(r = dial_d/2 - 0.9); }                // ring
        for (k = [0:9]) let(a = 90 - d*36*k) {
            rotate(a) translate([tick_r[0], -0.45]) square([tick_r[1] - tick_r[0], 0.9]);
            translate(num_r*[cos(a), sin(a)])
                text(str(k), size = num_size, font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
        }
        // direction arrow between 0 and 1 just inside the ring
        rotate(90 - d*18) translate([dial_d/2 - 2.6, 0]) rotate(d > 0 ? 180 : 0)
            polygon([[-1.1, -1.4], [-1.1, 1.4], [1.3, 0]]);
        translate([0, -dial_d/2 - 5]) text(str("×", dial_lbl[i]), size = 3.6,
            font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
    }
}
module dial_face_plate() linear_extrude(dial_t) difference() {
    plate2d();
    for (x = dial_x) translate([x, dial_z]) circle(d = sl_od + 0.8);
}
module dial_face_marks() translate([0, 0, dial_t - fudge]) linear_extrude(num_h + fudge) {
    for (i = [0:3]) dial_marks2d(i);
    translate([0, pl_z1 - 8]) text("MILLIMETRES OF RAIN", size = 5.2,
        font = "Liberation Sans:style=Bold", halign = "center", valign = "center");
    translate([pl_x1 - 9, sl_pin_z]) text("RESET", size = 3.4,
        font = "Liberation Sans:style=Bold", halign = "right", valign = "center");
    translate([pl_x1 - 7.8, sl_pin_z]) polygon([[0, -1.8], [0, 1.8], [3, 0]]);     // arrow → plunger
    translate([0, pl_z0 + 6]) text("read left to right · take the lower figure", size = 3,
        font = "Liberation Sans", halign = "center", valign = "center");
}
module dial_face() union() { dial_face_plate(); dial_face_marks(); }   // one part; colour-change at z = dial_t

// reset slide (heart plane). Front view; printed FRONT face down: bar + 4 hammer fingers are the
// first ht_t mm; the lock-cam tab and spring tab rise further (toward the rear) into the star plane.
tab_d = star_t - 0.2;                                            // tab depth into the star plane
module finger2d(i) {
    p = fing_path();
    translate([dial_x[i] + x_nose_rest, dial_z + nose_e]) {
        for (k = [1:len(p) - 2]) hull() { translate(p[k]) circle(d = fing_t, $fn = 24);
                                          translate(p[k + 1]) circle(d = fing_t, $fn = 24); }
        hull() { circle(r = nose_r, $fn = 24); translate(p[1]) circle(d = fing_t, $fn = 24); }   // beak
    }
}
module slide() {
    difference() {
        union() {
            linear_extrude(ht_t) {
                translate([sl_x0, sl_z0]) square([sl_x1 - sl_x0, sl_h]);
                for (i = [0:3]) finger2d(i);
            }
            // spring tab (left end): the return leaf, bent lf_pre to the left on assembly, presses
            // its left face (the leaf is printed straight, so the model shows it overlapping)
            linear_extrude(ht_t + tab_d) translate([lf_x_free - lf_pre + lf_t, lf_z1 - 16])
                square([4, sl_z0 + sl_h - (lf_z1 - 16)]);
            // lock hold-down tab: its flat bottom holds the flexure tip down at rest (V clear of
            // the star); 0.8 mm into the stroke it slides off and the V snaps into a slot. The 45°
            // lower-right chamfer pushes the beam down again on the return stroke.
            let(xr = lk_x_tip + lk_overlap + lk_tipdrop, zb = lk_top - lk_tipdrop)
            linear_extrude(ht_t + tab_d) polygon([
                [lk_x_tip - 3.5, zb], [lk_x_tip + lk_overlap, zb], [xr, lk_top + 0.3],
                [xr, sl_z0 + 0.1], [lk_x_tip - 3.5, sl_z0 + 0.1]]);
        }
        // guide slots (the pins stay put while the bar travels left by reset_stroke)
        for (x = sl_pin_x) translate([0, 0, -fudge]) linear_extrude(ht_t + tab_d + 2*fudge)
            hull() { translate([x, sl_pin_z]) circle(d = sl_pin_d + 0.5);
                     translate([x + reset_stroke + 0.6, sl_pin_z]) circle(d = sl_pin_d + 0.5); }
    }
}

// reset plunger: head outside the right wall, stem through it, flange inside
pl_stroke = reset_stroke + 0.8;
module plunger() {
    stem_d = 6;  head_d = 12;  flange_d = 10;
    cylinder(d = head_d, h = 3);
    cylinder(d = stem_d, h = 3 + pl_stroke + hs_wall + 1.2);
    translate([0, 0, 3 + pl_stroke + hs_wall + 0.6 - (flange_d - stem_d)/2]) cylinder(d1 = stem_d, d2 = flange_d, h = (flange_d - stem_d)/2 + fudge);
    translate([0, 0, 3 + pl_stroke + hs_wall + 0.6]) cylinder(d = flange_d, h = 1.8);
}

// === BUCKET & DRIVE ===
bk_zoff  = -(bk_vb - bk_tw);                         // print z = bucket v + bk_zoff (floor on bed)
bk_hub_d = 6;  bk_thrust_d = 8;  bk_thrust_t = w2;
bk_out_w = bk_W + 2*bk_tw + 2*bk_thrust_t;           // across the thrust bosses
bk_side_full = [[-bk_L, bk_vb - bk_tw], [bk_L, bk_vb - bk_tw], [bk_L, bk_vb + bk_side_h],
                [bk_td/2, bk_Hd], [-bk_td/2, bk_Hd], [-bk_L, bk_vb + bk_side_h]];
module yz_slab(x0, t) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(t) children();
module bucket() {
    translate([0, 0, bk_zoff]) difference() {
        union() {
            translate([-bk_W/2 - bk_tw, -bk_L, bk_vb - bk_tw]) cube([bk_W + 2*bk_tw, 2*bk_L, bk_tw]);
            translate([-bk_W/2 - fudge, -bk_td/2, bk_vb - bk_tw]) cube([bk_W + 2*fudge, bk_td, bk_Hd - bk_vb + bk_tw]);
            for (x0 = [-bk_W/2 - bk_tw, bk_W/2]) yz_slab(x0, bk_tw) polygon(bk_side_full);
            yz_slab(-bk_W/2 - fudge, bk_W + 2*fudge) polygon(bk_bal_poly);
            // axle hub along X + thrust bosses (0.3 mm end float in the chamber)
            yz_slab(-bk_W/2 - bk_tw, bk_W + 2*bk_tw) rotate(180) teardrop2d(bk_hub_d);   // 45° underside
            rotate([0, 90, 0]) cylinder(d = bk_thrust_d, h = bk_out_w, center = true);
        }
        // press-fit axle bore, teardrop (point up) so it prints without support
        yz_slab(-bk_out_w/2 - 1, bk_out_w + 2) teardrop2d(bore_press);
        // 45° relief under the thrust bosses so they don't hang (they start above the floor)
    }
}

// drive arm: plate in the use YZ plane beside the ratchet; printed plate-down (its +X face on the
// bed), hub rising toward the bucket. Print XY = use (Y, Z) about the axle; modelled at mid stroke.
arm_t = w6;  arm_x_plate = x_contact - 1.5 - 0.5 - arm_t;          // plate's -X face (use x)
arm_hub_d = 10;  arm_hub_l = 7;  arm_tail = 16;
pawl_t = 3;  pawl_boss = 7;
module arm() {
    difference() {
        union() {
            linear_extrude(arm_t) {
                hull() { circle(d = arm_hub_d); translate([-arm_r, 0]) circle(d = pawl_boss); }
                hull() { circle(d = arm_hub_d - 2); translate([arm_tail, 0]) circle(d = 4); }
                translate([arm_tail, 0]) circle(d = arm_tail_bulb_d);          // counterweight
                translate([4, 3]) square([8, 5]);                                // clamp ear
            }
            translate([0, 0, arm_t - fudge]) cylinder(d = arm_hub_d, h = arm_hub_l + fudge);
            translate([4, 3, arm_t - fudge]) cube([8, 5, arm_hub_l + fudge]);    // clamp ear
        }
        translate([0, 0, -fudge]) cylinder(d = bore_bear, h = 30);
        translate([0, -0.5, arm_t + 0.6]) cube([13, 1.0, arm_hub_l]);            // clamp slit
        // clamp screw across the slit (along print Y = use Z), teardrop, nut pocket on top
        translate([8, 10, arm_t + arm_hub_l/2 + 0.4]) rotate([90, 0, 0])
            linear_extrude(12) rotate(90) teardrop2d(m3_clear);
        translate([8, 8 - m3_nut_t, arm_t + arm_hub_l/2 + 0.4]) rotate([-90, 0, 0])
            cylinder(d = m3_nut_af/cos(30) + 0.3, h = m3_nut_t + 0.3, $fn = 6);
        translate([-arm_r, 0, -fudge]) cylinder(d = m3_tap, h = 20);            // pawl pivot screw
    }
}
arm_tail_bulb_d = 9;

// pawls: flat plates in the use YZ plane, printed flat. 2D in use (y, z) about the pivot.
pawl_tip = [-(pawl_lean + rt_h - 0.2), pawl_rise];                         // tip corner (push face)
// Upright stem whose front edge stays 0.8 mm behind the tooth-tip plane (rel. y = -pawl_lean), and
// a tooth that protrudes forward into the teeth: top face flat (pushes the drive face), 45° lower
// front chamfer (rides up the ramps on the return stroke). CG sits ahead of the pivot → gravity
// leans the tooth onto the ratchet face.
module pawl2d(tip) difference() {
    stem_f = -pawl_lean + 0.8;                     // stem front edge (rel. y)
    union() {
        hull() { circle(d = pawl_boss); translate([stem_f, tip[1] - 2.6]) square([3.2, 2.6]); }
        polygon([[stem_f + fudge, tip[1]], [tip[0], tip[1]], [tip[0], tip[1] - 1.0],
                 [tip[0] + 1.4, tip[1] - 2.4], [stem_f + fudge, tip[1] - 2.4]]);
    }
    circle(d = m3_run);
}
module drive_pawl() linear_extrude(pawl_t) pawl2d(pawl_tip);

// click pawl at 12 o'clock on the ratchet: stands on a post, leans onto the face, blocks backward
// rotation by taking the tooth's sideways (X) push on its pivot screw. Same body as the drive pawl.
module click_pawl() linear_extrude(pawl_t) pawl2d(pawl_tip);
// grid: drive face angle at the top of the pawl stroke (front view, about the units arbor)
grid_ang   = atan2(arm_r*sin(bk_theta0), x_contact - dial_x[3]);    // pawl tip height = pivot + pawl_rise
function wrap(a) = ((a % 360) + 360) % 360;
face_top   = let(k = floor((wrap(grid_ang) - 90)/rt_pitch_ang)) wrap(grid_ang) - (k + 1)*rt_pitch_ang;  // face just CW of 12 o'clock
click_ang  = face_top + click_backlash*rt_pitch_ang;
click_x    = dial_x[3] + rc_mid*cos(click_ang);
click_z    = dial_z + rc_mid*sin(click_ang);

// === HOUSING ===
hs_in_half = -hs_in_x;
ch_in      = bk_out_w/2 + 0.3;                       // chamber inside half width (0.3 end float)
ch_y_back  = hs_back_r;                              // chamber side walls run to the back wall
stop_u     = 28;                                     // stop contact distance along the bucket
stop_y     = stop_u*cos(bk_theta0) + (bk_vb - bk_tw)*sin(bk_theta0);          // 20.1
stop_top_z = z_b - stop_u*sin(bk_theta0) + (bk_vb - bk_tw)*cos(bk_theta0);    // screw head top
stop_boss_top = stop_top_z - m3_head_h - m3_nut_t - 1.0;
lid_cols   = [[90, -30], [-90, -30], [70, 60], [-70, 60]];
click_post = [click_x + pawl_t/2 + 0.5, -17, 0];    // post's -X face, -Y face
click_piv  = [-arm_r, click_z - pawl_rise];         // click pivot (use y, z)
sl_y_mid   = (y_ht_front + y_ht_back)/2;
module back_half2d() intersection() { circle(r = hs_back_r, $fn = 180); translate([-hs_back_r, 0]) square(2*hs_back_r); }
module hs_outline2d(front_y) hull() {
    translate([-hs_half_w, front_y]) square([2*hs_half_w, -front_y]);
    back_half2d();
}
module housing_base() {
    difference() {
        union() {
            difference() {
                union() {
                    linear_extrude(hs_h) hs_outline2d(y_base_front);
                }
                translate([0, 0, floor_t]) linear_extrude(hs_h) offset(delta = -hs_wall) hs_outline2d(y_base_front);
                translate([-hs_in_half, y_base_front - 1, floor_t]) cube([2*hs_in_half, hs_wall + 2, hs_h]);
                // outside bottom edge chamfer (elephant foot)
                translate([0, 0, -fudge]) linear_extrude(ef) difference() {
                    offset(delta = 5) hs_outline2d(y_base_front); offset(delta = -ef) hs_outline2d(y_base_front); }
            }
            intersection() {
                linear_extrude(hs_h) offset(delta = -1) hs_outline2d(y_base_front);
                union() {
                    // chamber: front wall + two side walls to the back
                    translate([-ch_in - ch_wall, ch_front_in - ch_wall, 0]) cube([2*(ch_in + ch_wall), ch_wall, hs_h]);
                    for (sx = [-1, 1]) translate([sx > 0 ? ch_in : -ch_in - ch_wall, ch_front_in - ch_wall, 0])
                        cube([ch_wall, ch_y_back - ch_front_in + ch_wall, hs_h]);
                    // wet-strip floor ramp: 3 mm high at the front, falling to the back drains
                    translate([ch_in + fudge, 0, 0]) rotate([0, -90, 0]) linear_extrude(2*ch_in + 2*fudge)
                        polygon([[0, ch_front_in - fudge], [floor_t + 3, ch_front_in - fudge], [floor_t, ch_y_back], [0, ch_y_back]]);
                    // stop-screw bosses (front and back)
                    for (sy = [-1, 1]) translate([0, sy*stop_y, 0]) cylinder(d = 10, h = stop_boss_top);
                    // lid screw columns
                    for (c = lid_cols) translate([c[0], c[1], 0]) cylinder(d = 8, h = hs_h);
                    // click-pawl post in the drive bay
                    translate([click_post[0], click_post[1], 0]) cube([6, 8, click_piv[1] + 4]);
                    // bezel sill across the front, below the movement plates
                    translate([-hs_in_half, y_base_front, 0]) cube([2*hs_in_half, y_ff_front - 0.4 - y_base_front, pl_z0 - 0.5]);
                    // plunger guide boss (outside the right wall)
                    translate([hs_half_w - fudge, sl_y_mid, sl_pin_z]) rotate([0, 90, 0]) cylinder(d = 14, h = 6);
                }
            }
            translate([hs_half_w - fudge, sl_y_mid, sl_pin_z]) rotate([0, 90, 0]) cylinder(d = 14, h = 6);
        }
        // rolling seats for the bucket axle: closed windows in both chamber walls (flat bottom)
        for (sx = [-1, 1]) translate([sx*(ch_in + ch_wall/2), 0, z_b - rod_d/2]) rotate([90, 0, 90])
            linear_extrude(ch_wall + 2, center = true)
                polygon([[-3.9, 0], [3.9, 0], [3.9, rod_d + 1.2], [0, rod_d + 1.2 + 3.9], [-3.9, rod_d + 1.2]]);
        // stop screws: M3 through the boss, captive nut entered from the side
        for (sy = [-1, 1]) translate([0, sy*stop_y, 0]) {
            translate([0, 0, 2]) cylinder(d = m3_clear, h = stop_boss_top);
            translate([0, 0, stop_boss_top - 5.5]) rotate(30) cylinder(d = m3_nut_af/cos(30) + 0.3, h = m3_nut_t + 0.3, $fn = 6);
            translate([0, -(m3_nut_af + 0.3)/2, stop_boss_top - 5.5]) cube([8, m3_nut_af + 0.3, m3_nut_t + 0.3]);
        }
        // lid screw taps
        for (c = lid_cols) translate([c[0], c[1], hs_h - 12]) cylinder(d = m3_tap, h = 13);
        // click pivot tap (along X)
        translate([click_post[0] - 1, click_piv[0], click_piv[1]]) rotate([0, 90, 0]) cylinder(d = m3_tap, h = 8);
        // back drains for the wet strip: vertical slots at floor level (bars between)
        for (x = [-16:4:16]) translate([x - 1.2, 80, floor_t - fudge]) cube([2.4, 30, 5]);
        // small drains for the dry bays (side walls) and through the sill
        for (sx = [-1, 1], y = [-30, 20]) translate([sx*(hs_half_w - hs_wall/2), y, floor_t - fudge])
            cube([hs_wall + 2, 5, 2.4], center = false);
        for (x = [-60, 60]) translate([x - 3, y_base_front - 1, floor_t - fudge]) cube([6, 20, 2.0]);
        // bezel screw taps in the sill
        for (x = [-80, 80]) translate([x, y_base_front - 1, (pl_z0 - 0.5 + floor_t)/2 + 0.6]) rotate([-90, 0, 0])
            cylinder(d = m3_tap, h = 10);
        // plunger bore through the right wall + guide boss
        translate([hs_half_w - hs_wall - 1, sl_y_mid, sl_pin_z]) rotate([0, 90, 0]) linear_extrude(12) rotate(90) teardrop2d(6.6);
    }
}

// lid: flat plate on the walls, printed bottom-down. Collector sits in the socket ring on top.
lid_front   = y_front - 6;                           // 6 mm visor over the bezel
col_boss_r  = col_od/2 + 7;
col_tab_ang = [90, 210, 330];
level_pos   = [92, -58];
module lid_outline2d() hull() {
    translate([-hs_half_w, lid_front]) square([2*hs_half_w, -lid_front]);
    back_half2d();
}
module housing_lid() {
    difference() {
        union() {
            linear_extrude(lid_t) lid_outline2d();
            translate([0, 0, lid_t - fudge]) difference() {                            // socket ring
                cylinder(d = col_od + 0.6 + 2*w5, h = 4 + fudge, $fn = 180);
                cylinder(d = col_od + 0.6, h = 10, $fn = 180);
            }
            for (a = col_tab_ang) translate([col_boss_r*cos(a), col_boss_r*sin(a), lid_t - fudge])
                cylinder(d = 9, h = 6 + fudge);
            translate([level_pos[0], level_pos[1], lid_t - fudge]) cylinder(d = 21, h = 4 + fudge);
        }
        translate([0, 0, -fudge]) cylinder(d = col_od - 5, h = 20, $fn = 180);         // opening
        for (a = col_tab_ang) translate([col_boss_r*cos(a), col_boss_r*sin(a), 1]) cylinder(d = m3_tap, h = 10);
        for (c = lid_cols) translate([c[0], c[1], -fudge]) {
            cylinder(d = m3_clear, h = 10);
            translate([0, 0, lid_t - 1.7]) cylinder(d1 = m3_clear, d2 = 6.2, h = 1.7 + fudge);
        }
        translate([level_pos[0], level_pos[1], lid_t + 4 - 4.2]) cylinder(d = 15.6, h = 5);   // 15 mm bubble level
        // groove on the underside that captures the bezel's top tongue
        translate([-hs_half_w + 8, y_front - 1, -fudge]) cube([2*hs_half_w - 16, 7.0, 1.6]);
        // bottom edge elephant-foot chamfer
        translate([0, 0, -fudge]) linear_extrude(ef) difference() {
            offset(delta = 5) lid_outline2d(); offset(delta = -ef) lid_outline2d(); }
    }
}

// bezel: frame in front of the base holding an optional 2 mm clear acrylic window.
// Printed front-face down: print z = use y - y_front; print (x, y) = use (x, z).
bz_frame = 7;  win_t = 2.0;  win_y = 2.0;
module bezel() {
    difference() {
        union() {
            linear_extrude(bz_depth) translate([-hs_half_w, 0]) square([2*hs_half_w, hs_h]);
            translate([-hs_half_w + 8.2, hs_h - fudge, 0]) cube([2*hs_half_w - 16.4, 1.4 + fudge, 5.6]);   // top tongue
        }
        // viewing opening
        translate([-hs_half_w + bz_frame, pl_z0 + 2, -fudge]) cube([2*(hs_half_w - bz_frame), pl_z1 - pl_z0 - 4, bz_depth + 1]);
        // pocket behind the window so the frame clears the pointers and presses the dial face rim
        translate([-hs_in_half + 0.3, pl_z0 - 0.5, win_y + win_t + 1.2]) cube([2*(hs_in_half - 0.3), pl_z1 - pl_z0 + 1, bz_depth]);
        // window groove, open at the top edge
        translate([-hs_half_w + bz_frame - 4, pl_z0 - 2, win_y]) cube([2*(hs_half_w - bz_frame + 4), hs_h, win_t + 0.3]);
        // screws into the sill (countersunk from the front)
        for (x = [-80, 80]) translate([x, (pl_z0 - 0.5 + floor_t)/2 + 0.6, -fudge]) {
            cylinder(d = m3_clear, h = bz_depth + 1);
            cylinder(d1 = 6.2, d2 = m3_clear, h = 1.7);
        }
        translate([0, 0, -fudge]) linear_extrude(ef) difference() {              // elephant foot
            translate([-hs_half_w - 5, -5]) square([2*hs_half_w + 10, hs_h + 10]);
            translate([-hs_half_w + ef, ef]) square([2*hs_half_w - 2*ef, hs_h - 2*ef]); }
    }
}

// === COLLECTOR, SCREEN, NOZZLE ===
col_rib_t = w3;  col_tab_w = 12;  col_tab_t = 3;
funnel_t  = w3;
fn_col    = $preview ? 96 : 200;
module collector() {
    zt   = z_cone_top;  tr = throat_bore/2;  tod = throat_bore/2 + w4;
    dz_u = funnel_t/cos(funnel_deg);                         // vertical thickness of the cone
    bev  = (rim_wall - ew)/tan(30);                          // outer knife-edge bevel height
    zu   = function(r) throat_stub - dz_u + (r - throat_d/2)*tan(funnel_deg);
    difference() {
        union() {
            // tube: splash wall + skirt, sharp rim (vertical inside, 30° bevel outside)
            rotate_extrude($fn = fn_col) polygon([
                [rim_r, 0], [rim_r + rim_wall - ef, 0], [rim_r + rim_wall, ef],
                [rim_r + rim_wall, col_h - bev], [rim_r + ew, col_h], [rim_r, col_h]]);
            // funnel cone (50°) + throat tube
            rotate_extrude($fn = fn_col) polygon([
                [throat_d/2, throat_stub], [rim_r + fudge, zt], [rim_r + fudge, zt - dz_u],
                [tod, zu(tod)], [tod, 0], [tr, 0], [tr, throat_stub - 2]]);
            // radial ribs tie the throat to the skirt (rigid print, no wobbling cone)
            for (i = [0:3]) rotate(45 + i*90) rotate([90, 0, 0]) linear_extrude(col_rib_t, center = true)
                polygon([[tod - 0.5, 0], [rim_r + 0.5, 0], [rim_r + 0.5, zu(rim_r)], [tod - 0.5, zu(tod - 0.5)]]);
            // screw tabs on the foot
            for (a = col_tab_ang) rotate(a) translate([rim_r, -col_tab_w/2, 0]) cube([col_boss_r - rim_r + 5, col_tab_w, col_tab_t]);
        }
        translate([0, 0, -fudge]) cylinder(r = throat_bore/2, h = throat_stub + fudge);      // throat bore
        for (a = col_tab_ang) rotate(a) translate([col_boss_r, 0, -fudge]) cylinder(d = m3_clear, h = col_tab_t + 1);
    }
}
module screen() {                                           // leaf screen: slotted cage on a spigot
    difference() {
        union() {
            cylinder(d = throat_bore - 0.4, h = 4);             // spigot into the throat
            translate([0, 0, 4 - fudge]) cylinder(d1 = throat_bore - 0.4, d2 = 16, h = (16 - throat_bore + 0.4)/2 + fudge);
            translate([0, 0, 4 + (16 - throat_bore + 0.4)/2 - fudge]) cylinder(d = 16, h = 12 - (16 - throat_bore + 0.4)/2);
            translate([0, 0, 16 - fudge]) cylinder(d1 = 16, d2 = 2, h = 7);   // cone roof sheds leaves
        }
        translate([0, 0, -fudge]) cylinder(d = throat_bore - 0.4 - 2*w2, h = 4 + 2*fudge);
        translate([0, 0, 4 - 2*fudge]) cylinder(d1 = throat_bore - 0.4 - 2*w2, d2 = 16 - 2*w3, h = (16 - throat_bore + 0.4)/2);
        translate([0, 0, 4 + (16 - throat_bore + 0.4)/2 - 3*fudge]) cylinder(d = 16 - 2*w3, h = 12);
        translate([0, 0, 16 - 2*fudge]) cylinder(d1 = 16 - 2*w3, d2 = 0.1, h = 6.1);
        for (i = [0:9]) rotate(i*36) translate([0, -0.6, 5.5]) cube([10, 1.2, 9.5]);  // 1.2 mm slots
    }
}
nozzle_drop = (hs_h + lid_t) - (z_b + bk_bal_top + 5);      // throat foot → 5 mm above the bucket top
module nozzle() {                                           // printed outlet-down
    difference() {
        union() {
            cylinder(d = 6.4, h = nozzle_drop);
            translate([0, 0, nozzle_drop - 2.5]) cylinder(d1 = 6.4, d2 = 11.4, h = 2.5);   // 45° under the flange
            translate([0, 0, nozzle_drop - fudge]) cylinder(d = 11.4, h = 1.2);
            translate([0, 0, nozzle_drop + 1.2 - fudge]) cylinder(d = throat_d, h = 4);   // press plug
        }
        translate([0, 0, -fudge]) cylinder(d = 3.4, h = nozzle_drop + 10);
        translate([0, 0, -fudge]) cylinder(d1 = 4.6, d2 = 3.4, h = 0.6);                // drip edge
    }
}

// === PRINT PLATES / COUPONS ===
module small_parts() {                                       // everything small, one 0.12 mm plate
    for (i = [0:3]) translate([-60 + i*30, 40, 0]) heart();
    for (i = [0:3]) translate([-66 + i*16, 8, 0]) pointer();
    translate([10, 8, 0]) lock_star();
    translate([30, 8, 0]) ratchet_U();
    translate([55, 8, 0]) pinion_U();
    translate([-60, -20, 0]) drive_pawl();
    translate([-45, -20, 0]) click_pawl();
    translate([-20, -22, 0]) arm();
    translate([35, -22, 0]) nozzle();
    translate([55, -22, 0]) screen();
    translate([72, 30, 0]) plunger();
}
module test_coupons() {                                      // print these first
    difference() {                                           // gear jig: two arbors at the dial pitch
        translate([-8, -8, 0]) cube([ctr_dist + 16, 16, 4]);
        for (x = [0, ctr_dist]) translate([x, 0, -fudge]) cylinder(d = bore_bear, h = 5);
    }
    translate([0, 16, 0]) difference() {                     // bore gauge: press / bearing / running
        translate([-8, -6, 0]) cube([44, 12, 4]);
        for (i = [0:2]) translate([i*12, 0, -fudge]) cylinder(d = [bore_press, bore_bear, bore_run][i], h = 5);
        for (i = [0:2]) translate([i*12, -5.2, 4 - 0.6]) linear_extrude(1)
            text(["P", "B", "R"][i], size = 2.4, halign = "center");
    }
}

// === ASSEMBLY (use orientation) ===
module place_front_up(y0) multmatrix([[1, 0, 0, 0], [0, 0, -1, y0], [0, 1, 0, 0], [0, 0, 0, 1]]) children();
module place_rear_up(y0)  multmatrix([[1, 0, 0, 0], [0, 0, 1, y0], [0, 1, 0, 0], [0, 0, 0, 1]]) children();
module rod(p0, p1, d = rod_d) color("silver") hull() { translate(p0) sphere(d = d, $fn = 16); translate(p1) sphere(d = d, $fn = 16); }
demo_reading = [1, 2, 3, 4];                                 // shows 1234 mm (K, H, T, U)
function dial_turn(i) = let(v = i == 3 ? demo_reading[3] :
                            demo_reading[i] + (demo_reading[i+1] + (i + 2 <= 3 ? demo_reading[i+2]/10 : 0))/10)
                        -dial_dir[i]*36*v;
module assembly() {
    ex = explode;
    tip = pose_tip;
    // --- movement ---
    color("gainsboro") translate([0, 0.0*ex, 0]) place_front_up(y_bp_back) back_plate();
    color("gainsboro") translate([0, -0.6*ex, 0]) place_front_up(y_ff_back) front_frame();
    for (i = [0:3]) rod([dial_x[i], i == 3 ? y_rt_face : y_bp_back, dial_z], [dial_x[i], y_ptr_front + 0.6, dial_z]);
    color("orange") translate([dial_x[2], -0.3*ex, dial_z]) place_rear_up(gp_front(1)) wheel_T();
    color("darkorange") translate([dial_x[1], -0.2*ex, dial_z]) place_rear_up(gp_front(2)) wheel_H();
    color("orange") translate([dial_x[0], -0.1*ex, dial_z]) place_rear_up(gp_front(3)) wheel_K();
    color("darkorange") translate([dial_x[3], -0.3*ex, dial_z]) place_rear_up(y_ff_back + 0.3) pinion_U();
    color("tomato") translate([dial_x[3], 0.3*ex, dial_z]) place_rear_up(y_rt_face - rt_h - rt_base) ratchet_U();
    color("steelblue") translate([dial_x[3], -0.8*ex, dial_z]) place_front_up(y_star_back) lock_star();
    for (i = [0:3]) translate([dial_x[i], -1.0*ex, dial_z]) {
        color("slateblue") place_front_up(y_ht_back) rotate(dial_turn(i)) heart();
        color("black") translate([0, -0.6*ex, 0]) place_front_up(y_ptr_back) rotate(dial_turn(i)) pointer();
    }
    color("mediumseagreen") translate([-reset_pos*reset_stroke, -0.9*ex, 0]) place_rear_up(y_ht_front) slide();
    translate([0, -1.3*ex, 0]) place_front_up(y_dial_back) { color("white") dial_face_plate(); color("black") dial_face_marks(); }
    color("crimson") translate([sl_x1 - reset_pos*reset_stroke + 3 + pl_stroke + hs_wall + 3.0 + 0.4*ex, sl_y_mid, sl_pin_z])
        rotate([0, -90, 0]) plunger();
    // --- bucket, drive ---
    translate([0, 0, z_b + 0.6*ex]) rotate([-tip, 0, 0]) {
        color("gold") translate([0, 0, -bk_zoff]) bucket();
        rod([-ch_in - ch_wall - 1.5, 0, 0], [arm_x_plate + arm_t - arm_hub_l - arm_t + 0.5, 0, 0]);
        color("teal") multmatrix([[0, 0, -1, arm_x_plate + arm_t], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]]) arm();
    }
    piv = [0, -arm_r*cos(tip), z_b + arm_r*sin(tip) + 0.6*ex];
    color("teal") multmatrix([[0, 0, 1, x_contact - pawl_t/2], [1, 0, 0, piv[1]], [0, 1, 0, piv[2]], [0, 0, 0, 1]]) drive_pawl();
    color("teal") multmatrix([[0, 0, 1, click_x - pawl_t/2], [1, 0, 0, click_piv[0]], [0, 1, 0, click_piv[1]], [0, 0, 0, 1]]) click_pawl();
    // stop screws (heads)
    for (sy = [-1, 1]) color("silver") translate([0, sy*stop_y, stop_top_z - m3_head_h]) cylinder(d = m3_head_d, h = m3_head_h);
    // --- shell ---
    if (show_shell) {
        color("whitesmoke") housing_base();
        color("whitesmoke", 0.9) translate([0, 0, hs_h + 0.5*ex]) housing_lid();
        color("whitesmoke") translate([0, -1.6*ex, 0]) multmatrix([[1, 0, 0, 0], [0, 0, 1, y_front], [0, 1, 0, 0], [0, 0, 0, 1]]) bezel();
        translate([0, 0, hs_h + lid_t + 1.2*ex]) {
            color("white") collector();
            color("lightgreen") translate([0, 0, throat_stub - 4]) screen();
            color("lightgreen") translate([0, 0, 4 - (nozzle_drop + 1.2 + 4) - 0.3*ex]) nozzle();
        }
    }
}

// === DISPATCH ===
module show_part(p) {
    if      (p == "collector")    collector();
    else if (p == "screen")       screen();
    else if (p == "nozzle")       nozzle();
    else if (p == "housing_base") housing_base();
    else if (p == "housing_lid")  housing_lid();
    else if (p == "bezel")        bezel();
    else if (p == "plunger")      plunger();
    else if (p == "bucket")       bucket();
    else if (p == "arm")          arm();
    else if (p == "drive_pawl")   drive_pawl();
    else if (p == "click_pawl")   click_pawl();
    else if (p == "front_frame")  front_frame();
    else if (p == "back_plate")   back_plate();
    else if (p == "dial_face")    dial_face();
    else if (p == "slide")        slide();
    else if (p == "wheel_T")      wheel_T();
    else if (p == "wheel_H")      wheel_H();
    else if (p == "wheel_K")      wheel_K();
    else if (p == "pinion_U")     pinion_U();
    else if (p == "ratchet_U")    ratchet_U();
    else if (p == "lock_star")    lock_star();
    else if (p == "heart")        heart();
    else if (p == "pointer")      pointer();
    else if (p == "small_parts")  small_parts();
    else if (p == "test_coupons") test_coupons();
    else if (p != "none") assert(false, str("unknown part ", p));
}
if (part == "assembly") {
    if (cut_x < 999) intersection() { assembly(); translate([-500 + cut_x, -500, -10]) cube([500, 1000, 600]); }
    else assembly();
} else show_part(part);

// finger clearance contracts (evaluated after the geometry functions above)
fing_rest_clear = min([for (q = fing_samples())
    norm([x_nose_rest + q[0] - dial_pitch, nose_e + q[1]])]) - ht_rmax - fing_t/2;
fing_end_clear = min([for (q = fing_samples()) if (q[0] >= fing_beak - 0.01)
    let(x = x_seat - sl_overtravel + q[0], z = nose_e + q[1]) norm([x, z]) - heart_r(atan2(z, x))]) - fing_t/2;
assert(fing_rest_clear >= 1.0, str("finger hits the neighbouring heart at rest: ", fing_rest_clear));
assert(lk_overlap < sl_rest_clear - 0.3, "lock must engage before a hammer can touch a heart");
assert(3*lk_t*lk_tipdrop/(2*lk_L*lk_L) <= 0.03, "lock flexure strain");
assert(lk_x_tip + lk_overlap + lk_tipdrop < dial_x[3] - sqrt(max(0, star_r*star_r - pow(dial_z - lk_top - 0.3, 2))) - 0.8,
       "hold-down tab clears the star");
assert(fing_end_clear >= 0.8, str("finger body hits its own heart at the end of stroke: ", fing_end_clear));
echo(str("DESIGN: finger clearance at rest ", fing_rest_clear, " mm, at full stroke ", fing_end_clear, " mm"));
