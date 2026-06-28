// === DESCRIPTION ===
// Caster Tube Insert v3 (simple solid push-in): a ONE-PIECE plug that mounts an
// M8 threaded-stem caster into a round steel tube (~18mm ID, 17-19mm, 21mm deep).
// The deliberately-simple version after v1 (printed thread wouldn't form, teeth
// broke) and v2 (self-tap too tight, thin cantilever fins snapped off).
//
// Two things make v3 robust where v1/v2 failed:
//   1. THE M8 HOLE: a plain Ø7.5 self-tap pilot in a SOLID hub. The steel M8 screw
//      forms its own thread -- nothing fine to misprint. v2's Ø7.0 was too small
//      (~90% thread => seizes); Ø7.5 is ~50% thread: holds a caster, drives easily.
//      A clearance counterbore at the mouth means the screw only forms thread over
//      the deeper ~10mm, cutting the torque. A plain hole can't misprint -- the
//      reliability problem in v1/v2 was the thread geometry, not the printer.
//   2. THE FINS: the whole plug is ONE solid 2D cross-section extruded straight up,
//      so every wall is vertical (prints clean, no supports). The grip fins lean
//      TANGENTIALLY, so when the tube squeezes them they bend SIDEWAYS (in the
//      layer plane = full strength) instead of bending across the layers (which is
//      what delaminated and snapped v2's fins).
//
// Physical context & load path: the caster's own top plate carries the standing
// weight onto the tube rim; this plug resists pull-out and stops wobble. Grip is
// the springy fins' radial pressure x friction on the steel (they can't bite steel).
//
// Terminology -> code:
//   "the hub / core"     -> hub_d (solid centre holding the M8 hole)
//   "the M8 hole/socket"  -> selftap_d, counterbore_d/_depth, thread_engage
//   "fins / grip / slack" -> n_fin, fin_thick, fin_lean, crest_d (relaxed grip dia)
//   "how tight in tube"   -> crest_d (raise=tighter, lower=easier push-in)
//   "screw too tight/loose"-> selftap_d (bigger=easier drive/less hold; smaller=opposite)
//
// Common modifications:
//   Too hard to push in    -> lower crest_d (e.g. 19.0) or fin_thick (e.g. 1.2)
//   Too loose / pulls out    -> raise crest_d, add fins (n_fin), or thicker fin_thick
//   M8 too hard to drive    -> raise selftap_d (7.5 -> 7.7)
//   M8 strips / won't hold    -> lower selftap_d (7.5 -> 7.2)
//   Different stem (M6/M10)  -> selftap_d (M6~5.0, M10~9.3), counterbore_d
//
// Overall: ~19.5mm grip dia (relaxed) x 18mm long; fits 17-19mm ID, <=21mm deep.
// Bambu Lab, PETG. Z = tube axis = print height; Z=0 = build plate = open/caster end.

// === PRINT SETTINGS ===
// Material: PETG (ductile: fins flex without snapping, hub takes a self-tapped thread).
// Layer Height: 0.2mm is fine (no printed thread to resolve in self-tap mode).
// Walls: 4+ perimeters; Infill: 50-100% (hub should be near-solid for the thread).
// Supports: NONE -- it's a straight vertical extrusion; every face is vertical
//   except the deep-end lead-in chamfer (self-supporting) and the base.
// Orientation: as modeled, open/caster end (with the counterbore) DOWN on the plate.
// Notes:
//   - PRE-FORM THE THREAD on the bench: wind a plain M8 bolt fully into the hub once
//     (use a spanner -- easy leverage), back it out. Now the caster threads in by hand.
//   - Assembly: thread the caster into the hub, THEN push/tap the assembly into the
//     tube until the caster plate meets the rim. Hold the solid hub, not the fins.

// === PARAMETERS ===
// --- Printer ---
nozzle_diameter = 0.4;
layer_height    = 0.2;

// --- Tube ---
tube_id_min = 17;
tube_id_nom = 18;
tube_id_max = 19;
tube_depth_max = 21;

// --- Caster / M8 hole ---
m8_d        = 8;      // caster stem major dia (the screw)
selftap_d   = 7.5;    // self-tap pilot. M8 forms ~50% thread in PETG here. THE key fix.
counterbore_d     = 8.6;  // clearance mouth so the screw only forms thread deeper in
counterbore_depth = 4.0;  // (reduces driving torque)
thread_engage     = 11;   // depth of the self-tap (thread-forming) region

// --- Overall ---
plug_len = 18;        // <= tube_depth_max

// --- Hub (solid centre) ---
hub_d = 13;           // wall around the M8 hole = (hub_d - selftap_d)/2 ~ 2.75mm

// --- Grip fins ---
crest_d   = 19.5;     // relaxed grip diameter (~tube_id_max + 0.5 for interference)
n_fin     = 6;        // number of tangential fins
fin_thick = 1.4;      // fin wall thickness
fin_lean  = 40;       // tangential lean angle (deg). Higher = flexes more easily.

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
wall_thickness  = extrusion_width * 4;
fudge = 0.01;
tolerance = 0.3;
ef_chamfer = 0.4;
$fn = $preview ? 64 : 128;

hub_r  = hub_d/2;
crest_r = crest_d/2;

assert(plug_len <= tube_depth_max, "plug_len exceeds tube_depth_max");
assert(selftap_d < m8_d, "selftap_d must be below the M8 major");
assert(hub_d < tube_id_min, "hub must fit the tightest tube");
echo(hub_wall = (hub_d - selftap_d)/2, fins = n_fin, crest = crest_d);

// === MODULES ===

// --- 2D: one tangential fin (a leaning blade from the hub out to the crest) ---
module fin_2d() {
    // blade length so the leaning tip reaches ~crest_r
    L = (crest_r - hub_r + 1.5) / cos(fin_lean);
    rotate(fin_lean)
        translate([hub_r - 1.0, -fin_thick/2])
            square([L, fin_thick]);
}

// --- 2D: full cross-section (hub + fins), trimmed to the crest circle ---
module profile_2d() {
    intersection() {
        union() {
            circle(d = hub_d);
            for (i = [0:n_fin-1]) rotate(i*360/n_fin) fin_2d();
        }
        circle(d = crest_d);    // trim fin tips to a clean grip circle
    }
}

// --- the M8 self-tap socket, cut from the hub ---
module m8_socket() {
    // counterbore (clearance mouth) from the open end -- no thread formed here, less torque
    translate([0, 0, -fudge])
        cylinder(h = counterbore_depth, d = counterbore_d);
    // lead-in chamfer at the very mouth so the screw starts straight
    translate([0, 0, -fudge])
        cylinder(h = 1.2, d1 = counterbore_d + 2, d2 = counterbore_d);
    // thread-forming pilot (the M8 cuts its own thread here)
    translate([0, 0, counterbore_depth - fudge])
        cylinder(h = thread_engage + fudge, d = selftap_d);
    // clearance beyond, so a long stem tip doesn't bind
    translate([0, 0, counterbore_depth + thread_engage - fudge])
        cylinder(h = plug_len, d = counterbore_d);
}

module plug() {
    difference() {
        // solid body = hub + fins, extruded straight up (all vertical walls)
        linear_extrude(height = plug_len, convexity = 10) profile_2d();
        // M8 socket down the centre
        m8_socket();
        // deep-end lead-in chamfer so it starts into the tube (up-facing => no support)
        lead = 2.5;
        translate([0, 0, plug_len - lead])
            difference() {
                cylinder(h = lead + fudge, d = crest_d + 6);
                cylinder(h = lead + fudge, d1 = crest_d + fudge, d2 = tube_id_min - 1);
            }
        // (elephant foot: leave to the slicer's compensation -- a CAD chamfer here
        //  would undercut the fin bases and make them print floating.)
    }
}

// === ASSEMBLY / RENDER ===
part = "plug"; // "plug", "section" (axial cutaway), "profile" (2D pattern check)

if (part == "plug") plug();
if (part == "section")
    difference() { plug(); translate([0,-50,-1]) cube([50,50,plug_len+4]); }
if (part == "profile")
    linear_extrude(height = 1) profile_2d();
