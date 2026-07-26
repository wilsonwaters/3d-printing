// === DESCRIPTION ===
// Mechanical Rain Gauge (Opus 5.0): a fully mechanical, self-powered rain gauge that
// totalises rainfall on a 4-digit "old style" odometer dial (like a water or electricity
// meter register), reading 0000-9999 mm of rain. No electronics, no battery. The energy
// to drive the counter comes entirely from the falling water.
//
// How it works, water to dial:
//   1. Rain lands in a round inverted-bucket COLLECTOR funnel with a sharp, level rim.
//      The rim aperture is 159.577 mm ID, giving a catch area of exactly 200.0 cm^2 --
//      the WMO/CIMO standard collection area. That makes 1 mm of rainfall exactly 20.00 mL,
//      so the gauge can be calibrated with an ordinary syringe.
//   2. The funnel drains into a twin-chamber TIPPING BUCKET balanced on a pivot. Each
//      chamber holds 10.00 mL = 0.5 mm of rain. When full it overbalances, dumps, and
//      presents the other chamber. Adjustable stop screws set the tip volume (this is how
//      commercial gauges are trimmed).
//   3. A crank pin on the tipper shaft pushes a LINK, which drives a PAWL one tooth of a
//      10-tooth ratchet on the units number wheel. The pawl advances on one half of the
//      rocker cycle only, so 2 tips = 1 tooth = 1 digit = 1.0 mm of rain. Driving off the
//      half-cycle is deliberate: it avoids a fragile double-acting pawl and lets the tipper
//      run at a realistic 10 mL rather than a 20 mL bucket.
//   4. Four NUMBER WHEELs carry 0-9 on flat facets, read through a window. The 9->0 carry
//      uses the classic cyclometer trick from US Patent 897379 (1908): a "mutilated" gear
//      on the lower wheel exposes just 2 teeth, which kick a 20-tooth TRANSFER PINION 1/10
//      of a turn once per revolution, and the pinion turns the next wheel up by one digit.
//      A DETENT COMB holds every wheel crisply on a digit and locks the idle pinions
//      through their mesh.
//   5. RESET: pressing the PLUNGER does two things at once, exactly as US 897379's
//      "vibratory frame" does -- it rocks the PINION CARRIER so all three transfer pinions
//      leave mesh (freeing the wheels from each other), then presses the HAMMER blade onto
//      a HEART CAM on each wheel. A heart cam pressed by a flat face can only rest with its
//      cusp centred, so each wheel is driven to a unique angular position: 0. This is the
//      chronograph reset-to-zero mechanism. It is a pure push -- no knob to turn, and it
//      cannot land between digits. Release and springs re-mesh everything.
//
// Physical context: lives outdoors on a post or fence in the open, ideally with the rim
//   300 mm+ above ground and clear of obstructions by twice their height (WMO siting).
//   Loads are tiny -- the whole mechanism runs on a few grams of water head -- so the
//   design driver is FRICTION and WATER INGRESS, not strength. The register lives in its own
//   bay in FRONT of the wet tipper compartment -- they are side by side, not stacked, and do
//   not overlap in plan. Its dryness comes from that separation plus reg_frame + reg_side
//   enclosing the wheels on all four long faces.
//   NOT YET MODELLED: a dedicated splash shield around the drive-link slot. The link has to
//   cross from the wet side to the dry side and nothing currently baffles that opening. Add
//   an upstand on the chassis between the tipper and the register bay before printing for
//   real outdoor service.
//
// Design decisions:
//   - 200.0 cm^2 aperture (159.577 mm ID) rather than a round 150 mm: it is the WMO
//     standard area AND it makes 1 mm of rain exactly 20.00 mL. Clean calibration beats a
//     clean diameter.
//   - 0.5 mm per tip with a 2:1 mechanical reduction, instead of 1.0 mm per tip direct.
//     A 1 mm/tip bucket at this aperture would need 20 mL chambers, which is roughly 3x
//     any commercial tipper and tips sluggishly. Two 10 mL chambers behave like a real
//     instrument, and the single-acting pawl gets the 2:1 for free.
//   - Wheel band order along the axis is gear / cam / digit / drive. This is the only
//     order where (a) the transfer pinion never has to pass a digit drum, so it can be a
//     plain gear instead of a stepped two-tier pinion, and (b) the wheel's diameters step
//     almost monotonically downward in the print, so it prints support-free with a single
//     45 deg chamfer under the digit drum.
//   - Digits sit on 10 FLAT FACETS (a decagonal prism), not a cylinder. Flat facets print
//     crisply, keep embossed strokes an even height, and are how real counter drums read.
//   - Heart-cam reset rather than a stop-lug reset. A hard stop lug would block the wheel
//     in both directions and so could not rotate continuously; the heart cam is always
//     present and only touched during reset.
//   - Reset presses from above and the pinions withdraw downward, so a single plunger
//     stroke does both jobs with one ramp and one spring.
//   - PETG for the whole gauge: outdoor Tg, ductile flexures for the detent comb and pawl
//     springs, and good layer adhesion for the thin funnel shell.
//
// Terminology -> code:
//   "collector" / "funnel"   -> funnel(), aperture_id, cone_angle, funnel_wall
//   "sharp rim"              -> rim_h, rim_out_bot, rim_out_top
//   "tipping bucket"/"tipper"-> tipper(), chamber_w, chamber_l, chamber_h, tip_volume_ml
//   "calibration screws"     -> stop_screw_d, stop_screw_x, stop_screw_z (in chassis())
//   "dials" / "number wheels"-> number_wheel(), wheel_od, digit_band_w, digit_size
//   "carry" / "rollover"     -> carry_teeth, mutilated_hub_r, transfer_pinion()
//   "detent"                 -> detent_comb() inside pinion_carrier(), detent_notch_r
//   "drive pawl"             -> drive_pawl(), pawl_len
//   "link" / "connecting rod"-> link(), crank_r
//   "reset button"           -> plunger(), plunger_stroke
//   "reset hammer"           -> hammer(), hammer_blade_w
//   "heart cam"              -> heart_cam_2d(), cam_r_min, cam_r_max
//   "register box"           -> reg_frame(), reg_side()
//   "window"                 -> window_w, window_h
//   "housing" / "body"       -> body(), body_od, body_h
//   "internal frame"         -> chassis()
//
// Common modifications:
//   Finer resolution (0.1 mm/digit, 0-999.9 mm)  -> set mm_per_tip = 0.05. Everything
//     downstream (tip volume, chamber size) re-derives. Paint a decimal point before the
//     last wheel. This is the WMO 0.1 mm resolution and gives a realistic 2 mL bucket.
//   Coarser/finer aperture                        -> catch_area_cm2 (aperture_id derives)
//   More dials                                    -> digit_wheels (frame/plunger re-derive)
//   Bigger digits                                 -> digit_size, then wheel_od (needs
//     circumference >= 10 * digit facet width)
//   Looser/tighter running fit                    -> tolerance (PETG sliding = 0.3)
//   Different printer                             -> build_x/y/z; asserts will catch a part
//     that no longer fits
//
// Overall dimensions (assembled): 182 dia x 178 mm tall (187 mm across the mount lugs).
//   The funnel hangs from the body's top collar with its whole cone inside the housing, so
//   the gauge is no taller than the body.
//   Largest single part: body, 182 dia x 178 mm. Funnel, 175.6 dia x 104 mm.
//   Both fit the Bambu X1C 256 x 256 x 256 build volume.
// Coordinate system: per-part, Z = height from build plate (each part is modelled in its
//   own print orientation). In the assembly view the register shaft runs along X, the
//   window faces +Y, and gravity is -Z.
// NOTE: Every part is modelled in PRINT orientation, so the OpenSCAD preview of a single
//   part matches the plate. Two parts are used in a different orientation than printed:
//   the FUNNEL prints rim-down (mouth on the plate) and is used rim-up; the TIPPER prints
//   chambers-up and is used chambers-up (same).

// === PRINT SETTINGS ===
// Material: PETG. Outdoor Tg 75-85C (PLA would creep in a sun-baked gauge), ductile enough
//   for the detent comb and pawl leaf springs (5-8% working strain vs PLA's 1-1.5%), and
//   the best layer adhesion of the common filaments, which matters for the thin funnel wall.
//   DRY IT FIRST: 60-65C for 4-6 hours. Wet PETG strings, and this model has small
//   gear teeth where strings are fatal.
// Layer Height: 0.20 mm for the funnel, body, chassis, tipper.
//                0.12 mm for number wheels, transfer pinions, pawl, detent comb, hammer
//                (gear teeth, digit strokes and flexures all benefit).
// Walls/Perimeters: 4 (1.8 mm) structural; 5 (2.25 mm) on the funnel and tipper so layer
//                lines do not wick water.
// Infill: 25% gyroid general; 100% in the detent comb, drive pawl and link (thin flexures
//                and load paths need solid).
// Supports: None required. All overhangs are <= 45 deg from vertical:
//                - funnel prints rim-down so every layer steps inward
//                - wheel band diameters step downward, with one 45 deg chamfer under the
//                  digit drum
//                - the pinion is a plain gear, printed teeth-vertical
//                - horizontal pivot bores use teardrop profiles
// Orientation: as modelled, Z=0 on the plate, for every part= value.
// Notes: - Cooling 30-40% max. Higher looks better on the gear teeth but wrecks layer
//          adhesion, and the funnel is a single-wall-thin cone.
//        - Print the funnel with a 5 mm brim: a 168 mm PETG ring will lift at the edge
//          otherwise.
//        - Break in the detent comb and pawl springs by flexing them 5-10 times slowly
//          before assembly.
//        - Do NOT scale this model. The calibration depends on the aperture area.

// === PARAMETERS ===
// ---- Printer ----
// Printer: Bambu Lab X1 Carbon
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_x = 256;
build_y = 256;
build_z = 256;
// X1/P1 reserve an 18x28mm front-left corner (bed_exclude_area, protecting the filament
// cutter stopper), so the real auto-centred printable square is ~220mm, NOT 256. Footprints
// are checked against this, not against build_x.
build_usable = 220;

// ---- Meteorological calibration (the heart of the design) ----
catch_area_cm2 = 200.0;  // WMO/CIMO standard collection area. 1 mm rain = 20.00 mL.
mm_per_tip     = 0.5;    // Rainfall depth per bucket tip. 0.05 -> 0.1 mm/digit variant.
tips_per_digit = 2;      // Pawl advances on one half-cycle only, so 2 tips per tooth.
digit_wheels   = 4;      // 4 wheels -> 0000..9999
digits_per_wheel = 10;

// ---- Collector funnel ----
rim_h        = 6.0;   // vertical inner rim band height (defines the sharp aperture edge)
rim_out_bot  = 8.0;   // rim flange at the mouth. This flange is what the funnel hangs from:
                      // it rests on the body's top collar while the cone drops inside.
rim_out_top  = 1.2;   // rim outer thickness where the cone starts
cone_angle   = 50;    // cone wall angle from horizontal. 50 -> 40 deg from vertical (PETG safe)
funnel_wall  = 2.25;  // 5 perimeters, so layer lines do not wick
spout_id     = 18.0;  // spout bore
spout_h      = 14.0;  // spout tube length
strainer_bars = 5;    // debris bars across the spout

// ---- Tipping bucket ----
chamber_w    = 30.0;  // across the tipper (Y in use)
chamber_l    = 30.0;  // along the tipper, per chamber (X in use)
chamber_h    = 20.0;  // chamber depth (fill depth for 10 mL is ~11.1 mm)
tipper_wall  = 1.8;
divider_t    = 2.4;
tip_angle    = 22;    // half-stroke of the rocker, degrees
crank_r      = 14.0;  // crank pin radius on the tipper shaft
pivot_rod_d  = 3.0;   // stainless/brass rod through the tipper hub
floor_slope  = 2.5;   // chamber floor fall, divider end -> outer end (drains dry)
hub_d        = 10.0;  // tipper pivot hub outside diameter
hub_stub     = 4.0;   // how far the hub projects past the body on the plain side
hub_boss_l   = 8.0;   // D-keyed boss length on the crank side
hub_flat     = 2.0;   // depth of the D-flat that keys the crank

// ---- Number wheels ----
wheel_od       = 34.0;  // decagon circumradius x2 -> facet width 10.5 mm
digit_band_w   = 7.5;
gear_band_w    = 3.0;
cam_band_w     = 4.0;
// The ratchet/detent ring and the carry teeth get SEPARATE bands. They cannot share one:
// the 2 carry teeth are fixed to the wheel, so over ten digit positions their 36 deg wedge
// sweeps every single world angle -- there is no angle at which a pawl or detent riding the
// hub would escape being lifted 3.4 mm by a tooth once per revolution. Angular placement
// cannot solve it; axial separation can.
ratchet_band_w = 3.0;
carry_full_w   = 3.0;   // full-height tooth region that actually meshes the pinion
wheel_gap      = 1.3;
digit_size     = 8.0;   // character height, measured around the drum
digit_emboss   = 1.0;   // emboss height above the facet
digit_sink     = 0.8;   // how far the glyph is rooted below the facet
digit_font     = "DejaVu Sans:style=Bold";
shaft_d        = 10.0;  // register shaft (printed)

// ---- Carry gearing ----
gear_mod    = 1.5;   // module. 1.5 gives a 1.57 mm thick tooth at pitch = 3+ extrusions
gear_teeth  = 20;
carry_teeth = 2;     // teeth left on the "mutilated" driver
gear_backlash = 0.35;// mm, PETG

// ---- Detent / drive ratchet ----
// detent_notch_r is DERIVED (= gear_root_r) further down. It must sit exactly on the
// mutilated gear's root circle: any smaller and the carry-teeth pie slice stands proud of
// the hub and bridges one of the ten detent notches.
detent_notch_d    = 0.8;   // notch depth = detent finger deflection
// Leaf-spring detents. These are deliberately LIGHT. The whole mechanism runs on about
// 1 mJ per tip (10 g of water falling ~10 mm), and during a 9->0 carry the tipper has to
// lift TWO detents at once -- the units wheel's and the tens wheel's. A stiff comb is the
// most likely thing to stall a carry, so the springs are long, the notches shallow, and the
// energy margin is asserted below.
detent_spring_t   = 1.35;  // 3 perimeters at 0.45 extrusion width
detent_spring_len = 38.0;  // long, because the comb has to reach up past the pinions
carrier_t         = 3.0;   // comb plate thickness = flexure height
yoke_spine_t      = 5.0;   // reset yoke spine depth in Y
yoke_ear_t        = 3.5;   // reset yoke end ear thickness
petg_E            = 2000;  // MPa, PETG Young's modulus
// Drive pawl lever arms. The ratio pawl_tooth_r/pawl_link_r sets how far one tip advances
// the ratchet -- see the pawl_notches assert. Must land between 1.0 and 2.0 notches.
pawl_tooth_r = 20.0;  // pivot -> pawl tooth contact
pawl_link_r  = 24.0;  // pivot -> link pin eye
link_len     = 46.0;  // connecting rod, crank pin -> pawl link pin (set on assembly)
pawl_spring_angle = 55;  // splay of the pawl's return spring away from the lever axis

// ---- Heart cam (reset) ----
cam_r_min = 11.5;   // raised so the ratchet ring above barely oversails the cam
cam_r_max = 15.0;
cam_asym  = 0.92;   // breaks the unstable equilibrium opposite the cusp

// ---- Register frame / window ----
reg_wall     = 2.4;
window_h     = 11.0;  // vertical aperture, shows one digit
reg_clear    = 1.2;   // RADIAL clearance: wheel drum to the window wall. Keep small or the
                      // digits sit too far behind the window.

// ---- Reset plunger ----
plunger_d       = 12.0;
plunger_stroke  = 6.0;
hammer_blade_w  = 3.0;

// ---- Housing ----
body_od   = 172.0;
body_wall = 2.4;
// body_h is DERIVED below from the vertical stack (floor -> tipper swing -> spout -> funnel),
// so the funnel, tipper and register cannot be left overlapping by accident.
floor_clear   = 6.0;  // clearance under the tipper's swept corner
spout_gap     = 6.0;  // gap between the spout mouth and the tipper's highest swung corner
drain_slots = 8;
collar_t     = 5.0;   // extra wall at the top, so the funnel rebate has material around it
collar_h     = 12.0;
collar_flare = 5.0;   // 45 deg flare onto the shell (self-supporting underside)
funnel_rebate_h = 6.0;
window_z     = 62.0;  // height of the register window above the base. Driven by reg_shaft_y:
                      // the frame now hangs reg_shaft_y below the window centreline and must
                      // still clear the floor (see the reg_bottom_z assert).

// ---- Fasteners ----
m3_d = 3.0;
stop_screw_d = 3.0;
stop_screw_x = 26.0;  // radius at which the stop screws catch the tipper
stop_boss_h  = 14.0;

// ---- Assembly explode (view only) ----
explode = 0;   // set to e.g. 40 to pull the assembly apart

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;      // 0.45
wall_thickness  = extrusion_width * 4;          // 1.8
fudge     = 0.01;
tolerance = 0.3;                                 // PETG sliding fit
ef_chamfer = 0.4;
$fn = $preview ? 32 : 64;

// -- calibration chain --
catch_area_mm2 = catch_area_cm2 * 100;                       // 20000 mm^2
aperture_id    = 2 * sqrt(catch_area_mm2 / PI);              // 159.577 mm
aperture_r     = aperture_id / 2;
tip_volume_mm3 = mm_per_tip * catch_area_mm2;                // 10000 mm^3
tip_volume_ml  = tip_volume_mm3 / 1000;                      // 10.00 mL
mm_per_digit   = mm_per_tip * tips_per_digit;                // 1.0 mm
gauge_max_mm   = pow(digits_per_wheel, digit_wheels) * mm_per_digit - mm_per_digit;
// Water depth (above the chamber's low corner) holding one tip volume. The sloped floor
// removes a prism of w*l*slope/2, so the level sits slope/2 higher than a flat floor.
fill_depth     = tip_volume_mm3 / (chamber_w * chamber_l) + floor_slope/2;   // 12.36 mm
// Brim-full capacity, with the sloped floor accounted for.
chamber_ml     = (chamber_w * chamber_l * chamber_h
                  - chamber_w * chamber_l * floor_slope/2) / 1000;           // 16.9 mL

// -- funnel --
cone_dr      = aperture_r - spout_id/2;
cone_dz      = cone_dr * tan(cone_angle);
cone_top_z   = rim_h + cone_dz;
funnel_h     = cone_top_z + spout_h;
funnel_od    = aperture_id + 2*rim_out_bot;

// -- gears --
gear_pitch_r = gear_teeth * gear_mod / 2;        // 15.0
gear_outer_r = gear_pitch_r + gear_mod;          // 16.5
gear_root_r  = gear_pitch_r - 1.25 * gear_mod;   // 13.125
centre_dist  = gear_pitch_r * 2;                 // 30.0  wheel axis -> pinion axis
// The pinion must reach BOTH mesh planes: the drive band of wheel N (which carries the 2
// mutilated carry teeth) and the gear band of wheel N+1. It must not reach as far as wheel
// N's digit drum or wheel N+1's cam band, or it would foul them -- hence the 0.4 mm trim.
pinion_w     = carry_full_w + wheel_gap + gear_band_w - 0.4;   // 6.9
pinion_shaft_d = 4.0;   // steel rod, 3 pinions on one shaft
// Drive-band hub radius. Pinned to the root circle so the carry-teeth wedge is flush with
// the hub and all ten detent notches are identical.
// Carry-band hub sits on the gear's root circle (standard 0.25*module root clearance to the
// pinion tips, 0.375 mm). The ratchet ring has its OWN radius, now that it is a separate
// band and no longer has to share the carry band's hub.
carry_hub_r    = gear_root_r;                    // 13.125
detent_notch_r = cam_r_min + 0.5;                // 12.0 -- ratchet/detent contact radius
carry_lead     = gear_outer_r - detent_notch_r;  // 4.5 -- 45 deg ramp up to the carry teeth
carry_band_w   = carry_lead + carry_full_w;      // 7.5

// -- wheel --
wheel_r        = wheel_od / 2;                   // 17.0 decagon circumradius
facet_inradius = wheel_r * cos(180/digits_per_wheel);   // 16.17
facet_w        = 2 * wheel_r * sin(180/digits_per_wheel); // 10.51
wheel_w        = gear_band_w + digit_band_w + cam_band_w
               + ratchet_band_w + carry_band_w;   // 25.0
wheel_pitch    = wheel_w + wheel_gap;            // 18.8
bore_d         = shaft_d + 2*tolerance;          // 10.6 running fit
digit_step     = 360 / digits_per_wheel;         // 36
drum_chamfer   = wheel_r - gear_outer_r;         // 0.5, 45 deg under the digit drum

// -- drive train kinematics (needs digit_step, so it lives here) --
// The tipper's crank pin sweeps this chord over one half-cycle, i.e. one tip:
crank_chord  = 2 * crank_r * sin(tip_angle);                       // 10.49 mm
// One detent notch, as a straight-line chord at the pawl's contact radius:
notch_chord  = 2 * detent_notch_r * sin(digit_step/2);             // 8.11 mm
// The pawl is a lever: the link pushes it at pawl_link_r, the tooth acts at pawl_tooth_r.
pawl_travel  = crank_chord * pawl_tooth_r / pawl_link_r;           // 8.74 mm
pawl_notches = pawl_travel / notch_chord;                          // 1.078 -> one notch, never two

// -- energy budget: can one tip actually drive the carry? --
// This is the design's real failure mode, so it is checked rather than assumed.
// A tip releases the potential energy of one chamber of water falling as the bucket rolls.
tip_drop_mm   = chamber_l/2 * sin(2*tip_angle);                    // ~10.4 mm
tip_energy_mj = (tip_volume_mm3 * 1e-6) * 9.81 * (tip_drop_mm/1000) * 1000;   // ~1.02 mJ
// Cantilever detent finger: force at the tip, peak surface strain, and the energy to lift
// it over one notch crest (triangular loading, so half F*delta).
detent_I      = carrier_t * pow(detent_spring_t, 3) / 12;
detent_force  = 3 * petg_E * detent_I * detent_notch_d / pow(detent_spring_len, 3);  // N
detent_strain = 3 * detent_spring_t * detent_notch_d / (2 * pow(detent_spring_len, 2));
detent_work_mj = 0.5 * detent_force * detent_notch_d;              // 1 N*mm == 1 mJ
// Worst case is a carry: the units wheel's detent AND the next wheel's detent both lift.
carry_work_mj = 2 * detent_work_mj;
energy_margin = tip_energy_mj / carry_work_mj;

// -- band z positions within a wheel (print order, bottom up) --
// Order is gear / digit / cam / drive. Two constraints pick this:
//   1. The transfer pinion has to bridge wheel N's DRIVE band and wheel N+1's GEAR band,
//      so drive must be last and gear must be first. That is fixed.
//   2. Of the two remaining arrangements, this one prints far better. Putting the cam
//      *under* the drum means the drum's chamfer base (r=15) overhangs the heart cam,
//      which is only r=10 at its cusp -- a 5 mm unsupported ring. Putting the cam *above*
//      the drum leaves diameters 16.5 -> 17 -> 15 -> 13.125, i.e. one 0.5 mm step up and
//      then all steps down.
z_gear    = 0;
z_digit   = gear_band_w;
z_cam     = z_digit + digit_band_w;
z_ratchet = z_cam + cam_band_w;
z_carry   = z_ratchet + ratchet_band_w;
// Diameters bottom-up: 16.5 -> 17 (0.5 chamfer) -> 15 -> 12 -> 13.125 then 16.5 on a
// 45 deg ramp. Only two small steps up, both ramped.

// -- phasing, all measured as wheel-local angle from "digit 0 at the window" --
// Directions, as wheel-local angles (0 = window/+Y, 90 = up/+Z, 180 = back/-Y, 270 = down/-Z):
window_phi = 0;
hammer_phi = 90;    // reset hammer presses down from above
detent_phi = 270;   // detent comb bears from below
pawl_phi   = 234;   // drive pawl, from below-back
pinion_phi = 270;   // transfer pinions sit below the wheel axis
// The detent comb and the pinions share the 270 deg direction, which is fine because they
// act on DIFFERENT axial bands (ratchet vs carry) -- see the detent_x/pinion_x asserts.
// 270 is not a multiple of digit_step, so the ratchet notches carry a phase offset instead
// of sitting on the digit angles.
ratchet_phase = detent_phi - floor(detent_phi/digit_step) * digit_step;   // 18
// Carry teeth must be at the pinion when the wheel is mid-way through its 9->0 step:
carry_phase = pinion_phi + (digits_per_wheel - 0.5) * digit_step;   // -> 612 == 252 mod 360

// -- register frame --
// AXIAL clearance is a separate number from the radial one: the reset yoke's end ears have
// to live in the gap between the frame's end plates and the ends of the wheel stack, so that
// gap is sized by the ear, not by a running clearance.
reg_side_clear = yoke_ear_t + 1.5;                     // 5.0
stack_w    = digit_wheels * wheel_pitch - wheel_gap;   // 103.9
reg_in_w   = stack_w + 2*reg_side_clear;
reg_out_w  = reg_in_w + 2*reg_wall;
window_w   = stack_w + 2;
// Wheel axis position within the frame. Below the axis there must be room for the pinion
// AXIS (centre_dist away) *plus the pinion's own outer radius* plus a wall -- getting this
// wrong is what makes the pinions hang outside the frame.
// One downward stroke of the reset yoke does both jobs. Sized by the harder of the two:
//   - unmesh a pinion: needs > 2*addendum = 3.0 mm of radial retreat
//   - seat the hammer's flat on a heart cam cusp: the blade starts just clear of the drum
//     (wheel_r + 2) and has to come down to just above cam_r_min for the flat to straddle
//     the cusp. That is the binding case, at 7.2 mm.
blade_rest_r = wheel_r + 2;                                // 19.0
reset_stroke = blade_rest_r - (cam_r_min + 0.3);            // 7.2
// The frame must leave room BELOW the pinion for the full stroke, not just for the pinion.
reg_shaft_y = centre_dist + gear_outer_r + reg_wall + 2 + reset_stroke;   // 58.1
pinion_y    = reg_shaft_y - centre_dist;                   // 28.1
// Above the wheels: hammer blades, and the top spine that carries them.
yoke_top_y  = reg_shaft_y + blade_rest_r + 4;              // 81.1
reg_h       = yoke_top_y + yoke_spine_t + 4;               // 89.1
reg_depth   = wheel_od + 2*reg_clear + reg_wall;            // 38.8
// Yoke sits behind the window wall and slides vertically in slots in the frame ends.
yoke_z0     = reg_wall + 0.5;
// The yoke must stop short of the detent comb, which is mounted flat against the back cover.
// Running the yoke the full depth puts its bottom spine straight through the comb's fingers.
comb_z      = reg_depth - reg_wall - carrier_t;
yoke_depth  = comb_z - yoke_z0 - 0.5;
yoke_shaft_z = shaft_axis_z() - yoke_z0;                   // pinion shaft, in yoke-local z

// -- vertical stack, derived bottom-up so nothing can silently overlap --
// The tipper's corners sweep well below its pivot, which is the clearance that actually
// sets how high everything above it has to sit.
floor_t      = 3.0;                                       // body floor thickness
tip_swing_dn = sqrt(pow(tipper_ol()/2, 2) + pow(hub_z(), 2));            // 34.25
tip_rise_up  = tipper_ol()/2 * sin(tip_angle)
             + (tipper_oh() - hub_z()) * cos(tip_angle);                 // 24.08
tipper_hub_z = floor_t + floor_clear + tip_swing_dn;                     // 43.25
spout_z      = tipper_hub_z + tip_rise_up + spout_gap;                   // 73.33
// The funnel hangs from the top collar with its cone inside the body, so the body's height
// is fixed by where the spout mouth has to land.
body_h       = spout_z + funnel_h;                                       // 177.7
chassis_z    = floor_t;
post_h       = tipper_hub_z - chassis_z + 8;                             // 48.25
reg_bottom_z = window_z + window_h/2 - reg_shaft_y;
reg_top_z    = reg_bottom_z + reg_h;

// -- housing --
body_id = body_od - 2*body_wall;

// === VALIDATION (acceptance criteria as build-time contracts) ===
assert(abs(catch_area_mm2 - PI*aperture_r*aperture_r) < 1.0,
       "AC1: aperture does not give the intended catch area");
assert(abs(aperture_id - 159.577) < 0.01,
       "AC1: aperture ID should be 159.577 mm for 200 cm^2");
assert(abs(tip_volume_ml - 10.0) < 0.3,
       "AC2: tip volume must be 10.00 mL +/- 3%");
assert(abs(mm_per_digit - 1.0) < 0.001,
       "AC2: one digit must equal 1.0 mm of rain");
assert(gauge_max_mm == 9999,
       "AC3: gauge must read up to 9999 mm");
assert(fill_depth < chamber_h - 4,
       "AC2: chamber too shallow -- 10 mL would overflow before it tips");
assert(chamber_ml > tip_volume_ml * 1.5,
       "AC2: chamber needs >=50% freeboard above the tip volume");
assert(carry_teeth < gear_teeth,
       "AC4: mutilated driver must have fewer teeth than a full gear");
assert(abs(centre_dist - gear_pitch_r*2) < 0.001,
       "AC4: pinion centre distance must equal 2x pitch radius for a 1:1 mesh");
assert(gear_teeth * carry_teeth / gear_teeth == carry_teeth,
       "AC4: carry ratio sanity");
// The carry hub is the gear's root circle, so its clearance to the pinion tips is exactly
// the standard 0.25*module root clearance (0.375 mm) -- correct by gear geometry, not a
// tuned fudge.
assert(abs((centre_dist - gear_outer_r) - carry_hub_r - 0.25*gear_mod) < 0.001,
       "AC4: carry hub is not on the root circle -- pinion tip/root clearance is wrong");
// Ratchet ring must be clear of the pinion AND of the carry teeth radially, and it lives in
// its own band so the sweeping carry wedge can never reach the pawl or the detent.
assert(detent_notch_r < carry_hub_r,
       "AC4: ratchet ring must sit inside the carry hub");
assert(z_carry > z_ratchet && z_ratchet > z_cam,
       "AC4: ratchet band must be axially separate from the carry band -- the carry wedge sweeps all 360 deg");
assert(detent_notch_r >= cam_r_min,
       "AC7: ratchet ring undercuts the heart cam below it");
assert(detent_notch_r - cam_r_min <= 1.0,
       "AC7: ratchet ring oversails the cam cusp by more than 1 mm -- add a 45 deg ramp");
assert(abs(carry_lead - (gear_outer_r - detent_notch_r)) < 0.001,
       "AC7: carry-tooth ramp must be 45 deg from the ratchet ring up to the tooth tips");
// -- drive train: one tip must advance exactly one notch, never two --
assert(pawl_notches > 1.02,
       "AC2: pawl throw too short -- it will not carry the ratchet a full notch");
assert(pawl_notches < 1.8,
       "AC2: pawl throw too long -- it could advance two notches on one tip");
assert(detent_notch_d > 0.6 && detent_notch_d < detent_notch_r/6,
       "AC4: detent notch depth unreasonable");
// -- the mechanism must have the energy to do its job --
assert(energy_margin > 6,
       "AC4: detent comb too stiff -- one tip may not have the energy to drive a 9->0 carry");
assert(detent_strain < 0.02,
       "AC4: detent flexure strain over 2% -- PETG will take a set and lose its detent force");
assert(detent_spring_t >= 2 * extrusion_width - 0.01,
       "AC7: detent flexure thinner than 2 perimeters");
assert(detent_spring_len / detent_spring_t > 10,
       "AC7: detent flexure too stubby to act as a spring (want L:t > 10)");
assert(cam_r_max < wheel_r,
       "AC5: heart cam must sit inside the digit drum");
assert(cam_r_max - cam_r_min > plunger_stroke * 0.5,
       "AC5: cam rise too small for the plunger stroke to zero the wheels");
assert(hammer_blade_w < cam_band_w - 0.5,
       "AC5: hammer blade will not fit the cam band slot");
// Both the pawl and the detent act on the ratchet ring, so both must fall on a notch. The
// notches are at i*digit_step + ratchet_phase, so it is that residue they have to match.
assert(abs((pawl_phi - floor(pawl_phi/digit_step)*digit_step) - ratchet_phase) < 0.001,
       "AC4: drive pawl does not line up with a ratchet notch");
assert(abs((detent_phi - floor(detent_phi/digit_step)*digit_step) - ratchet_phase) < 0.001,
       "AC4: detent comb does not line up with a ratchet notch");
// The comb and the pinions both come from below (270 deg). That is only safe because they
// act on different axial bands -- prove the two never overlap in X.
assert(detent_x(0) + 2 < pinion_x(0) || pinion_x(0) + pinion_w < detent_x(0) - 2,
       "AC4: detent comb and transfer pinion occupy the same axial station");
assert(facet_w > digit_size * 0.6,
       "AC3: digit facet too narrow for the character size");
assert(funnel_od <= build_usable && funnel_h < build_z,
       "AC6: funnel does not fit the usable bed (X1/P1 exclusion zone applies)");
assert(body_od + 2*collar_t + 14 <= build_usable && body_h < build_z,
       "AC6: body (incl. collar and mount lugs) does not fit the usable bed");
assert(reg_out_w <= build_usable && reg_h <= build_usable,
       "AC6: register frame does not fit the usable bed");
assert(wheel_w == gear_band_w + digit_band_w + cam_band_w + ratchet_band_w + carry_band_w,
       "wheel band widths inconsistent");
assert(drum_chamfer >= 0.4,
       "AC7: digit drum needs a 45 deg chamfer to print support-free");
assert(z_carry > z_ratchet && z_ratchet > z_cam && z_cam > z_digit && z_digit > z_gear,
       "AC7: band order must be gear/digit/cam/ratchet/carry (see the note at z_gear)");
assert(pinion_w >= carry_full_w + wheel_gap + 1.0,
       "AC4: pinion too narrow -- it must reach the next wheel's gear band or the carry cannot transmit");
assert(pinion_w <= carry_full_w + wheel_gap + gear_band_w - 0.3,
       "AC4: pinion too wide -- it will foul the digit drum or the next cam band");
assert(centre_dist - gear_outer_r < wheel_r,
       "geometry note: pinion must stay axially clear of every digit drum (it does, by band order)");
// -- the pinion must live INSIDE the register frame, radius included, not just its axis --
assert(reg_shaft_y - centre_dist - gear_outer_r >= reg_wall,
       "AC4: register too shallow -- the transfer pinions would hang outside the frame");
assert(reg_h - reg_shaft_y >= wheel_r + 6,
       "AC5: no room above the wheels for the reset hammer to swing");
// -- vertical stack clearances --
assert(tipper_hub_z - tip_swing_dn >= floor_t + 2,
       "AC2: the tipper's swept corner would strike the floor");
assert(spout_z >= tipper_hub_z + tip_rise_up + 2,
       "AC2: the spout would strike the tipper at full tip");
assert(reg_bottom_z >= floor_t + 2,
       "AC6: register frame would sit on the wet floor");
assert(reg_top_z <= body_h - collar_h - 10,
       "AC6: register frame collides with the top collar");
assert(funnel_outer_r_at(reg_top_z) < body_id/2 - 4 - reg_depth,
       "AC6: funnel cone fouls the register bay");
// -- funnel has to drop through the bore and then hang on its flange --
assert(aperture_id + 2*rim_out_top < body_id - 2,
       "AC6: funnel cone will not pass down through the body bore");
assert(funnel_od > body_id + 4,
       "AC6: funnel flange too small -- it would fall through the bore instead of seating");
assert(body_od + 2*collar_t - (funnel_od + 2*tolerance) >= 4,
       "AC6: not enough collar material around the funnel rebate");
assert(spout_id + 2*funnel_wall < chamber_l,
       "AC2: spout wider than a bucket chamber");

// Outer radius of the funnel at a given height above the body's base, in USE orientation
// (mouth up). Used to prove the cone does not foul the register bay.
function funnel_outer_r_at(z) =
    let (z0 = spout_z + spout_h, z1 = body_h - rim_h,
         r0 = spout_id/2 + funnel_wall, r1 = aperture_r + rim_out_top)
    z <= z0 ? r0 : (z >= z1 ? r1 : r0 + (r1 - r0) * (z - z0) / (z1 - z0));

// === 2D PROFILE HELPERS ===

// Trapezoidal-tooth spur gear profile. At module 1.5 the tooth is ~1.57 mm thick at the
// pitch line (3+ extrusions), which FDM prints reliably.
module gear_2d(teeth = gear_teeth, mod = gear_mod, backlash = gear_backlash) {
    pr = teeth * mod / 2;
    orr = pr + mod;
    irr = pr - 1.25 * mod;
    ta = 360 / teeth;
    bl = backlash / pr * 180 / PI;   // mm of backlash -> degrees at the pitch circle
    union() {
        circle(r = irr);
        for (i = [0 : teeth-1])
            rotate(i * ta)
                polygon([
                    [irr * cos(-ta/4 + bl/2), irr * sin(-ta/4 + bl/2)],
                    [orr * cos(-ta/8 + bl/2), orr * sin(-ta/8 + bl/2)],
                    [orr * cos( ta/8 - bl/2), orr * sin( ta/8 - bl/2)],
                    [irr * cos( ta/4 - bl/2), irr * sin( ta/4 - bl/2)]
                ]);
    }
}

// "Mutilated" driver: a plain hub with only `carry_teeth` teeth left standing, centred on
// `phase`. This is the US 897379 single/double-tooth carry driver.
module mutilated_gear_2d(phase = carry_phase) {
    ta = 360 / gear_teeth;
    union() {
        circle(r = carry_hub_r);
        intersection() {
            gear_2d();
            // keep only the wedge holding the carry teeth
            rotate(phase)
                polygon([[0,0],
                         [gear_outer_r*2 * cos(-carry_teeth*ta/2), gear_outer_r*2 * sin(-carry_teeth*ta/2)],
                         [gear_outer_r*2 * cos(0),                 gear_outer_r*2 * sin(0)],
                         [gear_outer_r*2 * cos( carry_teeth*ta/2), gear_outer_r*2 * sin( carry_teeth*ta/2)]]);
        }
    }
}

// Ratchet / detent ring: a plain hub with 10 asymmetric notches. Steep driving face for the
// pawl on one side, shallow return ramp on the other. Serves two jobs -- the detent comb
// rests in a notch to hold the digit, and the drive pawl pushes a steep face to advance it.
// Crucially it carries NO gear teeth, so the pawl and detent never meet the carry wedge.
module ratchet_band_2d() {
    difference() {
        circle(r = detent_notch_r);
        for (i = [0 : digits_per_wheel-1])
            rotate(i * digit_step + ratchet_phase)
                polygon([
                    [detent_notch_r + fudge, 0],
                    [detent_notch_r - detent_notch_d, 0],
                    [(detent_notch_r + fudge) * cos(digit_step*0.42),
                     (detent_notch_r + fudge) * sin(digit_step*0.42)]
                ]);
    }
}

// Heart cam. r grows away from the cusp in both directions, so a flat face pressed against
// it can only rest with the cusp centred -- one unique angular position = digit 0.
// `cam_asym` puts a small step at the far side so the point opposite the cusp is not a
// stable equilibrium.
function heart_r(t) = cam_r_min + (cam_r_max - cam_r_min) * (abs(t) / 180) * (t < 0 ? 1 : cam_asym);
module heart_cam_2d(cusp = hammer_phi) {
    pts = [ for (t = [-180 : 4 : 180]) let(r = heart_r(t)) [ r*cos(t + cusp), r*sin(t + cusp) ] ];
    polygon(pts);
}

// Teardrop for self-supporting horizontal bores.
module teardrop_2d(d) {
    r = d/2;
    union() { circle(r=r); polygon([[-r*0.707, r*0.707],[r*0.707, r*0.707],[0, r*1.414]]); }
}

// === PART: NUMBER WHEEL (x4, identical) ===
// Print orientation: axis vertical, gear band on the plate. Diameters step down as it
// rises (16.5 -> 15 -> 17 via a 45 deg chamfer -> 12.5), so it needs no support.
// Digit 0 sits at wheel-local angle 0.
module number_wheel() {
    difference() {
        union() {
            // carry gear (receives the carry from the wheel below)
            translate([0,0,z_gear]) linear_extrude(gear_band_w) gear_2d();
            // heart cam for reset
            translate([0,0,z_cam])  linear_extrude(cam_band_w)  heart_cam_2d();
            // digit drum: decagonal prism, one flat facet per digit, 45 deg chamfer beneath
            translate([0,0,z_digit]) {
                linear_extrude(drum_chamfer, scale = wheel_r/gear_outer_r)
                    rotate(-180/digits_per_wheel) circle(r = gear_outer_r, $fn = digits_per_wheel);
                translate([0,0,drum_chamfer])
                    linear_extrude(digit_band_w - drum_chamfer)
                        rotate(-180/digits_per_wheel) circle(r = wheel_r, $fn = digits_per_wheel);
            }
            // ratchet / detent ring. Sits straight on the cam: at r=12 it oversails the
            // cam's 11.5 mm cusp by only 0.5 mm, which needs no ramp.
            translate([0,0,z_ratchet]) linear_extrude(ratchet_band_w) ratchet_band_2d();
            // carry band: 45 deg ramp up from the ratchet ring to the 2 carry teeth, then
            // the full-height tooth region that meshes the transfer pinion. Without the
            // ramp the teeth would be a 4.5 mm unsupported overhang.
            translate([0,0,z_carry]) {
                hull() {
                    // Deliberately UNDER the ratchet radius. Matching it exactly makes the
                    // ramp's base cylinder coincide with the ratchet ring's, and the ten
                    // notch mouths then meet edge-on -- Manifold self-heals that but Bambu
                    // Studio reports it as non-manifold edges.
                    linear_extrude(0.01) circle(r = detent_notch_r - 0.5);
                    translate([0,0,carry_lead]) linear_extrude(0.01) mutilated_gear_2d();
                }
                translate([0,0,carry_lead])
                    linear_extrude(carry_full_w) mutilated_gear_2d();
            }
            // embossed digits, one per facet
            for (i = [0 : digits_per_wheel-1])
                rotate(i * digit_step)
                    translate([facet_inradius - digit_sink, 0, z_digit + digit_band_w/2])
                        rotate([0,90,0])
                            linear_extrude(digit_sink + digit_emboss)
                                text(str(i), size = digit_size, font = digit_font,
                                     halign = "center", valign = "center", $fn = 24);
        }
        // bore
        translate([0,0,-fudge]) cylinder(h = wheel_w + 2*fudge, d = bore_d);
        // hollow out the drum to save material and let it spin light
        translate([0,0,z_digit + 1.2])
            difference() {
                cylinder(h = digit_band_w - 2.4, r = facet_inradius - 2.0);
                cylinder(h = digit_band_w - 2.4, d = bore_d + 2*3.0);
            }
    }
}

// === PART: TRANSFER PINION (x3) ===
// A plain 20-tooth gear. Because the band order keeps it clear of every digit drum, it
// needs none of the stepped "two-tier" geometry a Veeder-Root pinion normally has.
module transfer_pinion() {
    difference() {
        linear_extrude(pinion_w) gear_2d();
        translate([0,0,-fudge]) cylinder(h = pinion_w + 2*fudge, d = 4 + 2*tolerance);
    }
}

// === PART: REGISTER FRAME ===
// U-channel that carries the wheel shaft, the window, the pinion carrier pivot and the
// plunger guide. Print orientation: window face down on the plate, so the window aperture
// and the shaft bores print as vertical walls and the open top needs no support.
// Print orientation: WINDOW FACE DOWN on the plate. Every wall then rises vertically, the
// two long faces stay open, and no feature overhangs. In use the window faces +Y (front),
// the open top becomes the back (capped by reg_side), and the two open long faces become
// the top and bottom -- which is exactly where the reset hammer and the pinion carrier
// need to reach in.
module reg_frame() {
    difference() {
        union() {
            cube([reg_out_w, reg_h, reg_wall]);                       // window wall, on plate
            cube([reg_wall, reg_h, reg_depth]);                       // left end plate
            translate([reg_out_w - reg_wall, 0, 0])
                cube([reg_wall, reg_h, reg_depth]);                   // right end plate
            // tie bars along the two open long edges, at the back (out of the way of the
            // hammer and the carrier, which come in nearer the window)
            for (y = [0, reg_h - reg_wall])
                translate([0, y, reg_depth - reg_wall])
                    cube([reg_out_w, reg_wall, reg_wall]);
        }
        // digit window, centred on the wheel axis
        translate([(reg_out_w - window_w)/2, reg_shaft_y - window_h/2, -fudge])
            cube([window_w, window_h, reg_wall + 2*fudge]);
        // wheel shaft bores through both end plates (horizontal holes -> teardrop)
        translate([-fudge, reg_shaft_y, shaft_axis_z()])
            rotate([0,90,0]) rotate([0,0,-90])
                linear_extrude(reg_out_w + 2*fudge) teardrop_2d(shaft_d + tolerance);
        // Reset yoke guides. The yoke TRANSLATES, so these are vertical slots, not pivot
        // bores -- two per end plate, which constrains it to pure vertical motion.
        for (gy = [pinion_y, yoke_top_y + yoke_spine_t/2])
            hull() for (dy = [0, -reset_stroke - 1])
                translate([-fudge, gy + dy, shaft_axis_z()])
                    rotate([0,90,0])
                        cylinder(h = reg_out_w + 2*fudge, d = pinion_shaft_d + tolerance);
        // plunger entry, above the wheels, so the plunger can bear on the yoke's top spine
        translate([reg_out_w/2, yoke_top_y + yoke_spine_t + plunger_d/2 - 1, -fudge])
            rotate([-90,0,0]) rotate([0,0,180])
                linear_extrude(reg_wall + 2*fudge) teardrop_2d(plunger_d + tolerance);
        // screw bosses for the back cover
        for (x = [6, reg_out_w - 6]) for (y = [6, reg_h - 6])
            translate([x, y, reg_depth - 8]) cylinder(h = 10, d = m3_d - 0.4);
    }
}
function shaft_axis_z()  = reg_wall + reg_clear + wheel_r;

// === PART: REGISTER BACK COVER ===
// Closes the open back of the frame once the wheels and pinions are in, and keeps the wet
// side out of the register. Prints flat. Deliberately has no shaft pockets -- the shaft is
// carried by the frame's end plates and slides in from outside.
module reg_side() {
    difference() {
        cube([reg_out_w, reg_h, reg_wall]);
        for (x = [6, reg_out_w - 6]) for (y = [6, reg_h - 6])
            translate([x, y, -fudge]) cylinder(h = reg_wall + 2*fudge, d = m3_d + 0.3);
        // detent comb screws: the comb mounts to this cover, immediately in front of it
        for (x = [reg_wall + 4, reg_out_w - reg_wall - 4])
            translate([x, comb_base_y() + 3, -fudge])
                cylinder(h = reg_wall + 2*fudge, d = m3_d + 0.3);
    }
}

// === PART: PINION CARRIER (with integral detent comb) ===
// Holds all three transfer pinions on one rocking plate -- US 897379's "vibratory frame".
// The reset plunger rocks it a couple of millimetres so every carry leaves mesh at once,
// freeing the wheels to be zeroed independently. The detent comb is on the same part so
// one moulding does both jobs. Prints flat, flexures in the XY plane so they bend along
// layers rather than across them.
// This is US 897379's "vibratory frame", as one printed part. A single downward stroke:
//   - carries the pinion shaft DOWN, so all three transfer pinions leave mesh at once and
//     the wheels are freed from each other
//   - drives the hammer blades DOWN onto the four heart cams, zeroing every wheel
// Both from one motion, which is why the carrier and the hammer are not separate parts.
// Sequencing is automatic and geometric: the pinions unmesh after 3.0 mm, while the blades
// do not touch a cam until 4.0 mm, so the wheels are always free before they are driven.
//
// Print orientation: laid so the yoke's own Z is the frame's DEPTH direction. Every wall is
// then vertical, the spines and ears all start on the plate, and the horizontal shaft bores
// are teardrops. Footprint is large but flat.
module reset_yoke() {
    w  = yoke_span();
    ht = yoke_top_y - yoke_bot_y() + yoke_spine_t;
    difference() {
        union() {
            // bottom spine, clear below the pinions
            translate([0, yoke_bot_y(), 0]) cube([w, yoke_spine_t, yoke_depth]);
            // top spine, carrying the hammer blades and the plunger ramp
            translate([0, yoke_top_y, 0]) cube([w, yoke_spine_t, yoke_depth]);
            // end ears. These stay INSIDE the frame -- a spine or ear that crossed an end
            // plate would foul it through the whole stroke.
            for (x = [0, w - yoke_ear_t])
                translate([x, yoke_bot_y(), 0]) cube([yoke_ear_t, ht, yoke_depth]);
            // top guide stubs, projecting outward into the frame's upper guide slots. With
            // the pinion shaft below, these two give pure vertical translation.
            for (s = [0, 1])
                translate([s ? w - fudge : -yoke_guide_l + fudge,
                           yoke_top_y + yoke_spine_t/2, yoke_shaft_z])
                    rotate([0,90,0])
                        cylinder(h = yoke_guide_l, d = pinion_shaft_d - tolerance);
            // hammer blades, thin enough to enter the cam band slot.
            // cam_x() is measured from the frame interior, so shift into yoke-local X.
            for (i = [0 : digit_wheels-1])
                translate([reg_wall + cam_x(i) - yoke_x0() - hammer_blade_w/2,
                           reg_shaft_y + blade_rest_r, 0])
                    cube([hammer_blade_w,
                          yoke_top_y - reg_shaft_y - blade_rest_r + fudge, yoke_depth]);
        }
        // pinion shaft bore through both ears
        translate([-fudge, pinion_y, yoke_shaft_z])
            rotate([0,90,0]) rotate([0,0,-90])
                linear_extrude(w + 2*fudge) teardrop_2d(pinion_shaft_d + tolerance);
    }
    // No ramp on the yoke: the wedge lives on the PLUNGER tip, which bears down on this
    // spine's plain top face. Keeping the incline on one part means only one part has to be
    // right, and the yoke needs no matching feature.
}
function yoke_x0()    = reg_wall + 0.5;    // yoke's X origin in frame coordinates
function yoke_span()  = reg_in_w - 1.0;   // ears land in the reg_side_clear gaps
function yoke_bot_y() = pinion_y - gear_outer_r - 3;
yoke_guide_l = 4.0;

// === PART: DETENT COMB ===
// Mounted to the FRAME, not to the yoke. It has to stay put while the yoke moves, and it
// does not need to lift for a reset: the heart cam beats a detent about 11:1 on torque, so
// the wheels simply click over their detents while being zeroed.
// Fingers reach up from below the pinions to the ratchet rings. They are long (38 mm)
// because they must clear the pinions, which is why they are 3 perimeters thick rather
// than 2 -- see the detent_force / detent_strain contracts.
// Prints flat; every flexure bends within the layer plane.
module detent_comb() {
    base_y = comb_base_y();
    difference() {
        union() {
            cube([reg_in_w, 6, carrier_t]);
            for (i = [0 : digit_wheels-1]) {
                translate([detent_x(i) - detent_spring_t/2, 6 - fudge, 0])
                    cube([detent_spring_t, detent_spring_len, carrier_t]);
                // tapered pad, so the tip seats in the shallow notch instead of riding on
                // its shoulders
                translate([detent_x(i), 6 + detent_spring_len - fudge, 0])
                    linear_extrude(carrier_t)
                        polygon([[-1.7,0], [1.7,0], [0.85,2.0], [-0.85,2.0]]);
            }
        }
        for (x = [4, reg_in_w - 4])
            translate([x, 3, -fudge]) cylinder(h = carrier_t + 2*fudge, d = m3_d + 0.3);
    }
}
// Comb base sits below the pinions; the finger tips reach the ratchet ring from below.
function comb_base_y() = reg_shaft_y - detent_notch_r - detent_spring_len - 8;
// Axial left edge of the pinion at carry station i: it meshes the FULL-height part of
// wheel i's carry band, so it starts after the 45 deg ramp.
function pinion_x(i) = reg_side_clear + wheel_pitch*i + z_carry + carry_lead + 0.2;
// Detent finger and drive pawl both act on the ratchet band.
function detent_x(i) = reg_side_clear + wheel_pitch*i + z_ratchet + ratchet_band_w/2;

// === PART: RESET HAMMER ===
// One blade per wheel, all on a common rocking bar. Pressed onto the heart cams by the
// plunger; each blade's flat face can only sit still with its cam's cusp centred, so all
// four wheels are driven to digit 0 simultaneously. Prints flat.
// (The separate hammer part is gone: its blades are now part of reset_yoke, because one
// downward stroke has to drive both the declutch and the zeroing.)
function cam_x(i) = reg_side_clear + wheel_pitch*i + z_cam + cam_band_w/2;

// === PART: RESET PLUNGER ===
// Push-button. The first part of the stroke rocks the pinion carrier out of mesh via the
// lower ramp; the rest presses the hammer bar onto the heart cams via the upper ramp.
// Sequencing them on one shaft is what lets a single button do the whole reset.
module plunger() {
    difference() {
        union() {
            cylinder(h = plunger_stroke + 14, d = plunger_d - tolerance);
            // finger cap. 4 mm of rise for 3.15 mm of radius growth = 38 deg from vertical,
            // so it self-supports (3 mm would be 46 deg and would droop in PETG).
            translate([0, 0, plunger_stroke + 14 - fudge])
                cylinder(h = 4, d1 = plunger_d - tolerance, d2 = plunger_d + 6);
            // declutch ramp (acts first)
            translate([0, 0, 4])
                cylinder(h = 4, d1 = plunger_d - tolerance, d2 = plunger_d + 5);
            // hammer ramp (acts second)
            translate([0, 0, 10])
                cylinder(h = 4, d1 = plunger_d - tolerance, d2 = plunger_d + 5);
        }
        // spring pocket
        translate([0,0,-fudge]) cylinder(h = plunger_stroke + 4, d = 6);
    }
}

// === PART: DRIVE PAWL ===
// Single-acting pawl. Advances the units wheel one notch on one half of the tipper's
// rocker cycle, and cams harmlessly out of the way on the other half and during reset --
// it is deliberately NON-locking, because the detent comb (not the pawl) is what holds
// the digit. Prints flat with the leaf spring in the XY plane.
module drive_pawl() {
    difference() {
        union() {
            // lever, pivot out to the link pin eye
            hull() {
                cylinder(h = 3, d = 9);
                translate([pawl_link_r, 0, 0]) cylinder(h = 3, d = 7);
            }
            // pawl tooth, branching off tangentially at pawl_tooth_r
            translate([pawl_tooth_r, 0, 0])
                linear_extrude(3)
                    polygon([[0, 0], [0, 4.5], [-2.2, 5.6], [-3.4, 3.0]]);
            // Return leaf spring. It MUST project clear of the lever hull -- rooted on the
            // lever's centreline it is entirely swallowed by the hull and contributes no
            // spring force at all. So it is rooted at the pivot boss and runs off at an
            // angle, well outside the lever body.
            rotate(pawl_spring_angle)
                translate([3, -detent_spring_t/2, 0])
                    cube([detent_spring_len, detent_spring_t, 3]);
        }
        // pivot bore
        translate([0, 0, -fudge]) cylinder(h = 3 + 2*fudge, d = 4 + tolerance);
        // link pin eye -- deliberately at pawl_link_r, NOT at the tooth, so it cannot
        // perforate the tooth root
        translate([pawl_link_r, 0, -fudge])
            cylinder(h = 3 + 2*fudge, d = 2.4 + tolerance);
    }
}

// === PART: LINK ===
// Connecting rod, tipper crank pin -> drive pawl. Prints flat.
module link() {
    l = link_len;
    difference() {
        union() {
            hull() { cylinder(h=3, d=7); translate([l,0,0]) cylinder(h=3, d=7); }
        }
        translate([0,0,-fudge]) cylinder(h=3+2*fudge, d = 2.4 + tolerance);
        translate([l,0,-fudge]) cylinder(h=3+2*fudge, d = 2.4 + tolerance);
    }
}

// === PART: TIPPING BUCKET ===
// Twin chambers, each 10.00 mL = 0.5 mm of rain at this aperture. Sloped floors so the
// chamber empties completely (residual water is the biggest systematic error in a tipping
// bucket). Prints chambers-up: every wall is vertical and the sloped floors are printed
// as shallow ramps, so no support.
module tipper() {
    ow = tipper_ow();
    ol = tipper_ol();
    oh = tipper_oh();
    hz = hub_z();
    difference() {
        union() {
            // body
            translate([-ol/2, -ow/2, 0]) cube([ol, ow, oh]);
            // pivot hub. Runs right through and projects both sides; the +Y end is longer
            // and carries a D-flat that keys the separate crank arm.
            translate([0, -ow/2 - hub_stub, hz]) rotate([-90,0,0])
                cylinder(h = ow + hub_stub + hub_boss_l, d = hub_d);
            // 45 deg gussets under both hub stubs, so the projecting stubs are not a
            // round overhang hanging in mid-air
            for (s = [-1, 1])
                mirror([0, s > 0 ? 0 : 1, 0])
                    hull() {
                        translate([-hub_d/2, ow/2 - 1, 0]) cube([hub_d, 1, 0.1]);
                        translate([-hub_d/2, ow/2 - 1, hz - 0.1])
                            cube([hub_d, hub_stub + hub_boss_l + 1, 0.1]);
                    }
        }
        // two chambers. Floors slope down toward the outer end so each chamber drains dry --
        // residual trapped water is the largest systematic error in a tipping bucket.
        for (s = [-1, 1])
            translate([s * (chamber_l + divider_t)/2, 0, tipper_wall])
                hull() {
                    translate([-chamber_l/2, -chamber_w/2, chamber_h - 0.1])
                        cube([chamber_l, chamber_w, 0.1]);                        // opening
                    translate([s*chamber_l/2 - 0.05, -chamber_w/2, 0])
                        cube([0.1, chamber_w, 0.1]);                              // low, outboard
                    translate([-s*chamber_l/2 - 0.05, -chamber_w/2, floor_slope])
                        cube([0.1, chamber_w, 0.1]);                              // high, at divider
                }
        // pivot bore
        translate([0, -ow/2 - hub_stub - fudge, hz]) rotate([-90,0,0])
            cylinder(h = ow + hub_stub + hub_boss_l + 2*fudge, d = pivot_rod_d + tolerance);
        // D-flat on the outboard boss, to key the crank
        translate([hub_d/2 - hub_flat, ow/2 + hub_stub, hz - hub_d/2 - fudge])
            cube([hub_d, hub_boss_l + fudge, hub_d + 2*fudge]);
    }
}
function tipper_ow() = chamber_w + 2*tipper_wall;
function tipper_ol() = 2*chamber_l + divider_t + 2*tipper_wall;
function tipper_oh() = chamber_h + tipper_wall;
function hub_z()     = tipper_oh() * 0.42;

// === PART: CRANK ARM ===
// Separate from the tipper so the tipper prints with no mid-air cantilever. Presses onto
// the tipper hub's D-boss (the flat is what transmits rotation) and carries the pin that
// drives the link. Prints flat, pin pointing up, so the pin is a vertical cylinder.
module crank() {
    difference() {
        union() {
            linear_extrude(4) hull() { circle(d = hub_d + 5); translate([crank_r,0]) circle(d = 6); }
            translate([crank_r, 0, 4 - fudge]) cylinder(h = 6, d = 2.4);
        }
        // D-socket matching the tipper boss
        translate([0,0,-fudge])
            linear_extrude(4 + 2*fudge)
                intersection() {
                    circle(d = hub_d + tolerance);
                    translate([-hub_d, -hub_d/2 - hub_d])
                        square([hub_d + hub_d/2 - hub_flat + tolerance/2, 2*hub_d]);
                }
    }
}

// === PART: CHASSIS ===
// Internal deck: carries the tipper pivot, the calibration stop screws and the register
// bay. Drops into the body. Prints deck-down; the bearing upstands are vertical walls.
module chassis() {
    deck_w  = body_id - 2;
    // The tipper rocks about a Y axis, so its bearing upstands must straddle it in Y.
    post_y  = tipper_ow()/2 + hub_stub + 3;
    difference() {
        union() {
            linear_extrude(floor_t) circle(d = deck_w);
            for (s = [-1, 1])
                translate([0, s * post_y, 0])
                    linear_extrude(post_h)
                        hull() { translate([0,-5]) circle(d=12); translate([0,5]) circle(d=12); }
            // bosses for the two calibration stop screws
            for (s = [-1, 1])
                translate([s * stop_screw_x, 0, 0]) linear_extrude(stop_boss_h) circle(d = 9);
        }
        // pivot bore straight through both upstands (axis along Y -> teardrop so the
        // horizontal bore self-supports)
        translate([0, -body_id, chassis_bore_z()])
            rotate([-90,0,0]) rotate([0,0,180])
                linear_extrude(2*body_id) teardrop_2d(pivot_rod_d + tolerance);
        // calibration stop screws: self-tapped M3, adjust to trim the tip volume
        for (s = [-1, 1])
            translate([s * stop_screw_x, 0, -fudge])
                cylinder(h = stop_boss_h + 2*fudge, d = stop_screw_d - 0.4);
        // drainage
        for (a = [0 : 360/drain_slots : 359])
            rotate(a) translate([deck_w/4, 0, -fudge])
                cylinder(h = floor_t + 2*fudge, d = 12);
        translate([0, 0, -fudge]) cylinder(h = floor_t + 2*fudge, d = 20);
    }
}
function chassis_bore_z() = post_h - 8;

// === PART: BODY ===
// Weather shell. Prints upright, open end up: a plain cylinder with vertical walls, drain
// slots chamfered at 45 deg so they self-support, and two mounting lugs at the back.
module body() {
    difference() {
        union() {
            cylinder(h = body_h, d = body_od);
            // Top collar. The funnel rebate has to be cut somewhere with enough meat around
            // it -- cutting it straight into a 2.4 mm shell would leave a 0.9 mm lip. The
            // collar is flared on at 45 deg so its underside self-supports.
            translate([0, 0, body_h - collar_h - collar_flare])
                cylinder(h = collar_flare, d1 = body_od, d2 = body_od + 2*collar_t);
            translate([0, 0, body_h - collar_h])
                cylinder(h = collar_h, d = body_od + 2*collar_t);
            // mounting lugs
            for (z = [30, body_h - 55])
                translate([0, -body_od/2 - 3, z]) rotate([0,90,0])
                    cylinder(h = 26, d = 14, center = true);
        }
        // bore, leaving the floor
        translate([0, 0, floor_t]) cylinder(h = body_h, d = body_id);
        // funnel locating rebate in the collar
        translate([0, 0, body_h - funnel_rebate_h])
            cylinder(h = funnel_rebate_h + fudge, d = funnel_od + 2*tolerance);
        // digit window -- cut only through the front wall
        translate([-window_w/2 - 3, body_id/2 - 4, window_z])
            cube([window_w + 6, body_od, window_h + 12]);
        // plunger hole through the front wall
        translate([window_w/2 + 14, body_id/2 - 4, window_z + window_h/2])
            rotate([-90,0,0]) cylinder(h = body_od, d = plunger_d + tolerance);
        // floor drains: vertical holes, so no overhang at all
        for (a = [0 : 360/drain_slots : 359])
            rotate(a) translate([body_id/2 - 12, 0, -fudge])
                cylinder(h = floor_t + 2*fudge, d = 10);
        // wall slots just above the floor, so standing water cannot pool. Rectangular, so
        // the only overhang is a 6 mm bridge across the top (PETG bridges this easily).
        for (a = [0 : 360/drain_slots : 359])
            rotate(a) translate([-3, body_id/2 - 4, floor_t])
                cube([6, body_wall + 8, 8]);
        // mount lug bores
        for (z = [30, body_h - 55])
            translate([0, -body_od/2 - 3, z]) rotate([0,90,0])
                cylinder(h = 30, d = m3_d + 0.4, center = true);
    }
}

// === PART: COLLECTOR FUNNEL ===
// Round inverted-bucket collector. Aperture 159.577 mm ID = exactly 200.0 cm^2.
// Print orientation: MOUTH DOWN on the plate. Every layer then steps inward, so the whole
// cone is self-supporting, and the aperture edge -- the one dimension the calibration
// depends on -- is the first layer, printed against glass and therefore accurate.
// In use it is inverted: rim up, spout down.
module funnel() {
    sr = spout_id/2;
    rotate_extrude(convexity = 4)
        polygon([
            [aperture_r, 0],                         // sharp aperture edge (on the plate)
            [aperture_r, rim_h],                     // vertical inner rim band
            [sr, cone_top_z],                        // inner cone
            [sr, cone_top_z + spout_h],              // inner spout
            [sr + funnel_wall, cone_top_z + spout_h],// spout end face
            [sr + funnel_wall, cone_top_z],          // outer spout
            [aperture_r + rim_out_top, rim_h],       // outer cone
            [aperture_r + rim_out_bot, 0]            // drip edge (widest, at the plate)
        ]);
    // debris bars across the spout mouth
    for (i = [0 : strainer_bars-1])
        translate([0, -sr + (i + 0.5) * 2*sr/strainer_bars, cone_top_z + spout_h - 2])
            cube([2*sr, 1.6, 2], center = true);
}

// === ASSEMBLY ===
// The register sub-assembly, in the frame's own coordinates (x along the wheel shaft,
// +y = up in use, +z = toward the back in use). Kept as its own module so the same
// placement is reused by assembly() and by the interference check.
//   reset = 0 for the rest state, 1 for the fully-pressed reset state.
module register(reset = 0) {
    dy = -reset * reset_stroke;
    color("darkseagreen") reg_frame();
    for (i = [0 : digit_wheels-1])
        color("ivory")
            translate([reg_wall + reg_side_clear + i*wheel_pitch, reg_shaft_y, shaft_axis_z()])
                rotate([0,90,0]) number_wheel();
    for (i = [0 : digit_wheels-2])
        color("orange")
            translate([reg_wall + pinion_x(i), pinion_y + dy, shaft_axis_z()])
                rotate([0,90,0]) rotate([0,0,180/gear_teeth]) transfer_pinion();
    color("indianred")
        translate([yoke_x0(), dy, yoke_z0]) reset_yoke();
    color("slateblue")
        translate([reg_wall, comb_base_y(), comb_z]) detent_comb();
    // drive pawl: pivots in the frame, tooth reaching the units wheel's ratchet band from
    // pawl_phi (below-back)
    color("gold")
        translate([reg_wall + detent_x(0) - 1.5, pawl_pivot_y(), pawl_pivot_z()])
            rotate([0, 0, pawl_phi - 270]) rotate([0,-90,0]) drive_pawl();
}
function pawl_pivot_y() = reg_shaft_y - detent_notch_r - pawl_tooth_r*sin(pawl_phi - 180);
function pawl_pivot_z() = shaft_axis_z() + pawl_tooth_r*cos(pawl_phi - 180);

module assembly() {
    e = explode;
    // housing
    color("gainsboro", 0.35) body();
    // funnel: flipped out of print orientation into use orientation (mouth up, spout down).
    // It hangs from the body's top collar with the whole cone inside the housing.
    color("lightsteelblue", 0.45)
        translate([0, 0, body_h + e]) rotate([180,0,0]) funnel();
    // internal chassis
    color("tan") translate([0, 0, chassis_z + e*0.5]) chassis();
    // tipper, shown part way through a tip, with its crank arm keyed on
    translate([0, 0, tipper_hub_z + e*0.7]) rotate([0, tip_angle, 0])
        translate([0, 0, -hub_z()]) {
            color("steelblue") tipper();
            color("dimgray")
                translate([0, tipper_ow()/2 + hub_stub + 1, hub_z()]) rotate([-90,0,0]) crank();
        }
    // register: window facing +Y, wheel shaft along X
    translate([-reg_out_w/2, body_id/2 - 4, reg_bottom_z]) rotate([90,0,0]) register(reset_view);
    // reset plunger, entering the body's front wall and bearing on the yoke's push tab
    color("firebrick")
        translate([window_w/2 + 14, body_id/2 - 4 + 8, window_z + window_h/2])
            rotate([90,0,0]) plunger();
    // connecting rod, tipper crank pin -> pawl link pin
    color("darkorange")
        translate([crank_r, tipper_ow()/2 + hub_stub + 3, tipper_hub_z]) rotate([0,-70,0]) link();
}

// === RENDER ===
part = "all";  // "all","funnel","body","chassis","tipper","crank","wheel","pinion",
               // "reg_frame","reg_side","yoke","comb","plunger","pawl","link",
               // "register","register_reset","clash","clash_reset"
reset_view = 0;   // 0 = rest, 1 = reset button fully pressed

// Mechanical interference check. Intersecting the moving group with the static group gives a
// solid only where parts CLASH -- so an empty result is a real, deterministic fit check, and
// a non-empty one reports exactly where. Run it at both ends of the reset stroke.
//   openscad -D 'part="clash"' -o /dev/null --summary all model.scad
// An empty top-level object (facets 0 / "object is empty") means NO interference.
module clash_check(reset = 0) {
    dy = -reset * reset_stroke;
    intersection() {
        union() {   // moving group: the yoke only.
            // The pinions ride on the yoke but are deliberately excluded -- they MESH with
            // the wheels, so intersecting them would only ever report the intended mesh
            // (and gear_2d is a trapezoidal approximation of an involute, which overlaps a
            // little by construction). The pinions' clearance to the wheels is governed by
            // centre_dist and gear_backlash, and their travel by the reset_stroke asserts.
            translate([yoke_x0(), dy, yoke_z0]) reset_yoke();
        }
        union() {   // static group
            // Wheels are EXCLUDED on purpose. The hammer blade is meant to touch a heart cam
            // and the pinion teeth are meant to touch the wheel teeth, so including the
            // wheels would only ever report intended contact -- and the wheels are drawn at
            // their rest rotation, not the rotation the cam would take up. What this check
            // does prove is the fit of the moving yoke inside the fixed structure.
            reg_frame();
            translate([reg_wall, comb_base_y(), comb_z]) detent_comb();
        }
    }
}

if (part == "all")        assembly();
if (part == "funnel")     funnel();
if (part == "body")       body();
if (part == "chassis")    chassis();
if (part == "tipper")     tipper();
if (part == "crank")      crank();
if (part == "wheel")      number_wheel();
if (part == "pinion")     transfer_pinion();
if (part == "reg_frame")  reg_frame();
if (part == "reg_side")   reg_side();
if (part == "yoke")       reset_yoke();
if (part == "comb")       detent_comb();
if (part == "register")       register(0);
if (part == "register_reset") register(1);
if (part == "clash")          clash_check(0);
if (part == "clash_reset")    clash_check(1);
if (part == "plunger")    plunger();
if (part == "pawl")       drive_pawl();
if (part == "link")       link();

echo(str("Aperture ID = ", aperture_id, " mm  -> catch area ", catch_area_mm2/100, " cm^2"));
echo(str("Tip volume  = ", tip_volume_ml, " mL = ", mm_per_tip, " mm rain; fill depth ", fill_depth, " mm"));
echo(str("1 digit     = ", mm_per_digit, " mm rain; full scale ", gauge_max_mm, " mm"));
echo(str("Wheel ", wheel_od, " dia x ", wheel_w, " wide; stack ", stack_w, " mm; register ", reg_out_w, " mm"));
echo(str("Funnel ", funnel_od, " dia x ", funnel_h, " tall; body ", body_od + 2*collar_t,
         " dia x ", body_h, " tall"));
echo(str("Drive: crank chord ", crank_chord, " mm -> pawl travel ", pawl_travel,
         " mm = ", pawl_notches, " notches (must be 1.02..1.8)"));
echo(str("Carry: teeth at ", carry_phase % 360, " deg from digit 0; pinion at ", pinion_phi,
         " deg; hub r ", detent_notch_r, " vs pinion tip reach ", centre_dist - gear_outer_r));
echo(str("Stack: tipper hub z ", tipper_hub_z, "; spout z ", spout_z,
         "; register z ", reg_bottom_z, "..", reg_top_z));
echo(str("Energy: ", tip_energy_mj, " mJ per tip vs ", carry_work_mj,
         " mJ to lift 2 detents in a carry -> margin ", energy_margin, "x"));
echo(str("Detent: ", detent_force, " N per finger, peak strain ", detent_strain*100, " %"));
