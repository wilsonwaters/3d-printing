// === DESCRIPTION ===
// v2 - fixes from the first physical print of the bucket (2026-07-19):
//   1. teardrop_x() crown now points UP (was sideways -> bore tops sagged shut)
//   2. pivot bore sealed: the divider thickens into an octagonal rib around
//      the bore (the bore used to cut a full-length slot through both divider
//      faces, letting water flow between chambers so the bucket never tipped)
//   3. funnel knife edge: the outer bevel now converges past the bore radius
//      into a true chamfered edge (orifice diameter unchanged - it IS the lip)
//   4. chambers are now open WEDGES: outer walls dropped to a ~1.8 mm lip at
//      the floor's outer edge (they rose 11 mm above it, so a tipped chamber
//      retained most of its water - it needed ~90 deg to empty). Tipped 28 deg
//      past rest, the floor now runs ~17 deg down-and-out and pours clean.
//
// Mechanical Rain Gauge "Fable": a fully mechanical tipping-bucket rain gauge.
// No electronics. Rain falls into a WMO-standard 200 cm^2 round collector funnel,
// drips onto a dual-chamber tipping bucket ("seesaw"); every 10 mL (= exactly
// 0.5 mm of rainfall over 200 cm^2) the bucket tips. Alternate tips drive the
// feed pawl, so every 2 tips (= exactly 1 mm) advance the 4-digit drum odometer
// register by 1: dial mm = rainfall mm. The register reads cumulative rainfall
// 0000-9999 mm through a front window. A front push-button performs a one-touch
// snap-to-zero reset (snail cams + hammer fingers; pinion yoke disengages
// first, per Veeder-Root US 3,244,368 staging).
//
// Physical context: lives outdoors on a post/pipe (parametric socket under the
// base, default 25.4 mm pipe). PETG, UV-exposed, rain-wet. Mechanism forces are
// gram-scale; the governing constraints are FRICTION (each tip liberates only
// ~2-4 mJ which must drive the counter) and WATER (drain everything; keep the
// register bay splash-free behind a bulkhead).
//
// Mechanism lineage (from research):
//   - Tipping bucket: Wren/Hooke 1662; Negretti & Zambra 1890 mechanical-dial
//     tipping gauge proves tip-driven mechanical registers work.
//   - Carry: Veeder-Root two-tooth sector -> 8T long/short-tooth transfer pinion
//     -> 20T internal ring gear = exactly 36 deg (one digit) per carry, with a
//     locking disc holding idle drums (US 548,482, US 2,285,844).
//   - Reset: SNAIL cams (one-way, forward-to-zero, tally-counter style) so the
//     drive pawls and detent never block a reset; the pinion yoke still swings
//     out of mesh FIRST so each drum zeroes independently (US 3,244,368 staging:
//     slider nose 1 = yoke, nose 2 = hammer).
//
// Design decisions:
//   - 0.5 mm per tip (10 g of water) = 2.5x the energy of a commercial 0.2 mm
//     gauge, and a heavy count (rollover carry) can never hard-fail: the bucket
//     is force-unlimited (water keeps accumulating until it tips), so worst
//     case is a moment's delay, self-correcting.
//   - Drums Dia46 on a Ø3 steel shaft (low, repeatable friction). Transfer
//     pinions run on printed C-saddle journals on the yoke blades (loaded only
//     during carries; gear separation force seats them into the saddle).
//   - Single-acting pawl rocker concentric on the drum shaft, driven pin-and-
//     slot by the bucket crank peg: forward tip = advance one digit, return
//     tip = recock. (A coaxial pawl can only drive one stroke direction -
//     hence 2 tips per count, like a tally counter's press-and-release.)
//   - Bucket pivots on a Ø3 steel pin resting in open V-seats (line contact,
//     lowest printable friction), retained by printed clips; two M3 screws are
//     adjustable calibration stops (calibrate slightly LOW: transit-loss comp).
//   - Every part is support-free in its stated print orientation.
//
// Terminology -> code:
//   "collector/funnel"    -> funnel(), collector_area_cm2, orifice_d
//   "knife edge"          -> knife edge cut in funnel(), rim_wall_h
//   "debris screen"       -> screen()
//   "tipping bucket"      -> bucket(), chamber_*, tip_angle_deg
//   "calibration screws"  -> stop bosses in chassis(), stop_span_y (M3)
//   "the dials/register"  -> drum_std(), drum_units(), register in assembly()
//   "digit wheels"        -> drum_*, digit_*
//   "carry gears"         -> sector/pinion/ring (Veeder-Root train), gear_module
//   "reset button"        -> slider() (button is its front face), reset_*
//   "snail cams"          -> snail_2d(), cam_*, hammer()
//   "pinion cage"         -> yoke(), yoke_*
//   "click/pawls"         -> rocker(), pawl_*, detent (in chassis tower)
//   "pipe mount"          -> pipe_od, socket_* (in base())
//   "window"              -> win_* (in body())
//
// Common modifications:
//   Different pipe size    -> pipe_od (socket auto-resizes)
//   Bigger digits          -> digit_h + digit_band_w (drum pitch follows)
//   Different collector    -> collector_area_cm2 (funnel + tip volume follow;
//                             tip volume = area/10 mL per mm - keep >= 15 mL!)
//   Looser mechanism       -> tol_journal, gear_backlash (for wet/worn running)
//   Stiffer/softer clicks  -> pawl_t, detent_leaf_t
//
// Overall (assembled): ~Dia178 x ~300 mm incl. socket; every part fits 250 mm.
// Coordinate system: assembly Z up from socket bottom, window faces -Y, drum and
// bucket axes along X, +X = viewer's right = units drum end. Part modules are
// modeled in PRINT orientation (Z=0 = build plate); assembly() re-orients them.
// Funnel and body/base/chassis print in their use orientation.
//
// === PRINT SETTINGS ===
// Material: PETG (outdoor UV/heat, ductile pawl+spring flexures) - dry it first!
// Layer Height: 0.2 mm (0.12 mm recommended for drums/pinions/rocker)
// Walls/Perimeters: 4 (1.8 mm); small mechanism parts effectively solid
// Infill: 20% gyroid (funnel/body/base/chassis); 100% pinion/rocker/link/clips
// Supports: None - every part is support-free in its modeled orientation
// Orientation (per part, as modeled = as printed):
//   funnel    as used: spout tip ring on bed, cone >=45 deg, knife edge on top
//   screen    flat
//   body      as used (tube upright; window top 45 deg corbel; eave 45 deg)
//   base      as used (socket + shell walls vertical; gothic vents)
//   chassis   as used (deck on bed; towers/bulkhead rise)
//   bucket    chambers up (teardrop pivot bore)
//   drums     cam-flank down (axis vertical; digits emboss on the rim)
//   pinion    ring-gear band down (axis vertical)
//   yoke/rocker/link/hammer/slider/clip: flat
// Notes: PETG strings - print mechanism parts slow, 30-40% fan (50%+ funnel cone);
//   brim for drums/pinions; NO raft (kills tolerances). Scale nothing - clearances
//   are tuned for PETG shrink.
//
// === PART SELECTOR ===
part = "assembly"; // ["assembly","mech","funnel","screen","body","base",
                   //  "chassis","bucket","crank","drum_std","drum_units",
                   //  "pinion","yoke","rocker","hammer","slider","detent",
                   //  "clip","plate"]
explode = 0;       // mm of exploded-view separation (assembly)
section = 0;       // 1 = cut at rocker plane (X); 2 = cut at Y=0
tip_pose = 0;      // bucket tip angle for assembly pose (-tip_angle_deg..+)

// === PARAMETERS ===
// Printer
nozzle_diameter   = 0.4;
layer_height      = 0.2;
build_xyz         = 250;      // usable envelope (256 bed minus margin)

// Material / fit (PETG)
tol_slide         = 0.35;     // printed-on-printed sliding clearance (per side)
tol_journal       = 0.35;     // printed bore on Ø3 steel pin (diametral)
gear_backlash     = 0.35;     // arc thinning per mesh
tol_press         = 0.15;     // press-fit interference on steel (diametral)

// Hardware (BOM)
pin_d             = 3.0;      // steel rod: bucket pivot + drum shaft
m3_d              = 3.0;      // M3: 2 calibration stops + 2 socket clamp screws
pipe_od           = 25.4;     // mounting pipe outer diameter (parametric)

// Collector (WMO 200 cm^2 standard)
collector_area_cm2 = 200;
rim_wall_h        = 26;       // vertical splash wall below knife edge
funnel_wall       = 2.25;     // 5 perimeters
cone_slope_min    = 45;       // deg from horizontal on the STEEPEST meridian
throat_r          = 7;        // spout throat radius
lip_h             = 3;        // drip-former lip below cone apex

// Body / bays (chassis-local z; deck top = 0)
shell_od          = 174;
shell_wall        = 2.25;
bucket_pivot_y    = 14;       // bucket axis (and spout) sit aft of centre
drum_axis_y       = -48;
bulkhead_y        = -26;
deck_z            = 44;       // assembly Z of chassis deck top
bucket_pivot_z    = 38;
drum_axis_z       = 58;

// Tipping bucket. tips_per_count=2: each tip is 0.5 mm (10 mL); the pawl
// advances the register on alternate tips only (single-acting feed - a
// coaxial pawl can only drive one stroke direction), so 2 tips = 1 mm = 1
// count and dial-mm = rain-mm exactly. 0.5 mm/tip matches commercial gauges.
tips_per_count    = 2;
tip_angle_deg     = 14;       // swing each way from level
chamber_len_x     = 70;       // interior x width
chamber_wid_y     = 20;       // interior y depth per chamber
chamber_out_h     = 20;       // outer wall height
divider_h         = 30;       // centre divider height
bucket_wall       = 1.8;
bucket_pin_z      = 8;        // pin height above bucket floor (local)
stop_span_y       = 22;       // calibration stop offset from pivot y

// Register - drums
n_drums           = 4;
drum_od           = 46;
digit_band_w      = 10;
digit_h           = 9;
digit_raise       = 0.6;
ring_teeth        = 20;
sector_teeth      = 2;
pinion_teeth      = 8;        // alternating long/short
gear_module       = 1.8;
ring_band_w       = 3.2;      // channel depth incl. floor web
sector_band_w     = 2.6;
disc_band_w       = 2.2;
cam_band_w        = 3.0;      // snail cam + yoke blade + hammer finger band
band_clr          = 0.5;
cam_r_max         = 7.3;
cam_r_min         = 3.2;
hub_od            = 9;
ratchet_teeth     = 10;
ratchet_r_o       = 20;
ratchet_depth     = 4;
ratchet_band_w    = 6;
track_band_w      = 2.2;      // shallow detent-notch track beside the ratchet
track_r_o         = 17.5;     // track crest radius
track_depth       = 1.2;      // notch depth (shallow => tiny climb torque)
track_phase       = 270;      // notch lattice clocking vs digit lattice
rocker_t          = 3.5;
pawl_t            = 1.3;
detent_leaf_t     = 1.3;

// Register - carry
pinion_angle      = 40;       // deg aft-down from drum axis to pinion centre
disc_notch_deg    = 56;       // relieved arc of locking disc
disc_r            = 5.2;
disc_notch_r      = 1.6;

// Phasing (drum-frame degrees; derivations in place_* notes, then visual-tuned)
// Window = local -90 deg; pinion contact = local ~40 deg; hammer finger
// approach = local ~151 deg. Digit i sits at -90 - 36*i (+ digit_phase trim).
digit_phase       = 0;        // trim: digit 0 centred in window at rest zero
sector_phase      = 58;       // carry sector centred on the 9->0 transit
cam_phase         = 151;      // snail step points at the hammer finger at zero
mesh_phase        = 22.5;     // pinion tooth clocking into the ring gear

// Reset
yoke_pivot_yz     = [-38, 30];   // chassis-local pivot of pinion cage
yoke_swing_deg    = 8;
hammer_pivot_yz   = [-28, 94];
reset_stage1      = 3.0;         // slider travel before hammer nose engages
reset_stroke      = 9.0;
slider_x          = -60;         // slider lane: outboard of the register
slider_z          = 38;          // slider TOP, chassis-local (bar hangs below)

// Base
base_od           = 175;
base_wall         = 2.7;
base_h            = 50;
socket_wall       = 3.15;
socket_h          = 46;
n_fins            = 6;
vent_w            = 12;
vent_h            = 9;

// === DERIVED CONSTANTS ===
ew        = nozzle_diameter * 1.125;   // 0.45
wall4     = 4 * ew;                    // 1.8
fudge     = 0.01;
ef        = 0.4;
$fn       = $preview ? 48 : 96;

orifice_d   = 2 * sqrt(collector_area_cm2 * 100 / PI);   // 159.577
tip_ml      = collector_area_cm2 / 10 / tips_per_count;   // 10 mL = 0.5 mm/tip
shell_id    = shell_od - 2*shell_wall;

// gears
ring_pr     = ring_teeth   * gear_module / 2;   // 18
pin_pr      = pinion_teeth * gear_module / 2;   // 7.2
mesh_offset = ring_pr - pin_pr;                 // 10.8
ring_tip_r  = ring_pr - gear_module;            // 16.2
ring_root_r = ring_pr + 1.25*gear_module;       // 20.25
ring_wall_r = ring_root_r + 0.45;               // 20.7
pin_tip_r   = pin_pr + gear_module;             // 9.0
pin_root_r  = pin_pr - 1.25*gear_module;        // 4.95
pin_seat_r  = disc_r + 0.3;                     // concave seat radius
sleeve_od   = 5.2;
drum_r      = drum_od/2;

// drum axial stack (drum-local z, printed cam-flank-down):
//   [cam 3.0][clr][disc 2.2][clr][sector 2.6][digits 10][ring block 3.6]
cam_z0    = 0;
disc_z0   = cam_z0 + cam_band_w + band_clr;
sector_z0 = disc_z0 + disc_band_w + band_clr;
digit_z0  = sector_z0 + sector_band_w;                    // 8.8
rb_w      = ring_band_w + 0.4;                            // 3.6 block width
ringb_z0  = digit_z0 + digit_band_w;
drum_h    = ringb_z0 + rb_w;
drum_pitch = drum_h + 3.4;                                // air for pinion float+clr

// register global x (digit band left edge of drum n; drum0 = units at +x)
drum0_x     = 28;
function drum_x(n) = drum0_x - drum_pitch*n;
// channel mouth (top of ring block) of drum n:
function mouth_x(n) = drum_x(n) + digit_band_w + rb_w;
ratchet_x0  = drum0_x + digit_band_w + 0.4;               // ratchet on units drum
rocker_x0   = ratchet_x0 + ratchet_band_w + track_band_w + 0.8;
jr_tower_x  = rocker_x0 + rocker_t + 0.5 + 2.8 + 1.4;   // clears the crank plate
jl_tower_x  = drum_x(n_drums-1) - digit_z0 - 4.5;
shaft_len   = (jr_tower_x + 3 + 3) - (jl_tower_x - 3);

// detent spring (separate part; geometry shared with the chassis saddle)
detent_t     = 1.6;                                   // lamina thickness
detent_nub_x = ratchet_x0 + ratchet_band_w + track_band_w/2;  // track centre
detent_foot_x= 36;                                    // saddle centreline (x)
detent_nub_l = 4.2;    // nub cone length: lamina must clear the ratchet crests

// pinion i sits between drum i and drum i+1: ring band into drum i+1's channel,
// lock+sector bands mating drum i's disc+sector, slim sleeve across cam band.
pin_ring_w  = ring_band_w - 0.4;                          // 2.8 in-channel band
pinion_z0g  = 0.3;      // ring band bottom sits this far above channel floor
function pinion_x(i) = mouth_x(i+1) - ring_band_w + pinion_z0g;
pinion_len  = drum_x(0) - pinion_x(0) - 0.3;              // to sector top - clr
pin_lock_z  = pinion_len - (digit_z0 - disc_z0) + 0.0;    // lock band start (local)
pin_sect_z  = pinion_len - sector_band_w - 0.2;           // sector band start
pin_cy      = drum_axis_y + mesh_offset*sin(pinion_angle);
pin_cz      = drum_axis_z - mesh_offset*cos(pinion_angle);

// crank / rocker pin-and-slot kinematics (chassis-local yz).
// The bucket crank carries a peg that rides in an open radial slot on the
// rocker arm - classic pin-and-slot lever coupling: one joint, and the radial
// slide absorbs the arc mismatch and all over-travel. The peg sits on the line
// between the two axes; the split of that distance sets the stroke ratio.
target_stroke = 50;      // deg at the ratchet (36 + generous indexing margin)
axes_v      = [drum_axis_y - bucket_pivot_y, drum_axis_z - bucket_pivot_z];
axes_d      = norm(axes_v);                               // ~65.1
slot_r      = axes_d / (1 + target_stroke/(2*tip_angle_deg));  // rocker side ~26.8
crank_r_eff = axes_d - slot_r;                            // crank side ~38.3
peg_yz      = [bucket_pivot_y + crank_r_eff*axes_v[0]/axes_d,
               bucket_pivot_z + crank_r_eff*axes_v[1]/axes_d]; // [-22.5, 49.8]
rocker_pose_deg = atan2(peg_yz[1]-drum_axis_z, peg_yz[0]-drum_axis_y);
stroke_deg  = 2*tip_angle_deg * crank_r_eff / slot_r;     // ~40

// yoke geometry
yoke_blade_l = norm([pin_cy-yoke_pivot_yz[0], pin_cz-yoke_pivot_yz[1]]);
yoke_blade_ang = atan2(pin_cy-yoke_pivot_yz[0], pin_cz-yoke_pivot_yz[1]);
yoke_x0      = jl_tower_x + 0.8;          // yoke bar left end (global x)
hammer_x0    = jl_tower_x + 0.5;          // hammer bar left end (global x)
// hammer rake: pivot -> cam-contact direction, degrees from straight down
hammer_rake  = atan2(-(drum_axis_y - hammer_pivot_yz[0]),
                     hammer_pivot_yz[1] - (drum_axis_z + cam_r_min + 1));
hammer_reach = norm([drum_axis_y - hammer_pivot_yz[0],
                     hammer_pivot_yz[1] - (drum_axis_z + cam_r_min + 1)]);
// slider face positions (global y)
slider_y0    = -shell_od/2 + shell_wall + 2.5;   // button face at rest
yoke_tail_y  = yoke_pivot_yz[0] + 2;             // yoke tail contact face
hammer_tail_y= hammer_pivot_yz[0] - 3;           // hammer tail contact face
nose_len     = 8;

// funnel / heights (assembly z)
cone_top_r    = orifice_d/2;
crest_z       = deck_z + bucket_pivot_z + (divider_h - bucket_pin_z);  // divider top
spout_lip_z   = crest_z + 12;                       // drip point
cone_drop     = (cone_top_r + abs(bucket_pivot_y) - throat_r) * tan(cone_slope_min);
body_top_z    = spout_lip_z + lip_h + cone_drop;
body_h        = body_top_z - base_h;
win_z0        = deck_z + drum_axis_z - 8;
win_z1        = deck_z + drum_axis_z + 8;

// === CONTRACTS (acceptance criteria as asserts) ===
assert(abs(PI*orifice_d*orifice_d/4 - collector_area_cm2*100) < collector_area_cm2,
       "collector area must equal spec within 0.1%");
assert(360*sector_teeth/ring_teeth == 36, "carry must be exactly one digit (36deg)");
assert(pinion_teeth % 4 == 0, "pinion needs alternating long/short teeth");
assert(gear_module >= 1.2, "FDM minimum gear module");
assert(mesh_offset - sleeve_od/2 > cam_r_max + 0.4, "pinion sleeve must clear cams");
assert(disc_r > pin_root_r + 0.2 && pin_tip_r > mesh_offset - disc_r + 0.5,
       "locking disc must block long teeth but clear roots");
assert(tip_ml >= 8, "tip volume too small to drive the counter");
// v2: chambers are open wedges (no tall outer wall). At the receiving tilt
// (rest + 2*tip_angle) water pools between the divider and the raised floor;
// capacity = width-capped wedge cross-section x length, vs 1.2x tip volume.
floor_slope = atan((9-5)/chamber_wid_y);
recv_slope  = floor_slope + 2*tip_angle_deg;
recv_cap    = (chamber_wid_y*(divider_h-8)
               - 0.5*chamber_wid_y*chamber_wid_y*tan(recv_slope)) * chamber_len_x;
assert(recv_cap > tip_ml*1000*1.2,
       "receiving-tilt wedge must hold >=1.2x the tip volume");
assert(tips_per_count * tip_ml * 10 == collector_area_cm2,
       "tips_per_count x tip volume must equal exactly 1 mm of rain");
assert(shell_od <= build_xyz && body_h <= build_xyz, "body exceeds printer");
assert(cone_drop + rim_wall_h + lip_h <= build_xyz, "funnel exceeds printer");
assert(2*sqrt(pow(shell_id/2,2) - pow(abs(drum_axis_y),2)) >
       (jr_tower_x + 3) - (jl_tower_x - 3) + 6, "register too wide for shell chord");
assert(reset_stage1 >= 2.5, "yoke must disengage before hammers strike");
assert(stroke_deg > 38 && stroke_deg < 68, "rocker stroke must index exactly 1 tooth");
assert(win_z1 - win_z0 <= 2*PI*drum_r*36/360 + 4, "window must show one digit row");
assert(crest_z + 8 < spout_lip_z, "spout must clear the tipping divider crest");
assert(slot_r > ratchet_r_o + 2.5,
       "crank peg slot radius too close to the ratchet (axially separate, but keep margin)");
echo(str("== Fable gauge: orifice Ø",orifice_d,", ",tip_ml," mL/tip, pitch ",
         drum_pitch,", pinion_len ",pinion_len,", stroke ",stroke_deg,
         " deg, crank ",crank_r_eff,"/",slot_r,", body H ",body_h,
         ", top-of-rim Z ",body_top_z+rim_wall_h));
echo(str("== BOM: Ø3 steel rod ~",ceil((shaft_len+chamber_len_x+26)/10)*10,
         " mm (drum shaft ",shaft_len,", bucket pin ",chamber_len_x+24,
         "); 2x M3x12 (calibration stops); 2x M3x10 (pipe clamp)"));

// === UTILITY MODULES ===
module tube(od, id, h) {
    difference() {
        cylinder(d=od, h=h);
        translate([0,0,-fudge]) cylinder(d=id, h=h+2*fudge);
    }
}
module ef_cyl(d, h) {   // elephant-foot chamfered cylinder
    cylinder(d1=d-2*ef, d2=d, h=ef+fudge);
    translate([0,0,ef]) cylinder(d=d, h=h-ef);
}
module teardrop_x(d, l) {   // horizontal hole along X, self-supporting crown
    // v2: the inner rotate points the crown at local -x, which the [0,90,0]
    // maps to global +Z (v1 left it at +Y = sideways, so bore tops sagged)
    rotate([0,90,0]) rotate([0,0,90]) linear_extrude(l, center=true)
        union() { circle(d=d); polygon([[-d/2,0],[d/2,0],[0,d*0.7]]); }
}
// internal-ring-gear tooth set (teeth point inward from ring_wall_r)
module ring_teeth_2d(nt=ring_teeth, bl=gear_backlash) {
    pa = 360/nt;
    ha_r = pa/2*0.52 - (bl/ring_root_r)*90/PI;
    ha_t = pa/2*0.30 - (bl/ring_tip_r)*90/PI;
    for (i=[0:nt-1]) rotate([0,0,i*pa])
        polygon([[ring_wall_r*cos(ha_r),  ring_wall_r*sin(ha_r)],
                 [ring_tip_r*cos(ha_t),   ring_tip_r*sin(ha_t)],
                 [ring_tip_r*cos(ha_t),  -ring_tip_r*sin(ha_t)],
                 [ring_wall_r*cos(ha_r), -ring_wall_r*sin(ha_r)]]);
}
module ext_tooth2d(r0, r1, ha0, ha1) {
    polygon([[r0*cos(ha0), r0*sin(ha0)], [r1*cos(ha1), r1*sin(ha1)],
             [r1*cos(ha1), -r1*sin(ha1)], [r0*cos(ha0), -r0*sin(ha0)]]);
}
// pinion tooth sets; kind 0 = all teeth (ring band), 1 = long + concave disc
// seats (lock band), 2 = long only (sector band)
module pinion_2d(kind=0) {
    pa = 360/pinion_teeth;
    ha_r = pa/2*0.55 - (gear_backlash/pin_root_r)*90/PI;
    ha_t = pa/2*0.28 - (gear_backlash/pin_tip_r)*90/PI;
    union() {
        circle(r=pin_root_r);
        for (i=[0:pinion_teeth-1]) {
            long = (i%2==0);
            if (kind==0)
                rotate([0,0,i*pa]) ext_tooth2d(pin_root_r, pin_tip_r, ha_r, ha_t);
            else if (long)
                rotate([0,0,i*pa])
                    ext_tooth2d(pin_root_r, pin_tip_r,
                                kind==1 ? ha_r*0.8 : ha_r, kind==1 ? ha_t*0.7 : ha_t);
            else if (kind==1)
                rotate([0,0,i*pa]) difference() {
                    ext_tooth2d(pin_root_r, pin_seat_r+1.0, ha_r, ha_r*0.9);
                    translate([mesh_offset,0]) circle(r=disc_r+0.3);
                }
        }
    }
}
// snail cam: radius falls from cam_r_max just behind the step to cam_r_min at
// the step; pressing a follower drives the drum FORWARD (+rotation) to zero.
module snail_2d() {
    pts = concat([for (a=[2:4:358])
                    let(r = cam_r_min + (cam_r_max-cam_r_min)*a/360)
                    [r*cos(-a), r*sin(-a)]],   // negative: forward = count sense
                 [[cam_r_min*cos(-2), cam_r_min*sin(-2)]]);
    polygon(pts);
}
// ratchet wheel: nt saw teeth; drive faces push the wheel in +rotation
module ratchet_2d(nt=ratchet_teeth) {
    ri = ratchet_r_o - ratchet_depth;
    pa = 360/nt;
    union() {
        circle(r=ri);
        for (i=[0:nt-1]) rotate([0,0,i*pa])
            polygon([[ri*cos(8), ri*sin(8)],
                     [ratchet_r_o*cos(1.5), ratchet_r_o*sin(1.5)],
                     [ri*cos(-(pa-10)), -ri*sin(pa-10)]]);
    }
}

// === PART MODULES (each in PRINT orientation) ===

// ---- FUNNEL (print = use orientation; spout lip ring on the bed) ----
// local z0 = drip lip bottom; cone widens upward; knife edge topmost.
module funnel() {
    land_od  = shell_id - 0.7;           // spigot engaging body ID
    land_h   = 10;
    flare_od = shell_od + 4;             // rain-shedding flange over body rim
    kw       = funnel_wall;
    rim_z    = lip_h + cone_drop;        // cone-top ring level
    total_h  = rim_z + rim_wall_h;
    ty       = bucket_pivot_y;           // throat over the bucket pivot
    difference() {
        union() {
            // drip lip + offset cone (outer)
            hull() {
                translate([0,ty,0]) cylinder(r=throat_r+kw, h=lip_h+fudge);
                translate([0,0,rim_z-fudge]) cylinder(r=cone_top_r+kw, h=fudge);
            }
            // flare flange + rim wall
            translate([0,0,rim_z-6]) cylinder(r1=cone_top_r+kw, r2=flare_od/2, h=6);
            translate([0,0,rim_z-fudge]) cylinder(r1=flare_od/2, r2=cone_top_r+kw, h=6);
            translate([0,0,rim_z+6-2*fudge]) cylinder(r=cone_top_r+kw, h=rim_wall_h-6);
            // spigot land skirt (below flare; lowest edge lands on cone outer)
            translate([0,0,rim_z-land_h]) tube(land_od, land_od-2*kw, land_h);
        }
        // throat + cone void + rim bore
        translate([0,ty,-fudge]) cylinder(r=throat_r, h=lip_h+2*fudge);
        hull() {
            translate([0,ty,lip_h]) cylinder(r=throat_r, h=fudge);
            translate([0,0,rim_z]) cylinder(r=cone_top_r, h=fudge);
        }
        translate([0,0,rim_z-fudge]) cylinder(r=orifice_d/2, h=rim_wall_h+2*fudge);
        // knife edge: outside bevel converging PAST the bore radius, so bevel
        // and bore intersect in a true chamfered edge exactly at orifice_d
        // (v1 left a 0.3 flat land on top, which printed as a square rim)
        translate([0,0,total_h-7])
            difference() {
                cylinder(r=cone_top_r+kw+flare_od, h=7+fudge);
                translate([0,0,-fudge])
                    cylinder(r1=cone_top_r+kw+0.3, r2=orifice_d/2-0.3, h=7+3*fudge);
            }
        // 3 bayonet L-slots in the spigot land (engage body top lugs)
        for (a=[0:120:240]) rotate([0,0,a]) {
            // vertical entry
            translate([0,0,rim_z-land_h-fudge]) rotate([0,0,-4]) rotate_extrude(angle=8)
                translate([land_od/2-kw-1.2, 0]) square([kw+1.2+fudge, 6.5]);
            // horizontal lock groove
            rotate([0,0,2]) rotate_extrude(angle=14)
                translate([land_od/2-kw-1.2, rim_z-land_h+3.2]) square([kw+1.2+fudge, 3.4]);
        }
        // screen ledge groove in the cone wall (screen drops onto it)
        translate([0, ty*0.55, lip_h + (44-throat_r)*tan(cone_slope_min)])
            tube(94, 88, 2.6);
    }
}

// ---- SCREEN (printed flat): coarse debris grid on the funnel ledge ----
module screen() {
    tube(87, 81, 2.2);
    intersection() {
        cylinder(d=87, h=2.2);
        union() {
            for (i=[-5:5]) translate([i*8-1, -46, 0]) cube([2, 92, 2.2]);
            for (i=[-5:5]) translate([-46, i*8-1, 0]) cube([92, 2, 2.2]);
        }
    }
}

// ---- BODY SHELL (print = use orientation) ----
// local z0 = bottom (slides over base upstand); window faces -y.
module body() {
    win_w  = (drum0_x + digit_band_w + ratchet_band_w + 2) - (drum_x(n_drums-1) - digit_z0 - 2);
    win_xc = (drum0_x + digit_band_w + ratchet_band_w + 2 + drum_x(n_drums-1) - digit_z0 - 2)/2;
    wz0    = win_z0 - base_h;
    wz1    = win_z1 - base_h;
    ap_w   = digit_band_w + 2.4;   // per-digit aperture width
    difference() {
        union() {
            tube(shell_od, shell_id, body_h);
            // eave over the window band (45 deg underside, integral awning)
            translate([0,0,wz1+2]) intersection() {
                difference() {
                    union() {
                        cylinder(d1=shell_od, d2=shell_od+14, h=7);
                        translate([0,0,7-fudge]) cylinder(d1=shell_od+14, d2=shell_od, h=5);
                    }
                    translate([0,0,-fudge]) cylinder(d=shell_id, h=12+2*fudge);
                }
                translate([win_xc-win_w/2-8, -shell_od/2-14, 0]) cube([win_w+16, 60, 12]);
            }
        }
        // four digit apertures with 45 deg pitched (corbelled) heads; the frame
        // ribs between them (mullions) hide the carry machinery - meter style
        for (n=[0:n_drums-1])
            translate([drum_x(n) + digit_band_w/2 - ap_w/2, 0, 0]) {
                translate([0, -shell_od/2-6, wz0]) cube([ap_w, 30, wz1-wz0]);
                translate([0, -shell_od/2-6, wz1-fudge]) rotate([-90,0,0])
                    linear_extrude(30) polygon([[0,0],[ap_w,0],[ap_w/2,ap_w/2]]);
            }
        // reset button hole (round, matches slider button face)
        translate([slider_x, -shell_od/2+shell_wall+1, deck_z + slider_z - 5 - base_h])
            rotate([90,0,0]) cylinder(d=15, h=shell_wall+8);
        // bottom bayonet slots (engage base upstand lugs)
        for (a=[30:120:270]) rotate([0,0,a]) {
            translate([0,0,-fudge]) rotate([0,0,-3.5]) rotate_extrude(angle=7)
                translate([shell_id/2-1, 0]) square([shell_wall+2, 6.5]);
            rotate([0,0,1.5]) rotate_extrude(angle=12)
                translate([shell_id/2-1, 3.2]) square([shell_wall+2, 3.4]);
        }
    }
    // top interior lugs (funnel bayonet)
    for (a=[0:120:240]) rotate([0,0,a+6]) rotate_extrude(angle=8)
        translate([shell_id/2-2.4, body_h-5.4])
            polygon([[0,2.6],[2.4,2.6],[2.4,0],[1.2,0]]);
}

// ---- BASE SHELL (print = use orientation; all walls vertical) ----
module base() {
    upstand_od = shell_id - 0.7;
    difference() {
        union() {
            tube(base_od, base_od-2*base_wall, base_h);
            translate([0,0,base_h-fudge]) tube(upstand_od, upstand_od-2*base_wall, 8);
            ef_cyl(pipe_od+2*socket_wall+0.5, socket_h);
            for (a=[0:360/n_fins:359]) rotate([0,0,a])
                translate([pipe_od/2+socket_wall-1, -1.25, 0])
                    cube([base_od/2-base_wall-pipe_od/2-socket_wall, 2.5, deck_z-4.2]);
            translate([0,0,deck_z-8]) tube(base_od-2*base_wall+fudge, base_od-2*base_wall-7, 3.8);
        }
        translate([0,0,-fudge]) cylinder(d=pipe_od+0.5, h=socket_h+2*fudge);
        // clamp screws (teardrop crowns, self-tap M3)
        for (a=[90,270]) rotate([0,0,a])
            translate([0, pipe_od/2+socket_wall/2+1, 18]) rotate([0,0,90])
                rotate([0,0,0]) teardrop_x(2.7, pipe_od+2*socket_wall+14);
        // gothic drainage vents
        for (a=[45:90:315]) rotate([0,0,a]) translate([base_od/2-base_wall-6, 0, 0])
            rotate([90,0,90]) translate([-vent_w/2, -fudge, 0]) linear_extrude(base_wall+12)
                polygon([[0,0],[vent_w,0],[vent_w,vent_h-vent_w/2],
                         [vent_w/2,vent_h],[0,vent_h-vent_w/2]]);
    }
    for (a=[30:120:270]) rotate([0,0,a]) rotate_extrude(angle=6)
        translate([upstand_od/2-fudge, base_h+1.4]) square([2.2, 2.8]);
}

// ---- CHASSIS (print = use orientation; deck bottom on bed) ----
// local z0 = deck bottom; deck top = 4. All chassis-local z below are +4.
module chassis() {
    deck_r = (shell_id-0.7)/2 - base_wall - 0.5;
    dt = 4;
    difference() {
        union() {
            ef_cyl(2*deck_r, dt);
            for (sx=[-1,1]) translate([sx*(chamber_len_x/2+7), bucket_pivot_y, 0])
                bucket_tower();
            for (sy=[-1,1]) translate([0, bucket_pivot_y+sy*stop_span_y, 0])
                cylinder(d=9, h=12);
            translate([-66, bulkhead_y-1.2, 0]) cube([132, 2.4, dt+70]);
            // detent saddle: bulkhead-top extension, 45deg+ underside rearward
            hull() {
                translate([detent_foot_x-7.2, bulkhead_y-1.2, dt+70])
                    cube([14.4, 2.4, 16.5]);
                translate([detent_foot_x-7.2, bulkhead_y+13.1, dt+82])
                    cube([14.4, 1.4, 4.5]);
            }
            // drip lip over the rocker/crank bulkhead slot (45deg underside)
            hull() {
                translate([rocker_x0-5, bulkhead_y+1.2-fudge, dt+74]) cube([20, fudge, 4]);
                translate([rocker_x0-5, bulkhead_y+5.2, dt+78]) cube([20, fudge, fudge]);
            }
            translate([jl_tower_x-3, 0, 0]) journal_tower(false);
            translate([jr_tower_x, 0, 0]) journal_tower(true);
            for (tx=[jl_tower_x-3, jr_tower_x]) translate([tx, yoke_pivot_yz[0], 0])
                yoke_boss();
            slider_rails();
        }
        for (sy=[-1,1]) translate([0, bucket_pivot_y+sy*stop_span_y, 2])
            cylinder(d=2.5, h=12);
        for (sx=[-1,1], sy=[-1,1])
            translate([sx*18, bucket_pivot_y+sy*(chamber_wid_y+5), -fudge])
                cylinder(d=11, h=dt+2*fudge);
        // rocker-arm + crank-blade passage through the bulkhead (high, small)
        translate([rocker_x0-4, bulkhead_y-1.2-fudge, dt+40]) cube([16, 2.4+2*fudge, 34]);
        // detent saddle channel (opens rearward into the bucket bay: the
        // detent spring slides in before the bucket is installed)
        translate([detent_foot_x-5.85, bulkhead_y+2, dt+78.5])
            cube([11.7, 12.3, detent_t+0.35]);
        // slider passage through bulkhead (return leaf rides its rear face)
        translate([slider_x-4.5, bulkhead_y-1.2-fudge, dt+slider_z-11])
            cube([9, 2.4+2*fudge, 12.5]);
    }
    // detent retention bump: foot clicks past it on insertion (ramp on the
    // rear/opening side), then the steep front face blocks creep back out.
    translate([detent_foot_x-3, 0, 0]) rotate([90,0,90]) linear_extrude(6)
        polygon([[bulkhead_y+13.9, dt+78.5], [bulkhead_y+12.7, dt+78.5],
                 [bulkhead_y+12.7, dt+78.95], [bulkhead_y+13.5, dt+78.95]]);
}
module bucket_tower() {
    difference() {
        union() {
            translate([-2, -8, 0]) cube([4, 16, 4+bucket_pivot_z+5]);
            for (sy=[-1,1]) translate([-1, sy>0 ? 8-fudge : -14+fudge, 0])
                cube([2, 6, 14]);   // toe gussets
        }
        // V-seat opening up (pin rests in the vee)
        translate([0, 0, 4+bucket_pivot_z+2.8]) rotate([0,90,0])
            linear_extrude(4+2*fudge, center=true) rotate(45) square(5.6, center=true);
        // clip notches
        for (sy=[-1,1]) translate([-2-fudge, sy*5.4-0.8, 4+bucket_pivot_z-3])
            cube([4+2*fudge, 1.6, 12]);
    }
}
module journal_tower(right) {
    difference() {
        union() {
            translate([0, drum_axis_y-16, 0]) cube([3, 34, 4+drum_axis_z+10]);
            translate([0, hammer_pivot_yz[0]-9, 0]) cube([3, 18, 4+hammer_pivot_yz[1]+7]);
        }
        // shaft journal slot, open top
        translate([-fudge, drum_axis_y, 4+drum_axis_z]) hull() {
            rotate([0,90,0]) cylinder(d=pin_d+tol_journal, h=3+2*fudge);
            translate([0,0,14]) rotate([0,90,0]) cylinder(d=pin_d+tol_journal, h=3+2*fudge);
        }
        for (sy=[-1,1]) translate([-fudge, drum_axis_y+sy*(pin_d/2+1.6)-0.8, 4+drum_axis_z-3])
            cube([3+2*fudge, 1.6, 12]);
        // hammer pivot hole
        translate([-fudge, hammer_pivot_yz[0], 4+hammer_pivot_yz[1]])
            rotate([0,90,0]) cylinder(d=4.5, h=3+2*fudge);
        // open-top slot to drop the hammer stub in
        translate([-fudge, hammer_pivot_yz[0]-2.25, 4+hammer_pivot_yz[1]])
            cube([3+2*fudge, 4.5, 8]);
    }
}
module yoke_boss() {
    difference() {
        translate([-0.5, -5, 0]) cube([4, 10, 4+yoke_pivot_yz[1]+5]);
        translate([-0.5-fudge, 0, 4+yoke_pivot_yz[1]]) rotate([0,90,0])
            cylinder(d=4.5, h=4+2*fudge);
        translate([-0.5-fudge, -2.25, 4+yoke_pivot_yz[1]])
            cube([4+2*fudge, 4.5, 7]);   // drop-in slot
    }
}
module slider_rails() {
    // closed guide loops; the slider bar (5.2 x 10) hangs through the eyes
    for (yy=[-66, -44]) translate([slider_x, yy, 0]) difference() {
        translate([-6.5, -2.5, 0]) cube([13, 5, 4+slider_z+2.2]);
        translate([-3, -2.5-fudge, 4+slider_z-10.4]) cube([6, 5+2*fudge, 10.8]);
    }
}

// ---- BUCKET (printed chambers-up) ----
// local: pivot axis along X at y=0, z=bucket_pin_z; +y chamber = rear.
module bucket() {
    ow = bucket_wall;
    bl = chamber_len_x + 2*ow;
    bw = 2*chamber_wid_y + 2*ow + 2.4;
    lip_z = 9 + 1.8;   // outer wall = floor's outer edge + a small stiffening lip
    difference() {
        union() {
            difference() {
                union() {
                    // shell: open-wedge profile - outer walls stop just above
                    // the floor's pour edge, rising to full height at centre
                    translate([-bl/2, 0, 0]) rotate([90,0,90]) linear_extrude(bl)
                        polygon([[-bw/2, 0], [bw/2, 0], [bw/2, lip_z],
                                 [6, chamber_out_h], [-6, chamber_out_h],
                                 [-bw/2, lip_z]]);
                    translate([-bl/2, -1.2, 0]) cube([bl, 2.4, divider_h]);
                    // pivot boss slabs (rectangular: support-free)
                    for (sx=[-1,1]) scale([sx,1,1])
                        translate([bl/2-fudge, -6, 0]) cube([4.4, 12, 14]);
                    // crank drive tab (v2: INSIDE the bore difference - in v1
                    // it was added after, plugging the right bore exit!)
                    translate([chamber_len_x/2+bucket_wall-fudge, -12, 0])
                        cube([2.8, 18, bucket_pin_z+30]);
                }
                for (sy=[-1,1]) scale([1,sy,1]) translate([-chamber_len_x/2, 1.2, 0])
                    chamber_void();
            }
            // pivot rib: octagonal boss sealing the bore through the water
            // space (v1's bore broke through both divider faces = the leak
            // slot). 45-deg facets print support-free; proud of the floor.
            translate([-bl/2, 0, bucket_pin_z]) rotate([0,90,0]) rotate([0,0,22.5])
                cylinder(r=4.6, h=bl, $fn=8);
        }
        translate([0,0,bucket_pin_z]) teardrop_x(pin_d+tol_journal, bl+40);
    }
}
module chamber_void() {
    hull() {   // floor rises toward the outer lip: drains fully when tipped
        translate([0, 0, 5]) cube([chamber_len_x, fudge, divider_h]);
        translate([0, chamber_wid_y-fudge, 9]) cube([chamber_len_x, fudge, divider_h]);
    }
}
// ---- CRANK PLATE (separate part) ----
// Modeled in USE orientation (yz about the bucket pivot, thickness along x):
// a blade plate in the rocker plane carrying the drive peg (-x, into the
// rocker slot) plus a lap boss whose pocket drops over the bucket's tab fin.
// part="crank" exports it rotated flat (boss + peg up) for printing.
crank_px0 = rocker_x0 + rocker_t + 0.5;      // plate inner face (global x)
module xcyl(x, y, z, d, l) { translate([x,y,z]) rotate([0,90,0]) cylinder(d=d, h=l); }
module crank_use() {
    py = peg_yz[0] - bucket_pivot_y;                  // ~ -36.5
    pz = peg_yz[1] - bucket_pivot_z;                  // ~ +11.8 rel pivot
    tab_x = chamber_len_x/2 + bucket_wall;            // 36.8
    difference() {
        union() {
            // blade in the rocker plane: boss zone down-forward to the peg
            hull() {
                xcyl(crank_px0, -3, 20, 12, 2.8);
                xcyl(crank_px0, py, pz, 9, 2.8);
            }
            // lap boss back over the tab (sits high: clears pivot towers/pin)
            translate([tab_x-0.4, -13.6, 9])
                cube([crank_px0-tab_x+0.4+2.8, 21.2, 23]);
            // drive peg, 45 deg cone base
            xcyl(crank_px0-4.8, py, pz, 4.2, 4.8+fudge);
            translate([crank_px0+fudge, py, pz]) rotate([0,-90,0])
                cylinder(d1=7, d2=4.2, h=1.4);
        }
        // pocket for the tab fin: enters from the boss underside (drop-on)
        difference() {
            translate([tab_x-0.4-fudge, -12.35, 9-fudge]) cube([3.55, 18.7, 21.5]);
            // crush rib: light interference grips the tab (review fix - the
            // lap joint needs positive retention against reversing loads)
            translate([tab_x+2.55, -3.2, 9]) cylinder(d=1.0, h=21.6);
        }
    }
}
module crank() {   // print orientation: plate flat on bed, boss + peg up
    translate([0, 0, crank_px0+2.8]) rotate([0,90,0]) crank_use();
}

// ---- DRUMS (printed cam-flank-down, axis vertical) ----
module drum_common() {
    tube(hub_od, pin_d+tol_journal, drum_h);
    // snail cam (reset)
    translate([0,0,cam_z0]) linear_extrude(cam_band_w) rotate([0,0,cam_phase])
        difference() { snail_2d(); circle(d=pin_d+tol_journal); }
    // locking disc with relieved notch over the carry window
    translate([0,0,disc_z0]) linear_extrude(disc_band_w) difference() {
        circle(r=disc_r);
        rotate([0,0,sector_phase]) polygon(
            [[0,0],[3*disc_r*cos(disc_notch_deg/2), 3*disc_r*sin(disc_notch_deg/2)],
             [3*disc_r*cos(disc_notch_deg/2), -3*disc_r*sin(disc_notch_deg/2)]]);
        circle(d=pin_d+tol_journal);
    }
    // spokes disc joins hub to sector flange + digit rim
    translate([0,0,sector_z0]) tube(drum_od-2, hub_od-fudge, 2.2);
    // sector band: guard flange + EXACTLY two carry teeth (teeth shifted half
    // a pitch so the +/-19 deg wedge captures two whole teeth, never a third)
    translate([0,0,sector_z0]) linear_extrude(sector_band_w) {
        difference() { circle(r=drum_r); circle(r=ring_wall_r+0.35); }
        rotate([0,0,sector_phase]) intersection() {
            rotate([0,0,9]) ring_teeth_2d();
            polygon([[0,0],[60*cos(19),60*sin(19)],[60,0],[60*cos(19),-60*sin(19)]]);
        }
    }
    // digit band
    translate([0,0,digit_z0]) tube(drum_od, drum_od-2*wall4, digit_band_w);
    translate([0,0,digit_z0+digit_band_w/2-1.1]) tube(drum_od-2, hub_od-fudge, 2.2);
    // digits emboss on the rim. The glyph is constructed at local -90 deg (the
    // window direction); rotating by -36*i stacks the wheel so counting
    // rotation (+local z) rolls 0,1,2,... into view in order. Glyph frame:
    // baseline -> +z (drum axis), up -> -x, normal -> -y (radial out) - reads
    // upright through the window after the drum's 90 deg assembly rotation.
    for (i=[0:9]) rotate([0,0, digit_phase - i*36])
        translate([0, -(drum_r-0.5), digit_z0+digit_band_w/2])
            rotate([0,-90,0]) rotate([90,0,0])
                linear_extrude(digit_raise+0.5)
                    text(str(i), size=digit_h, halign="center", valign="center",
                         font="Liberation Sans:style=Bold");
}
module drum_std() {
    drum_common();
    translate([0,0,ringb_z0]) {
        tube(drum_od, 2*ring_wall_r+0.8, rb_w);                     // channel outer wall
        linear_extrude(0.4+fudge) difference() {                    // channel floor web
            circle(r=ring_wall_r+0.6); circle(r=ring_tip_r-1.5); }
        translate([0,0,0.4]) linear_extrude(rb_w-0.4) rotate([0,0,mesh_phase])
            ring_teeth_2d();
        linear_extrude(rb_w) difference() {                          // hub continues
            circle(d=hub_od); circle(d=pin_d+tol_journal); }
    }
}
module drum_units() {
    drum_common();
    translate([0,0,ringb_z0]) {
        linear_extrude(ratchet_band_w) difference() {
            ratchet_2d(); circle(d=pin_d+tol_journal); }
        // shallow 10-notch detent track (outboard of the ratchet): the frame
        // detent's nub rests in a notch at every digit position - alignment +
        // anti-reverse - at ~1/10 the climb torque of riding the deep ratchet
        translate([0,0,ratchet_band_w-fudge]) linear_extrude(track_band_w+fudge)
            difference() {
                rotate([0,0,track_phase + digit_phase]) track_2d();
                circle(d=pin_d+tol_journal);
            }
    }
}
module track_2d() {
    difference() {
        circle(r=track_r_o);
        for (i=[0:9]) rotate([0,0,i*36])
            translate([track_r_o+0.4, 0]) rotate([0,0,45])
                square((track_depth+0.4)*sqrt(2), center=true);
    }
}

// ---- TRANSFER PINION (printed ring-band-down, axis vertical) ----
module pinion() {
    difference() {
        union() {
            linear_extrude(pin_ring_w) pinion_2d(0);
            translate([0,0,pin_ring_w-fudge])
                cylinder(d=sleeve_od, h=pin_lock_z-pin_ring_w+2*fudge);
            translate([0,0,pin_lock_z]) linear_extrude(disc_band_w) pinion_2d(1);
            translate([0,0,pin_lock_z+disc_band_w-fudge])
                cylinder(d=sleeve_od, h=pin_sect_z-(pin_lock_z+disc_band_w)+2*fudge);
            translate([0,0,pin_sect_z]) linear_extrude(pinion_len-pin_sect_z) pinion_2d(2);
        }
        translate([0,0,-fudge]) cylinder(d=2.4, h=pinion_len+2*fudge); // lightening bore
    }
}

// ---- YOKE (pinion cage; printed flat, blades in plane) ----
// local: bar along +x from 0, pivot line at (y=0, z=2); blades extend +y with a
// C-saddle cradling each pinion sleeve at the cam band. Assembly stands it up so
// local +y points from the pivot toward the pinion axis.
module yoke() {
    bar_l = jr_tower_x - 0.8 - yoke_x0;
    saddle_id = sleeve_od + 2*tol_slide;
    union() {
        difference() {
            translate([0, -4, 0]) cube([bar_l, 8, 4]);
            // relief under blades keeps bar light
        }
        // pivot stubs into the chassis yoke bosses
        translate([-4+fudge, 0, 2]) rotate([0,90,0]) cylinder(d=4.2, h=4);
        translate([bar_l-fudge, 0, 2]) rotate([0,90,0]) cylinder(d=4.2, h=4);
        // blades at each cam-band gap
        for (i=[0:n_drums-2])
            translate([drum_x(i) - digit_z0 + 0.3 - yoke_x0, 4-fudge, 0]) {
                cube([cam_band_w-0.6, yoke_blade_l-4-saddle_id/2, 4]);
                translate([(cam_band_w-0.6)/2, yoke_blade_l-4, 0]) difference() {
                    cylinder(d=saddle_id+2.7, h=4);
                    translate([0,0,-fudge]) cylinder(d=saddle_id, h=4+2*fudge);
                    // opening rotated ~30 deg from blade axis (toward drum axis)
                    rotate([0,0,60]) translate([-saddle_id/2-1.5, 0, -fudge])
                        cube([saddle_id+3, saddle_id, 4+2*fudge]);
                }
            }
        // tail lever above the pivot; slider nose 1 pushes it (+y in use)
        translate([slider_x - yoke_x0 - 6, 4-fudge, 0])
            cube([12, yoke_pivot_yz[1] > 0 ? 18 : 18, 4]);
    }
}

// ---- ROCKER (printed flat; pawl flexures on a raised band, link hole in arm) ----
// local: hub at origin, plate z[0,rocker_t]; link arm along +y with a slotted
// hole; pawl band raised +z (faces the ratchet in assembly).
module rocker() {
    slot_w = 4.2 + 2*0.3;   // crank peg dia + clearance
    difference() {
        union() {
            cylinder(d=13, h=rocker_t);
            translate([-5, 0, 0]) cube([10, slot_r+7, rocker_t]);
            pawl_arm();
        }
        translate([0,0,-fudge]) cylinder(d=pin_d+tol_journal, h=rocker_t+20);
        // open radial slot: the bucket crank's peg rides here (pin-and-slot
        // drive; radial slide absorbs arc mismatch and over-travel)
        hull() {
            translate([0, slot_r-6.5, -fudge]) cylinder(d=slot_w, h=rocker_t+2*fudge);
            translate([0, slot_r+7.5, -fudge]) cylinder(d=slot_w, h=rocker_t+2*fudge);
        }
    }
}
module pawl_arm() {
    // Single-acting feed: carrier plate (at rocker-plate level, axially beside
    // the wheel) reaches an anchor outside the crests; a long near-tangential
    // flexure beam sweeps back to a hook that dips below the crest circle at
    // the tangent zone (~2.7% strain at full tooth lift). On the drive stroke
    // the hook bears on a tooth's radial face and turns the drum one digit; on
    // the return stroke it flexes out and clicks over the crests. The symmetric
    // hook tip lets the saw form of the wheel decide the one-way direction.
    band = ratchet_band_w - 1;   // raised band riding the ratchet plane
    rotate([0,0,180]) {
        // carrier plate: hub pad -> anchor pad (plate level - clears the wheel
        // axially, so radius doesn't matter here)
        linear_extrude(rocker_t) hull() {
            translate([2,7]) circle(d=7);
            translate([19.5,25]) circle(d=8);
        }
        // anchor riser: spans past the detent track band to the ratchet plane
        translate([16.5, 21.5, 0]) cube([6, 6.5, rocker_t + band + 2.2]);
        // flexure beam + hook (offset so they ride ONLY the ratchet band,
        // clearing the shallow detent track between ratchet and rocker)
        translate([0, 0, rocker_t + 3.2]) linear_extrude(band - 1) union() {
            polygon([[3, 20.6], [20.5, 23.7], [20.5, 25.2], [3, 22.1]]);  // beam
            polygon([[2.6, 22.0], [5.6, 21.6], [5.1, 17.3], [3.3, 17.3]]); // hook
        }
    }
}

// ---- HAMMER (printed flat): pivot bar, 4 snail fingers, slider tail ----
// local: bar along +x, pivot line (y=0,z=2); fingers extend +y (down-forward in
// use, raked by hammer_rake). No return spring: the slider's fork both pushes
// and pulls the tail, so the fingers are held OFF the cams while counting.
module hammer() {
    bar_l = (jr_tower_x - 0.5) - (jl_tower_x + 0.5);
    finger_l = hammer_reach + 1.5;
    tail_l = (hammer_pivot_yz[1] + 4) - (slider_z - 8);   // hangs to slider depth
    union() {
        translate([0, -5, 0]) cube([bar_l, 10, 4]);
        // pivot stubs into the journal-tower holes
        translate([-4+fudge, 0, 2]) rotate([0,-90,0]) cylinder(d=4.2, h=4);
        translate([bar_l-fudge, 0, 2]) rotate([0,90,0]) cylinder(d=4.2, h=4);
        // snail-cam fingers
        for (n=[0:n_drums-1])
            translate([drum_x(n) - digit_z0 + 0.3 - hammer_x0, 5-fudge, 0]) {
                cube([cam_band_w-0.6, finger_l-4, 4]);
                translate([0, finger_l-4-fudge, 0]) cube([cam_band_w-0.6, 4, 5.5]);
            }
        // slider tail (right half of the lane): rides in the slider's fork -
        // pushed to strike, PULLED back on release, so no return spring needed
        translate([slider_x + 0.2 - hammer_x0, 5-fudge, 0]) cube([5.6, tail_l, 4]);
    }
}

// ---- SLIDER incl. button (printed lying on its side) ----
// local: travel along +y, +z up; bar hangs below rail top; button face at y0;
// two half-width noses on top: nose 1 (left) = yoke tail (engaged-stop +
// stage 1), nose 2 (right) = hammer tail (stage 2). Leaf spring at the tail
// presses the bulkhead rear face for return + yoke engagement preload.
module slider() {
    bar_h = 10; bar_w = 5.2;
    n1 = (yoke_tail_y - slider_y0) - nose_len + 0.2;    // contact at stroke ~0
    // hammer fork: tail (4 thick) sits between front + rear posts; rear post
    // strikes after reset_stage1, front post pulls the hammer back on release
    fork_front = (hammer_tail_y - slider_y0) - 2.4;
    fork_rear  = (hammer_tail_y - slider_y0) + 4 + reset_stage1;
    rail_span  = (bulkhead_y - slider_y0) + 16;
    union() {
        translate([-bar_w/2, 0, 0]) cube([bar_w, rail_span, bar_h]);
        translate([0, -2.8, bar_h/2]) rotate([-90,0,0]) cylinder(d=13.8, h=3+fudge);
        // nose 1 (left lane): yoke tail - engaged-stop at rest, stage 1 on push
        translate([-bar_w/2, n1, bar_h-fudge]) cube([2.4, nose_len, 4]);
        // hammer fork (right lane)
        translate([bar_w/2-2.4, fork_front, bar_h-fudge]) cube([2.4, 2.4, 5.5]);
        translate([bar_w/2-2.4, fork_rear, bar_h-fudge]) cube([2.4, 2.4, 5.5]);
        // return leaf: angled cantilever, tip slides on the bulkhead rear face
        translate([bar_w/2-1.2, (bulkhead_y - slider_y0) + 1.5, 0])
            linear_extrude(bar_h) polygon(
                [[0,0],[1.2,0],[8.5,12],[7.2,12.8],[0,2.2]]);
    }
}

// ---- DETENT (separate flat spring; slides into the bulkhead-top saddle) ----
// A thin lamina: foot tab (grips in the saddle channel) + doglegged flexure
// beam reaching forward over the units drum + a nub riding the shallow
// 10-notch track. Gives digit alignment + anti-reverse at ~0.4 N.mm climb
// torque. Printed flat, nub up; installed nub-down (flip about X).
// Use-frame targets: nub at (x centred on the track band, y=drum_axis_y,
// z just above track crest); foot in the saddle over the bulkhead.
// (detent_* dimensions live with the register derived constants.)
module detent() {
    dogleg = detent_nub_x - detent_foot_x;            // beam x-shift to the track
    reach  = (bulkhead_y + 11.5) - drum_axis_y;       // foot y0 -> nub at drum axis
    union() {
        // foot tab + wings (slide into the saddle channel)
        translate([-4, 0, 0]) cube([8, 8, detent_t]);
        translate([-5.6, 2.5, 0]) cube([11.2, 5.5, detent_t]);
        // flexure beam (doglegs sideways to centre the nub over the track)
        linear_extrude(detent_t) polygon(
            [[-2, 8-fudge], [2, 8-fudge], [dogleg+2.2, reach+3],
             [dogleg-2.2, reach+3]]);
        // nub cone (45-deg-ish flanks drop into the shallow V-notches)
        translate([dogleg, reach, detent_t-fudge])
            cylinder(d1=5.6, d2=2.0, h=detent_nub_l+fudge);
    }
}
module place_detent() {
    // flip about X (nub down), foot into the saddle over the bulkhead
    translate([detent_foot_x, bulkhead_y + 11.5,
               fz + drum_axis_z + track_r_o - track_depth + 0.2 + detent_nub_l + detent_t
               + explode*1.3])
        rotate([180,0,0]) detent();
}

// ---- CLIP (retains pins in open V/journal slots; springs over notches) ----
module clip() {
    linear_extrude(3.6) difference() {
        offset(r=1.8) square([7.6, 10], center=true);
        square([7.6, 10], center=true);
        translate([-8, -10.8]) square([16, 8]);
    }
}

// === ASSEMBLY ===
fz = deck_z;   // chassis-local -> assembly z offset (deck top)

module place_funnel() { translate([0, 0, spout_lip_z + explode*2.2]) funnel(); }
module place_screen() {
    translate([0, bucket_pivot_y*0.49,
               spout_lip_z + lip_h + (44-throat_r)*tan(cone_slope_min) + 0.5 + explode*2.6])
        screen();
}
module place_body()    { translate([0, 0, base_h + explode*1.2]) body(); }
module place_base()    { base(); }
module place_chassis() { translate([0, 0, fz - 4 + explode*0.6]) chassis(); }
module place_bucket() {
    translate([0, bucket_pivot_y, fz + bucket_pivot_z + explode*1.0])
        rotate([tip_pose, 0, 0]) translate([0, 0, -bucket_pin_z]) bucket();
}
module place_crank() {
    translate([0, bucket_pivot_y, fz + bucket_pivot_z + explode*1.4])
        rotate([tip_pose, 0, 0]) crank_use();
}
module place_drum(n) {
    translate([drum_x(n) - digit_z0 + explode*(0.4+0.2*n), drum_axis_y, fz + drum_axis_z])
        rotate([0, 90, 0]) if (n==0) drum_units(); else drum_std();
}
module place_pinion(i) {
    translate([pinion_x(i) + explode*0.5, pin_cy, fz + pin_cz])
        rotate([0, 90, 0]) rotate([0, 0, mesh_phase]) pinion();
}
module place_yoke() {
    translate([yoke_x0 + explode*0.9, yoke_pivot_yz[0], fz + yoke_pivot_yz[1]])
        rotate([90 - yoke_blade_ang - (explode>0 ? yoke_swing_deg : 0), 0, 0])
            translate([0, 0, -2]) yoke();
}
module place_rocker() {
    translate([rocker_x0 + rocker_t + explode*0.7, drum_axis_y, fz + drum_axis_z])
        rotate([rocker_pose_deg, 0, 0]) rotate([0, -90, 0]) rocker();
}
hammer_rest_deg = 8;   // rest lift (fork holds fingers clear of the cams)
module place_hammer() {
    translate([hammer_x0 + explode*0, hammer_pivot_yz[0], fz + hammer_pivot_yz[1]])
        rotate([-90 - hammer_rake + hammer_rest_deg, 0, 0])
            translate([0, 0, -2]) hammer();
}
module place_slider() {
    translate([slider_x, slider_y0 - explode*1.6, fz + slider_z - 10]) slider();
}

module assembly() {
    color("SteelBlue")    place_funnel();
    color("LightGrey")    place_screen();
    color("Gainsboro",0.32) place_body();
    color("DimGray")      place_base();
    color("SlateGray")    place_chassis();
    color("Orange")       place_bucket();
    color("OrangeRed")    place_crank();
    for (n=[0:n_drums-1]) color(n==0 ? "Gold" : "Khaki") place_drum(n);
    for (i=[0:n_drums-2]) color("Tomato") place_pinion(i);
    color("YellowGreen")  place_yoke();
    color("MediumPurple") place_rocker();
    color("SpringGreen")  place_detent();
    color("IndianRed")    place_hammer();
    color("Crimson")      place_slider();
}

module plate() {
    translate([26, 0, 0]) drum_units();
    for (i=[1:3]) translate([26+i*56, 0, 0]) drum_std();
    for (i=[0:2]) translate([30+i*26, 58, 0]) pinion();
    translate([115, 62, 0]) rocker();
    translate([165, 62, 0]) crank();
    translate([12, 96, 0]) yoke();
    translate([12, 140, 0]) hammer();
    translate([185, 100, 0]) slider();
    translate([225, 100, 0]) detent();
    for (i=[0:3]) translate([200+i*14, 150, 0]) clip();
    translate([160, 175, 0]) clip(); translate([175, 175, 0]) clip();
}

// === RENDER ===
module mech() {   // mechanism only - inspection/review view
    color("SlateGray")    place_chassis();
    color("Orange")       place_bucket();
    color("OrangeRed")    place_crank();
    for (n=[0:n_drums-1]) color(n==0 ? "Gold" : "Khaki") place_drum(n);
    for (i=[0:n_drums-2]) color("Tomato") place_pinion(i);
    color("YellowGreen")  place_yoke();
    color("MediumPurple") place_rocker();
    color("SpringGreen")  place_detent();
    color("IndianRed")    place_hammer();
    color("Crimson")      place_slider();
}

module model() {
    if (part=="assembly")        assembly();
    else if (part=="mech")       mech();
    else if (part=="funnel")     funnel();
    else if (part=="screen")     screen();
    else if (part=="body")       body();
    else if (part=="base")       base();
    else if (part=="chassis")    chassis();
    else if (part=="bucket")     bucket();
    else if (part=="crank")      crank();
    else if (part=="drum_std")   drum_std();
    else if (part=="drum_units") drum_units();
    else if (part=="pinion")     pinion();
    else if (part=="yoke")       yoke();
    else if (part=="rocker")     rocker();
    else if (part=="detent")     detent();
    else if (part=="hammer")     hammer();
    else if (part=="slider")     slider();
    else if (part=="clip")       clip();
    else if (part=="plate")      plate();
}
slab = [0, 10];   // x-range kept by section=3 (thin-slab inspection view)
if (section == 0) model();
else if (section == 1) difference() { model(); translate([rocker_x0, -500, -500]) cube(1000); }
else if (section == 2) difference() { model(); translate([-500, 0, -500]) cube(1000); }
else intersection() { model(); translate([slab[0], -500, -500]) cube([slab[1]-slab[0], 1000, 1000]); }
