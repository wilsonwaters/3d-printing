// rg-wet.scad: tipping bucket, base and collector (included by mechanical-rain-gauge.scad).
// Gauge coordinates: x = right, y = back (the register faces -y), z = up from the base floor.

// ---- tipping bucket (prints as used: floor on the bed, knife edges on the bed) ----
bk_y = bk_W / 2 + bk_wall;                       // outer face of each end wall
trunnion_len = 6;
neck_straight_end = bp_rear_y - (bp_t + 0.2);    // gauge y where the neck starts to taper
neck_tip_f = f_anchor + anchor_t - 1.5;            // stops short of the hub's front face: room for the taper to seat deeper
neck_tip_y = bp_rear_y - neck_tip_f;
collar_y = -bk_y - 1.0;                          // drip collar between the bucket and the back plate
module bucket_end2d() {                          // end wall profile (x along the floor, y up)
    polygon([[-bk_L, 0], [bk_L, 0], [bk_L, bk_floor + bk_end_h], [bk_mast_t / 2, bk_floor + bk_end_peak],
             [-bk_mast_t / 2, bk_floor + bk_end_peak], [-bk_L, bk_floor + bk_end_h]]);
}
module key_prism(y0, y1, k0 = 1, k1 = 1) {       // knife-edge prism between two gauge y positions
    hull() {
        translate([0, y0, 0]) rotate([90, 0, 0]) linear_extrude(fudge) key2d(k0);
        translate([0, y1 + fudge, 0]) rotate([90, 0, 0]) linear_extrude(fudge) key2d(k1);
    }
}
module bucket() {                                // origin: pivot axis (centre of the knife radius), centred in y
    union() {
      translate([0, 0, -knife_r]) {
        translate([-bk_L, -bk_y, 0]) cube([2 * bk_L, 2 * bk_y, bk_floor]);
        hull() {                                 // ballast mast with a roof so drops run off
            translate([-bk_mast_t / 2, -bk_W / 2 - fudge, 0]) cube([bk_mast_t, bk_W + 2 * fudge, bk_floor + bk_mast_h - bk_mast_t / 2]);
            translate([-0.4, -bk_W / 2 - fudge, 0]) cube([0.8, bk_W + 2 * fudge, bk_floor + bk_mast_h]);
        }
        for (sy = [-1, 1]) translate([0, sy > 0 ? bk_y : -bk_W / 2, 0]) rotate([90, 0, 0]) linear_extrude(bk_wall) bucket_end2d();
        translate([0, collar_y, 0]) rotate([90, 0, 0]) linear_extrude(1.2)       // drip collar
            intersection() { translate([0, 4]) circle(r = 8.5, $fn = 48); translate([-10, 0]) square([20, 20]); }
      }
        key_prism(bk_y + trunnion_len, bk_y - 0.5);                              // rear trunnion
        key_prism(-bk_y + 0.5, neck_straight_end);                               // neck through the back plate
        key_prism(neck_straight_end + fudge, neck_tip_y, 1, key_scale(neck_tip_f));   // tapered seat for the anchor
    }
}

// ---- base (prints as used; z = 0 here is the underside, the floor top is at base_t) ----
post_y0 = bk_y + 0.8;                            // rear pivot post front face
post_len = trunnion_len + 2.0;                   // V slot length; the rocker is located endways by the anchor hub, not here
post_w = 16;
boss_top_z = 19; boss_d = 11; head_recess_z = 6; // calibration screw boss (M3 x 20 from below)
foot_screw_y = bp_rear_y - (bp_t + foot_d / 2);
skirt_screw_z = 4.5;
skirt_screw_ang = [0, 90, 180];
upstand_ro = orifice_r - tolerance;
module drain_slots2d() {
    for (sx = [-1, 1], j = [-3:3]) hull() for (xx = [39, 62 - abs(j) * 1.5]) translate([sx * xx, j * 6]) circle(d = 4, $fn = 16);
    for (yy = [-65, -72]) hull() for (xx = [-22, 22]) translate([xx, yy]) circle(d = 4, $fn = 16);   // apron in front of the dials
}
module base() {
    difference() {
        union() {
            hull() { cylinder(r = skirt_ro - ef_chamfer, h = fudge, $fn = 180); translate([0, 0, ef_chamfer]) cylinder(r = skirt_ro, h = base_t - ef_chamfer, $fn = 180); }
            for (a = [90, 210, 330]) hull() {
                rotate(a) translate([ear_r, 0, 0]) cylinder(r = 8, h = base_t);
                rotate(a) translate([skirt_ro - 12, -11, 0]) cube([4, 22, base_t]);
            }
            translate([0, 0, base_t - fudge]) {
                difference() {                   // upstand ring that centres the collector skirt
                    cylinder(r = upstand_ro, h = upstand_h, $fn = 180);
                    translate([0, 0, -1]) cylinder(r = upstand_ro - 2.0, h = upstand_h + 2, $fn = 180);
                    translate([-notch_half - 1, -100, -1]) cube([2 * notch_half + 2, 52, upstand_h + 2]);
                }
                intersection() {                 // pads behind the three skirt screws
                    cylinder(r = upstand_ro, h = upstand_h, $fn = 180);
                    for (a = skirt_screw_ang) rotate(a) translate([upstand_ro - 7, -4.5, 0]) cube([8, 9, upstand_h]);
                }
                // rear pivot post with a buttress
                translate([-post_w / 2, post_y0, 0]) cube([post_w, post_len + 2, pivot_z + 9]);
                hull() {
                    translate([-post_w / 2, post_y0 + post_len + 2 - fudge, 0]) cube([post_w, fudge, pivot_z - 2]);
                    translate([-post_w / 2, post_y0 + post_len + 2, 0]) cube([post_w, 16, fudge]);
                }
                for (sx = [-1, 1]) translate([sx * stop_x, 0, 0]) cylinder(d = boss_d, h = boss_top_z);
            }
        }
        translate([0, 0, -fudge]) linear_extrude(base_t + 2 * fudge) drain_slots2d();
        for (a = [90, 210, 330]) rotate(a) translate([ear_r, 0, -fudge]) cylinder(d = ear_hole + hole_comp, h = base_t + 2 * fudge, $fn = 24);
        // pivot V slot, open at the top
        translate([0, post_y0 - fudge, base_t + pivot_z]) rotate([-90, 0, 0]) mirror([0, 1, 0])
            linear_extrude(post_len + fudge) union() { vee2d(key_swing_r); translate([-key_swing_r, key_swing_r * 0.6]) square([2 * key_swing_r, 20]); }
        // calibration screws: head recess from below, clearance, then a self-tap pilot to the top of the boss
        for (sx = [-1, 1]) translate([sx * stop_x, 0, 0]) {
            translate([0, 0, -fudge]) cylinder(d = 6.5, h = base_t + head_recess_z + fudge, $fn = 32);
            cylinder(d = screw_clear, h = base_t + head_recess_z + 3, $fn = 24);
            cylinder(d = screw_pilot, h = base_t + boss_top_z + 1, $fn = 24);
        }
        // register feet: countersunk M3 from below
        for (sx = [-1, 1]) translate([sx * foot_x, foot_screw_y, 0]) {
            translate([0, 0, -fudge]) cylinder(d = screw_clear, h = base_t + 1, $fn = 24);
            translate([0, 0, -fudge]) cylinder(d1 = 6.6, d2 = screw_clear, h = 1.6, $fn = 32);
        }
        // skirt screws: radial self-tap pilots
        for (a = skirt_screw_ang) rotate(a) translate([upstand_ro + fudge, 0, base_t + skirt_screw_z]) rotate([0, -90, 0]) self_tap(7.5);
    }
}

// ---- collector: rim, funnel, nozzle and skirt in one piece ("inverted bucket") ----
throat_z = funnel_top_z - (orifice_r - nozzle_id / 2) * tan(funnel_slope);
funnel_tv = funnel_t / cos(funnel_slope);        // vertical thickness of the cone
nozzle_ro = nozzle_id / 2 + 1.6;
rim_land = 0.9;                                  // flat on the rim (2 perimeters), bevelled 30 degrees outside
module collector_profile2d() {
    bevel_h = (wall_t - rim_land) / tan(30);
    polygon([[orifice_r, 0], [skirt_ro, 0], [skirt_ro, rim_z - bevel_h], [orifice_r + rim_land, rim_z], [orifice_r, rim_z]]);
    polygon([[orifice_r + fudge, funnel_top_z], [nozzle_id / 2, throat_z], [nozzle_id / 2, nozzle_z], [nozzle_ro, nozzle_z],
             [nozzle_ro, throat_z + (nozzle_ro - nozzle_id / 2) * tan(funnel_slope) - funnel_tv], [orifice_r + fudge, funnel_top_z - funnel_tv]]);
}
module collector_use() {                         // gauge coordinates, skirt bottom on the base ledge at z = 0
    difference() {
        rotate_extrude($fn = 180) collector_profile2d();
        translate([-notch_half, -100, -1]) cube([2 * notch_half, 60, notch_top + 1]);          // register window
        for (a = skirt_screw_ang) rotate(a) translate([orifice_r + wall_t / 2, 0, skirt_screw_z]) mirror([0, 0, 1]) teardrop_hole(screw_clear, wall_t + 2, "x");   // point down: up when printed
    }
}
module collector() { translate([0, 0, rim_z]) rotate([180, 0, 0]) collector_use(); }           // printed rim-down

// ---- leaf guard: a spoked star that sits in the funnel above the nozzle (optional) ----
guard_r = 20; guard_t = 2; guard_spokes = 16; guard_spoke_w = 1.6;
guard_seat_r = guard_r - guard_t / tan(funnel_slope);                      // radius of the spoke tips' lower edge
guard_z = throat_z + (guard_seat_r - nozzle_id / 2) * tan(funnel_slope);   // height at which that edge meets the funnel
module leaf_guard() {
    intersection() {
        union() {
            cylinder(r = 5, h = guard_t, $fn = 32);
            cylinder(r = 2.5, h = guard_t + 7, $fn = 24);                  // lifting knob
            for (k = [0:guard_spokes - 1]) rotate(k * 360 / guard_spokes) translate([4, -guard_spoke_w / 2, 0]) cube([guard_r - 4, guard_spoke_w, guard_t]);
        }
        cylinder(r1 = guard_seat_r, r2 = guard_seat_r + 20 / tan(funnel_slope), h = 20, $fn = 96);   // tips cut to the funnel's slope
    }
}

// ---- foot: one under each mounting ear. They lift the base so the drains run free and the
//      calibration screws can be reached from below with a hex key while the gauge is mounted ----
foot_h = 20; foot_d_out = 18;
module foot() {
    difference() {
        hull() { cylinder(d = foot_d_out - 2 * ef_chamfer, h = fudge, $fn = 48); translate([0, 0, ef_chamfer]) cylinder(d = foot_d_out, h = foot_h - ef_chamfer, $fn = 48); }
        bore(ear_hole + hole_comp, foot_h);
    }
}
