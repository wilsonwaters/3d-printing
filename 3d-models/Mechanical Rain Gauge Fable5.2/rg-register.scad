// rg-register.scad: the dial register (included by mechanical-rain-gauge.scad).
// Front-view coordinates everywhere: x = right, y = height above the base floor.
// Rear-down parts grow forward (+z = towards the viewer); front-down parts are wrapped in front_down().

// ---- shared positions ----
so_low = [[52, 28], [-52, 28]];        // lower standoffs: their stepped tips also guide the reset bar
so_top = [-53, 75];                    // upper standoff
so_d = 9; so_tip_d = 6;
foot_x = 52; foot_w = 9; foot_h = 10; foot_d = 9;
plate_x = 55.5; plate_y0 = 22; plate_y1 = 77;
bp_shield_x = dial_x[0] + esc_rp + esc_pin_d / 2 + 2.5;   // back plate edge that covers the pin wheel
tab_x0 = 22; tab_x1 = 36;              // reset tab
run_d_arbor = arbor_d + hole_comp + fit_run;     // free-running bore on the arbors and posts
run_d_stub = stub_d + hole_comp + fit_run;
screw_clear = 3 + hole_comp + fit_run;           // M3 clearance
screw_pilot = 2.8;                               // M3 self-tap pilot (D - 0.4 P)
collar_long = f_cam - (f_A + gear_t + 0.1);      // dials x1, x10, x1000: cluster front face is in plane A
collar_short = f_cam - (f_C + gear_t + 0.1);     // dial x100: cluster front face is in plane C
function boss_top(i) = i == 2 ? f_A - 0.1 : f_B - 0.1;     // rear stop of each cluster
function cluster_front(i) = i == 2;                        // true: big gear in front (plane C), pinion behind (A)
function idler_front(i) = i == 1;                          // true: pinion in front (plane C), gear behind (A)

module self_tap(len) {   // along +z from z = 0
    translate([0, 0, -fudge]) cylinder(d = screw_clear, h = 1.5 + fudge, $fn = 24);
    cylinder(d = screw_pilot, h = len, $fn = 24);
}

// ---- knife-edge key (rocker frame: the origin is the centre of the edge radius = the true pivot axis, up = +y) ----
module key2d(k = 1, grow = 0) {
    offset(delta = grow) scale(k) hull() {
        circle(r = knife_r, $fn = 16);
        translate([-key_w / 2, key_w / 2 / tan(knife_half) - knife_r]) square([key_w, key_h - key_w / 2 / tan(knife_half)]);
    }
}
function key_scale(f) = 1 - max(0, f - (bp_t + 0.2)) * tan(key_taper) / (key_w / 2);   // neck taper along f
key_swing_r = norm([key_w / 2, key_h]) + 0.7;
vee_half = knife_half + tilt_max + 2.5;      // V-groove half angle: the knife never touches a flank
module vee2d(r) {                            // V-bottomed pivot opening; the round edge sits tangent to both flanks
    intersection() {
        circle(r = r);
        translate([0, -knife_r / sin(vee_half)]) polygon([[0, 0], pol(2 * r, 90 - vee_half), [2 * r, 2 * r], [-2 * r, 2 * r], pol(2 * r, 90 + vee_half)]);
    }
}

// ---- back plate (rear-down) ----
module plate_outline2d(x, y0, y1, r = 3) {
    hull() for (sx = [-1, 1], yy = [y0 + r, y1 - r]) translate([sx * (x - r), yy]) circle(r = r, $fn = 24);
}
module back_plate() {
    difference() {
        union() {
            linear_extrude(bp_t) hull() {                                   // wider on the pin-wheel side: splash shield
                plate_outline2d(foot_x + foot_w / 2, 0, 80);
                translate([bp_shield_x - 3, 3]) circle(r = 3, $fn = 24); translate([bp_shield_x - 3, 77]) circle(r = 3, $fn = 24);
            }
            for (i = [1:3]) translate(dial_pos(i)) cylinder(d = collar_d, h = boss_top(i));
            translate(dial_pos(0)) cylinder(d = 10, h = f_disc - 0.2);            // thrust pad for the pin wheel
            for (p = so_low) translate(p) { cylinder(d = so_d, h = f_slide - 0.15); cylinder(d = so_tip_d, h = f_dp); }
            translate(so_top) cylinder(d = so_d - 1, h = f_dp);
            for (sx = [-1, 1]) translate([sx * foot_x - foot_w / 2, 0, 0]) cube([foot_w, foot_h, bp_t + foot_d]);
            translate(idler_pos(2)) {      // idler 2 runs on a post from this plate (a front post would cross the x100 gear)
                cylinder(d = 6, h = f_B - 0.1);
                cylinder(d = post_d, h = f_A + gear_t - 0.3);
            }
        }
        translate([pivot_pos[0], pivot_pos[1], -fudge]) linear_extrude(bp_t + 2 * fudge) vee2d(key_swing_r);
        for (i = [0:3]) translate([dial_x[i], dial_z, 0]) bore(run_d_arbor, 40);
        for (p = concat(so_low, [so_top])) translate([p[0], p[1], f_dp + fudge]) mirror([0, 0, 1]) self_tap(9);
        for (sx = [-1, 1]) translate([sx * foot_x, 0, bp_t + foot_d / 2]) rotate([-90, 0, 0]) self_tap(foot_h - 1.5);
    }
}

// ---- dial plate (front-down): journals for the pointer stubs, posts for the idlers ----
module dial_outline2d() {
    difference() {
        plate_outline2d(plate_x, plate_y0, plate_y1);
        translate([tab_x0 - 1.5, plate_y0 - 1]) square([tab_x1 - tab_x0 + 3, 16.5]);     // reset tab travels here
    }
}
function post_shoulder_s(i) = f_card - ((idler_front(i) ? f_C : f_A) + gear_t + 0.1);   // depth behind the plate front
function post_end_s(i) = f_card - ((idler_front(i) ? f_A : f_B) + 0.3);
hub_stop_s = f_card - (f_anchor + anchor_t + 0.4);
module dial_plate() {
    front_down() difference() {
        union() {
            linear_extrude(dp_t) dial_outline2d();
            for (i = [0:1]) translate(idler_pos(i)) {
                cylinder(d = 5, h = post_shoulder_s(i));
                cylinder(d = post_d, h = post_end_s(i));
            }
            translate(pivot_pos) cylinder(d = 6, h = hub_stop_s);                        // end stop for the anchor hub
        }
        for (i = [0:3]) translate([dial_x[i], dial_z, 0]) bore(run_d_stub, dp_t);
        for (p = concat(so_low, [so_top])) translate([p[0], p[1], -fudge]) cylinder(d = screw_clear, h = dp_t + 2 * fudge, $fn = 24);
    }
}

// ---- dial card (rear-down): raised numerals; swap filament at card_t for contrast ----
dial_face_r = 13.2;
module dial_card() {
    labels = ["x1", "x10", "x100", "x1000"];
    difference() {
        union() {
            linear_extrude(card_t) dial_outline2d();
            translate([0, 0, card_t - fudge]) linear_extrude(card_relief + fudge) union() {
                for (i = [0:3]) translate(dial_pos(i)) {
                    ring2d(dial_face_r, dial_face_r - 0.8);
                    for (k = [0:9]) {
                        rotate(90 - 36 * k) translate([dial_face_r - 2.2, -0.4]) square([1.8, 0.8]);
                        translate(pol(8.6, 90 - 36 * k)) text(str(k), size = 3.4, font = "Liberation Sans:style=Bold",
                                                                halign = "center", valign = "center", $fn = 12);
                    }
                    translate([0, -dial_face_r - 4.6]) text(labels[i], size = 3.6, font = "Liberation Sans:style=Bold",
                                                              halign = "center", valign = "center", $fn = 12);
                }
                translate([4, plate_y1 - 5]) text("RAINFALL  mm", size = 4.2, font = "Liberation Sans:style=Bold",
                                                   halign = "center", valign = "center", $fn = 12);
            }
            for (i = [0:3]) translate(dial_pos(i)) cylinder(r = 5, h = card_t + card_relief + 0.3);   // pointer thrust boss
        }
        for (i = [0:3]) translate([dial_x[i], dial_z, -fudge]) cylinder(d = stub_d + 1.6, h = 5, $fn = 40);
        for (p = concat(so_low, [so_top])) translate([p[0], p[1], -fudge]) cylinder(d = screw_clear, h = 5, $fn = 24);
    }
}

// ---- rotor (front-down): heart cam + collar + arbor. One per dial; the pointer stub presses into its face ----
module cam2d() {   // cusp (pointer at 0) points down, towards the reset roller
    polygon([for (a = [-180:3:180]) pol(cam_r(a), -90 + a)]);
}
module dee2d(d) { intersection() { circle(d = d, $fn = 40); translate([-d, -d]) square([2 * d, d + 0.72 * d / 2]); } }
socket_depth = 3.0;
module rotor(collar_len) {
    arbor_end = (f_cam + cam_t) - 0.4;           // total length: stops 0.4 short of the back plate's rear face
    front_down() difference() {
        union() {
            linear_extrude(cam_t) cam2d();
            cylinder(d = collar_d, h = cam_t + collar_len);
            cylinder(d = arbor_d, h = arbor_end - 0.5, $fn = 32);
            translate([0, 0, arbor_end - 0.5 - fudge]) cylinder(d1 = arbor_d, d2 = arbor_d - 1, h = 0.5, $fn = 32);
        }
        translate([0, 0, -fudge]) linear_extrude(socket_depth) dee2d(stub_d + hole_comp + fit_press);
    }
}

// ---- pointer (front-down): needle + balanced tail + D-shaped stub ----
stub_len = f_ptr - (f_cam + cam_t - socket_depth + 0.2);
module pointer() {
    front_down() union() {
        linear_extrude(ptr_t) union() {
            circle(d = 8, $fn = 40);
            polygon([[-1.3, 0], [1.3, 0], [0.5, 9.2], [-0.5, 9.2]]);
            hull() { translate([-1.3, -4]) square([2.6, 4]); translate([0, -4.6]) circle(r = 2.1, $fn = 24); }
        }
        linear_extrude(ptr_t + stub_len) dee2d(stub_d);
    }
}

// ---- friction clutch: a cantilever beam inside the gear web that drags on the rotor arbor ----
clutch_L = 12; clutch_t = 0.9; clutch_slot = 0.8; clutch_defl = 0.6; clutch_roof = 0.4;   // roof = air gap = 2 layers
clutch_face = (-(run_d_arbor - hole_comp) / 2 + arbor_d) - clutch_defl;   // beam face height above the bore centre
module clutch_cut2d() {   // slots that free the beam (the beam itself is left standing)
    y0 = clutch_face; y1 = y0 + clutch_t;
    translate([-clutch_L, y1]) square([clutch_L + 2.0 + clutch_slot, clutch_slot]);           // above the beam
    translate([2.0, y0 - 0.4]) square([clutch_slot, clutch_t + clutch_slot + 0.4]);           // free end
    translate([-clutch_L + 1.5, y0 - clutch_slot]) square([clutch_L - 1.5, clutch_slot]);     // below the beam, into the bore
}
module clutch_roof2d() {   // gap over the beam so it is not fused to the layers above
    translate([-clutch_L + 0.8, clutch_face - clutch_slot]) square([clutch_L + 1.9 + clutch_slot, clutch_t + 2 * clutch_slot]);
}
module clutch_beam(h) {    // the beam itself: re-added after the bore is cut, because it reaches into the bore
    linear_extrude(h - 2 * clutch_roof) translate([-clutch_L - 0.5, clutch_face]) square([clutch_L + 2.5, clutch_t]);
}
module clutch_cut(h) {     // h = thickness of the layer holding the beam
    translate([0, 0, -fudge]) linear_extrude(h - clutch_roof + fudge) clutch_cut2d();
    translate([0, 0, h - 2 * clutch_roof]) linear_extrude(clutch_roof) clutch_roof2d();
}

// ---- gear cluster (x10, x100, x1000 dials): 32-tooth gear + 8-tooth pinion ----
module cluster(beam = true) {     // beam = false poses the part without its (deliberately interfering) clutch beam
    if (beam) clutch_beam(gear_t);
    difference() {
        union() {
            gear_bed(z_g2, -x_pin, gear_t);
            cylinder(r = gear_rf(z_p1, x_pin), h = gear_t + gear_gap + fudge, $fn = 32);
            translate([0, 0, gear_t + gear_gap]) linear_extrude(gear_t) gear2d(z_p1, x_pin, pin_short);
        }
        bore(run_d_arbor, 2 * gear_t + 2);
        clutch_cut(gear_t);
    }
}

// ---- idler: 25-tooth gear + 10-tooth pinion, free on a dial-plate post ----
module idler() {
    difference() {
        union() {
            gear_bed(z_g1, -x_pin, gear_t);
            cylinder(r = gear_rf(z_p2, x_pin), h = gear_t + gear_gap + fudge, $fn = 32);
            translate([0, 0, gear_t + gear_gap]) linear_extrude(gear_t) gear2d(z_p2, x_pin, pin_short);
        }
        bore(run_d_arbor, 2 * gear_t + 2);
    }
}

// ---- x1 pin wheel (rear-down): disc + 10 pins + sleeve + drive pinion ----
wheel_disc_r = esc_rp + esc_pin_d / 2 + 0.5;
wheel_sleeve_r = 3.3;
module units_wheel(beam = true) {
    z_cone = f_A - 2.0 - f_disc; z_pin = f_A - f_disc;
    if (beam) clutch_beam(disc_t);
    difference() {
        union() {
            cylinder(r = wheel_disc_r, h = disc_t);
            for (k = [0:esc_n - 1]) rotate(k * 360 / esc_n) translate([esc_rp, 0, 0]) cylinder(d = esc_pin_d, h = disc_t + pin_h, $fn = 32);
            cylinder(r = wheel_sleeve_r, h = z_cone + fudge, $fn = 40);
            intersection() {     // pinion teeth grow out of the sleeve on a 45-degree cone (no support)
                translate([0, 0, z_cone]) linear_extrude(z_pin - z_cone + gear_t) gear2d(z_p1, x_pin, pin_short);
                translate([0, 0, z_cone]) cylinder(r1 = wheel_sleeve_r, r2 = wheel_sleeve_r + 30, h = 30);
            }
        }
        bore(run_d_arbor, 40);
        clutch_cut(disc_t);
    }
}

// ---- escapement pallets (escapement frame, polar about the anchor pivot) ----
function esc_prof(s, b) = s < b ? esc_tip_w : s < b + esc_ramp ? esc_tip_w + (esc_w - esc_tip_w) * (s - b) / esc_ramp : esc_w;
esc_ss = [for (i = [0:2 * esc_len]) i / 2];
esc_ss1 = [for (i = [0:2 * esc_len1]) i / 2];
function rad2deg(a) = a * 180 / PI;
// pallet 2 (at -psi): locking face on the inside, ramp pushes pins outwards
function pallet2_pts(extra = 0) = concat(
    [for (s = esc_ss) pol(esc_lt - esc_w / 2, -esc_psi + rad2deg((esc_lead - s) / esc_lt))],
    [for (i = [len(esc_ss) - 1:-1:0]) let (s = esc_ss[i]) pol(esc_lt - esc_w / 2 + esc_prof(s, esc_blade) + extra, -esc_psi + rad2deg((esc_lead - s) / esc_lt))]);
// pallet 1 (at +psi): locking face on the outside, ramp pushes pins inwards
function pallet1_pts(extra = 0) = concat(
    [for (s = esc_ss1) pol(esc_lt + esc_w / 2, esc_psi - rad2deg((esc_lead1 - s) / esc_lt))],
    [for (i = [len(esc_ss1) - 1:-1:0]) let (s = esc_ss1[i]) pol(esc_lt + esc_w / 2 - esc_prof(s, esc_blade1) - extra, esc_psi - rad2deg((esc_lead1 - s) / esc_lt))]);
module esc_frame() { translate(pivot_pos) rotate(pw_ang) mirror([0, 1, 0]) children(); }   // escapement frame -> front view

// ---- anchor (front-down): plate, two pallets, keyed hub, counterweight ----
band_ri = 31; band_ro = 36;
arm_ang = 22;                          // arm direction in the escapement frame (clear of the x10 boss)
hub_r = 8.5; hub_len = f_anchor + anchor_t - (bp_t + 0.6);
cw_r = 27.3; cw_a0 = 177.5; cw_a1 = 239.5; cw_ri = 6;    // counterweight sector (front-view angles); balanced in calc/balance.py
pal_tail = rad2deg((esc_len - esc_lead) / esc_lt);  // pallet body angle beyond the tangent point
module anchor_plate2d() {
    esc_frame() {
        intersection() { ring2d(band_ro, band_ri); sector2d(60, -esc_psi - pal_tail, esc_psi + pal_tail, 40); }
        hull() { rotate(arm_ang) translate([hub_r - 2, -3]) square([band_ri - hub_r + 4, 6]); }
        polygon(pallet1_pts()); polygon(pallet2_pts());
        // webs joining each pallet's dwell end to the band
        intersection() { ring2d(esc_lt + esc_w / 2, band_ri); sector2d(60, esc_psi + rad2deg((esc_blade + esc_ramp - esc_lead) / esc_lt), esc_psi + pal_tail); }
        intersection() { ring2d(esc_lt + esc_w / 2, band_ri); sector2d(60, -esc_psi - pal_tail, -esc_psi - rad2deg((esc_blade + esc_ramp - esc_lead) / esc_lt)); }
    }
}
module anchor() {
    front_down() difference() {
        union() {
            linear_extrude(anchor_t) anchor_plate2d();
            linear_extrude(anchor_t + pin_h) esc_frame() { polygon(pallet1_pts()); polygon(pallet2_pts()); }
            translate([pivot_pos[0], pivot_pos[1] + key_h / 2, 0]) cylinder(r = hub_r, h = hub_len);
            translate(pivot_pos) linear_extrude(hub_len) intersection() { ring2d(cw_r, cw_ri); sector2d(60, cw_a0, cw_a1); }
        }
        // tapered key socket: narrow at the front (bed), nominal at the back
        translate(pivot_pos) hull() {
            translate([0, 0, -fudge]) linear_extrude(fudge) key2d(key_scale(f_anchor + anchor_t), hole_comp / 2);
            translate([0, 0, hub_len]) linear_extrude(fudge) key2d(key_scale(f_anchor + anchor_t - hub_len), hole_comp / 2);
        }
        translate([pivot_pos[0], pivot_pos[1] + 0.6, -fudge]) cylinder(r = 1.3, h = hub_len + 1, $fn = 20);   // relief round the knife edge
    }
}

// ---- reset bar (rear-down) and rollers ----
bar_y0 = 17; bar_y1 = dial_z - roller_rest + 2.6; bar_x = 56.5;
reset_travel = 10.5;
roller_h = (f_dp - 0.3) - (f_slide + slide_t + 0.3);
tab_reach = 10;                        // how far the tab stands in front of the dial card
module slide() {
    difference() {
        union() {
            linear_extrude(slide_t) plate_outline2d(bar_x, bar_y0, bar_y1, 2);
            for (i = [0:3]) translate([dial_x[i], dial_z - roller_rest, 0]) {
                cylinder(d = roller_post_d + 2.6, h = slide_t + 0.3);
                cylinder(d = roller_post_d, h = (f_dp - 0.3) - f_slide, $fn = 24);
            }
            translate([tab_x0, bar_y0 - 10, 0]) cube([tab_x1 - tab_x0, 12, f_card + card_t + tab_reach - f_slide]);
        }
        // guide slots on the two lower standoff tips and the anchor-hub post
        for (p = so_low) translate([p[0], p[1], -fudge]) linear_extrude(slide_t + 2 * fudge)
            hull() for (dy = [0, -reset_travel]) translate([0, dy]) circle(d = so_tip_d + 0.5, $fn = 24);
        translate([pivot_pos[0], pivot_pos[1], -fudge]) linear_extrude(slide_t + 2 * fudge)
            hull() for (dy = [12, -reset_travel]) translate([0, dy]) circle(d = 6.6, $fn = 24);   // open at the top edge
    }
}
module roller() {
    difference() {
        cylinder(d = roller_d, h = roller_h, $fn = 40);
        bore(roller_post_d + hole_comp + fit_run, roller_h, 0.3);
    }
}
