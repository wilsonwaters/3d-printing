// === DESCRIPTION ===
// Mechanical Tipping-Bucket Rain Gauge — v1 MECHANISM CORE
// A fully mechanical (no electronics) rain gauge that records rainfall on an
// "old-style" 4-dial odometer counter (0000-9999, reads directly in mm of rain).
// A twin-chamber tipping bucket tips once per 1.0 mm of rain and mechanically
// advances the counter one digit per tip. Manual knob/key reset to 0000.
//
// This v1 file is the MECHANISM CORE only (the hard, high-risk part):
//   counter wheels + decade carry + units drive + tipping bucket + frame + reset.
// The Ø159.6 mm knife-edge collector funnel, weatherproof housing and mount are
// a deliberate v2 iteration, added once this core is proven on the bench.
//
// CALIBRATION (the whole point):
//   1 mm rain = 1 L/m^2 = collected_volume(mL) / catch_area(cm^2) * 10.
//   Catch area is fixed at 200.0 cm^2 (Ø159.6 mm WMO standard orifice, mated in v2).
//   Trip volume per chamber = mm_per_tip * catch_area_cm2 / 10 = 1.0 * 200/10 = 20.0 mL.
//   => each tip = exactly 1.00 mm, counter maps tips->mm 1:1, so "10 mm rain = 10 mm dials".
//
// >>> CRITICAL REAL-WORLD RISK (read before printing) <<<
//   A single tip releases only ~6 mJ (20 mL dropping ~30 mm over-centre), of which
//   maybe ~2 mJ is harvestable at the pawl. That must advance the units wheel AND,
//   every 10th tip, drive a decade carry. This is MARGINAL. The design fights it with:
//   steel-rod shafts (low friction), a low-torque lost-motion/kick carry (not a
//   tight mutilated-pinion), light detents, and a lost-motion pawl slot. VALIDATE
//   ENERGY ON THE BENCH FIRST (print bucket + units indexer, count 100 tips) before
//   trusting the full stack. Documented fallbacks if the bench test comes up short:
//     (a) per-carry over-centre accumulator cocked over ~10 tips, or
//     (b) gated escapement driven by a sourced metal clock spring (periodic rewind).
//   The OpenSCAD build gate proves geometry/dimensions/fit — it does NOT prove the
//   mechanism has enough energy or indexes cleanly. That needs a real print + tuning.
//
// KNOWN v1 RESIDUALS (bench-tuned in the staged build; NOT claimed working as-modeled):
//   - Wheel + idler DETENTS are not yet frame features — each free wheel/idler needs a light
//     leaf detent on the end plate to hold its digit between events (add at Stage 4).
//   - Drive/hold pawl PIVOT BOSSES on the frame and the exact pawl throw/kicker engagement are
//     indicative in assembly() — finalise at Stage 2 (units indexer) on the bench.
//   - Carry idler<->ring mesh and the 1-tooth kick timing are first-draft; tune idler_offset and
//     the transfer-post angle on a 2-wheel test (Stage 4).
//   - Reset lift-rail kinematics (lift detents + hold pawl, then thumb-to-zero) are roughed in.
//   - Bucket interior must be sealed (epoxy/wipe-on) for repeatable trip volume (PETG wicks).
//
// Design decisions:
//   - Wheels, gears and the bucket are modeled in PRINT orientation (axis along Z,
//     flat on the bed) so each `part=` is slice-ready; assembly() rotates them to the
//     in-use orientation (wheel axis horizontal = X, digits roll past a top window).
//   - Lost-motion + detent carry chosen over a Veeder-Root mutilated pinion: a single
//     transfer tooth on each wheel kicks a 1:1 idler that is continuously meshed with
//     the next wheel; a detent quantises the kick to exactly one digit. Far more
//     backlash-tolerant on FDM than a locking-arc pinion (no ±0.1 mm arc tolerance).
//   - Wet/dry separation: the bucket lives in a -Y "wet" bay over an open drain; the
//     counter sits in the +Y "dry" bay behind a splash wall. A tappet on the bucket
//     pivot crosses a slot in the wall to kick the units pawl. Keeps water off gears.
//   - Steel rod for all rotating shafts (user-supplied) to minimise friction (see risk).
//
// Terminology -> code:
//   "number wheel / dial"   -> number_wheel(), wheel_od, digits
//   "ratchet / index teeth"  -> idx_teeth, ratchet ring on each wheel
//   "transfer tooth"         -> xfer feature that kicks the next wheel's idler
//   "decade carry / idler"   -> idler(), countershaft
//   "units drive pawl"       -> drive_pawl() (two of them, full-wave)
//   "holding pawl"           -> hold_pawl() (anti-backdrive on units)
//   "detent"                 -> leaf detents on the frame holding each wheel's digit
//   "tipping bucket"         -> bucket(), chamber, divider peak
//   "stop screws"            -> stop_boss (heat-set insert) trims trip volume
//   "tappet"                 -> tappet on bucket pivot, kicks the units pawl
//   "frame"                  -> frame(), end plates + splash wall + drain
//   "reset knob / lift-rail"  -> reset_rail(), reset_knob()
//
// Common modifications:
//   Finer resolution         -> drop mm_per_tip (recompute trip vol; needs reduction gearing, see plan)
//   Bigger/known collector    -> catch_area_cm2 (trip volume auto-rescales)
//   More/less digits          -> n_wheels (3 = 0-999, 5 = 0-99999)
//   Bigger digits             -> digit_size (keep <= wheel_w-2)
//   Looser/tighter fits       -> tol (PETG sliding 0.3-0.4)
//   Bigger steel shafts       -> shaft_wheel_d / shaft_counter_d / shaft_pivot_d (bores auto +tol)
//
// Overall (assembly) bounding box: ~125 (X) x ~95 (Y) x ~120 (Z) mm — fits Bambu 256^3.
// Coordinate system: X = wheel-stack axis (in use), Y = front(+)/back(-), Z = up from base.
// NOTE: individual parts render in print orientation (Z up off the bed); assembly() is the in-use view.

// === PRINT SETTINGS ===
// Material: PETG (functional mechanism, mild outdoor exposure once housed; ductile, good layer adhesion)
// Layer Height: 0.20 mm (0.16 for the wheels/pawls/idlers if teeth look rough)
// Walls/Perimeters: 4 (1.8 mm) structural; bucket chambers 4 perimeters + solid floor for watertightness
// Infill: 30% gyroid (wheels/idlers can be higher; small parts effectively solid)
// Supports: None intended — all parts modeled to print flat with overhangs <=45 deg.
//   The bucket prints open-side-up; check the floor-slope overhang in your slicer.
// Orientation (per part= ): all modeled flat on the bed as rendered.
//   wheel/idler/knob: circular face down. bucket: open top up. frame: base down. pawls/rail: flat.
// Notes: dry PETG (60-65C/4-6h). Steel rods (user-supplied): wheel shaft Ø5, counter Ø4, pivot Ø3.
//   #4 / M3 stop + insert screws for bucket calibration. Smooth/seal bucket interior to fix wetting loss.

// === PARAMETERS ===
// -- Printer settings --
nozzle_diameter = 0.4;
layer_height    = 0.20;
build_x = 256; build_y = 256; build_z = 256;

// -- Calibration (do not "fix" these without re-reading the header) --
catch_area_cm2 = 200.0;   // Ø159.6 mm WMO standard orifice (collector mated in v2)
mm_per_tip     = 1.0;      // rainfall depth per tip = counter resolution

// -- Counter --
n_wheels   = 4;            // 0000-9999
digits     = 10;
wheel_od   = 28;           // digit drum outer diameter
wheel_w    = 13;           // digit drum width (reading band)
digit_size = 6.5;          // engraved numeral size (mm)
digit_depth= 1.0;          // engrave depth
idx_teeth  = 10;           // ratchet/index teeth (one per digit -> 36 deg/tooth)
idx_pd     = 34;           // index-ring TIP diameter (must exceed wheel_od so a radial
                           //   pawl/idler can reach the teeth past the drum)
idx_tooth_h= 3.0;          // ratchet tooth height (radial); valley dia = idx_pd-2*this
ring_w     = 4.5;          // axial width of the index ring
xfer_w     = 3;            // axial width of the transfer-tooth disc

shaft_wheel_d   = 5;       // steel rod through all number wheels
shaft_counter_d = 4;       // steel rod for idlers (carry countershaft)
shaft_pivot_d   = 3;       // steel rod for the bucket pivot

wheel_pitch = 22;          // wheel center-to-center spacing (>= ring_w+wheel_w + reset-finger gap)

// -- Carry idler --
idler_teeth = 10;          // 1:1 with the wheel index ring (clean 36 deg/carry)
idler_pd    = 34;          // = idx_pd so they mesh 1:1
idler_w     = 20;          // must span from the lower wheel's transfer tooth to the NEXT ring
idler_offset= 32;          // countershaft Y offset from wheel axis (>idler+ring radii sum for clearance)

// -- Pawls / detents (flexible PETG) --
pawl_thick    = 2.4;       // body thickness of pawls
leaf_thick    = 1.2;       // flexing leaf thickness (PETG cantilever)
pawl_lostslot = 2.5;       // lost-motion overtravel slot length

// -- Tipping bucket (TAPERED self-draining scoop) --
//   Each chamber is a WEDGE: deep at the divider, the FLOOR SLOPES UP to a LOW outer rim. That is
//   what makes it drain — when it tips, the floor points outward-down and water sheets out over the
//   2 mm rim (the old deep box trapped water behind a tall vertical wall). The wedge also packs the
//   trip volume into a compact footprint. DIVIDER is tall: retains the up-side water + sheds rain.
chamber_len   = 60;        // along pivot axis (X in use)
chamber_wid   = 40;        // Y run of EACH chamber (divider face -> outer rim)
wedge_h       = 22;        // chamber DEPTH at the divider (inner); the floor rises toward the outer edge
floor_rise    = 15;        // how far the floor climbs from the divider (z=0) to the outer edge
outer_lip     = 2;         // SHORT outer rim above the risen floor — water drains over this on a tip
floor_t       = 2;         // floor thickness
bkt_wall      = 1.6;       // wall thickness (4 perimeters)
divider_t     = 7;         // central divider base thickness (carries the pivot bore)
div_base_h    = 12;        // rectangular divider base height (must enclose the pivot bore)
divider_peak  = 26;        // peaked watershed ridge (above wedge_h; sheds rain to the low side)
end_wall_h    = 22;        // CLOSED end-wall height (= wedge_h; retains water axially)
bkt_pivot_z   = 11;        // pivot height above the floor (near the filled CoM; bench-trim w/ stops)
tip_angle     = 28;        // travel-stop half-angle (deg): the bucket rocks +/- this; the frame stops set it
stop_boss_d   = 8;         // boss for M3 grub screw / counterweight (calibration)

// -- Frame --
base_th    = 4;            // baseplate thickness
plate_th   = 4;            // end-plate / wall thickness
window_h   = 16;           // digit window height
drain_w    = 40;           // open drain slot width under the bucket

// -- Fit / clearance --
tol = 0.35;                // PETG sliding clearance

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;       // 0.45
wall_thickness  = extrusion_width * 4;           // 1.8 (reference)
fudge   = 0.01;                                  // boolean overlap
ef      = 0.4;                                   // elephant-foot compensation
digit_deg = 360 / digits;                        // 36
tip_volume_ml = mm_per_tip * catch_area_cm2 / 10;// 20.0 mL per chamber
catch_dia = 2 * sqrt(catch_area_cm2 * 100 / PI); // mm  (=159.6 for 200 cm^2)

// open chamber capacity ~ a triangular wedge cross-section (0.5 * width * depth-at-divider) * length.
// The TRIP point (~20 mL) is set LOWER, on the bench, via the stops/counterweight; capacity carries
// ~30% headroom so the trip happens well before the chamber overflows.
chamber_vol_mm3 = 0.5 * chamber_wid * wedge_h * chamber_len;
chamber_vol_ml  = chamber_vol_mm3 / 1000;

stack_len = (n_wheels - 1) * wheel_pitch + wheel_w;  // wheels span along the axis

// --- Layout positions (shared by frame() and assembly() so shafts line up) ---
wheel_axis_z = 26;                 // height of the number-wheel shaft
wheel_y      = 0;                  // wheels at Y=0 (dry counter block)
counter_y    = -idler_offset;      // carry idlers on the countershaft, behind the wheels
splash_y     = 9;                  // splash wall plane: counter behind it (dry), bucket in front
pivot_y      = 50;                 // bucket pivot well forward: BOTH long-side dumps land in front
                                   // of the splash wall (wet zone), so the counter stays dry
pivot_z      = 60;                 // bucket sits above the counter

$fn = $preview ? 32 : 64;

// === CONTRACTS (fail the build if calibration / geometry drifts) ===
assert(abs(tip_volume_ml - 20.0) < 0.001, "trip volume must be 20.0 mL for 1mm/200cm2");
assert(abs(catch_dia - 159.6) < 0.2, "catch diameter should be ~159.6 mm for 200 cm2");
assert(digits == 10 && abs(digit_deg - 36) < 1e-6, "need 10 digits at 36 deg");
assert(idx_teeth == digits, "one index tooth per digit (pawl advances one digit per tip)");
assert(idler_teeth == idx_teeth && abs(idler_pd - idx_pd) < 1e-6, "idler must be 1:1 with index ring");
// chamber must be able to HOLD >= the 20 mL trip volume (stops trim down to 20.0)
assert(chamber_vol_ml >= tip_volume_ml, "chamber too small to reach the 20 mL trip point");
assert(chamber_vol_ml <= tip_volume_ml * 1.6, "chamber far larger than trip vol — wasteful/unstable");
assert(wheel_od < build_x && stack_len < build_x, "counter stack must fit the bed");
echo(tip_volume_ml = tip_volume_ml, catch_dia = catch_dia,
     chamber_vol_ml = chamber_vol_ml, stack_len = stack_len);

// ============================================================
// === 2D HELPERS ===
// ============================================================

// Sawtooth ratchet/index ring profile (2D). pd = TIP diameter. Each tooth has a near-radial
// load face (pawl pushes against it), a small tip flat (not a fragile point), and a ramp back
// to the next valley with a mid-arc point so the back face follows the circle, not a long chord.
module ratchet2d(teeth, pd, tooth_h) {
    r_out = pd/2;
    r_in  = pd/2 - tooth_h;
    step  = 360/teeth;
    tipw  = step*0.18;                 // small angular tip flat
    r_mid = r_in + (r_out - r_in)*0.45;
    pts = [ for (i = [0:teeth-1]) each [
        [ r_in  * cos(i*step),         r_in  * sin(i*step)         ],  // valley (load-face base)
        [ r_out * cos(i*step),         r_out * sin(i*step)         ],  // tip leading (radial load face)
        [ r_out * cos(i*step + tipw),  r_out * sin(i*step + tipw)  ],  // tip flat
        [ r_mid * cos(i*step + step*0.6), r_mid * sin(i*step + step*0.6) ] // ramp mid-arc point
    ] ];
    polygon(pts);
}

// Teardrop hole (self-supporting horizontal bore). teardrop_x: bore axis along X, point up (+Z).
module teardrop_hole(d, h) {
    r = d/2;
    rotate([90,0,0]) linear_extrude(height=h, center=true)
        union() { circle(r=r); polygon([[-r,0],[r,0],[0,r*1.1]]); }
}
module teardrop_x(d, h) { rotate([0,0,90]) teardrop_hole(d, h); }   // axis -> X, point up

// Simple trapezoidal spur-gear profile (2D) — good enough for low-speed kick/mesh.
module gear2d(teeth, pd, tooth_h) {
    rb = pd/2 - tooth_h*0.5;          // root/base radius
    rt = pd/2 + tooth_h*0.5;          // tip radius
    circ = 2*PI*rb;
    base_w = (circ/teeth) * 0.55;     // tooth width at base
    tip_w  = base_w * 0.55;           // narrower at tip
    union() {
        circle(r = rb);
        for (i = [0:teeth-1]) rotate(360*i/teeth)
            polygon([[rb-fudge,-base_w/2],[rb-fudge,base_w/2],
                     [rt,tip_w/2],[rt,-tip_w/2]]);
    }
}

// A rounded leaf cantilever (detent / pawl spring) in 2D, length L along +X, thickness t.
module leaf2d(L, t) {
    hull() {
        translate([0, -t/2]) square([fudge, t]);
        translate([L, 0]) circle(d = t);
    }
}

// ============================================================
// === NUMBER WHEEL (printed axis = Z, circular face on bed) ===
//   has_xfer: include the single transfer tooth that drives the next wheel's idler
// ============================================================
module number_wheel(has_xfer = true) {
    ring_od  = idx_pd + idx_tooth_h;   // tip diameter of the sawtooth ratchet teeth
    drum_z0  = ring_w;                 // drum sits ABOVE the ratchet ring so teeth stay exposed
    difference() {
        union() {
            // index/ratchet ring at the base (z = 0..ring_w) — pawl/idler engage these teeth
            linear_extrude(ring_w) ratchet2d(idx_teeth, ring_od, idx_tooth_h);
            // digit drum, raised above the ring so the ring teeth are accessible
            translate([0,0,drum_z0]) cylinder(h = wheel_w, d = wheel_od);
            // single transfer post near the ring rim — kicks the next wheel's idler once/rev
            if (has_xfer)
                rotate([0,0,-digit_deg/2])
                    translate([ring_od/2 - 2.5, 0, 0])
                        cylinder(h = ring_w + xfer_w, d = 4);
        }
        // bore for steel shaft (through everything, oversized for free spin)
        translate([0,0,-fudge]) cylinder(h = drum_z0 + wheel_w + 2*fudge, d = shaft_wheel_d + tol);
        // lighten the drum (annular cavity, keeps outer wall for engraving + central hub bearing)
        translate([0,0,drum_z0 + 1.5])
            difference() {
                cylinder(h = wheel_w, d = wheel_od - 4*wall_thickness);
                cylinder(h = wheel_w, d = shaft_wheel_d + 2*wall_thickness + tol);
            }
        // engrave the 10 numerals around the drum wall
        for (i = [0:digits-1]) digit_engrave(i, drum_z0);
    }
}

// Engrave one numeral on the drum wall. Wheel axis = Z (print orientation). The glyph
// sits on the cylindrical wall, normal radial-out; placed around Z at i*36 deg.
digit_spin = 90;   // in-plane glyph rotation so numerals stand upright in the in-use view
module digit_engrave(i, drum_z0) {
    rotate([0,0,i*digit_deg])
        translate([wheel_od/2 - digit_depth + fudge, 0, drum_z0 + wheel_w/2])
            rotate([90,0,90])                       // glyph plane onto the wall, normal radial
                linear_extrude(digit_depth + fudge)
                    rotate(digit_spin)              // height->circumference => upright in the window
                        text(str(i), size = digit_size, halign = "center",
                             valign = "center", font = "Liberation Sans:style=Bold");
}

// ============================================================
// === CARRY IDLER (printed axis = Z) ===
//   10 teeth, 1:1 mesh with the next wheel's index ring; kicked once per
//   lower-wheel revolution by that wheel's transfer tooth. Detent (frame) holds it.
// ============================================================
module idler() {
    difference() {
        linear_extrude(idler_w) gear2d(idler_teeth, idler_pd, idx_tooth_h);
        translate([0,0,-fudge]) cylinder(h = idler_w + 2*fudge, d = shaft_counter_d + tol);
    }
}

// ============================================================
// === DRIVE PAWL (units) — flexible, with lost-motion slot ===
//   Two of these (mirrored) ride the oscillating tappet arm; each kicks the units
//   ratchet one tooth on one swing direction (full-wave => one count per tip).
//   The lost-motion slot lets the fixed seesaw throw overstroke without double-indexing.
// ============================================================
module drive_pawl() {
    pl = 16;     // pawl length
    difference() {
        union() {
            // body
            linear_extrude(pawl_thick) leaf2d(pl, 4);
            // nose that engages a ratchet tooth
            translate([pl,0,0]) linear_extrude(pawl_thick)
                polygon([[0,-2],[0,2],[idx_tooth_h, -0.5]]);
        }
        // pivot hole
        translate([0,0,-fudge]) cylinder(h = pawl_thick + 2*fudge, d = 2.5 + tol);
        // lost-motion slot (overtravel)
        translate([pl*0.45,0,-fudge])
            hull() { cylinder(h=pawl_thick+2*fudge, d=2.2);
                     translate([pawl_lostslot,0,0]) cylinder(h=pawl_thick+2*fudge, d=2.2); }
    }
}

// ============================================================
// === HOLDING PAWL — anti-backdrive leaf on the frame, units ratchet ===
// ============================================================
module hold_pawl() {
    pl = 14;
    union() {
        linear_extrude(pawl_thick) leaf2d(pl, leaf_thick + 1.0);
        translate([pl,0,0]) linear_extrude(pawl_thick)
            polygon([[0,-1.5],[0,1.5],[idx_tooth_h*0.9, -0.3]]);
        // mount tab (overlaps the leaf root at X=0 so it's a single body) with a screw hole
        difference() {
            translate([-6, -3, 0]) cube([6 + fudge, 6, pawl_thick]);
            translate([-3, 0, -fudge]) cylinder(h = pawl_thick + 2*fudge, d = 2.5 + tol);
        }
    }
}

// ============================================================
// === TIPPING BUCKET (printed open-side up) ===
//   Twin chambers, central watershed peak, steel-rod pivot, stop-screw bosses.
//   Sized so each chamber holds >= 20.0 mL; stops trim the actual trip point to 20.0.
// ============================================================
module bucket() {
    L     = chamber_len;
    XW    = L + 2*bkt_wall;                          // full length incl. end walls
    inner = divider_t/2;                             // chamber inner edge (divider base face)
    outer = divider_t/2 + chamber_wid;               // chamber outer edge (under the rim)
    OW    = outer + bkt_wall;                        // outer half-width (outside of the rim)
    difference() {
        union() {
            // SLOPED floors (wedge): deep at the divider (top z=0), climbing to floor_rise at the
            // outer edge so a tip drains the chamber outward. Flat underside at z=-floor_t.
            for (s = [-1,1])
                hull() {
                    translate([-XW/2, s > 0 ? inner - fudge : -inner, -floor_t])
                        cube([XW, fudge, floor_t]);                       // inner: floor top at z=0
                    translate([-XW/2, s > 0 ? OW - fudge : -OW, -floor_t])
                        cube([XW, fudge, floor_rise + floor_t]);          // outer: floor top at floor_rise
                }
            // central divider: rectangular base (encloses the pivot bore) + peaked watershed ridge
            translate([-XW/2, -divider_t/2, 0]) cube([XW, divider_t, div_base_h]);
            hull() {
                translate([-XW/2, -divider_t/2, div_base_h - fudge]) cube([XW, divider_t, fudge]);
                translate([-XW/2, -fudge/2, divider_peak])           cube([XW, fudge, fudge]);
            }
            // SHORT outer rims sitting on the risen floor — water drains over these (only ~2 mm tall)
            for (s = [-1,1])
                translate([-XW/2, s > 0 ? outer : -outer - bkt_wall, floor_rise])
                    cube([XW, bkt_wall, outer_lip]);
            // CLOSED end walls (retain water axially)
            for (sx = [-1,1])
                translate([sx > 0 ? L/2 : -L/2 - bkt_wall, -OW, 0])
                    cube([bkt_wall, 2*OW, end_wall_h]);
        }
        // pivot bore along X through the divider base (teardrop = self-supporting)
        translate([0, 0, bkt_pivot_z]) teardrop_x(shaft_pivot_d + tol, XW + 2*fudge);
    }
    // calibration / counterweight bosses LOW on the end walls, offset below the pivot bore so an
    // M3 grub screw / trim weight cannot foul the pivot rod. Trim the trip volume on the bench.
    for (sx = [-1,1])
        translate([sx*(L/2 + bkt_wall - fudge), 0, 4]) rotate([0, sx*90, 0])
            difference() {
                cylinder(h = 6, d = stop_boss_d);
                translate([0,0,-fudge]) cylinder(h = 6 + 2*fudge, d = 3.0); // M3 insert pilot
            }
    // NOTE: tip is read off the pivot ROD via a separate tappet() crank. Travel STOPS live on the
    // frame (posts under the outer edges) and set the +/- tip_angle throw + the trip calibration.
}

// ============================================================
// === RESET LIFT-RAIL + KNOB ===
//   Pull the knob (axial) to lift all detents + carry idlers clear (wheels free),
//   then thumb each freed wheel to the printed 0 index; release to re-engage.
// ============================================================
module reset_rail() {
    rail_l = stack_len + 10;
    difference() {
        union() {
            cube([rail_l, 8, 4]);                  // the lift bar
            // one lifting finger aligned under each wheel's index ring (lifts that wheel's detent)
            for (i=[0:n_wheels-1])
                translate([i*wheel_pitch + ring_w/2 - 1.5, 0, 0]) cube([3, 12, 6]);
            // extra tab at the units end to lift the holding pawl during reset
            translate([ring_w/2 - 1.5, 8 - fudge, 0]) cube([3, 6, 9]);
        }
        // knob shaft bore at one end
        translate([-fudge, 4, 2]) rotate([0,90,0]) cylinder(h=8, d=shaft_counter_d+tol);
    }
}

// Tappet crank — keyed to the bucket pivot ROD at the units end; the rod turns with the bucket,
// so as the bucket tips this crank swings and its kicker pin nudges the units drive pawl one tooth.
// Printed flat (bore axis = Z as modeled). NOTE: the kicker/pawl engagement is bench-tuned (Stage 2).
module tappet() {
    arm   = pivot_z - (wheel_axis_z + idx_pd/2) + 8;  // reach from pivot down to just above units ring
    hub_d = shaft_pivot_d + tol + 6;
    difference() {
        linear_extrude(5) hull() { circle(d = hub_d); translate([0, -arm]) circle(d = 7); }
        translate([0,0,-fudge]) cylinder(h = 5 + 2*fudge, d = shaft_pivot_d + tol); // rod bore (set-screw/glue)
        // set-screw cross hole to key it to the rod
        translate([0, hub_d/2, 2.5]) rotate([90,0,0]) cylinder(h = hub_d, d = 2.2);
    }
    translate([0, -arm, 5 - fudge]) cylinder(h = 4, d = 4);   // kicker pin
}

module reset_knob() {
    union() {
        cylinder(h = 6, d = 22);                   // knurled-ish grip (flats for grip)
        for (a=[0:30:330]) rotate(a) translate([10,0,0]) cylinder(h=6, d=2.5);
        translate([0,0,6-fudge]) cylinder(h = 12, d = shaft_counter_d - tol); // press onto rod
    }
}

// ============================================================
// === FRAME (printed base down) ===
//   Two end plates carry the wheel + counter shafts; a splash wall separates the
//   wet bucket bay (-Y, over an open drain) from the dry counter bay (+Y); a digit
//   window opens over the wheels. Bucket pivot sits up in the wet bay.
// ============================================================
module frame() {
    x0   = -plate_th - 6;
    fw   = stack_len + 12;                 // base / plate span in X
    OWb  = divider_t/2 + chamber_wid + bkt_wall;   // bucket outer half-width
    ymin = counter_y - 18;                 // back (behind the idlers)
    ymax = pivot_y + OWb + 8;              // front: clear the wide bucket + drain margin
    fd   = ymax - ymin;
    fh   = pivot_z + 14;
    // travel-stop geometry: where the bucket's outer-bottom edge sits at +/- tip_angle
    dZp  = (pivot_z - bkt_pivot_z - floor_t) - pivot_z;          // edge z relative to pivot, neutral
    sty  = OWb*cos(tip_angle) + dZp*sin(tip_angle);             // |Y| of the tilted-down edge from pivot
    stz  = pivot_z + dZp*cos(tip_angle) - OWb*sin(tip_angle);   // its global z = stop-bar top height
    difference() {
        union() {
            translate([x0, ymin, 0]) cube([fw, fd, base_th]);                  // base
            for (sx = [0,1])                                                   // two end plates
                translate([x0 + sx*(fw - plate_th), ymin, 0]) cube([plate_th, fd, fh]);
            // splash wall: counter behind (dry), bucket/drain in front (wet)
            translate([x0, splash_y, base_th]) cube([fw, plate_th, fh - base_th - 16]);
            // TRAVEL STOPS: two cross-bars spanning the end plates; the bucket's outer-bottom edge
            // rests on one at +/- tip_angle, limiting the rock. Shim/raise them (or fit M3 screws)
            // to fine-tune the throw and the trip volume on the bench.
            for (s = [-1,1])
                translate([x0 + plate_th - fudge, pivot_y + s*sty - 1.5, stz - 4])
                    cube([fw - 2*plate_th + 2*fudge, 3, 4]);
        }
        // shaft bores through BOTH end plates (teardrop = self-supporting horizontal holes)
        for (sx = [0,1]) {
            pcx = (sx == 0) ? x0 + plate_th/2 : x0 + fw - plate_th/2;
            translate([pcx, wheel_y,  wheel_axis_z]) teardrop_x(shaft_wheel_d + tol,  plate_th + 2*fudge);
            translate([pcx, counter_y, wheel_axis_z]) teardrop_x(shaft_counter_d + tol, plate_th + 2*fudge);
            translate([pcx, pivot_y,  pivot_z])      teardrop_x(shaft_pivot_d + tol,  plate_th + 2*fudge);
        }
        // open drain in the base under the bucket (front/wet zone, beyond the splash wall)
        translate([x0 + fw/2 - drain_w/2, splash_y + plate_th + 2, -fudge])
            cube([drain_w, (ymax - (splash_y + plate_th + 2)) - 2, base_th + 2*fudge]);
        // tappet slot through the splash wall at the UNITS end (x~0), at the crank kick height,
        // so the rod-mounted tappet crank can reach the dry-side units drive pawl
        translate([-2, splash_y - fudge, 38]) cube([18, plate_th + 2*fudge, 20]);
    }
}

// ============================================================
// === ASSEMBLY (in-use orientation: wheel axis = X, Z up) ===
// ============================================================
module assembly() {
    bkt_pivot_local_z = bkt_pivot_z;                     // bore height within the bucket part
    // number wheels (axis along X), units at +X end
    for (i = [0:n_wheels-1])
        translate([i*wheel_pitch, wheel_y, wheel_axis_z]) rotate([0,90,0])
            color("Gainsboro") number_wheel(has_xfer = (i < n_wheels-1));
    // carry idlers on the countershaft behind the wheels
    for (i = [0:n_wheels-2])
        translate([i*wheel_pitch + wheel_pitch/2 - idler_w/2, counter_y, wheel_axis_z]) rotate([0,90,0])
            color("SteelBlue") idler();
    // tipping bucket forward and above; pivot bore aligned to the frame pivot axis
    translate([stack_len/2, pivot_y, pivot_z - bkt_pivot_local_z]) color("SkyBlue") bucket();
    // frame
    color("Tan") frame();
    // reset lift-rail tucked under the wheels
    translate([-4, wheel_y - 4, wheel_axis_z - wheel_od/2 - 8]) color("DimGray") reset_rail();

    // --- units drive/hold pawls + tappet crank ---
    // INDICATIVE placement only. The exact pawl pivots, lost-motion throw and kicker engagement
    // are the Stage-2 bench-tuning frontier (see header energy-risk note); shown here to convey intent.
    translate([1, wheel_y - 4, wheel_axis_z + idx_pd/2 - 3]) rotate([0,0,-55])
        color("Crimson") drive_pawl();
    translate([1, wheel_y + 9, wheel_axis_z + 4]) rotate([0,0,135])
        color("OrangeRed") hold_pawl();
    translate([2, pivot_y, pivot_z]) rotate([0,90,0]) rotate([0,0,90])
        color("Orange") tappet();
}

// ============================================================
// === PART SELECTOR ===
// ============================================================
part = "all";  // all,wheel,wheel_top,idler,drive_pawl,hold_pawl,tappet,bucket,frame,reset_rail,knob

if (part == "all")        assembly();
if (part == "wheel")      number_wheel(has_xfer = true);     // units/tens/hundreds (drives next)
if (part == "wheel_top")  number_wheel(has_xfer = false);    // thousands (no transfer tooth)
if (part == "idler")      idler();
if (part == "drive_pawl") drive_pawl();
if (part == "hold_pawl")  hold_pawl();
if (part == "tappet")     tappet();
if (part == "bucket")     bucket();
if (part == "frame")      frame();
if (part == "reset_rail") reset_rail();
if (part == "knob")       reset_knob();
