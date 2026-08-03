// === DESCRIPTION ===
// Mechanical Rain Gauge (Opus5.0 v2): a fully mechanical, no-electronics rain gauge that
// reads accumulated rainfall in millimetres on a four-digit "old meter" drum register
// (0000-9999 mm), driven by a tipping-bucket see-saw, with a push-button zero reset.
//
// Physical context: mounts outdoors on a 25-50mm post, rim levelled, sited in the open per
// WMO practice (clear of obstacles by >= 2x their height, rim 300-500mm above ground). Water
// enters the 200 cm^2 collector, is funnelled to a single drip nozzle, and lands in whichever
// half of the see-saw is currently RAISED -- the centre blade stands well above the pivot, so
// at rest its top edge has swung 16mm toward the low side, which puts the centred nozzle over
// the high chamber. At 10.0 mL (= 0.5mm of rain over 200 cm^2) the see-saw goes over-centre,
// dumps that half and presents the other. Dumped water leaves through the open bottom of the
// body. A single-lobe cam on the see-saw's pivot rod pushes a pawl that advances the units
// drum one tooth on alternate tips, so ONE COUNT = TWO TIPS = 1.000 mm of rain. Carry into
// tens/hundreds/thousands is by lug-and-pawl levers, as in a hand tally counter.
//
// Design decisions:
//   - 200 cm^2 catch area (rim ID 159.58mm): the WMO-recommended minimum, the most widely
//     used size worldwide, and the closest standard size to the 150mm originally suggested.
//     The AREA is the primary parameter and the rim diameter is derived, so the calibration
//     chain stays exact if the area is ever changed.
//   - 0.5mm per tip, single pawl firing on alternate strokes. A see-saw oscillates, so one
//     pawl naturally fires once per full cycle. Making 1 tip = 1 count instead needs two
//     pawls timed against each other: more parts, and a real risk of double-advance or
//     skipped counts. Cost: up to 0.5mm of rain can sit undisplayed, inherent to any
//     quantised gauge.
//
//   - THE TWO EQUATIONS THAT SET EVERYTHING. Both are derived in README.md.
//     (1) Energy per working stroke:  E = 2 * m * y_w * sin(rest_tilt)
//         where m is the tip mass and y_w the water centroid's distance from the pivot AXIS.
//         The restoring-moment term integrates to zero over a symmetric swing, so E does NOT
//         depend on the counterweight, the pivot height, or the pawl lever ratio -- only on
//         m, y_w and rest_tilt. Leverage buys nothing; it only trades force for stroke.
//     (2) Calibration robustness:  d(trip volume)/trip volume  =  dz_cog / bal_arm
//         i.e. the FRACTIONAL error in trip volume per mm of centre-of-gravity error is
//         exactly 1/bal_arm, where bal_arm = z_cog - pivot_z. Since a printed shell's CoG
//         can only be predicted to a millimetre or two, bal_arm must be made LARGE.
//         Solving the balance gives  bal_arm = 10*[y_w*cot(rest_tilt) - (z_w - z_cog)]/(M+10)
//         -- so a SHALLOW rest tilt and a LIGHT bucket are what buy accuracy.
//
//   - Chamber floor 28 deg, rest tilt 33 deg -- and the bucket is PRINTED ROTATED BY 28 DEG.
//     This is the key move in the whole design. A chamber only empties completely once
//     tilted past its own floor angle, so floor angle forces rest tilt. An earlier revision
//     used a 46-deg floor because that is the shallowest a floor's UNDERSIDE can be and
//     still print unsupported -- but it forced a 51-deg rest tilt, which put the water almost
//     directly over the pivot, collapsing bal_arm to 3.5mm and making trip volume swing 29%
//     per mm of CoG error. Unusable. Printing the bucket rotated by the floor angle removes
//     the printability constraint entirely: one chamber's underside then lies FLAT ON THE
//     BED and the other sits at 2*28 = 56 deg, both self-supporting, for ANY floor angle.
//     That freed the tilt down to 33 deg. Result vs the 46/51 version: bal_arm 3.5 -> 8.9mm
//     (error per mm of CoG: 29% -> 11%), tip energy 1.44 -> 1.53 mJ, nozzle window 7.4 ->
//     16.0mm, and the drip lip becomes the unique lowest point of the swept envelope, which
//     is what finally makes a clean adjustable stop possible.
//   - Adjustable stops are therefore essential, not a luxury: the residual ~11%/mm modelling
//     uncertainty is trimmed out by two M3 stop screws under the lips. They change rest_tilt
//     at 1.31 deg/mm, which is 4.6% of trip volume per turn, over a +/-37% range -- ample to
//     absorb the model error. TURN BOTH EQUALLY: a difference between them makes alternate
//     tips unequal, which shows up as a repeating odd/even error in a bucket-count test.
//   - Gravity clicks (weighted pawls falling into the ratchet), no springs anywhere in the
//     register. Detent force is the largest load on the drive; gravity gives a low,
//     perfectly repeatable force, and PETG leaf springs relax over months outdoors.
//   - Zeroing is by gravity return, not heart cams. Each drum carries an internal
//     counterweight sector so its stable hanging position is digit 0. The button lifts all
//     four clicks at once; drums swing to roughly zero and the clicks then drop into the
//     nearest tooth, which IS exactly digit 0. Gravity supplies authority, the ratchet
//     supplies precision. This deletes 4 heart cams, 4 hammers and the lift/hammer
//     sequencing, and exploits a constraint the gauge must satisfy anyway: it stands level.
//   - Each drum's ratchet flange is on its +X face and its carry lug on its -X face. That
//     ordering puts a drum's lug 5.25mm from the next-higher drum's ratchet (a short step for
//     the carry lever) AND puts the units ratchet at the outboard end of the row, where the
//     drive cam can sit on the pivot rod clear of the bucket. Flipping either feature breaks
//     one of those two things.
//   - The register lives in a cassette that is assembled on the bench and dropped into the
//     body from above. The body is then just an open-bottomed cylinder that drains freely:
//     no internal deck to bridge-print, and no water path over the drums.
//   - The bucket pivot bearings are moulded into the body itself (two internal web plates
//     with upward-opening saddles). One less part, and pivot alignment is guaranteed by the
//     body being a single print.
//
// Terminology -> code:
//   "collector" / "funnel"       -> catch_area_cm2, rim_id, funnel()
//   "the rim" (sharp edge)       -> rim_flat, rim_straight, cone_angle
//   "drip nozzle"                -> nozzle_bore, nozzle_len
//   "tipping bucket" / "see-saw" -> bucket(), tip_volume, rest_tilt, floor_angle
//   "the divider" (centre blade) -> divider_thick, divider_over_lip, spine_w
//   "the lip"                    -> lip_chamfer (sharp top edge, clean water release)
//   "trim screw" (coarse cal.)   -> trim_boss_d, trim_boss_h
//   "stop screws" (fine cal.)    -> stop_y, stop_z, stop_beam()
//   "pivot webs" / bearings      -> web_x, pivot_webs(), pivot_strap()
//   "dials" / "drums"            -> drum(), drum_count, drum_pitch, digit_h
//   "ratchet"                    -> ratchet_r, ratchet_teeth, tooth_depth
//   "click" (detent)             -> click(), click_mass_r, click_pos, click_mt (computed)
//   "carry lever"                -> carry_lever(), lug_r, carry_pos, carry_mt (computed)
//   "drive pawl" / "drive cam"   -> drive_pawl(), drive_cam(), cam_lobe_r, cam_mount (computed)
//   "reset button" / "lifter"    -> reset_button(), lifter(), click_lift, yoke_y, yoke_z
//   "window" / "bezel"           -> window_w, window_h, bezel(), boss_face_y
//   "cassette" (the movement)    -> cassette(), cassette_lid()
//   "body" (outer can)           -> body(), body_od, body_h
//   "post mount"                 -> post_mount(), post_d
//
// Common modifications:
//   Double the drive energy   -> catch_area_cm2 = 400 (the other WMO class). Rim becomes
//                                225.7mm, EXCEEDING the X1C 220mm auto-centred bed, so the
//                                funnel must be split or the stopper-clip mod fitted.
//   Trip volume reads high    -> back BOTH stop screws out equally (raises rest_tilt).
//   Trip volume reads low     -> screw both stops in equally; if out of range, add M3 nuts
//                                to the bucket trim boss.
//   More calibration margin   -> raise bal_arm: lower rest_tilt (and floor_angle with it), or
//                                lighten the bucket (bucket_wall, or narrower bucket_wx which
//                                lengthens the chamber and raises y_w).
//   Register feels stiff      -> reduce click_mass_r, and confirm drums printed at 0% infill
//                                (drum mass is the inertia the tip energy must accelerate).
//   Lever timing off          -> every mounting angle is COMPUTED in the LEVER KINEMATICS
//                                block, so do not hand-edit one. Move the shaft instead
//                                (click_pos / carry_pos), or change cam_lobe_r, then render
//                                part="mech" and sweep bucket_tilt to check the result.
//   Bigger digits             -> digit_h (max facet_w - 3), drum_af, digit_band
//
// Overall dimensions: 169 dia x 240 mm tall assembled. Largest single part is the funnel at
//   169 dia x 98mm, inside the X1C 220mm auto-centred bed. Coordinate system (assembly
//   frame): X = along the drum and pivot axes, Y = front(-) to back(+), Z = up from the
//   body's bottom rim. Each part module is in ITS OWN PRINT orientation with Z=0 on the
//   plate; assembly() applies the use transforms.
// NOTE ON ORIENTATION: body, funnel and cassette print as used. The BUCKET prints rotated by
//   floor_angle about X (see above) -- so its preview does NOT match its attitude in use.
//   Drums print axis-vertical; in use the axis is horizontal, along X.

// === PRINT SETTINGS ===
// Material: PETG. Outdoor part: Tg 75-85C survives a sun-baked dark surface (PLA creeps at
//   55C and would sag the funnel rim out of level, which directly corrupts the catch area);
//   150-300% elongation survives the see-saw slamming its stops millions of times; layer
//   adhesion 90-95% of bulk matters for the thin funnel cone. Moderate UV resistance --
//   expect <15% strength loss in year one. PRINT IT LIGHT-COLOURED: white or light grey
//   reflects UV, runs cooler, and makes the engraved digits far more legible.
// Layer Height: 0.20mm. Use 0.12mm for drum / click / carry_lever / drive_pawl (fine teeth).
// Walls/Perimeters: 5 (2.25mm) for body, funnel, cassette; 4 (1.80mm) for everything else.
// Infill: 20% gyroid. EXCEPTIONS: drum = 0% infill (it is the inertia the tip energy has to
//   accelerate) but its counterweight sector must be 100%; the mass bosses on click,
//   carry_lever and drive_pawl must be 100%.
// Supports: NONE on any part. Every overhang is <= 45 deg from vertical or a <= 3mm bridge.
// Orientation:
//   funnel     - as modelled, rim UP. The cone grows outward from the nozzle at 42 deg
//                (self-supporting), the skirt is a plain vertical wall, and the rim bevel
//                converges inward so the sharp edge needs no support.
//   body       - as modelled, open end DOWN on the plate. Window aperture and the internal
//                cassette pocket both have 45 deg gable tops so nothing bridges.
//   bucket     - AS MODELLED, which is rotated 28 deg from its attitude in use. It rests on
//                one chamber's underside: a 30 x 44mm flat, excellent adhesion, no brim
//                needed. The opposite chamber's underside is then 56 deg from horizontal and
//                the centre blade 28 deg from vertical -- all self-supporting.
//   cassette   - as modelled, floor down. Rod bores are teardrops in the side walls, so
//                the rods slide in axially after the drums and levers are dropped in.
//   drum       - as modelled, axis VERTICAL. Digit facets become vertical walls, so the
//                engraving is crisp and unstepped, and the ratchet teeth print in-plane.
//   click, carry_lever, drive_pawl, drive_cam, reset_button, lifter, spacers, pivot_strap,
//   cassette_lid, bezel, post_mount - flat, as modelled. Printing the levers
//                flat puts the layer lines across the lever, loading each pawl nose in shear
//                ALONG layers rather than peeling them apart.
// Notes: DRY THE PETG (60-65C, 4-6h) first -- strings inside a ratchet are a functional
//   defect, not a cosmetic one. Nozzle 240C for layer strength, bed 80C, 30-40% fan. Deburr
//   every tooth and journal, then cycle the mechanism ~200 times by hand to bed it in; this
//   is standard practice on real tipping-bucket gauges.

// === PARAMETERS ===

part = "assembly"; // "assembly","assembly_cut","mech","funnel","body","bucket","cassette","cassette_lid","drum","click","click_light","carry_lever","drive_pawl","drive_cam","reset_button","lifter","spacers","pivot_strap","bezel","post_mount","fit_test","plate","plate_fine"

// -- Printer --
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_x = 256; build_y = 256; build_z = 256;
bed_safe = 220;          // X1C auto-centred printable square (front-left cutter exclusion)

// -- Metrology: the calibration chain. Change these and everything else follows. --
catch_area_cm2   = 200;  // WMO collector area class: 200 or 400
rain_per_tip     = 0.5;  // mm of rain per bucket tip
tips_per_count   = 2;    // pawl fires once per full see-saw cycle
chamber_headroom = 1.20; // chamber holds 20% more than the trip volume, so it cannot overflow

// -- Tipping bucket --
bucket_wx        = 30;   // internal chamber width along the pivot axis
floor_angle      = 28;   // chamber floor rise from horizontal; ALSO the print rotation
rest_tilt        = 33;   // rest angle each side of level (> floor_angle for a clean dump)
divider_thick    = 2.0;
divider_over_lip = 12;   // how far the centre blade stands above the lip
spine_w          = 8.0;  // local thickening of the blade to enclose the pivot rod
spine_top        = 12.0; // must enclose the rod: pivot_z is DERIVED from the balance, so if the
                         // mass model changes, re-check the "rod fully enclosed" contract  // height the spine thickening runs to
lip_chamfer      = 1.2;  // chamfer on the TOP of each lip: a sharp edge releases water cleanly
bucket_wall      = 1.8;  // 4 perimeters
keel_trunc       = 1.6;  // truncate the keel apex to a printable flat
rod_d            = 3.0;  // every shaft in the gauge is 3mm steel rod
boss_out         = 2.5;  // pivot bearing pad projecting OUTBOARD (never into the chambers)
// Trim-screw boss (coarse calibration: add M3 nuts to raise z_cog). Sized for HANDLING, not
// service: at Ø7 on the bare 2mm blade the bonded root was only 8.8mm^2 and a ~10N knock on the
// tip came within 1.3x of snapping it off, while a 2.2mm wall is thin to self-tap M3 into. Ø9 on
// a locally thickened pad, and 3mm shorter, gives 4.4x the root area and 11.6x the weak-axis
// section for a fraction of a gram.
trim_boss_d      = 9.0;
trim_boss_h      = 15;
trim_pad_w       = 6.0;  // blade thickened locally under the boss
trim_pad_h       = 10;   // over this much of the blade's top

// -- Collector --
rim_straight = 6;        // vertical inner wall at the rim: this is what defines catch area
rim_flat     = 0.9;      // rim land width (2 perimeters); a true knife edge is not printable
cone_angle   = 42;       // cone from vertical (<=45 printable, >45 from horizontal per WMO)
nozzle_bore  = 5;
nozzle_len   = 6;
funnel_wall  = 1.8;
skirt_wall   = 2.8;
skirt_rebate = 10;       // depth the funnel skirt slips down over the body

// -- Register drums --
drum_count    = 4;
drum_af       = 32;      // across-flats of the decagonal digit band
drum_pitch    = 18;
digit_band    = 10;      // axial width of the engraved band
digit_h       = 6.5;
digit_depth   = 1.0;    // deeper than it looks like it needs: a shallow engraving in light
                        // PETG casts no shadow viewed straight-on and is nearly unreadable
drum_wall     = 2.0;    // must exceed digit_depth by >= 2 extrusions
// drum_bore is derived from bore_run below -- drums must spin freely
ratchet_r     = 12;      // tooth tip radius
ratchet_teeth = 10;
ratchet_w     = 3.0;
tooth_depth   = 2.0;
lug_r         = 15.0;    // carry lug tip radius. Raising this shortens the follower arm AND
                         // lengthens the lug's own arc, so it cuts the source-drum sweep the
                         // carry needs (29.2 deg -> 23.7 deg of the 36 deg available). It costs
                         // torque ratio (1.23 -> 1.52), which the 3.6x energy margin absorbs.
lug_w         = 2.5;
cw_sector     = 110;     // counterweight sector angle (sets the gravity zero-return)
digit_font    = "Liberation Sans:style=Bold";

// -- Levers. Arm lengths and mounting angles are COMPUTED from the shaft positions further
//    down, not hard-coded, so the timing cannot drift when a shaft or radius is moved.
//    Only the free choices live here.
click_mass_r = 5.0;      // mass boss radius on the UNITS click: sets detent force
click_mass_r_light = 3.4; // the tens/hundreds/thousands clicks. They are stepped 10x, 100x and
                         // 1000x less often, so they need far less preload -- and their load is
                         // what the carry chain MULTIPLIES on a 0999->1000 rollover, so making
                         // them lighter is the cheapest way to buy energy margin. See
                         // register_load_mJ below for why this matters so much.
hook_depth   = 2.6;      // how far a nose hooks in past the tooth tip
lever_thick  = 2.4;
drum_fwd     = 1;        // +1 = drums advance CCW seen along +X. Flips the pawl/click hands
                         // and the engraved digit order together, so the display still counts up.
cam_lobe_r   = 24;       // drive cam lobe tip radius
cam_w        = 3.2;

// -- Cassette / body --
cassette_wall = 3.0;
window_h   = 12;
body_od    = 164;
body_wall  = 2.4;
web_thick  = 3.0;        // bucket pivot web plates inside the body
stop_clear = 10;         // gap between the cassette top and the bucket's lowest sweep
post_d     = 32;         // round post for the OPTIONAL side clamp (post_mount)
// -- Pole-top socket: the primary mount. Coaxial, so the gauge's weight acts straight down the
//    pole axis and there is NO static overturning moment -- unlike a side clamp, which holds
//    ~750g cantilevered ~100mm out and creeps in warm PETG until the rim goes off level.
pole_d        = 32;      // pole OD the socket accepts
socket_depth  = 70;      // how far the pole enters the body (>= 2x pole_d for a stiff joint)
socket_wall   = 4.0;
level_tilt    = 3;       // levelling range each way, degrees -- sets the bore clearance
level_screw_d = 4.0;     // M4 grub/set screws, two rings of three
socket_spokes = 6;
socket_spoke_t = 4.0;
socket_spoke_h = 11;     // must clear the cassette floor above
rim_height    = 1000;    // design rim height above ground; drives the pole length in the README

// -- Fits --
tolerance  = 0.30;       // PETG clearance between EXTERNAL mating surfaces
ef_chamfer = 0.40;       // elephant-foot compensation
// FDM prints holes UNDERSIZE -- roughly this much on a 0.4mm nozzle, and PETG sits at the high
// end because the inner wall oozes inward. This MUST be added to every bore, and forgetting it
// is not a cosmetic error: a "3.0mm press fit" bore prints at 2.65mm, which no amount of
// pushing will get a 3mm rod into, and a nominally-free 3.4mm drum bore prints at 3.05mm and
// seizes. Print part="fit_test" FIRST and trim this number to your own machine before
// committing to the rest.
// MEASURED on an X1C in PETG with the fit_test LADDER (go/no-go against the actual rod), which
// is the only test here that proved trustworthy. Rungs 14/18/22/26 would not accept the rod, 30
// was a firm push that would not twist, 34 could be twisted -- a clean monotonic progression that
// pins comp = 0.30, and which also explains the earlier coupon's results. An intermediate guess
// of 0.22, inferred from verbal descriptions of "rock" rather than from the ladder, explained
// neither coupon: prose is not a measurement. Re-measure for another printer or material.
hole_comp  = 0.30;
// Allowance ON TOP of the compensation, one per fit class. Split out from hole_comp because
// they answer different questions: hole_comp is what the MACHINE does to a hole, the allowance
// is what the JOINT needs. Confusing the two is how the press fit ended up specified as a
// 0.00-clearance slide -- which is not a press fit at all, and let the drive cam wriggle on
// the rod. A press fit needs INTERFERENCE, i.e. a negative allowance.
fit_press  = -0.08;   // rod is gripped: bucket pivot, drive cam, cassette side walls
fit_bear   =  0.15;   // fixed frame, rod rotates within it: body webs, pivot straps
fit_run    =  0.30;   // part swings or spins freely on the rod: drums, levers, spacers
bore_press = rod_d + hole_comp + fit_press;   // ~2.92 printed: firm push, will not rotate
bore_bear  = rod_d + hole_comp + fit_bear;    // ~3.15 printed
bore_run   = rod_d + hole_comp + fit_run;     // ~3.30 printed

// -- View helpers (no effect on printed parts) --
bucket_tilt   = rest_tilt;   // try -rest_tilt or 0 to inspect the mechanism mid-stroke
show_hardware = true;

// === DERIVED CONSTANTS ===
fudge = 0.01;
ew    = nozzle_diameter * 1.125;      // extrusion width 0.45
wall4 = ew * 4;                       // 1.80
wall5 = ew * 5;                       // 2.25
$fn   = $preview ? 32 : 64;

// -- Calibration chain --
catch_area  = catch_area_cm2 * 100;          // mm^2   200 cm^2 -> 20000
rim_id      = 2 * sqrt(catch_area / PI);     // 159.577 mm
rim_ir      = rim_id / 2;
tip_volume  = catch_area * rain_per_tip;     // mm^3    10000 = 10.0 mL
count_mm    = rain_per_tip * tips_per_count; // mm of rain per displayed count = 1.000
chamber_cap = tip_volume * chamber_headroom; // 12000 mm^3

// -- Bucket cross-section. Local frame: y across, z up, z=0 at the divider base. --
// Each chamber is a right triangle: vertical divider face, floor rising at floor_angle,
// open outer lip.   capacity = 1/2 * L^2 * tan(floor_angle) * bucket_wx
bkt_L    = sqrt(2 * chamber_cap / (bucket_wx * tan(floor_angle)));
bkt_hlip = bkt_L * tan(floor_angle);
div_hw   = divider_thick / 2;
lip_iy   = div_hw + bkt_L;
lip_iz   = bkt_hlip;
div_top  = bkt_hlip + divider_over_lip;

// Outer surface = floor offset perpendicular by bucket_wall; normal (sin a, -cos a).
off_y  = bucket_wall * sin(floor_angle);
off_z  = -bucket_wall * cos(floor_angle);
lip_oy = lip_iy + off_y;
lip_oz = lip_iz + off_z;
apex_z = off_z - (div_hw + off_y) * tan(floor_angle);   // outer panels meet at y=0
apex_cut = apex_z + keel_trunc;
keel_hw  = keel_trunc / tan(floor_angle);
bkt_hy   = lip_oy;
bkt_x    = bucket_wx + 2 * bucket_wall;

// -- First-order mass / balance model (volumes x PETG 1.27 g/cm^3) --
pan_len   = bkt_L / cos(floor_angle);
end_area  = 2 * (0.5 * bkt_L * bkt_hlip) + 2 * pan_len * bucket_wall + divider_thick * div_top;
v_panel   = 2 * pan_len * bucket_wx * bucket_wall;                 zv_panel = bkt_hlip / 2;
v_blade   = (div_top - apex_z) * divider_thick * bucket_wx;        zv_blade = (div_top + apex_z) / 2;
v_spine   = (spine_top - apex_cut) * (spine_w - divider_thick) * bucket_wx;
                                                                  zv_spine = (spine_top + apex_cut) / 2;
v_end     = 2 * end_area * bucket_wall;                            zv_end   = 2 * bkt_hlip / 3;
// The trim pad and boss sit at the very top, so they pull z_cog up appreciably for their size --
// leaving them out of the model understates the balance arm.
v_pad     = trim_pad_h * (trim_pad_w - divider_thick) * bucket_wx;  zv_pad = div_top - trim_pad_h / 2;
v_boss    = PI / 4 * (pow(trim_boss_d, 2) - pow(2.6, 2)) * trim_boss_h;
                                                                   zv_boss = div_top + trim_boss_h / 2;
v_tot     = v_panel + v_blade + v_spine + v_end + v_pad + v_boss;
bkt_mass  = v_tot * 1.27 / 1000;                                   // grams
z_cog     = (v_panel * zv_panel + v_blade * zv_blade + v_spine * zv_spine + v_end * zv_end
             + v_pad * zv_pad + v_boss * zv_boss) / v_tot;

// Water body at the trip volume: a triangle similar to the full chamber.
w_scale  = sqrt((tip_volume / bucket_wx) / (0.5 * bkt_L * bkt_hlip));
w_L      = bkt_L * w_scale;   w_H = bkt_hlip * w_scale;
y_w      = (div_hw + (div_hw + w_L) + div_hw) / 3;   // centroid of the water triangle
z_w      = 2 * w_H / 3;
tip_mass = tip_volume / 1000;                        // grams of water

// Closed-form balance solution (see equation (2) in the header):
bal_arm  = tip_mass * (y_w / tan(rest_tilt) - (z_w - z_cog)) / (bkt_mass + tip_mass);
pivot_z  = z_cog - bal_arm;
cal_sens = 100 / bal_arm;                            // % trip-volume error per mm of CoG error

// Energy identity  E = 2*m*y_w*sin(rest_tilt).   g*mm -> mJ
tip_energy_mJ    = 2 * tip_mass * y_w * sin(rest_tilt) * 9.81e-3;
ratchet_step     = 360 / ratchet_teeth;
// (register load model lives after LEVER KINEMATICS -- it needs carry_sweep)

// -- Swept envelope. A point at radius r and bucket-local angle th reaches its lowest Z at
//    the tilt that brings it nearest straight-down, clamped to -90 deg.
function pol_r(dy, dz)  = sqrt(dy * dy + dz * dz);
function pol_a(dy, dz)  = atan2(dz, dy);
function minz(dy, dz, T) = pol_r(dy, dz) * sin(max(-90, pol_a(dy, dz) - T));
function minz_y(dy, dz, T) = pol_r(dy, dz) * cos(max(-90, pol_a(dy, dz) - T));
function maxz(dy, dz, T) = pol_r(dy, dz) * sin(min(90, pol_a(dy, dz) + T));

// Sample the underside line from the keel flat out to the lip corner, plus the gunwale.
n_samp = 24;
under_pts = [for (i = [0 : n_samp])
                let (y = keel_hw + (lip_oy - keel_hw) * i / n_samp)
                [y, apex_z + y * tan(floor_angle) - pivot_z]];
// The trim boss is the bucket's highest point, so it MUST be in the envelope: otherwise
// nozzle_gz is set from the lip alone and the boss can grow up into the funnel unnoticed.
top_pts   = [[lip_iy, lip_iz - pivot_z], [0, div_top - pivot_z],
             [0, div_top + trim_boss_h - pivot_z]];
all_pts   = concat(under_pts, top_pts);
sw_zmin   = min([for (p = all_pts) minz(p[0], p[1], rest_tilt)]);
sw_zmax   = max([for (p = all_pts) maxz(p[0], p[1], rest_tilt)]);
sw_ymax   = max([for (p = all_pts) max(abs(minz_y(p[0], p[1], rest_tilt)), pol_r(p[0], p[1]))]);
// The lip's outer corner should be the unique minimum: that is what makes the stop clean.
lip_minz  = minz(lip_oy, lip_oz - pivot_z, rest_tilt);
stop_y    = minz_y(lip_oy, lip_oz - pivot_z, rest_tilt);
stop_z    = lip_minz;

// Nozzle window: the raised chamber's mouth runs from the blade top to its own inner lip.
// The centred drip stream must sit inside that span at BOTH rest positions.
function rot_y(dy, dz, t) = dy * cos(t) - dz * sin(t);
win_lip = rot_y(lip_iy, lip_iz - pivot_z, rest_tilt);
win_top = rot_y(0, div_top - pivot_z, rest_tilt);
nozzle_window = min(abs(win_lip), abs(win_top));

// -- Collector --
noz_ir    = nozzle_bore / 2;
noz_or    = noz_ir + funnel_wall;
cone_k    = 1 / tan(cone_angle);              // dz/dr along the cone
cone_dr   = funnel_wall / cos(cone_angle);    // radial offset giving a perpendicular wall
cone_rise = (rim_ir - noz_ir) * cone_k;
funnel_h  = nozzle_len + cone_rise + rim_straight;
rim_or    = rim_ir + rim_flat;
skirt_or  = body_od / 2 + skirt_wall + tolerance;
skirt_ir  = skirt_or - skirt_wall;
rebate_ir = body_od / 2 + tolerance;
rim_bev   = skirt_or - rim_or;

// -- Register geometry. Cassette-local frame: origin ON the drum axis, y back, z up. --
drum_w    = lug_w + digit_band + ratchet_w;              // 15.5
drum_bore = bore_run;                                    // drums spin freely on the rod
facet_w   = drum_af * tan(180 / ratchet_teeth);          // decagon facet 10.40
drum_span = drum_count * drum_pitch;                     // 72
function drum_cx(i)    = -drum_span / 2 + drum_pitch / 2 + i * drum_pitch;
function lug_cx(i)     = drum_cx(i) - drum_w / 2 + lug_w / 2;      // lug on the -X face
function ratchet_cx(i) = drum_cx(i) + drum_w / 2 - ratchet_w / 2;  // ratchet on the +X face
units_i = drum_count - 1;                                // units drum is rightmost (+X)
// Axial step a carry lever must reach across, from one drum's ratchet to the next drum's lug.
// (Declared here, not beside carry_lever(): OpenSCAD hoists functions and modules but
// evaluates variable assignments in source order, so this must precede carry_bays below.)
carry_step = lug_cx(1) - ratchet_cx(0);

click_pos = [-8, 23];
carry_pos = [20, 21];
c_front = -17.5;      c_back = 28;      c_bot = -20;      c_top = 44;
cass_x  = drum_span + 2 * 5 + 2 * cassette_wall;          // 88
cass_wall_in = cass_x / 2 - cassette_wall;                // inner face of each side wall
window_w = drum_span + 6;

// -- Assembly frame placement --
body_ir     = body_od / 2 - body_wall;                    // 79.6
boss_face_y = -(body_od / 2 - 2);                         // flat window boss outer face
boss_in_y   = boss_face_y + body_wall;
drum_y      = boss_in_y + cassette_wall - c_front;
cass_bot_z  = 14;
drum_z      = cass_bot_z + cassette_wall - c_bot;
cass_top_z  = drum_z + c_top + cassette_wall;
pivot_gz    = cass_top_z + stop_clear - sw_zmin;
nozzle_gz   = pivot_gz + sw_zmax + 8;
body_h      = nozzle_gz + skirt_rebate;
rim_gz      = body_h - skirt_rebate + funnel_h;
cam_cx      = ratchet_cx(units_i);                        // cam shares the pawl's X plane
web_x       = cam_cx + cam_w / 2 + 5;                     // pivot webs outboard of the cam
// Bore clearance for the levelling range: tilting by t over socket_depth needs the bore
// oversized by socket_depth*tan(t) diametrally, or the pole binds before it is level.
socket_bore = pole_d + socket_depth * tan(level_tilt) + 0.6;
socket_od   = socket_bore + 2 * socket_wall;
level_z_lo  = socket_spoke_h + 5;
level_z_hi  = socket_depth - 10;
pole_top_z  = socket_depth;                               // pole bottoms on the shoulder here
pole_stand  = rim_height - rim_gz + pole_top_z;           // pole length needed ABOVE ground
// Worst-case Y reach of the six levelling-screw bosses. None points at the cassette, so the
// governing number is reach*sin(angle), not reach itself.
socket_reach = socket_bore / 2 + socket_wall + 4;
socket_y_max = max([for (ring = [0, 1]) for (i = [0 : 2])
                    abs(socket_reach * sin(i * 120 + ring * 60))]);
stop_beam_z = pivot_gz + stop_z - 4;                      // beam top: strictly below the sweep

// === LEVER KINEMATICS ===
// Computed, never hard-coded, so the timing cannot drift if a shaft or radius moves.
// All in the cassette-local frame with the drum axis at the origin (y back, z up).
function vlen(v)      = sqrt(v[0] * v[0] + v[1] * v[1]);
function cross2(a, b) = a[0] * b[1] - a[1] * b[0];
// Mounting angle that makes a lever drawn along its local +X point along v in the YZ plane.
// (A lever is placed with rotate([0,90,0]) rotate([0,0,a]), which sends local +X to
//  world (0, sin a, -cos a) -- hence atan2(v.y, -v.z).)
function mount_ang(v) = atan2(v[0], -v[1]);
function tan_pt(P, R, s) = let (d = vlen(P), th = atan2(P[1], P[0]) + s * acos(R / d))
                           [R * cos(th), R * sin(th)];

// CLICK -- a TANGENT arm. Its nose therefore moves radially, which is what a detent wants:
// it drops in to engage and blocks the tooth by abutment. Gravity engages it for free,
// because every point of the arm lies at positive local +X from the pivot and that is the
// direction whose weight closes the lever onto the wheel.
click_ct   = tan_pt(click_pos, ratchet_r, -drum_fwd);
click_v    = click_ct - click_pos;
click_len  = vlen(click_v);
click_mt   = mount_ang(click_v);
click_hand = sign(cross2(click_v, -click_pos));   // which side of the arm the wheel sits on

// CARRY LEVER -- a RADIAL arm, so its nose moves TANGENTIALLY and can drive a tooth round.
// (A tangent arm cannot: its nose moves radially and would only rub.) lug_r is deliberately
// only 1.5mm above ratchet_r, which makes the follower and nose arms nearly equal and the
// carry nearly 1:1 in torque. A large lug radius would force the source drum to supply
// several times the torque the driven drum needs, straight out of the tip energy budget.
carry_d     = vlen(carry_pos);
carry_nose  = carry_d - ratchet_r;
carry_foll  = carry_d - lug_r;
carry_mt    = mount_ang(-carry_pos);
tooth_arc   = 2 * PI * ratchet_r / ratchet_teeth;                  // 7.54mm at the nose
carry_sweep = (tooth_arc * carry_foll / carry_nose) / lug_r * 180 / PI;  // deg of source drum

// DRIVE PAWL -- radial nose arm; the tail reaches the cam on the bucket pivot rod.
cam_local  = [-drum_y, pivot_gz - drum_z];
pawl_nose  = carry_d - ratchet_r;
pawl_v     = cam_local - carry_pos;
pawl_tail  = vlen(pawl_v) - cam_lobe_r;
pawl_mt    = mount_ang(pawl_v);
pawl_inner = carry_mt - pawl_mt;                  // nose angle relative to the tail
cam_lift   = tooth_arc * pawl_tail / pawl_nose;   // cam lift = tail travel for one tooth
cam_base_r = cam_lobe_r - cam_lift;
// The lobe points straight at the pawl pivot at +rest_tilt (full push) and is 2*rest_tilt
// away at the other stop (fully retracted). That is what makes the pawl fire on alternate
// tips, giving 2 tips per count without a second pawl.
cam_mount  = mount_ang(carry_pos - cam_local) - rest_tilt;

// RESET LINKAGE -- a shaft LIFT, not a rotating blade.
// The click shaft rides in vertical slots and a yoke cradles it from below; pressing the
// button raises the yoke, which carries the shaft and all four clicks bodily out of the
// teeth. An earlier revision rotated a bar whose blade pushed each click's arm, but to get a
// usable button stroke the blade had to bear far out along the arm -- which is exactly where
// the arm passes inside the drum's silhouette, so the blade fouled the drums. Lifting the
// shaft is 1:1 (button travel = click lift), needs no clearance past the drums, and gravity
// on the shaft plus four clicks returns everything, so there is still no spring.
click_lift  = tooth_depth + 1.2;             // how far the clicks must rise to clear the teeth
yoke_y      = -14;                           // cross bar sits forward of the drums
yoke_z      = click_pos[1] - 7;
yoke_arm_x  = cass_wall_in - 5;
button_gz   = drum_z + yoke_z;
button_len  = abs(boss_face_y) + drum_y + yoke_y + 5;
button_travel = click_lift;                  // 45 deg wedge: horizontal push = vertical lift

click_torque     = 0.15;                             // N*mm, the UNITS click, design target
// Worst case is a triple carry (0999 -> 1000): four stages step at once, and the load does NOT
// simply add. Each carry stage advances its drum 36 deg while its source turns only
// carry_sweep, so it MULTIPLIES torque by carry_ratio -- and that compounds over three stages.
// Reflected to the units drum the factor is 1 + k*(r + r^2 + r^3), where k is how much lighter
// the upper clicks are (torque scales with the mass boss area). With equal clicks and r = 1.52
// this factor is 8.3 and the margin collapses to 1.7x; light upper clicks cut it to ~4.4.
carry_ratio      = ratchet_step / carry_sweep;
click_light_k    = pow(click_mass_r_light / click_mass_r, 2);
carry_load_factor = 1 + click_light_k * (carry_ratio + pow(carry_ratio, 2) + pow(carry_ratio, 3));
register_load_mJ = click_torque * carry_load_factor * (ratchet_step * PI / 180);

// === CONTRACTS ===
// Metrology
assert(abs(catch_area - PI * rim_ir * rim_ir) < 0.5, "rim ID does not match the catch area");
assert(abs(count_mm - 1.0) < 1e-6, "one displayed count must equal 1.000 mm of rain");
assert(catch_area_cm2 >= 200, "WMO recommends a collector of at least 200 cm^2");
assert(drum_count == 4 && ratchet_teeth == 10, "register must read 0000-9999");
// Bucket function
assert(rest_tilt >= floor_angle + 4, "rest_tilt must exceed floor_angle or the chamber will not empty");
assert(chamber_cap >= tip_volume * 1.15, "chamber has too little headroom over the trip volume");
assert(bal_arm > 5.0, str("balance arm ", bal_arm, "mm is too small: trip volume would be ",
       cal_sens, "% per mm of CoG error"));
assert(pivot_z > apex_cut + rod_d / 2 + 0.8, "pivot bore breaks out of the keel");
assert(pivot_z + rod_d / 2 < spine_top, "pivot rod is not fully enclosed by the blade spine");
assert(trim_pad_w > divider_thick + 2 && trim_pad_w <= trim_boss_d,
       "trim pad must be wider than the blade but no wider than the boss it carries");
assert(trim_boss_d - 2.6 >= 2 * 3 * ew, "trim boss wall too thin to self-tap M3 into");
assert(spine_w >= rod_d + 2 * bucket_wall, "blade spine too thin to enclose the rod");
assert(nozzle_window >= noz_ir + 4, "drip stream can miss the raised chamber or clear its lip");
assert(tip_energy_mJ > register_load_mJ * 2.5,
       str("tip energy has under 2.5x margin on the register: ", tip_energy_mJ / register_load_mJ));
assert(carry_ratio < 1.7, str("carry torque ratio ", carry_ratio, " compounds too hard over 3 stages"));
// The stop is only safe if the lip is the UNIQUE lowest point of the swept envelope.
assert(abs(lip_minz - sw_zmin) < 0.01, "lip is not the lowest swept point: the stop would foul");
assert(abs(stop_y) > 20, "stop screws land too close to the axis to be reachable");
// Linkage
assert(click_len > ratchet_r, "click arm is shorter than the wheel radius: geometry is degenerate");
assert(carry_sweep < ratchet_step - 3,
       str("carry needs ", carry_sweep, " deg of source rotation but only ", ratchet_step,
           " deg is available before the next count"));
assert(cam_base_r > rod_d / 2 + 3, "cam base circle too small to hold the rod");
assert(cam_lift < cam_lobe_r - rod_d, "cam lift exceeds what the lobe can provide");
assert(button_travel > 1.5, "reset button travel is too small to press reliably");
assert(button_len > 4, "reset plunger does not reach the lifter ramp");
assert(vlen([yoke_y, yoke_z]) > drum_af / 2 + 3, "lifter cross bar fouls the drums");
assert(yoke_y > c_front + 2, "lifter cross bar clashes with the cassette front wall");
assert(click_lift > tooth_depth, "clicks would not fully clear the teeth on a reset");
assert(abs(pawl_inner) > 90, "pawl nose and tail are too close in angle to work as a lever");
// Fit
assert(2 * (bkt_x / 2 + boss_out) < 2 * (cam_cx - cam_w / 2) - 2,
       "drive cam collides with the bucket pivot boss");
assert(web_x + 4 < sqrt(body_ir * body_ir - sw_ymax * sw_ymax), "pivot webs foul the swing");
assert(sw_ymax < body_ir - 3, "bucket swing fouls the body bore");
assert(stop_beam_z > cass_top_z + 1, "stop beams collide with the cassette");
assert(pocket_d > 2 && pocket_d < 20, str("cassette relief pocket depth implausible: ", pocket_d));
assert(pocket_d <= 18, "relief pocket ceiling would be too wide a bridge for PETG");
// Pole socket
assert(socket_depth >= 2 * pole_d, "pole socket too shallow to resist the wind moment stiffly");
assert(socket_depth + 12 < pivot_gz + sw_zmin, "pole socket fouls the tipping bucket's swing");
assert(socket_y_max < abs(drum_y + c_back + cassette_wall) - 2,
       str("pole socket screw bosses reach Y=", socket_y_max, " and foul the cassette"));
assert(socket_spoke_h < cass_bot_z - 2, "socket spokes foul the cassette floor");
assert(socket_bore > pole_d, "socket bore must clear the pole");
// Rod fits: ordered, and never smaller than the rod once the hole compensation is applied.
assert(hole_comp > 0.15 && hole_comp < 0.6, "hole_comp outside any plausible FDM range");
assert(bore_press >= rod_d, "press bore would print smaller than the rod");
assert(bore_bear > bore_press && bore_run > bore_bear, "rod fits are out of order");
assert(drum_bore == bore_run, "drums must use the free-running fit");
assert(level_z_hi - level_z_lo > 25, "levelling screw rings too close together to set a tilt");
assert(pole_stand > 100, str("pole stand-out of ", pole_stand, "mm is implausible for rim_height"));
// The boss MUST cover the pocket over its whole height, or the pocket breaches the cylinder.
assert(boss_z0 <= cass_bot_z && boss_z1 >= cass_top_z + 1,
       "window boss does not cover the cassette relief pocket: it would open the register bay");
assert(boss_z1 >= cass_top_z + 1 && boss_z0 <= cass_bot_z,
       "boss flat face does not span the relief pocket: the pocket would breach the cylinder");
assert(drum_z - window_h / 2 - 2 > boss_z0 && drum_z + window_h / 2 + 2 < boss_z1,
       "reading window falls outside the flat of the window boss");
assert(button_gz > boss_z0 + 6 && button_gz < boss_z1 - 6,
       "reset button falls outside the flat of the window boss");
assert(boss_z1 + boss_depth < body_h - skirt_rebate, "window boss collides with the funnel skirt");
assert(drum_w < drum_pitch - 0.8, "drums collide on their pitch");
assert(digit_h < facet_w - 3, "digit is too tall for the decagon facet");
assert(drum_wall - digit_depth >= 2 * ew, "engraving would leave the drum wall too thin");
assert(sqrt(pow(cass_x / 2, 2) + pow(drum_y + c_back + cassette_wall, 2)) < body_ir,
       "cassette back corners foul the body bore");
assert(lug_cx(units_i) - ratchet_cx(units_i - 1) > 2, "carry lever cannot span lug to ratchet");
// Printability / build volume
assert(2 * skirt_or <= bed_safe, "funnel exceeds the X1C auto-centred bed: split it or fit the clip");
assert(body_od <= bed_safe && body_h <= build_z, "body does not fit the build volume");
assert(skirt_ir >= rim_ir + cone_dr, "funnel profile self-intersects at the rim");
assert(2 * floor_angle <= 60, "far chamber underside would overhang past 45 deg once rotated");
assert(abs(bucket_wall - wall4) < 0.01, "bucket wall is not a whole number of extrusions");
assert(abs(funnel_wall - wall4) < 0.01, "funnel wall is not a whole number of extrusions");

echo("=== CALIBRATION ===");
echo(catch_area_cm2 = catch_area_cm2, rim_id = rim_id, tip_volume_mL = tip_volume / 1000,
     mm_per_count = count_mm, tips_per_count = tips_per_count);
echo("=== BUCKET ===");
echo(chamber_run = bkt_L, lip_height = bkt_hlip, bbox_in_use = [bkt_x, 2 * bkt_hy, div_top - apex_cut]);
echo(mass_g = bkt_mass, z_cog = z_cog, pivot_z = pivot_z, balance_arm = bal_arm);
echo(pct_trip_error_per_mm_cog = cal_sens);
echo(water_centroid_y = y_w, nozzle_window = nozzle_window);
echo(sweep = [sw_zmin, sw_zmax, sw_ymax], stop_at = [stop_y, stop_z]);
echo("=== ENERGY BUDGET (mJ per working stroke) ===");
echo(tip_energy_mJ = tip_energy_mJ, register_load_worst_mJ = register_load_mJ,
     margin_x = tip_energy_mJ / register_load_mJ, carry_ratio = carry_ratio,
     carry_load_factor = carry_load_factor);
echo("=== LEVER KINEMATICS (computed) ===");
echo(click_len = click_len, click_mount = click_mt, click_hand = click_hand, click_contact = click_ct);
echo(carry_nose = carry_nose, carry_foll = carry_foll, carry_mount = carry_mt,
     source_drum_sweep_deg = carry_sweep);
echo(pawl_nose = pawl_nose, pawl_tail = pawl_tail, pawl_mount = pawl_mt, pawl_inner = pawl_inner);
echo(cam_lift = cam_lift, cam_base_r = cam_base_r, cam_mount = cam_mount);
echo("=== POLE MOUNT ===");
echo(pole_d = pole_d, socket_bore = socket_bore, socket_depth = socket_depth,
     level_tilt_deg = level_tilt, rim_height = rim_height, pole_above_ground = pole_stand);
echo("=== ENVELOPE ===");
echo(body = [body_od, body_h], funnel = [2 * skirt_or, funnel_h],
     assembled_height = rim_gz, pivot_gz = pivot_gz, drum_z = drum_z, cam_cx = cam_cx);

// === SHARED HELPERS ===

module ring(orad, irad, h) {
    difference() {
        cylinder(r = orad, h = h);
        translate([0, 0, -fudge]) cylinder(r = irad, h = h + 2 * fudge);
    }
}

// Horizontal rod bore that prints without support: round bore plus a small gable above it,
// so the top of the hole has something to build on instead of bridging across the full width.
module teardrop_bore(d, len) {
    r = d / 2;
    rotate([0, 90, 0]) linear_extrude(height = len, center = true)
        union() {
            circle(r = r);
            polygon([[-r * 0.6, r * 0.6], [r * 0.6, r * 0.6], [0, r * 1.5]]);
        }
}

// Asymmetric ratchet: a radial drive face for the pawl, and a ramped back flank so the pawl
// and click both ride out in the non-working direction.
// Both tooth root points are pulled 0.5mm INSIDE the base circle. A root sitting exactly on
// the nominal radius lands outside the inscribed polygon between two of its vertices, which
// leaves a sliver and a non-manifold edge that Manifold self-heals but Bambu Studio rejects.
// $fn is also forced to a multiple of the tooth count so vertices land on tooth boundaries.
module ratchet_2d(rt, teeth, depth) {
    rr = rt - depth;
    pa = 360 / teeth;
    ri = rr - 0.5;
    union() {
        circle(r = rr, $fn = teeth * 6);
        for (i = [0 : teeth - 1])
            rotate(i * pa)
                polygon([[ri, 0], [rt, 0],
                         [rt * cos(pa * 0.30), rt * sin(pa * 0.30)],
                         [ri * cos(pa), ri * sin(pa)]]);
    }
}

module pie(r, a) {
    intersection() {
        circle(r = r);
        polygon([[0, 0], [r * 2 * cos(-a / 2), r * 2 * sin(-a / 2)],
                 [r * 2.4, 0], [r * 2 * cos(a / 2), r * 2 * sin(a / 2)]]);
    }
}

module lever_blank(len, w0, w1) {
    hull() { circle(d = w0); translate([len, 0]) circle(d = w1); }
}

// === BUCKET ===

// Material cross-section of the right-hand trough wall, with a sharp chamfered lip top.
function bkt_half_poly() = [
    [0, apex_z],
    [lip_oy, lip_oz],
    [lip_iy, lip_iz - lip_chamfer],
    [lip_iy - lip_chamfer, lip_iz],
    [div_hw, 0],
    [div_hw, apex_z + div_hw * tan(floor_angle)]
];

// The bucket's full outer silhouette: keel V up to a straight gunwale at each lip.
function bkt_outline() = [
    [0, apex_z], [lip_oy, lip_oz], [lip_iy, lip_iz], [0, div_top],
    [-lip_iy, lip_iz], [-lip_oy, lip_oz]
];

module bucket_section_2d() {
    intersection() {
        union() {
            polygon(bkt_half_poly());
            mirror([1, 0, 0]) polygon(bkt_half_poly());
            translate([-div_hw, apex_z]) square([divider_thick, div_top - apex_z]);
            // Local pad under the trim boss: the blade is only divider_thick (2mm) at the top,
            // which is too little to hang a screw boss off. Tapered at 45 deg, so the one face
            // that ends up overhanging after the 28 deg print rotation spans barely 1.5mm.
            polygon([[-trim_pad_w / 2, div_top],
                     [ trim_pad_w / 2, div_top],
                     [ trim_pad_w / 2, div_top - trim_pad_h],
                     [ div_hw, div_top - trim_pad_h - (trim_pad_w / 2 - div_hw)],
                     [-div_hw, div_top - trim_pad_h - (trim_pad_w / 2 - div_hw)],
                     [-trim_pad_w / 2, div_top - trim_pad_h]]);
            // Blade spine, CLIPPED to the outer silhouette. Unclipped, its 8mm width bulges
            // below the 6mm keel flat, so the part would rest on a spine corner instead of
            // on a chamber underside -- losing the flat 33 x 43mm first layer.
            intersection() {
                translate([-spine_w / 2, apex_z]) square([spine_w, spine_top - apex_z]);
                polygon(bkt_outline());
            }
        }
        translate([-bkt_hy - 1, apex_cut]) square([2 * bkt_hy + 2, div_top - apex_cut + 1]);
    }
}

// End wall: closes both chambers up to a straight gunwale from lip to blade top.
module bucket_endwall_2d() {
    intersection() {
        polygon(bkt_outline());
        translate([-bkt_hy - 1, apex_cut]) square([2 * bkt_hy + 2, div_top - apex_cut + 1]);
    }
}

module bucket_core() {
    difference() {
        union() {
            rotate([90, 0, 90]) translate([0, 0, -bucket_wx / 2])
                linear_extrude(height = bucket_wx) bucket_section_2d();
            for (s = [-1, 1])
                translate([s * (bucket_wx / 2 + bucket_wall / 2), 0, 0]) rotate([90, 0, 90])
                    translate([0, 0, -bucket_wall / 2])
                        linear_extrude(height = bucket_wall) bucket_endwall_2d();
            // OUTBOARD bearing pads: they never intrude into the water chambers
            for (s = [-1, 1])
                translate([s * (bkt_x / 2 - fudge), 0, pivot_z]) rotate([0, s * 90, 0])
                    cylinder(d = rod_d + 6, h = boss_out + fudge);
            translate([0, 0, div_top - fudge]) cylinder(d = trim_boss_d, h = trim_boss_h);
        }
        // pivot bore: press fit, so the rod turns with the bucket and drives the cam
        translate([-bkt_x, 0, pivot_z]) rotate([0, 90, 0])
            cylinder(d = bore_press, h = 3 * bkt_x);
        translate([0, 0, div_top - 7]) cylinder(d = 2.6, h = trim_boss_h + 9);
        // keel vents so the underside cannot hold water
        for (i = [-1, 0, 1])
            translate([i * 9, 0, apex_cut - 1]) rotate([90, 0, 0])
                cylinder(d = 4, h = 40, center = true, $fn = 24);
    }
}

// Once rotated by floor_angle, the +y chamber's underside plane is horizontal and sits this
// far below the origin, so lifting by it puts that flat exactly on the build plate.
bkt_print_dz = abs(apex_z) * cos(floor_angle);
bkt_foot_area = (lip_oy - keel_hw) / cos(floor_angle) * bkt_x;

module bucket() {
    // PRINT ORIENTATION: rotated by floor_angle so one chamber underside lies flat on the bed.
    translate([0, 0, bkt_print_dz]) rotate([-floor_angle, 0, 0]) bucket_core();
}

// Single-lobe cam pressed onto the pivot rod outboard of the bucket. It pushes the pawl on
// one stroke and simply retreats on the other, so the pawl advances once per full cycle.
// Its base and lobe radii come from cam_lift in the kinematics block.
module drive_cam() {
    linear_extrude(height = cam_w)
        difference() {
            hull() {
                circle(r = cam_base_r);
                translate([cam_lobe_r - 4.5, 0]) circle(r = 4.5);
            }
            circle(d = bore_press);
            translate([-rod_d / 2, rod_d / 2 - 0.5]) square([rod_d, 0.55]);   // anti-creep flat
        }
}

// === COLLECTOR ===

// Revolved profile. Every surface is vertical, converges upward, or is a 42-deg cone growing
// outward from the nozzle -- all self-supporting printed rim-up.
module funnel_profile_2d() {
    zr = funnel_h;
    z_ref = zr - rim_straight;
    polygon([
        [rebate_ir, 0], [skirt_or, 0],
        [skirt_or, zr - rim_bev], [rim_or, zr],
        [rim_ir, zr], [rim_ir, z_ref],
        [noz_ir, nozzle_len], [noz_ir, 0], [noz_or, 0],
        [noz_ir + cone_dr, nozzle_len],
        [rim_ir + cone_dr, z_ref],
        [skirt_ir, z_ref],
        [skirt_ir, skirt_rebate + 1.2],
        [rebate_ir, skirt_rebate]
    ]);
}

module funnel() { rotate_extrude(angle = 360, convexity = 8) funnel_profile_2d(); }

// === BODY ===
// Open-bottomed cylinder: it drains freely, so there is no internal deck to bridge-print.
module body() {
    difference() {
        union() {
            ring(body_od / 2, body_ir, body_h);
            window_boss();
            pivot_webs();
            stop_beams();
            pole_socket();
            for (s = [-1, 1])
                translate([s * (cass_x / 2 - 5), drum_y + c_back, cass_bot_z - 8])
                    cylinder(d = 11, h = 9);
            translate([0, body_ir - 1, body_h * 0.42])
                cube([post_d + 20, 10, 74], center = true);
        }
        cassette_pocket();
        translate([0, boss_face_y - 6, drum_z]) window_cut(30);
        translate([0, boss_face_y - 6, button_gz]) rotate([-90, 0, 0])
            cylinder(d = 8 + tolerance, h = button_len + 8);
        for (s = [-1, 1]) for (yy = [-13, 13])
            translate([s * web_x, yy, pivot_gz + 9]) cylinder(d = 2.6, h = 16, center = true);
        for (s = [-1, 1])
            translate([0, s * abs(stop_y), stop_beam_z - 14]) cylinder(d = 2.6, h = 18);
        for (s = [-1, 1])
            translate([s * (cass_x / 2 - 5), drum_y + c_back, cass_bot_z - 9])
                cylinder(d = 2.6, h = 18);
        for (z = [-24, 24])
            translate([0, body_ir + 8, body_h * 0.42 + z]) rotate([90, 0, 0])
                cylinder(d = 3.4, h = 34, center = true);
        for (a = [0 : 30 : 359])
            rotate([0, 0, a]) translate([0, body_ir - 1, -fudge]) rotate([0, 0, 45])
                cube([10, 10, 11]);
        difference() {
            translate([0, 0, -fudge]) cylinder(r = body_od, h = ef_chamfer + fudge);
            cylinder(r1 = body_od / 2 - ef_chamfer, r2 = body_od / 2, h = ef_chamfer + 2 * fudge);
        }
    }
}

// Flat-faced boss carrying the reading window and the reset button. It only stands proud of
// the cylinder where the cylinder falls away, and its top and bottom are 45-deg ramps.
// Height is DRIVEN BY THE CASSETTE, not chosen. The boss has to cover the relief pocket over
// the cassette's whole height; if it stops short, the pocket cuts straight through the plain
// cylinder wall above it and opens the register bay to the weather.
// boss_z0..boss_z1 is the FLAT face, and it must span the whole relief pocket -- not just the
// windows. Only the TOP gets a 45 deg ramp (to shed rain and print unsupported); the underside
// is left flat, which is a boss_depth (14mm) overhang off the cylinder and well inside PETG's
// bridging range. Chamfering both ends instead pulls the face in by 2*boss_depth, and then the
// pocket runs past the face into the receding chamfer and breaches the cylinder again.
boss_z0 = cass_bot_z - 3;
boss_z1 = cass_top_z + 2;
boss_depth = 14;
boss_face_h = boss_z1 - boss_z0;
module window_boss() {
    bw = cass_x + 6;
    hull() {
        translate([0, boss_face_y + 1, (boss_z0 + boss_z1) / 2])
            cube([bw, 2, boss_face_h], center = true);
        translate([0, boss_face_y + 1 + boss_depth, (boss_z0 + boss_z1 + boss_depth) / 2])
            cube([bw, 2, boss_face_h + boss_depth], center = true);
    }
}

// FOUR small apertures, one per drum, each with its own 45 deg gable -- NOT one wide slot.
// A single 78mm-wide slot needs either a 78mm bridge (impossible in PETG) or a 45 deg gable
// 39mm tall, which is a huge triangular hole straight into the register bay for rain and
// debris. Per-drum apertures make each gable only 5.75mm tall and match the bezel exactly.
module window_apertures_2d() {
    aw = digit_band + 1.5;
    for (i = [0 : drum_count - 1])
        translate([drum_cx(i), 0])
            polygon([[-aw / 2, -window_h / 2], [aw / 2, -window_h / 2], [aw / 2, window_h / 2],
                     [0, window_h / 2 + aw / 2], [-aw / 2, window_h / 2]]);
}

// Cut the apertures through a front-facing wall of the given thickness. The transform lives
// here so the body and the cassette cannot disagree, and because it needs a correction that is
// easy to get wrong: rotate([-90,0,0]) maps (x,y,z)->(x,z,-y), so local +y becomes world -Z and
// the gable apex would end up at the BOTTOM -- a downward spike below the slot instead of a
// peaked roof above it, defeating both the no-bridge and the rain-shedding intent. Hence the
// mirror. Negating the rotation to rotate([90,0,0]) is NOT an alternative: that also sends the
// extrusion to -Y, so the hole would tunnel outward instead of into the wall.
module window_cut(depth) {
    rotate([-90, 0, 0]) linear_extrude(height = depth) mirror([0, 1, 0]) window_apertures_2d();
}

// Two internal web plates carrying the bucket pivot saddles.
module pivot_webs() {
    for (s = [-1, 1])
        translate([s * web_x, 0, 0])
            difference() {
                intersection() {
                    translate([-web_thick / 2, -body_ir, cass_top_z + 2])
                        cube([web_thick, 2 * body_ir, pivot_gz + 16 - cass_top_z - 2]);
                    cylinder(r = body_ir - 0.2, h = body_h);
                }
                translate([0, 0, pivot_gz]) rotate([0, 90, 0])
                    cylinder(d = bore_bear, h = 3 * web_thick, center = true);
                translate([-web_thick, -rod_d / 2 - tolerance / 2, pivot_gz])
                    cube([3 * web_thick, bore_bear, 24]);
                for (yy = [-58, -38, 38, 58])
                    translate([0, yy, cass_top_z + 12]) rotate([0, 90, 0])
                        linear_extrude(height = 3 * web_thick, center = true)
                            polygon([[-7, -6], [7, -6], [7, 6], [0, 13], [-7, 6]]);
            }
    // thicken the webs locally at the bearing for a longer journal
    for (s = [-1, 1])
        translate([s * web_x, 0, pivot_gz])
            difference() {
                translate([-4, -9, -14]) cube([8, 18, 20]);
                rotate([0, 90, 0]) cylinder(d = bore_bear, h = 20, center = true);
                translate([-5, -bore_bear / 2, 0]) cube([10, bore_bear, 10]);
            }
}

// Stop-screw beams. Their tops sit strictly BELOW the bucket's lowest sweep, so nothing can
// touch them; only the screw heads reach up into the sweep plane, at the one Y where the lip
// bottoms out. Undersides are 45-deg ramps off the webs, so nothing bridges.
module stop_beams() {
    for (s = [-1, 1])
        hull() {
            translate([-web_x, s * abs(stop_y) - 6, stop_beam_z - 2])
                cube([2 * web_x, 12, 2]);
            translate([-web_x, s * abs(stop_y) - 6, stop_beam_z - 16])
                cube([2 * web_x, 12 - 2 * 12, 2]);
            translate([-web_x, s * abs(stop_y) - 1, stop_beam_z - 16]) cube([2 * web_x, 2, 2]);
        }
}

// The cassette is 88mm wide, so its front corners sit outside the body bore and bite into the
// window boss. Only THAT sliver needs relieving -- pocket_d below -- not the cassette's whole
// depth. (An earlier version hulled two boxes sharing a corner, which is not a wedge at all:
// the larger box contains the smaller, so the result was a plain 88 x 52 x 122mm box cut clean
// through the front of the gauge.) The roof is a true 45 deg ramp rising rearward, so each
// layer's new material overhangs the one below by less than a wall width.
pocket_d = -boss_in_y - sqrt(body_ir * body_ir - pow(cass_x / 2 + tolerance, 2)) + 1.5;
module cassette_pocket() {
    w = cass_x + 2 * tolerance;
    // Plain box with a flat top. The ceiling is only pocket_d (~13mm) deep and is backed by
    // the front wall, so PETG bridges it -- no ramp needed, and crucially no extra height that
    // would run past the top of the boss.
    translate([-w / 2, boss_in_y, cass_bot_z])
        cube([w, pocket_d, cass_top_z - cass_bot_z + 1]);
}

module pivot_strap() {
    difference() {
        union() {
            cube([web_thick + 9, 30, 4], center = true);
            translate([0, 0, -3.4]) cube([web_thick + 9, 12, 4], center = true);
        }
        rotate([0, 90, 0]) cylinder(d = bore_bear, h = 40, center = true);
        for (yy = [-11, 11]) translate([0, yy, 0]) cylinder(d = 3.4, h = 20, center = true);
    }
}

// Pole-top socket. Coaxial with the gauge, tied to the body wall by spokes that stay BELOW the
// cassette floor. Two rings of three set screws 44mm apart let the rim be trimmed level even on
// an out-of-plumb pole, and lock it there. The bore stays open above the shoulder so water that
// gets in runs down past the pole instead of pooling on top of it.
module pole_socket() {
    difference() {
        union() {
            cylinder(d = socket_od, h = socket_depth);
            for (ring = [0, 1]) for (i = [0 : 2])
                rotate([0, 0, i * 120 + ring * 60])
                    translate([0, 0, ring == 0 ? level_z_lo : level_z_hi]) rotate([0, 90, 0])
                        cylinder(d = level_screw_d + 10, h = socket_bore / 2 + socket_wall + 4);
            for (i = [0 : socket_spokes - 1])
                rotate([0, 0, i * 360 / socket_spokes])
                    translate([0, -socket_spoke_t / 2, 0])
                        cube([body_ir - 0.4, socket_spoke_t, socket_spoke_h]);
        }
        translate([0, 0, -fudge]) cylinder(d = socket_bore, h = socket_depth + fudge);
        translate([0, 0, socket_depth - fudge]) cylinder(d = 20, h = 30);   // drain-through
        for (ring = [0, 1]) for (i = [0 : 2])
            rotate([0, 0, i * 120 + ring * 60])
                translate([0, 0, ring == 0 ? level_z_lo : level_z_hi]) rotate([0, 90, 0])
                    cylinder(d = level_screw_d - 0.4, h = 80);              // M4 self-tap pilot
    }
}

// === CASSETTE ===
// All four rods slide in axially through press-fit bores in the side walls after the drums
// and levers are dropped in -- the way a real counter register is assembled. An earlier
// revision used upward-opening saddles plus a lid with fingers to trap the rods, but the
// drum-shaft finger had to reach 42mm down from the lid past the drums, which is absurd.
module cassette() {
    wall_in = cass_x / 2 - cassette_wall;
    difference() {
        union() {
            translate([0, (c_front + c_back) / 2, c_bot - cassette_wall / 2])
                cube([cass_x, c_back - c_front + 2 * cassette_wall, cassette_wall], center = true);
            for (s = [-1, 1])
                translate([s * (cass_x / 2 - cassette_wall / 2), (c_front + c_back) / 2,
                           (c_bot + c_top) / 2])
                    cube([cassette_wall, c_back - c_front + 2 * cassette_wall,
                          c_top - c_bot], center = true);
            for (yy = [c_back + cassette_wall / 2, c_front - cassette_wall / 2])
                translate([0, yy, (c_bot + c_top) / 2])
                    cube([cass_x, cassette_wall, c_top - c_bot], center = true);
            // integral end collars take up the slack either side of the drum row, so only the
            // three inter-drum spacers are loose parts
            for (s = [-1, 1])
                translate([s * (drum_span / 2 - drum_pitch / 2 + drum_w / 2), 0, 0])
                    rotate([0, s * 90, 0])
                        cylinder(d = drum_bore + 5, h = wall_in - (drum_span / 2 - drum_pitch / 2 + drum_w / 2));
        }
        // rod bores, press fit, through both side walls
        // drum and carry shafts are plain press-fit bores; the CLICK shaft gets a vertical
        // slot instead, because the reset lifts it bodily out of the teeth
        for (p = [[0, 0], carry_pos])
            translate([0, p[0], p[1]]) teardrop_bore(bore_press, 3 * cass_x);
        translate([0, click_pos[0], click_pos[1]]) {
            teardrop_bore(bore_run, 3 * cass_x);
            translate([0, -bore_run / 2, 0])
                cube([3 * cass_x, bore_run, click_lift + 2], center = false);
            translate([-1.5 * cass_x, -bore_run / 2, 0])
                cube([3 * cass_x, bore_run, click_lift + 2]);
        }
        // reading window: four gabled apertures, matching the body and bezel. Same shared
        // transform as the body -- the gable inversion bit here too, not just in body().
        translate([0, c_front - cassette_wall - 1, 0]) window_cut(cassette_wall + 2);
        // floor drains: anything that gets in, gets out
        for (i = [-2 : 2])
            translate([i * 15 - 2, c_front + 4, c_bot - cassette_wall - fudge])
                cube([4, 16, cassette_wall + 2 * fudge]);
        // slot for the drive pawl tail to reach the cam
        translate([cam_cx - 6, c_back - 1, carry_pos[1] - 6])
            cube([12, cassette_wall + 2, c_top - carry_pos[1] + 7]);
        // slot for the reset lever arm to reach the button
        // clearance for the reset button and the lifter ramp
        translate([-11, c_front - cassette_wall - 1, yoke_z - 2])
            cube([22, cassette_wall + 6, 20]);
    }
}

// Plain drip cover. It carries no mechanism: the rods are retained by the side walls.
module cassette_lid() {
    difference() {
        translate([0, (c_front + c_back) / 2, 0])
            cube([cass_x, c_back - c_front + 2 * cassette_wall, cassette_wall], center = true);
        for (s = [-1, 1])
            translate([s * (cass_x / 2 - 5), c_back - 5, -cassette_wall])
                cylinder(d = 3.4, h = 3 * cassette_wall);
    }
}

// -- Axial spacers. Lengths are DERIVED from where the levers actually sit, so they cannot
//    go stale if a lever position or thickness changes. Printed as one break-apart comb.
click_bays = [for (i = [0 : drum_count - 1])
                 [ratchet_cx(i) - lever_thick / 2, ratchet_cx(i) + lever_thick / 2]];
carry_bays = concat(
    [for (i = [1 : drum_count - 1])
        [ratchet_cx(i - 1) - lever_thick / 2,
         ratchet_cx(i - 1) + lever_thick / 2 + carry_step - 0.8]],
    [[cam_cx - (lever_thick + 0.8) / 2, cam_cx + (lever_thick + 0.8) / 2]]);
function gaps(bays) = concat(
    [bays[0][0] + cass_wall_in],
    [for (i = [1 : len(bays) - 1]) bays[i][0] - bays[i - 1][1]],
    [cass_wall_in - bays[len(bays) - 1][1]]);
click_gaps = gaps(click_bays);
carry_gaps = gaps(carry_bays);
drum_gap   = drum_pitch - drum_w;
spacer_set = concat(click_gaps, carry_gaps, [drum_gap, drum_gap, drum_gap]);

module spacers() {
    raft = 0.6;
    for (i = [0 : len(spacer_set) - 1])
        translate([i * 11, 0, 0]) {
            difference() {
                cylinder(d = drum_bore + 4.6, h = spacer_set[i]);
                translate([0, 0, -fudge]) cylinder(d = bore_run, h = spacer_set[i] + 2 * fudge);
            }
            // break-away raft tab linking this tube to the next
            if (i < len(spacer_set) - 1)
                translate([0, -1, 0]) cube([11, 2, raft]);
        }
}

// === DRUM ===
// Printed axis-vertical: digit facets are vertical walls (crisp text), teeth print in-plane.
// Local +Z maps to +X in use, so the LUG is at low z and the RATCHET at high z.
module drum() {
    af = drum_af / 2;
    difference() {
        union() {
            linear_extrude(height = lug_w)
                union() {
                    circle(r = 8);
                    polygon([[0, -3.2], [lug_r, -2.2], [lug_r, 2.2], [0, 3.2]]);
                }
            translate([0, 0, lug_w]) linear_extrude(height = digit_band)
                circle(r = af / cos(180 / ratchet_teeth), $fn = ratchet_teeth);
            translate([0, 0, lug_w + digit_band]) linear_extrude(height = ratchet_w)
                ratchet_2d(ratchet_r, ratchet_teeth, tooth_depth);
            cylinder(d = drum_bore + 2 * drum_wall + 1.6, h = drum_w);
        }
        // hollow the digit band, leaving the counterweight sector solid
        translate([0, 0, lug_w + drum_wall])
            difference() {
                cylinder(r = af - drum_wall, h = digit_band - 2 * drum_wall);
                translate([0, 0, -fudge])
                    cylinder(d = drum_bore + 2 * drum_wall + 1.6 + 2 * fudge,
                             h = digit_band + 2 * fudge);
                // Sector left SOLID: it is the counterweight that makes the drum hang at
                // digit 0 when the reset button lifts the clicks. Local +X maps to world -Z
                // once mounted, so a sector centred on local 0 hangs straight down.
                translate([0, 0, -fudge]) linear_extrude(height = digit_band + 2 * fudge)
                    pie(af - 1.2, cw_sector);
            }
        translate([0, 0, -fudge]) cylinder(d = drum_bore, h = drum_w + 2 * fudge);
        // engraved digits: one per facet, height circumferential, width axial
        // Digit 0 sits at local -90 deg, which faces the window (world -Y) when the
        // counterweight hangs down. Order follows drum_fwd so the display counts UP.
        for (i = [0 : ratchet_teeth - 1])
            rotate(-90 - drum_fwd * i * (360 / ratchet_teeth))
                translate([af + fudge, 0, lug_w + digit_band / 2])
                    rotate([0, -90, 0]) linear_extrude(height = digit_depth + 2 * fudge)
                        // mirror() is NOT decoration -- it is load-bearing. The composed chain
                        // Ry(90)*Rz(-90-i*36)*Ry(-90) sends the glyph's width to +X (the
                        // viewer's right, correct) but its UP to -Z, i.e. every digit comes out
                        // vertically flipped once the drum is mounted: 6 reads as 9, and 2/5/7
                        // are unreadable. One axis is inverted, not both, so it is a mirror and
                        // rotating the text 180 deg does NOT fix it. Verified by composing the
                        // matrices: as-shipped up->-Z, with this mirror up->+Z.
                        mirror([0, 1, 0])
                            text(str(i), size = digit_h, font = digit_font,
                                 halign = "center", valign = "center");
    }
}

// === LEVERS ===
// All three lever types share one pattern: a bore at the pivot, a working nose, and a gravity
// mass boss on the tail. There are no springs anywhere in the register.

// Detent. The mass boss sits on the arm, offset to the side AWAY from the wheel so it clears
// the ratchet; its weight is what preloads the nose into the teeth. Keep it light -- this is
// the single largest load on the tip energy budget (see click_torque).
module click(mass_r = click_mass_r) {
    linear_extrude(height = lever_thick)
        difference() {
            union() {
                lever_blank(click_len, 8, 5.4);
                hull() {
                    translate([click_len * 0.34, 0]) circle(d = 6.5);
                    translate([click_len * 0.66, -click_hand * (mass_r + 1.4)])
                        circle(r = mass_r);
                }
                // hook: leans in past the tooth tips so it can seat in a root
                hull() {
                    translate([click_len, 0]) circle(d = 5.4);
                    translate([click_len - 1.2, click_hand * (hook_depth + 0.9)]) circle(d = 3.2);
                }
            }
            circle(d = bore_run);
        }
}

// Reusable driving nose: a hook whose leading face pushes the tooth's radial drive face.
module pawl_nose_2d(len) {
    union() {
        lever_blank(len, 9, 5.4);
        hull() {
            translate([len, 0]) circle(d = 5.4);
            translate([len - 1.3, -drum_fwd * (hook_depth + 0.9)]) circle(d = 3.2);
        }
    }
}

// Carry lever: drum N's lug pushes the follower, and the nose advances drum N-1 by one tooth.
// Follower and nose are on the SAME radial arm at almost the same radius but in different
// drum planes, so the follower rides on a pad stepped over by carry_step.
module carry_lever() {
    union() {
        linear_extrude(height = lever_thick)
            difference() {
                union() {
                    pawl_nose_2d(carry_nose);
                    // gravity return mass, behind the pivot
                    hull() { circle(d = 9); rotate(168) translate([11, 0]) circle(r = 4.4); }
                }
                circle(d = bore_run);
            }
        // follower pad, stepped over into the lug's plane
        translate([0, 0, lever_thick - fudge]) linear_extrude(height = carry_step - 0.8)
            difference() {
                hull() { circle(d = 9); translate([carry_foll, 0]) circle(d = 8); }
                circle(d = bore_run);
                // relief so the lug cams the follower out at the end of its stroke, and can
                // also pass backwards freely while the register is being zeroed
                translate([carry_foll - 1.0, drum_fwd * 1.2]) rotate(drum_fwd * 32)
                    square([10, 10]);
            }
    }
}

module drive_pawl() {
    linear_extrude(height = lever_thick + 0.8)
        difference() {
            union() {
                lever_blank(pawl_tail, 9, 9);
                translate([pawl_tail, 0]) circle(d = 13);         // cam follower pad
                rotate(pawl_inner) pawl_nose_2d(pawl_nose);
                // gravity return: it must beat the nose's own ratcheting friction
                hull() { circle(d = 9); rotate(pawl_inner + 172) translate([11, 0]) circle(r = 5.2); }
            }
            circle(d = bore_run);
        }
}

// One bar lifts all four clicks at once. The actuating arm the button pushes is INTEGRAL to
// the bar rather than a separate lever: the bar has to span the whole shaft anyway, which
// leaves nowhere for a separate lever to sit, and merging them removes an assembly ambiguity.
// A counterweight tail plus the four clicks' own weight returns it when the button releases.
// Lifter yoke: cradles the click shaft from below and raises it on a reset. It is located by
// the shaft it carries, so it needs no separate guides. Its front-bottom edge is chamfered
// 45 deg; the button's flat face bears on that chamfer, and because the shaft can only move
// vertically in its slot the rearward push turns into pure lift. Printed flat as modelled.
// LOCAL FRAME: origin on the cross bar's centre, bottom, mid-depth.
yoke_sy = click_pos[0] - yoke_y;      // shaft position in the yoke's own frame
yoke_sz = click_pos[1] - yoke_z;
yoke_ramp = 5;
module lifter() {
    cr = bore_run / 2;
    difference() {
        union() {
            // cross bar spanning the cassette, with the actuating chamfer on its front edge
            translate([-yoke_arm_x, -4, 0]) cube([2 * yoke_arm_x, 8, 7]);
            // cradle arms reaching back and up to the shaft
            for (sx = [-1, 1])
                translate([sx * yoke_arm_x - (sx > 0 ? 7 : 0), -4, 0])
                    cube([7, yoke_sy + 4 + 4, yoke_sz + 5]);
        }
        // shaft cradles, open upward so the yoke drops away if the shaft is removed
        for (sx = [-1, 1])
            translate([sx * yoke_arm_x, yoke_sy, yoke_sz]) {
                rotate([0, 90, 0]) cylinder(r = cr, h = 30, center = true);
                translate([-15, -cr, 0]) cube([30, 2 * cr, 20]);
            }
        // 45 deg actuating chamfer along the front-bottom edge
        translate([-yoke_arm_x - 1, -4, 0]) rotate([-45, 0, 0])
            translate([0, -yoke_ramp * 1.5, 0]) cube([2 * yoke_arm_x + 2, yoke_ramp * 1.5, yoke_ramp * 1.5]);
        // lighten the cross bar between the arms
        for (i = [-1, 0, 1])
            translate([i * 22 - 5, -5, 2.4]) cube([10, 10, 8]);
    }
}

// Plunger. Flat face: it bears on the lifter's 45 deg chamfer. Length follows the computed
// yoke position, so it always just reaches. Gravity on the shaft, clicks and yoke pushes it
// back out again -- there is no return spring anywhere in the gauge.
module reset_button() {
    union() {
        cylinder(d = 8 - tolerance, h = button_len + 4);
        cylinder(d = 14, h = 3);
    }
}

// === BEZEL ===
module bezel() {
    difference() {
        union() {
            translate([0, 1.2, 0]) cube([window_w + 12, 2.4, window_h + 12], center = true);
            translate([0, -0.6, 0]) cube([window_w + 6, 1.2, window_h + 6], center = true);
        }
        for (i = [0 : drum_count - 1])
            translate([drum_cx(i), 0, 0])
                cube([digit_band + 1.5, 12, window_h + 0.5], center = true);
    }
}

// Fit-test coupon. Print this before anything else.
// LADDER (numbered row): each hole is the press bore that hole_comp = that/100 would produce.
//   Find the SMALLEST hole the rod enters with a firm push and will not rotate in -- its label
//   IS your hole_comp. This is self-calibrating, so it works on any printer and any material
//   without you having to judge an absolute size.
// NAMED (P/B/R): the three fits at the hole_comp currently set, to confirm the answer.
//   P = firm push, no rotation.  B = turns freely, no rock.  R = turns with obvious slop.
// Two minutes of printing saves discovering a seized register after four drums and 11 spacers.
fit_ladder = [0.22, 0.26, 0.30, 0.34, 0.38, 0.42];   // 0.04 steps, bracketing the measured 0.30
module fit_test() {
    n = len(fit_ladder);
    pitch = 12; w = (n + 3) * pitch + 8; d = 30; t = 6;
    labels = ["P", "B", "R"];
    bores  = [bore_press, bore_bear, bore_run];
    difference() {
        translate([-w / 2, -d / 2, 0]) cube([w, d, t]);
        // Row 1: the LADDER. Each hole is the press bore that a given hole_comp would give.
        // The smallest one the rod enters with a firm push IS your hole_comp.
        for (i = [0 : n - 1])
            translate([-w / 2 + 4 + (i + 0.5) * pitch, 5, 0]) {
                translate([0, 0, -fudge])
                    cylinder(d = rod_d + fit_ladder[i] + fit_press, h = t + 2 * fudge);
                translate([0, -9, t - 0.8]) linear_extrude(height = 1.0)
                    text(str(fit_ladder[i] * 100), size = 4.6, font = digit_font,
                         halign = "center", valign = "center");
            }
        // Row 2: the three named fits at the CURRENT hole_comp, to confirm the result.
        for (i = [0 : 2])
            translate([w / 2 - 4 - (2.5 - i) * pitch, 5, 0]) {
                translate([0, 0, -fudge]) cylinder(d = bores[i], h = t + 2 * fudge);
                translate([0, -9, t - 0.8]) linear_extrude(height = 1.0)
                    text(labels[i], size = 6, font = digit_font,
                         halign = "center", valign = "center");
            }
    }
}

// === POST MOUNT ===
module post_mount() {
    h = 62;
    difference() {
        union() {
            translate([0, 0, h / 2]) cube([post_d + 20, 10, h], center = true);
            translate([0, -post_d / 2 - 4, 0]) ring((post_d + 13) / 2, post_d / 2 + tolerance, h);
        }
        translate([0, -post_d / 2 - 4, -fudge])
            cylinder(d = post_d + 2 * tolerance, h = h + 2 * fudge);
        translate([-4.5, -post_d - 18, -fudge]) cube([9, 16, h + 2 * fudge]);
        for (z = [h / 2 - 24, h / 2 + 24])
            translate([0, 0, z]) rotate([90, 0, 0]) cylinder(d = 3.4, h = 40, center = true);
        for (z = [h / 2 - 16, h / 2 + 16])
            translate([0, -post_d - 9, z]) rotate([0, 90, 0])
                cylinder(d = 3.4, h = 40, center = true);
    }
}

// === ASSEMBLY ===

module register_mech() {
    translate([0, drum_y, drum_z]) {
        for (i = [0 : drum_count - 1])
            translate([drum_cx(i) - drum_w / 2, 0, 0]) rotate([0, 90, 0])
                color(i == units_i ? "#ffdd99" : "#eeeeee") drum();
        if (show_hardware)
            color("silver") translate([-cass_x / 2 - 2, 0, 0]) rotate([0, 90, 0])
                cylinder(d = rod_d, h = cass_x + 4);
        for (i = [0 : drum_count - 1])
            translate([ratchet_cx(i) - lever_thick / 2, click_pos[0], click_pos[1]])
                rotate([0, 90, 0]) rotate([0, 0, click_mt])
                    color(i == units_i ? "#cc8866" : "#ddaa88")
                        click(i == units_i ? click_mass_r : click_mass_r_light);
        for (i = [0 : drum_count - 2])
            translate([ratchet_cx(i) - lever_thick / 2, carry_pos[0], carry_pos[1]])
                rotate([0, 90, 0]) rotate([0, 0, carry_mt]) color("#88bb88") carry_lever();
        translate([cam_cx - (lever_thick + 0.8) / 2, carry_pos[0], carry_pos[1]])
            rotate([0, 90, 0]) rotate([0, 0, pawl_mt]) color("#dd6666") drive_pawl();
        translate([0, yoke_y, yoke_z]) color("#9999cc") lifter();
        // axial spacers keeping each lever in its plane
        if (show_hardware) color("#dddddd", 0.5) {
            for (i = [0 : len(click_bays) - 1])
                translate([click_bays[i][1], click_pos[0], click_pos[1]]) rotate([0, 90, 0])
                    difference() {
                        cylinder(d = drum_bore + 4.6, h = click_gaps[i + 1]);
                        translate([0, 0, -fudge])
                            cylinder(d = bore_run, h = click_gaps[i + 1] + 2 * fudge);
                    }
            for (i = [0 : drum_count - 2])
                translate([drum_cx(i) + drum_w / 2, 0, 0]) rotate([0, 90, 0])
                    difference() {
                        cylinder(d = drum_bore + 4.6, h = drum_gap);
                        translate([0, 0, -fudge])
                            cylinder(d = bore_run, h = drum_gap + 2 * fudge);
                    }
        }
    }
}

module assembly() {
    color("#dddddd", 0.92) body();
    translate([0, 0, body_h - skirt_rebate]) color("#e8e8e8", 0.92) funnel();
    translate([0, 0, pivot_gz]) rotate([bucket_tilt, 0, 0]) translate([0, 0, -pivot_z])
        color("#ffcc66") bucket_core();
    if (show_hardware) {
        color("silver") translate([-web_x - 6, 0, pivot_gz]) rotate([0, 90, 0])
            cylinder(d = rod_d, h = 2 * web_x + 12);
        for (s = [-1, 1]) translate([s * web_x, 0, pivot_gz + 5]) color("#bbbbbb") pivot_strap();
    }
    translate([cam_cx - cam_w / 2, 0, pivot_gz]) rotate([0, 90, 0])
        rotate([0, 0, cam_mount + bucket_tilt]) color("#ff9944") drive_cam();
    translate([0, drum_y, drum_z]) color("#88aacc", 0.30) cassette();
    translate([0, drum_y, drum_z + c_top]) color("#88aacc", 0.30) cassette_lid();
    register_mech();
    translate([0, boss_in_y - 1.2, drum_z]) color("#333333") bezel();
    translate([0, boss_face_y - 3, button_gz]) rotate([-90, 0, 0])
        color("#cc3333") reset_button();
    // the pole itself, for context: it enters coaxially and bottoms on the socket shoulder
    if (show_hardware)
        color("#8899aa") translate([0, 0, pole_top_z]) mirror([0, 0, 1])
            cylinder(d = pole_d, h = 150);
    // OPTIONAL alternative mount: side clamp for an existing post or fence rail
    %translate([0, body_ir + 4, body_h * 0.42 - 31]) post_mount();
}

// === RENDER ===
if (part == "assembly") assembly();
else if (part == "assembly_cut")
    difference() { assembly(); translate([-260, -300, -20]) cube([260, 600, 400]); }
else if (part == "mech") {
    register_mech();
    translate([cam_cx - cam_w / 2, 0, pivot_gz]) rotate([0, 90, 0])
        rotate([0, 0, cam_mount + bucket_tilt]) drive_cam();
}
else if (part == "funnel")       funnel();
else if (part == "body")         body();
else if (part == "bucket")       bucket();
else if (part == "cassette")     translate([0, 0, -c_bot + cassette_wall]) cassette();
else if (part == "cassette_lid") translate([0, 0, cassette_wall / 2]) cassette_lid();
else if (part == "drum")         drum();
else if (part == "click")        click();
else if (part == "click_light")  click(click_mass_r_light);
else if (part == "carry_lever")  carry_lever();
else if (part == "drive_pawl")   drive_pawl();
else if (part == "drive_cam")    drive_cam();
else if (part == "reset_button") reset_button();
else if (part == "lifter")       lifter();
else if (part == "spacers")      spacers();
else if (part == "pivot_strap")  translate([0, 0, 5.4]) pivot_strap();
else if (part == "bezel")        translate([0, 0, 2.4]) rotate([-90, 0, 0]) bezel();
else if (part == "post_mount")   post_mount();
else if (part == "fit_test")     fit_test();
else if (part == "plate") {
    // Print job 1: everything sharing 0.20mm / 4 walls / 20% infill. Positions were packed
    // with a >=5mm gap and checked for clashes against each part's real bounding box; the
    // big shells (funnel, body, cassette) print one at a time.
    translate([-85.7, -78.1, 0]) bucket();
    translate([-17.4, -84.5, cassette_wall / 2]) cassette_lid();
    translate([ 57.6, -63.0, 0]) post_mount();
    translate([ 94.6, -90.0, 5.4]) pivot_strap();
    translate([-99.0, -13.2, 5.4]) pivot_strap();
    translate([-43.0, -16.2, 2.4]) rotate([-90, 0, 0]) bezel();
    translate([ 43.0, -24.2, 0]) lifter();
    translate([ 91.0, -21.2, 0]) reset_button();
    translate([-101.0, 10.8, 0]) spacers();
    translate([-40, 40, 0]) fit_test();
}
else if (part == "plate_fine") {
    // Print job 2: 0.12mm layers for the fine ratchet teeth and engraved digits.
    for (i = [0 : 3]) translate([-88.2 + i * 38.65, -89.0, 0]) drum();
    translate([-101.0, -62.9, 0]) click();                                  // units (heavy boss)
    for (i = [1 : 3]) translate([-101.0 + i * 32.9, -62.9, 0]) click(click_mass_r_light);
    for (i = [0 : 2]) translate([-89.8 + i * 39.85, -41.4, 0]) carry_lever();
    translate([ 58.2, -96.4, 0]) drive_cam();
    translate([ 46.2, -60.4, 0]) drive_pawl();
}
else assert(false, str("unknown part: ", part));
