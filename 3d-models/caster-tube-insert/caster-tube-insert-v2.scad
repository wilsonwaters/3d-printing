// === DESCRIPTION ===
// Caster Tube Insert v2 (push-in, self-tapping): a ONE-PIECE plug that mounts an
// M8 threaded-stem caster into a round steel tube. The "back to basics" version
// after v1's two-part screw-tightened collet proved hard to manufacture (the
// small printed M8 thread in the cone-nut would not form reliably, and gripping
// the unit to drive the screw broke the collet teeth).
//
// Physical context: tube ID ~18mm (varies 17-19mm), usable depth 21mm, open at
// one end. The caster's M8 male stem (14mm long) self-taps into a solid core in
// this plug; flexible barbed fingers grip the tube wall. The caster's own top
// plate carries the standing weight onto the tube rim; this plug resists pull-out
// and stops the caster wobbling.
//
// Why this design (lessons from v1):
//   - NO captured nut: a steel M8 nut is ~15mm across corners + walls > 17mm tube,
//     so it can't fit. NO printed M8 thread: too small/fine to print reliably here.
//     Instead a plain Ø7 hole in a SOLID core -- the steel M8 screw cuts its own
//     thread (self-tap). Reliable, strong, and a solid core won't split.
//   - NO in-tube screwing: assemble OUTSIDE the tube (drive the caster into the
//     core), then push/tap the whole assembly in. Nothing delicate to grip.
//   - Flexible barbed fingers (not a rigid wedge) absorb the +-1mm tube variance:
//     they compress to enter a tight tube and spring out to grip a loose one.
//
// How the grip works: the fingers' barb crests sit slightly oversize (relaxed
// ~19.5mm). Pushing the plug in deep-end-first compresses them; the barbs' steep
// (open-facing) faces resist pull-out. On steel the barbs can't bite, so grip is
// spring pressure x friction -- adequate for a furniture/cart caster.
//
// Terminology -> code:
//   "the plug / core"        -> core(), core_d, plug_len
//   "self-tap hole / socket" -> selftap_d, m8_d (the screw it accepts)
//   "fingers / barbs / grip" -> barbed_sleeve(), n_seg, relaxed_crest_d, barb_depth
//   "the slots"              -> slot_w, slots()
//   "the head / push face"   -> head(), head_d, head_thick
//   "how tight in the tube"  -> relaxed_crest_d (raise=tighter, lower=easier push-in)
//   "screw won't bite / strips" -> selftap_d (smaller=more grip+torque, bigger=easier)
//
// Common modifications:
//   Too hard to push in       -> lower relaxed_crest_d (e.g. 19.0) or thin seg_wall
//   Too loose / pulls out      -> raise relaxed_crest_d, or add barb rings (barb_pitch)
//   Caster strips / won't hold  -> lower selftap_d (7.0 -> 6.8); too hard to drive -> 7.3
//   Different tube ID          -> relaxed_crest_d (~tube max + 0.5) and core/seg sizes
//   Different stem (M6/M10)     -> m8_d, selftap_d (M6~5.2, M10~8.7), stem_clear_d
//
// Overall dimensions: ~19.5mm crest (relaxed) x 19mm long; fits 17-19mm ID, <=21mm deep.
// Designed for Bambu Lab (0.4mm nozzle), PETG.
// Coordinate system: Z = tube axis = print height. Z=0 = build plate = the OPEN
//   (caster) end. +Z points DEEP into the tube. In use the tube opening faces the
//   caster, so print-Z (deep) points away from the caster.

// === PRINT SETTINGS ===
// Material: PETG -- ductile, so the fingers flex without snapping and the core
//   accepts a self-tapped thread without cracking. (PLA would be too brittle.)
// Layer Height: 0.2mm is fine (no fine threads to resolve in v2).
// Walls/Perimeters: 4+ perimeters; the solid core should be ~solid (high infill).
// Infill: 60-100% -- the core carries the caster thread; near-solid is best.
// Supports: None -- prints open-end (head) DOWN on a flat disc base; barb catch
//   faces are 45deg (self-supporting), finger gaps and the core are vertical.
// Orientation: As modeled, Z=0 on the plate. The HEAD (flat disc) is the base --
//   big, stable, no brim needed. Fingers and core rise from it.
// Notes:
//   - Drive a real M8 bolt (or the caster) into the core ONCE to cut the thread,
//     before final assembly -- easier on the bench than in the tube.
//   - Assembly: drive the caster stem fully into the core, THEN push/tap the plug
//     into the tube (a few firm taps with a soft mallet). Do not screw it in place
//     inside the tube. Hold the plug by the solid HEAD/CORE, never the fingers.

// === PARAMETERS ===
// --- Printer ---
nozzle_diameter = 0.4;
layer_height    = 0.2;

// --- Tube ---
tube_id_min    = 17;
tube_id_nom    = 18;
tube_id_max    = 19;
tube_depth_max = 21;

// --- Caster stem ---
m8_d              = 8;     // caster stem nominal major dia (the screw)
caster_thread_len = 14;    // length of the male thread on the caster stem
selftap_d         = 7.0;   // self-tap pilot hole. M8 forms its own thread in this.
                           //   Smaller = more grip but more torque; 7.0 is a good PETG start.
stem_clear_d      = 9.0;   // (unused in self-tap mode; kept for M6/M10 retuning)

// --- Overall ---
plug_len   = 19;   // total length along the tube axis (<= tube_depth_max)

// --- Core (solid, holds the self-tapped thread) ---
core_d     = 11.5; // solid core OD (wall around selftap hole = (core_d-selftap_d)/2)

// --- Head (flat base / push face at the open end) ---
head_d     = 16.5; // <= tube_id_min so it enters; flat disc = stable print base
head_thick = 2.5;

// --- Barbed fingers (grip) ---
relaxed_crest_d = 19.5; // barb crest dia, relaxed (~tube_id_max + 0.5 for grip)
seg_inner_d     = 14.5; // inner face of the fingers (gap to core = flex room)
seg_wall        = 1.5;  // finger wall thickness (thinner = flexes easier)
n_seg           = 6;    // number of fingers (= number of slots)
slot_w          = 1.6;  // slot width between fingers
barb_depth      = 1.0;  // how far each barb crest stands out from the finger body
barb_pitch      = 3.0;  // axial spacing of barb rings

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;     // 0.45mm
wall_thickness  = extrusion_width * 4;         // ~1.8mm
fudge     = 0.01;
tolerance = 0.3;                               // PETG
ef_chamfer = 0.4;
$fn = $preview ? 48 : 96;

seg_body_d  = seg_inner_d + 2*seg_wall;        // finger body OD (barbs add on top)
slot_root_z = head_thick + 1.0;                // fingers/slots start above the head
flex_gap    = (seg_inner_d - core_d)/2;        // radial room for fingers to flex in

assert(plug_len <= tube_depth_max, "plug_len exceeds tube_depth_max");
assert(head_d < tube_id_min, "head_d must be < tube_id_min so the plug enters");
assert(flex_gap > 0, "seg_inner_d must exceed core_d (need flex room)");
assert(selftap_d < m8_d, "selftap_d must be below the M8 major to form a thread");
echo(flex_gap_mm = flex_gap, finger_body_od = seg_body_d, crest = relaxed_crest_d);

// === MODULES ===

// --- Solid core with the self-tap pilot hole (through) ---
module core() {
    difference() {
        cylinder(h = plug_len, d = core_d);
        // self-tap pilot hole, through, with a lead-in chamfer at the open (z=0) end
        translate([0, 0, -fudge])
            cylinder(h = plug_len + 2*fudge, d = selftap_d);
        translate([0, 0, -fudge])
            cylinder(h = 1.2, d1 = selftap_d + 2*1.2, d2 = selftap_d);  // entry funnel
    }
}

// --- One barb ring (revolved sawtooth): gentle lead-in up (deep), 45deg catch down ---
module barb_ring(z) {
    br = seg_body_d/2;
    translate([0, 0, z])
        rotate_extrude(convexity = 6)
            polygon(points = [
                [br - fudge, z_off(-barb_depth)],       // inner, lower (start of 45deg catch)
                [br + barb_depth, 0],                   // crest
                [br - fudge, z_off(barb_depth*1.6)]     // inner, upper (gentle lead-in ramp)
            ]);
}
function z_off(dz) = dz;  // (kept explicit for readability)

// --- Barbed sleeve (full rings; slots cut it into fingers later) ---
module sleeve_solid() {
    union() {
        // finger body tube
        translate([0, 0, head_thick - fudge])
            cylinder(h = plug_len - head_thick + fudge, d = seg_body_d);
        // barb rings along the fingers
        for (z = [slot_root_z + barb_depth : barb_pitch : plug_len - barb_depth])
            barb_ring(z);
    }
}

// --- Hollow out the inside of the sleeve, leaving the flex gap to the core ---
module sleeve() {
    difference() {
        sleeve_solid();
        // bore the inside (above the head) to seg_inner_d -> annular flex gap
        translate([0, 0, head_thick + fudge])
            cylinder(h = plug_len, d = seg_inner_d);
    }
}

// --- Expansion/compression slots (n_seg fingers) ---
module slots() {
    h = plug_len - slot_root_z + fudge;
    for (a = [0 : 360/n_seg : 359])
        rotate([0, 0, a])
            translate([0, -slot_w/2, slot_root_z])
                cube([relaxed_crest_d/2 + 2, slot_w, h + fudge]);
}

// --- Head: flat disc base at the open (caster) end ---
module head() {
    difference() {
        cylinder(h = head_thick, d = head_d);
        // self-tap hole continues through the head
        translate([0, 0, -fudge]) cylinder(h = head_thick + 2*fudge, d = selftap_d);
        // entry funnel on the very bottom face (caster side)
        translate([0, 0, -fudge]) cylinder(h = 1.2, d1 = selftap_d + 2*1.2, d2 = selftap_d);
        // elephant-foot chamfer on the base rim
        difference() {
            translate([0,0,-fudge]) cylinder(h = ef_chamfer + fudge, d = head_d + 2);
            cylinder(h = ef_chamfer + fudge, d1 = head_d - 2*ef_chamfer, d2 = head_d + 2*fudge);
        }
    }
}

module plug() {
    difference() {
        union() {
            head();
            core();
            sleeve();
        }
        slots();
        // deep-end lead-in chamfer on the finger tips so the plug starts into the
        // tube (the relaxed body is wider than the tightest tube). Up-facing => no support.
        lead = 2.5;
        translate([0, 0, plug_len - lead])
            difference() {
                cylinder(h = lead + fudge, d = relaxed_crest_d + 6);
                cylinder(h = lead + fudge, d1 = relaxed_crest_d + fudge, d2 = tube_id_min - 1);
            }
    }
}

// === ASSEMBLY / RENDER ===
part = "plug"; // "plug" (the printable part), "section" (cutaway to inspect)

if (part == "plug") plug();

if (part == "section") {
    difference() {
        plug();
        translate([0, -50, -1]) cube([50, 50, plug_len + 4]);
    }
}
