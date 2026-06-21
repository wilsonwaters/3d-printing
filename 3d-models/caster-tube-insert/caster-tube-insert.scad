// === DESCRIPTION ===
// Caster Tube Insert (Expanding Collet): a two-part plug that mounts an
// M8 threaded-stem caster wheel into the open end of a round STEEL tube.
//
// Physical context: the tube is a furniture/cart/equipment leg, ~18mm inside
// diameter (varies +-1mm), open at one end, with a usable internal depth of
// 21mm. A caster with an M8 male threaded stem (14mm long) screws into this
// insert; the insert grips the inside of the steel tube. The caster's own top
// plate seats on the tube rim and carries the standing weight in compression;
// this insert's job is to resist PULL-OUT (lifting the leg) and to stop the
// caster wobbling sideways.
//
// How it works (self-energising expanding collet):
//   - The COLLET (Part A) is a slotted sleeve with 4 spring fingers and
//     external gripping ridges. Relaxed, its ridge crest is just under the
//     tightest tube so it slides in freely.
//   - The CONE-NUT (Part B) carries the M8 thread for the caster and has a
//     tapered body that nests inside the collet fingers. Anti-rotation fins
//     ride in the collet slots so it cannot spin.
//   - Screwing the caster stem into the cone-nut draws the cone-nut toward the
//     caster; its taper wedges the fingers outward against the tube wall.
//   - Steel is harder than PETG, so the ridges don't bite -- grip is the wedge's
//     normal force x friction, set by how hard the caster is tightened. The wedge
//     half-angle is ~10 deg (high mechanical advantage). What HOLDS the cone-nut
//     at its tightened expansion is the M8 thread itself: its lead angle (~2.9 deg)
//     is far below the thread friction angle, so it is strongly self-locking and
//     the grip does not back off. For more grip on smooth steel, roughen the ridge
//     crests or add a dab of thread-locker on the caster stem.
//
// Design decisions:
//   - Two parts because the cone must move axially relative to the sleeve.
//   - Printed standing on the open (caster) end: the internal wedge cone widens
//     toward the top (self-supporting) and the slots are vertical, so NO
//     supports are needed and the round bore prints accurately.
//   - M8 thread is printed (the cone-nut is too small to capture a steel M8 nut
//     or a heat-set insert). The wedge, not the thread, carries the grip load,
//     so a printed thread is adequate; see Common modifications for a
//     heat-set / smooth-bore alternative.
//   - Anti-rotation fins (not a coaxial tool socket) so the caster itself does
//     the tightening -- no separate tool, and nothing blocks the M8 path.
//
// Terminology -> code:
//   "the sleeve / collet / fingers" -> collet(), n_fingers, finger_body_d
//   "gripping teeth / ridges"       -> tooth_depth, tooth_pitch, relaxed_crest_d
//   "the slots"                     -> slot_w, slot_root_z, slots()
//   "the cone / wedge / cone-nut"   -> cone_nut(), wedge_min_d, wedge_max_d, wedge_len
//   "M8 caster thread"             -> m8_d, m8_pitch, thread_cut()
//   "anti-spin fins / keys"         -> fin_w, fin_or, fins()
//   "the rim collar (open end)"     -> collar_thick, collar_od, stem_clear_d
//   "how loose/tight in the tube"   -> relaxed_crest_d (raise=tighter, lower=looser)
//
// Common modifications:
//   Won't push into the tube        -> lower relaxed_crest_d (e.g. 16.8)
//   Too loose / won't grip biggest  -> raise relaxed_crest_d, or print at 100.5%
//     tube                             scale; check it still inserts
//   Different tube ID               -> tube_id_nom (and re-check relaxed_crest_d
//                                       sits below your tightest tube)
//   Different stem thread (M6/M10)  -> m8_d, m8_pitch, m8_minor, stem_clear_d
//   Use a heat-set insert instead   -> set printed_thread=false and set
//     of a printed thread              insert_bore_d to the insert's hole size
//   Caster stem longer/shorter      -> caster_thread_len (affects engagement check)
//   Stronger fingers                -> fewer expansion: lower wedge_max_d, or
//                                       raise finger_body_d (thicker wall)
//
// Overall dimensions: ~17mm dia (relaxed) x 20mm long (fits 17-19mm ID tube, <=21mm deep)
// Designed for: Bambu Lab P1/X1/A1 (256^3 build, 0.4mm nozzle) -- tiny part,
//   build volume is not a constraint.
// Coordinate system: Z = tube axis = print height. Z=0 = build plate = the OPEN
//   (caster) end of the tube. +Z points DEEP into the tube.
// NOTE: Model is in print orientation -- OpenSCAD preview matches the print.
//   In use the tube is usually vertical with the opening DOWN, so print-Z (deep)
//   points UP into the leg.

// === PRINT SETTINGS ===
// Material: PETG -- ductile so the collet fingers flex to grip without cracking;
//   good layer adhesion for the load path; tougher than PLA for a load part.
// Layer Height: 0.2mm (0.16mm gives crisper printed threads if available)
// Walls/Perimeters: 4 perimeters minimum (collet fingers want solid walls)
// Infill: 40-60% gyroid (small part; near-solid is fine and stronger)
// Supports: None required -- internal cone widens upward (self-supporting),
//   slots are vertical, ridge undersides are ~52 deg (self-supporting).
// Orientation: As modeled, Z=0 on the build plate. The COLLET sits on its
//   open-end collar (wide, stable). The CONE-NUT sits on its narrow end -- small
//   footprint, so a BRIM (5-8mm) on the cone-nut is REQUIRED, not optional, or it
//   will detach mid-print. Print both together (laid out side by side in part="all").
// Notes:
//   - Dry PETG (60-65C, 4-6h) before printing for clean threads.
//   - 30-40% fan; too much cooling weakens layer bonds on this load part.
//   - After printing, run an M8 bolt (or the caster) through the cone-nut thread
//     once to clear/seat it. Clean any strings off the ridge crests.

// === PARAMETERS ===
// --- Printer settings ---
nozzle_diameter = 0.4;
layer_height    = 0.2;

// --- Tube (the thing we grip) ---
tube_id_nom    = 18;   // nominal inside diameter of the steel tube (mm)
tube_id_min    = 17;   // tightest expected ID -- insert must slide into this
tube_id_max    = 19;   // loosest expected ID -- grip must reach this
tube_depth_max = 21;   // usable depth inside the tube (mm)

// --- Caster stem (the thing we hold) ---
m8_d            = 8;     // caster stem thread nominal major diameter
m8_pitch        = 1.25;  // M8 coarse pitch
m8_minor        = 6.466; // M8 minor (root) diameter
caster_thread_len = 14;  // length of the male thread on the caster stem

// --- Overall ---
insert_len = 20;   // total assembled length along the tube axis (<= tube_depth_max)

// --- Collet (Part A) ---
relaxed_crest_d = 17.0; // ridge crest dia, RELAXED. At/under the tightest tube so
                        //   the PRE-ASSEMBLED unit slides in (fingers can still flex
                        //   inward ~0.2mm for a slightly tight tube); the wedge then
                        //   expands ~2mm to grip up to ~19mm. Raise=tighter fit but
                        //   harder to insert; lower=easier insert but less top reach.
tooth_depth = 0.55;     // radial height of each gripping ridge
tooth_pitch = 1.6;      // axial spacing between ridges
n_fingers   = 4;        // number of collet fingers (= number of slots)
slot_w      = 1.8;      // width of each expansion slot
collar_thick = 3.0;     // solid ring at the open (caster) end (finger anchor)
collar_od    = 16.6;    // open-end collar OD (slip fit, sets insertion clearance)
stem_clear_d = 9.0;     // clearance hole through collar for the M8 stem

// --- Wedge / cone geometry ---
// wedge_z0 sets a trade-off: lower = more M8 thread engagement at rest but less
// wedge travel; higher = more travel/expansion but less initial engagement.
wedge_z0     = 9.0;     // Z where the wedge cone starts (above the lower bore).
                        //   Higher => more wedge travel (=wedge_z0-collar_thick, here
                        //   6mm => ~2mm dia expansion to reach a 19mm tube) but less
                        //   M8 thread engagement at rest (~5mm; grows to full as it
                        //   tightens). Lower => more rest engagement, less expansion.
wedge_len    = 8.0;     // axial length of the wedge cone
wedge_min_d  = 10.6;    // collet inner dia at bottom of wedge (narrow)
wedge_max_d  = 13.4;    // collet inner dia at top of wedge (wide). Sets the ~10deg
                        //   wedge half-angle and finger-wall thickness (~1.25mm here)
lower_bore_d = 10.7;    // collet inner dia below the wedge (= travel space for cone-nut)

// --- Cone-nut (Part B) ---
cone_clear   = 0.25;    // radial-ish sliding clearance between cone-nut and collet
cone_cap     = 1.6;     // solid cap thickness at the deep (top) end of the cone-nut
fin_w        = 1.4;     // anti-rotation fin thickness (rides in slot; 0.2mm/side clearance)
fin_or       = 8.0;     // fin outer radius (sits inside the ridge crest)

// --- Thread option ---
printed_thread = true;  // true = printed M8 thread; false = smooth bore for a
                        //   heat-set insert / tapped hole
thread_clear   = 0.30;  // added clearance for the printed female M8 thread (PETG)
insert_bore_d  = 10.5;  // bore dia when printed_thread = false (set to your
                        //   M8 heat-set insert's recommended hole)

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;        // 0.45mm
wall_thickness  = extrusion_width * 4;            // ~1.8mm (4 perimeters)
fudge     = 0.01;                                 // boolean overlap
tolerance = 0.3;                                  // PETG mating clearance
ef_chamfer = 0.4;                                 // elephant-foot compensation
$fn = $preview ? 48 : 96;

finger_body_d = relaxed_crest_d - 2*tooth_depth;  // smooth body OD between ridges
slot_root_z   = collar_thick + 1.0;               // slots start above the collar
cone_rest_top = wedge_z0 + wedge_len;             // cone-nut top at rest (Z)

// Sanity checks
assert(insert_len <= tube_depth_max, "insert_len exceeds tube_depth_max");
assert(relaxed_crest_d < tube_id_max, "relaxed_crest_d must clear the loosest tube (tube_id_max)");
assert(wedge_max_d < finger_body_d - 2*0.9, "wedge_max_d too large -- finger wall < 0.9mm");
assert(cone_rest_top + cone_cap <= insert_len, "cone-nut pokes past the deep end");
echo("ASSEMBLY: drop the cone-nut into the collet from the deep (finger-tip) end, fins aligned to the slots, until it seats; push the unit fingers-first into the tube; then screw the caster into the cone-nut to expand and lock. (The cone-nut cannot be added after the collet is in the tube.)");

// === MODULES ===

// --- Ring ridge (revolved triangle): a sharp annular grip rib ---
// Printed standing, the underside face rises ~52 deg from horizontal (steeper than
// the 45 deg self-support limit, for margin); the top is a gentle insertion ramp.
module ridge_ring(z) {
    br = finger_body_d/2;
    translate([0, 0, z])
        rotate_extrude(convexity = 4)
            polygon(points = [
                [br - fudge, -tooth_depth*1.3],    // inner, lower (~52 deg underside)
                [br + tooth_depth, 0],             // crest (sharp, outward)
                [br - fudge,  tooth_depth*1.4]     // inner, upper (gentle ramp)
            ]);
}

// --- Collet solid (before slots) ---
module collet_solid() {
    union() {
        // Collar (open end) with elephant-foot compensated base
        cylinder(h = collar_thick, d = collar_od);
        // Finger body cylinder
        translate([0, 0, collar_thick - fudge])
            cylinder(h = insert_len - collar_thick + fudge, d = finger_body_d);
        // Gripping ridges along the finger body
        for (z = [slot_root_z + 1 : tooth_pitch : insert_len - tooth_depth])
            ridge_ring(z);
    }
}

// --- Internal bore of the collet (stem clearance + lower bore + wedge cone) ---
module collet_bore() {
    union() {
        // Stem clearance through the collar
        translate([0, 0, -fudge])
            cylinder(h = collar_thick + fudge, d = stem_clear_d);
        // Lower bore (clears cone-nut body as it draws down)
        translate([0, 0, collar_thick - fudge])
            cylinder(h = wedge_z0 - collar_thick + 2*fudge, d = lower_bore_d);
        // Wedge cone (narrow at bottom, wide at top = self-supporting)
        translate([0, 0, wedge_z0 - fudge])
            cylinder(h = wedge_len + fudge, d1 = wedge_min_d, d2 = wedge_max_d);
        // Open finger tips above the wedge
        translate([0, 0, wedge_z0 + wedge_len - fudge])
            cylinder(h = insert_len - (wedge_z0 + wedge_len) + 2*fudge, d = wedge_max_d);
    }
}

// --- Expansion slots (2 crossing boxes -> 4 slots) with rounded stress-relief roots ---
module slots() {
    h = insert_len - slot_root_z + fudge;
    for (a = [0 : 180/(n_fingers/2) : 179]) {
        rotate([0, 0, a]) {
            // main slot
            translate([0, -slot_w/2, slot_root_z])
                cube([relaxed_crest_d + 4, slot_w, h + fudge], center = false);
            translate([-(relaxed_crest_d + 4), -slot_w/2, slot_root_z])
                cube([relaxed_crest_d + 4, slot_w, h + fudge], center = false);
            // rounded stress-relief at the slot root (small Ø=slot_w bore;
            // bridges fine at this size, rounds the corner the fingers hinge at)
            translate([0, 0, slot_root_z])
                rotate([90, 0, 0])
                    cylinder(h = relaxed_crest_d + 4, d = slot_w, center = true);
        }
    }
}

module collet() {
    difference() {
        collet_solid();
        collet_bore();
        slots();
        // Elephant-foot compensation chamfer on the base
        difference() {
            translate([0, 0, -fudge]) cylinder(h = ef_chamfer + fudge, d = collar_od + 2);
            cylinder(h = ef_chamfer + fudge, d1 = collar_od - 2*ef_chamfer, d2 = collar_od + 2*fudge);
        }
    }
}

// --- Printed female M8 thread cutter (a male thread solid we subtract) ---
module thread_cut(len) {
    union() {
        // clear the male root
        translate([0, 0, -fudge])
            cylinder(h = len + 2*fudge, d = m8_minor + thread_clear);
        // helical groove cut: a triangular bead spiralling out past the male major
        // so a real M8 (major 8.0) seats with clearance. twist<0 => right-hand.
        slices = max(16, floor(len / m8_pitch * 20));
        linear_extrude(height = len, twist = -360 * len / m8_pitch,
                       slices = slices, convexity = 6)
            translate([(m8_d + thread_clear)/2 - m8_pitch*0.42, 0, 0])
                circle(d = m8_pitch * 0.95, $fn = 3);
    }
}

// --- Cone-nut solid body (tapered to match the wedge, minus sliding clearance) ---
module cone_nut_body() {
    union() {
        // tapered cone body (narrow at bottom, wide at top)
        cylinder(h = wedge_len,
                 d1 = wedge_min_d - cone_clear,
                 d2 = wedge_max_d - cone_clear);
        // deep-end cap
        translate([0, 0, wedge_len - fudge])
            cylinder(h = cone_cap + fudge, d = wedge_max_d - cone_clear);
    }
}

// --- Anti-rotation fins (key into the collet slots) ---
module fins() {
    for (a = [0 : 180/(n_fingers/2) : 179])
        rotate([0, 0, a])
            translate([-fin_or, -fin_w/2, 0])
                cube([2*fin_or, fin_w, wedge_len + cone_cap]);
}

module cone_nut() {
    total_h = wedge_len + cone_cap;
    difference() {
        union() {
            cone_nut_body();
            intersection() {   // trim fins radially (taller cutter => no coincident faces)
                fins();
                translate([0, 0, -1])
                    cylinder(h = total_h + 2, d = 2*fin_or + 1);
            }
        }
        // central thread / bore -- runs fully THROUGH so a short (14mm) stem can
        // extend past the cone-nut into the open deep end instead of bottoming out
        if (printed_thread) {
            // entry lead-in chamfer (open/bottom end)
            translate([0, 0, -fudge])
                cylinder(h = m8_pitch, d1 = m8_d + thread_clear + 2*m8_pitch, d2 = m8_d + thread_clear);
            translate([0, 0, -fudge])
                thread_cut(total_h + 2*fudge);
        } else {
            translate([0, 0, -fudge])
                cylinder(h = total_h + 2*fudge, d = insert_bore_d);
        }
        // Elephant-foot compensation on cone-nut base
        difference() {
            translate([0, 0, -fudge]) cylinder(h = ef_chamfer + fudge, d = wedge_min_d + 2);
            cylinder(h = ef_chamfer + fudge,
                     d1 = (wedge_min_d - cone_clear) - 2*ef_chamfer,
                     d2 = (wedge_min_d - cone_clear) + 2*fudge);
        }
    }
}

// === ASSEMBLY / RENDER ===
part = "all"; // "all" (printable layout), "assembled" (cutaway fit check),
              // "collet", "cone"

if (part == "collet") collet();

if (part == "cone") cone_nut();

if (part == "all") {
    collet();
    translate([relaxed_crest_d + 8, 0, 0]) cone_nut();
}

if (part == "assembled") {
    // cutaway showing the cone-nut nested in the collet at rest
    difference() {
        union() {
            collet();
            translate([0, 0, wedge_z0]) color("orange") cone_nut();
        }
        // quarter cutaway
        translate([0, -50, -1]) cube([50, 50, insert_len + 4]);
    }
}
