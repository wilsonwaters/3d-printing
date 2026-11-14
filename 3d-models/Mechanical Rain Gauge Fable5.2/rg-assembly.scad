// rg-assembly.scad: poses, assembly view, interference checks and the part selector.

// ---- pose helpers ----
function esc_adv(stroke, ang) = lookup(ang, [for (r = esc_table) if (r[0] == stroke) [r[1], r[2]]]);   // clamps beyond +-21 (dwell)
function dir_ang(a, b) = atan2(b[1] - a[1], b[0] - a[0]);
function wheel_rot(P) = pw_ang - (135 + esc_adv(P[0], P[1]));                       // x1 pin wheel (front view, CCW +)
function idler_rot(i, P) = mesh_rot(z_p1, i == 0 ? wheel_rot(P) : cluster_rot(i, P), z_g1, dir_ang(dial_pos(i), idler_pos(i)));
function cluster_rot(i, P) = mesh_rot(z_p2, idler_rot(i - 1, P), z_g2, dir_ang(idler_pos(i - 1), dial_pos(i)));
function ptr_rot(i, P) = -360 * P[2] / pow(10, i + 1);                              // pointers turn clockwise
// roller seat: closest the roller centre gets to the dial axis when both flanks of the cusp touch it
seat_q = max([for (a = [0:0.25:89]) let (r = cam_r(a), h = r * sin(a)) if (h < roller_d / 2) r * cos(a) + sqrt(pow(roller_d / 2, 2) - h * h)]);
reset_stroke = roller_rest - seat_q;
function bar_lift(P) = P[3] * (reset_stroke - 0.05);
lift = 0.05;                                                                         // poses resting contacts just apart

module reg_frame() { translate([0, bp_rear_y, 0.02]) rotate([90, 0, 0]) children(); }
module fd(f_front) { translate([0, 0, f_front]) rotate([0, 180, 0]) children(); }    // seat a front-down part
module spin(pos, f, ang) { translate([pos[0], pos[1], f]) rotate(ang) children(); }

n_elem = 29;
module elem(i, P) {
    if (i == 0) reg_frame() back_plate();
    if (i == 1) reg_frame() translate([0, 0, 0.02]) fd(f_card) dial_plate();
    if (i == 2) reg_frame() translate([0, 0, f_card + 0.04]) dial_card();
    if (i == 3) translate([0, 0, -base_t]) base();
    if (i == 4) translate([0, 0, 0.02]) collector_use();
    if (i == 5) translate([0, 0, pivot_z + lift]) rotate([0, P[1], 0]) bucket();
    if (i == 6) reg_frame() translate([0, lift, f_anchor + anchor_t]) translate(pivot_pos) rotate(-P[1]) translate(-pivot_pos) rotate([0, 180, 0]) anchor();
    if (i == 7) reg_frame() spin(dial_pos(0), f_disc, wheel_rot(P)) units_wheel(false);
    if (i >= 8 && i <= 10) { k = i - 7;                                              // clusters on dials 1..3
        reg_frame() if (cluster_front(k)) spin(dial_pos(k), f_C + gear_t, cluster_rot(k, P)) rotate([180, 0, 0]) cluster(false);
                    else spin(dial_pos(k), f_B, cluster_rot(k, P)) cluster(false); }
    if (i >= 11 && i <= 13) { k = i - 11;                                            // idlers 0..2
        reg_frame() if (idler_front(k)) spin(idler_pos(k), f_A, idler_rot(k, P)) idler();
                    else spin(idler_pos(k), f_A + gear_t, idler_rot(k, P)) rotate([180, 0, 0]) idler(); }
    if (i >= 14 && i <= 17) { k = i - 14;
        reg_frame() spin(dial_pos(k), f_cam + cam_t, ptr_rot(k, P)) rotate([0, 180, 0]) rotor(k == 2 ? collar_short : collar_long); }
    if (i >= 18 && i <= 21) { k = i - 18;
        reg_frame() spin(dial_pos(k), f_ptr + ptr_t, ptr_rot(k, P)) rotate([0, 180, 0]) pointer(); }
    if (i == 22) reg_frame() translate([0, bar_lift(P), f_slide]) slide();
    if (i >= 23 && i <= 26) { k = i - 23;
        reg_frame() translate([dial_x[k], dial_z - roller_rest + bar_lift(P), f_slide + slide_t + 0.35]) roller(); }
    if (i == 28) translate([0, 0, guard_z + 0.05]) leaf_guard();
    if (i == 27) for (sx = [-1, 1]) translate([sx * stop_x, 0, pivot_z - stop_x * tan(tilt_nom) - 20]) cylinder(d = 2.7, h = 20, $fn = 16);   // calibration screws (M3 x 20), view only
}
function elem_col(i) = i <= 2 ? "#e8e4d8" : i == 3 ? "#cfd6da" : i == 4 ? "#f4f4f0" : i == 5 ? "#3f88c5" : i == 6 ? "#d1495b"
    : i == 7 ? "#edae49" : i <= 10 ? "#c9a227" : i <= 13 ? "#b08d57" : i <= 17 ? "#66a182" : i <= 21 ? "#222222" : i <= 26 ? "#8f5fbf" : "#888888";
module clash_guard() { intersection() { collector_use(); translate([0, 0, guard_z + 0.05]) leaf_guard(); } }
module assembly(P, skip = []) { for (i = [0:n_elem - 1]) if (len(search(i, skip)) == 0) color(elem_col(i)) elem(i, P); }
n_clash = 27;   // element 27 (the screws) is for the view only
module clash_all(P) { for (i = [0:n_clash - 2], j = [i + 1:n_clash - 1]) intersection() { elem(i, P); elem(j, P); } }
module clash_esc(P) { intersection() { elem(6, P); elem(7, P); } }

// ---- print layouts ----
module plate_register() {     // every small register part on one plate
    for (k = [0:2]) translate([k * 40, 0, 0]) cluster();
    for (k = [0:2]) translate([k * 32, 40, 0]) idler();
    translate([28, 82, 0]) units_wheel();
    for (k = [0:2]) translate([70 + k * 30, 76, 0]) rotor(collar_long);
    translate([70, 104, 0]) rotor(collar_short);
    for (k = [0:3]) translate([100 + k * 16, 104, 0]) pointer();
    for (k = [0:3]) translate([100 + k * 12, 40, 0]) roller();
}

// === CONTRACTS: every claim the header and README make, checked on each compile ===
esc_done_deg = 14.6;        // anchor angle at which a tip has finished moving the wheel (calc/escapement.py)
tail_low_z = pivot_z + (esc_lt + esc_w / 2) * sin(pw_ang - (esc_psi + pal_tail + tilt_max));   // lowest point the anchor sweeps
sleeve_gap = min([for (p = pallet1_pts()) let (a = atan2(p[1], p[0]) - tilt_max, r = norm(p)) norm([r * cos(a) - esc_d, r * sin(a)])]) - wheel_sleeve_r;
mast_top_z = pivot_z - knife_r + bk_floor + bk_mast_h;
echo(orifice_d = orifice_d, tip_volume_ml = tip_volume_ml, dial_z = dial_z, pw_ang = pw_ang, reg_depth = reg_depth, rim_z = rim_z);
echo(contact_ratio_1 = gear_eps(z_p1, x_pin, pin_short, z_g1, -x_pin, 0, a1), contact_ratio_2 = gear_eps(z_p2, x_pin, pin_short, z_g2, -x_pin, 0, a2),
     tip_land_p1 = gear_tip_w(z_p1, x_pin, pin_short), tip_land_p2 = gear_tip_w(z_p2, x_pin, pin_short));
echo(cam_rmax = cam_rmax, reset_stroke = reset_stroke, tail_low_z = tail_low_z, sleeve_gap = sleeve_gap, mast_top_z = mast_top_z);
assert(abs(PI * orifice_d * orifice_d / 4 - collector_area_cm2 * 100) < 0.01, "orifice area");
assert(abs(tip_volume_ml - 10) < 1e-6, "0.5 mm on 200 cm2 is 10 ml per tip");
assert(abs(tips_per_rev * tip_mm - 10) < 1e-9, "one turn of the x1 pointer must be 10 mm");
assert(z_g1 * z_g2 == 10 * z_p1 * z_p2, "each stage must be exactly 10:1");
assert(gear_eps(z_p1, x_pin, pin_short, z_g1, -x_pin, 0, a1) > 1.2 && gear_eps(z_p2, x_pin, pin_short, z_g2, -x_pin, 0, a2) > 1.2, "contact ratio");
assert(gear_tip_w(z_p1, x_pin, pin_short) >= 0.4 && gear_tip_w(z_p2, x_pin, pin_short) >= 0.4, "pinion tip land too thin to print");
assert(esc_rp == 21 && esc_pin_d == 4 && esc_c == 0.6 && esc_blade == 4.5 && esc_blade1 == 3.5 && esc_ramp == 7 && esc_dwell == 5.5 && esc_lead == 1.5 && esc_lead1 == 0.5 && esc_tip_w == 1,
       "escapement changed: rerun calc/escapement.py and paste its new esc_table and esc_done_deg");
assert(esc_done_deg <= tilt_min - 2, "a tip must finish driving the wheel before the bucket reaches its stop");
assert(esc_dwell >= (tilt_max - esc_done_deg) * PI / 180 * esc_lt, "pallet dwell too short for the over-travel at tilt_max");
assert(sleeve_gap >= 0.5, "pallet 1 tip too close to the wheel sleeve at tilt_max");
assert(tail_low_z >= 1.5, "anchor would sweep into the base floor");
assert(tilt_min > 15, "the lowered floor must slope enough to drain");
assert(mast_top_z <= nozzle_z - 1, "bucket mast would hit the nozzle");
assert(funnel_slope >= 45, "WMO: funnel at least 45 degrees");
assert(2 * PI * guard_r / guard_spokes - guard_spoke_w <= 7 && guard_z + guard_t + 7 < funnel_top_z, "leaf guard gaps or seat");
assert(90 - funnel_slope <= 45, "funnel overhang when printed rim-down");
assert(rim_z <= build_z - 6, "collector too tall for the printer");
assert(2 * ear_r <= bed_free, "base must fit the bed without the exclusion-zone clip");
assert(cam_rmax + 0.5 <= a1 - 2.5 && 2 * cam_rmax + 1 <= dial_pitch, "heart cam fouls an idler post or its neighbour");
echo(reset_arm_cusp = reset_arm(cam_rmin), reset_arm_tip = reset_arm(cam_rmax));
assert(reset_arm(cam_rmin) >= 0.5 && reset_arm(cam_rmax) >= 0.5, "reset would stall: the cam's lift cannot beat roller and journal friction");
assert(reset_stroke <= reset_travel - 0.3, "reset bar slots too short to seat the rollers");
assert(dial_z - roller_rest + 2.6 + reset_stroke < dial_z - collar_d / 2 - 0.5, "reset bar would hit the rotor collars");
assert(norm([plate_x, reg_front_y + dp_t]) < upstand_ro && norm([bar_x, bp_rear_y - f_slide]) < upstand_ro - 2, "register must fit inside the skirt");
assert(bp_rear_y + 1.2 < collar_y - 1.2 + 0.01 || bp_rear_y < -bk_y - 3, "bucket too close to the back plate");
