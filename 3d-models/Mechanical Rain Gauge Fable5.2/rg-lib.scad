// rg-lib.scad: helpers for mechanical-rain-gauge.scad (included, not standalone).
// Involute spur gears with profile shift, teardrop holes, small 2D utilities.

function inv_rad(a) = tan(a) - a * PI / 180;                 // involute function, a in degrees, result in radians
function gear_r(z) = gear_m * z / 2;                         // pitch radius
function gear_rb(z) = gear_r(z) * cos(gear_pa);              // base radius
function gear_ra(z, x, short = 0) = gear_r(z) + gear_m * (1 + x) - short;   // tip radius
function gear_rf(z, x) = gear_r(z) - gear_m * (1.25 - x);    // root radius
function gear_s(z, x, bl) = gear_m * (PI / 2 + 2 * x * tan(gear_pa)) - bl;  // tooth thickness on pitch circle
// half tooth angle (degrees) at radius q
function gear_ha(z, x, bl, q) =
    (gear_s(z, x, bl) / (2 * gear_r(z)) + inv_rad(gear_pa) - inv_rad(acos(min(1, gear_rb(z) / q)))) * 180 / PI;
function gear_tip_w(z, x, short) = 2 * gear_ha(z, x, 0, gear_ra(z, x, short)) * PI / 180 * gear_ra(z, x, short);
// transverse contact ratio of a pair on centre distance a
function gear_eps(z1, x1, s1, z2, x2, s2, a) =
    (sqrt(pow(gear_ra(z1, x1, s1), 2) - pow(gear_rb(z1), 2)) + sqrt(pow(gear_ra(z2, x2, s2), 2) - pow(gear_rb(z2), 2))
     - a * sin(acos((gear_rb(z1) + gear_rb(z2)) / a))) / (PI * gear_m * cos(gear_pa));
// rotation of driven gear B (zb at direction phi from A) that meshes with A (za, rotation ra): tooth 0 on +X at rotation 0
function mesh_rot(za, ra, zb, phi) = phi + 180 + 180 / zb - (ra - phi) * za / zb;

module gear2d(z, x = 0, short = 0, bl = gear_backlash) {
    ra = gear_ra(z, x, short); rf = gear_rf(z, x); r0 = max(gear_rb(z), rf) + 0.001;
    n = 10;
    flank = [for (i = [0:n]) let (q = r0 + (ra - r0) * i / n, a = gear_ha(z, x, bl, q)) [q, a]];
    a0 = gear_ha(z, x, bl, r0);
    tooth = concat([[rf - 0.05, -a0]], [for (p = flank) [p[0], -p[1]]],
                   [for (i = [n:-1:0]) flank[i]], [[rf - 0.05, a0]]);
    union() {
        circle(r = rf, $fn = max(48, 4 * z));
        for (k = [0:z - 1]) rotate(k * 360 / z)
            polygon([for (p = tooth) [p[0] * cos(p[1]), p[0] * sin(p[1])]]);
    }
}

// A gear whose bed layer is drawn 0.15 mm small, so first-layer squish cannot pinch the mesh.
module gear_bed(z, x, h) {
    translate([0, 0, 0.24]) linear_extrude(h - 0.24) gear2d(z, x);
    linear_extrude(0.24 + fudge) offset(delta = -0.15) gear2d(z, x);
}
// A vertical bore from the bed with a 45-degree lead-in, so first-layer squish cannot pinch the shaft.
module bore(d, h, cham = 0.4) {
    translate([0, 0, -fudge]) cylinder(d = d, h = h + 2 * fudge, $fn = 40);
    translate([0, 0, -fudge]) cylinder(d1 = d + 2 * cham, d2 = d, h = cham + fudge, $fn = 40);
}

// Horizontal hole with a 45-degree roof (prints without support). axis "x" or "y".
module teardrop_hole(d, h, axis = "y") {
    r = d / 2;
    rotate([0, 0, axis == "x" ? 90 : 0]) rotate([90, 0, 0])
        linear_extrude(height = h, center = true)
            union() { circle(r = r); rotate(45) square(r); }
}

// polar helpers (degrees)
function pol(r, a) = [r * cos(a), r * sin(a)];
module ring2d(ro, ri) { difference() { circle(r = ro); circle(r = ri); } }
module sector2d(r, a0, a1, n = 24) {
    polygon(concat([[0, 0]], [for (i = [0:n]) pol(r, a0 + (a1 - a0) * i / n)]));
}
// Parts printed with their FRONT face on the bed are designed in front-view coordinates
// (x = right, y = up, z = towards the back) and mirrored once to become a real right-handed solid.
module front_down() { mirror([1, 0, 0]) children(); }
