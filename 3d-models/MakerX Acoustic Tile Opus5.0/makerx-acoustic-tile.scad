// ===========================================================================
// === DESCRIPTION ===========================================================
// ===========================================================================
// MakerX Acoustic Tile (Opus 5.0): a 250 x 250 mm wall tile that SCATTERS mid
// and high frequency sound instead of soaking it up, and additionally traps a
// slice of low-mid energy in tuned resonant cavities hidden behind its floors.
// Tiles butt together into arrays of any size; the pattern can be shifted per
// tile so a large array does not behave like one big periodic grating.
//
// It is NOT a foam panel. Nothing here is porous or fibrous. There are two
// mechanisms, both purely geometric:
//
//   1. DIFFUSION - a 2D Schroeder quadratic-residue well array (N = 7, so a
//      7 x 7 grid of 49 wells). Every well is a different depth, so every well
//      returns the incident wave with a different phase. The reflected wavefront
//      is broken into lobes spread across the hemisphere instead of one mirror
//      like specular slap-back. Predicted normalised diffusion coefficient
//      peaks at 0.86 around 3.1 kHz, mean 0.51 over 1.6-5 kHz.
//
//   2. RESONANT ABSORPTION - the user asked for "total internal reflection" to
//      absorb energy. Sound in air cannot be totally internally reflected (no
//      refractive-index contrast to work with), but the equivalent trick is to
//      trap the wave in a cavity where it has to keep moving air through a
//      narrow constriction, and let viscous drag in that constriction turn the
//      energy into heat. So:
//        - each well is a quarter-wave resonator in its own right (1.8-10.7 kHz
//          depending on depth), and
//        - the dead volume BEHIND each well floor - which would otherwise be
//          wasted - is sealed into a Helmholtz resonator, vented into the well
//          through 8 small necks drilled through the floor. Because each well
//          has a different depth, each back cavity has a different volume, so
//          the 40 vented cells resonate across 376-922 Hz rather than all at
//          one frequency. Predicted peak alpha 0.35 at 500 Hz, mean 0.23 over
//          315-1000 Hz.
//      This is a bonus band, not a bass trap. See README.md for honest limits.
//
// Physical context: hangs on a wall or ceiling in a studio, office, podcast
// room or home theatre, at first-reflection points. Indoor only - PLA softens
// above ~50 C so keep it out of direct sun. Carries only its own weight
// (~699 g) in shear through two keyhole hangers. No structural duty beyond
// not sagging and not rattling: a floppy panel re-radiates sound, so the
// egg-crate of fins is deliberately stiff. Measured solid volume 563 cm^3,
// so ~699 g in PLA at 1.24 g/cm^3.
//
// Design decisions:
//   - Wells DOWN into a thin-walled egg-crate rather than solid blocks UP.
//     Same phase-grating geometry, roughly a third of the filament, and it
//     creates the sealed back volumes that make mechanism 2 possible at all.
//   - Printed face-up (open wells toward the sky, back plate on the bed). Every
//     fin is then a vertical wall, and the only downward-facing surfaces are the
//     well floors' undersides, which are bridged inside sealed voids where
//     nobody will ever see or hear them.
//   - 45-degree gussets under each floor cut those bridges from 34 mm to 17 mm
//     and stiffen the whole panel, for ~35 g. The two keyhole cells get no
//     gussets - a gusset would sit exactly where the screw head must slide -
//     so those two floors bridge the full 34 mm, which PLA handles fine.
//   - Colour is banded by HEIGHT, not by cell. Only one filament is ever active
//     at a given Z, so the four brand colours need six filament swaps and NO
//     prime tower - which matters because a 250 mm tile leaves no room for one
//     on a 256 mm bed. Reads as a topographic map of the depth sequence.
//   - N = 7 chosen over 5/11/13. f_low is c/(4*well_depth_max) and so is the
//     same 1786 Hz for every N, but f_design scales with s_max/N (rises with N)
//     while f_high scales with 1/cell_w (also rises with N) - small N tunes
//     lower, large N reaches higher, and you cannot have both. N=5 tunes to
//     2858 Hz but its 48 mm cells cap f_high at 3558 Hz (barely an octave of
//     band, only 5 depth levels). N=7 gives 7 levels and 3062 Hz -> 5038 Hz
//     (1.5 octaves) for 699 g. N=11/13 reach 8.1/9.7 kHz but cost +150/+223 g.
//
// Terminology -> code:
//   "the tile" / "panel"        -> tile_size, tile_body()
//   "well" / "hole in the face" -> cell_w, well_depth(), cell_lo_n(), cell_ctr_n()
//   "well floor"               -> floor_t, cell_floors()
//   "fins" / "the grid"        -> fin_t, fin_grid()
//   "frame" / "outer rim"      -> rim_t, frame()
//   "necks" / "little holes"   -> neck_dia, neck_count, neck_holes()
//   "back cavity" / "void"     -> well_void(), the sealed space under a floor
//   "gussets" / "the 45s"      -> gusset_t, floor_gussets, cell_gussets()
//   "back plate"               -> back_t, back_plate()
//   "hangers" / "keyholes"     -> mount_style, keyhole_*, keyholes()
//   "the X" / "logo"           -> logo_badge, MX_X_PTS, badge_cut()
//   "side branding"            -> side_text, variant_text, side_text_cut()
//   "colour bands" / "strata"  -> band_edges(), band_colour_index()
//   "which pattern"            -> pattern_offset  (array modulation)
//
// Common modifications:
//   Thinner / faster tile       -> well_depth_max (32 = slim, 48 = default,
//                                  70 = max reach). Raises f_low by c/(4*d).
//   Lighter print               -> fin_t 1.35 -> 0.90 (2 perimeters), saves
//                                  ~76 g; still stiff because the grid braces
//                                  itself every 34 mm. Do not go below 0.90.
//   More absorption             -> neck_dia 1.4 -> 1.2 and neck_count 8 -> 12
//                                  (third-octave mean alpha 315-1000 Hz goes
//                                  0.23 -> 0.26, peak 0.35 -> 0.40). Only with
//                                  well calibrated flow: printed dia ~1.0 mm.
//   Higher top end              -> n_prime 7 -> 11 (f_high 5.0 -> 8.1 kHz) at
//                                  the cost of more fins and print time.
//   Different tile in an array  -> pattern_offset, any [m,n] in 0..N-1. All 49
//                                  shifts are acoustically equivalent.
//   No holes drilled in my wall -> mount_style = "none", use VHB tape.
//   Test before committing 25 h -> part = "coupon" (73 mm, ~1 h).
//
// Overall dimensions: 250.0 x 250.0 x 52.0 mm
//   (Bambu Lab X1C, 256 x 256 x 256 mm - 3 mm clearance each side in XY)
// Coordinate system: X, Y = the wall plane, tile centred on the origin.
//   Z = height from the build plate. Z = 0 is the BACK of the tile (the face
//   that touches the wall); Z = 52 is the acoustic face.
// NOTE: Model is in print orientation - OpenSCAD preview matches the print.
//   In use, the tile is rotated 90 degrees onto a wall: model +Y becomes UP
//   (the keyhole hangers are at the +Y edge and slide downward onto screws).

// ===========================================================================
// === PRINT SETTINGS ========================================================
// ===========================================================================
// Material: PLA. Chosen for dimensional accuracy on the 1.4 mm neck holes and
//   1.35 mm fins, low warp over a 250 mm footprint, and high stiffness (3 GPa)
//   so the fins do not resonate and re-radiate. PETG's stringing tends to veil
//   the necks and its extra toughness buys nothing on a wall-hung part.
// Layer Height: 0.20 mm. All colour band boundaries are multiples of 0.20 so
//   filament swaps land exactly on a layer.
// Walls/Perimeters: 3 (1.35 mm) - fins are exactly 3 perimeters wide, so they
//   print as solid walls with zero infill and zero gap fill.
// Infill: 15% gyroid. Only the floors and posts contain any infill at all.
// Supports: NONE. All fins are vertical; every downward-facing surface is a
//   bridge inside a sealed void - 17 mm for 47 of 49 cells, 34 mm for the two
//   keyhole cells. Do not enable supports - the slicer cannot reach the sealed
//   voids anyway and will only waste filament.
// Orientation: As modelled. Back plate flat on the plate, wells opening upward.
// Bed: 60 C, brim 5 mm recommended (250 mm of first layer is a lot of corner
//   lift risk even for PLA). Enclosure door open - PLA in a hot chamber gets
//   soft and the tall thin fins can lean.
// Cooling: 100% fan from layer 2. The 17 mm bridges want maximum cooling.
// Notes:
//   - "Detect thin walls" OFF, "Ensure vertical shell thickness" ON.
//   - Bridge flow ~110%, bridge speed <= 30 mm/s for clean floor undersides.
//   - The sealed voids are intentional. Ignore any "object has internal void"
//     hint from the slicer; do NOT add drain holes, they defeat mechanism 2.
//   - Colour: see README.md for the six swap heights. No prime tower needed.
//   - Estimated 25-30 h and ~699 g per tile at default settings (563 cm^3 solid);
//     ~517 g for the slim preset (well_depth_max=32, fin_t=0.9).

// ===========================================================================
// === PARAMETERS ============================================================
// ===========================================================================

/* [Output] */
// Which body to render
part = "tile";  // ["tile","preview","section","coupon","navy","magenta","gold","cyan"]

/* [Printer] */
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_x         = 256;   // Bambu Lab X1C
build_y         = 256;
build_z         = 256;
plate_margin    = 2.0;   // keep this much clear of each bed edge

/* [Tile] */
tile_size      = 250;    // outer square, mm. Tiles butt at this dimension.
n_prime        = 7;      // QRD modulus. Prime. 5, 7, 11 or 13.
pattern_offset = [4, 4]; // cyclic shift of the sequence - array modulation
well_depth_max = 48;     // depth of the deepest well below the face, mm
floor_t        = 2.4;    // well floor / Helmholtz neck plate thickness, mm
fin_t          = 1.35;   // internal fin thickness (3 perimeters), mm
rim_t          = 1.8;    // outer frame thickness (4 perimeters), mm
back_t         = 1.6;    // back plate thickness (4 perimeters), mm

/* [Helmholtz necks] */
neck_dia          = 1.4;  // nominal; prints ~0.2 mm under on a 0.4 nozzle
neck_count        = 8;    // necks per well floor
neck_ring_frac    = 0.25; // neck ring radius as a fraction of cell width
neck_start_angle  = 22.5; // degrees - offsets necks clear of the gussets
min_void_for_neck = 4.0;  // skip necks where the back cavity is shallower, mm

/* [Structure] */
floor_gussets     = true; // 45-degree bridge-shorteners under each floor
gusset_t          = 1.35;
corner_gusset_leg = 10;   // solid triangular posts in the four tile corners

/* [Mounting] */
mount_style      = "keyhole"; // ["keyhole","none"]
keyhole_head_dia = 9.0;   // screw head passes through this
keyhole_slot_dia = 4.6;   // shank rides in this
keyhole_travel   = 7.0;   // how far the tile drops onto the screws
keyhole_pad_t    = 4.0;   // local back-plate thickening around each keyhole
keyhole_min_void = 12;    // only hang from cells with at least this much void

/* [Branding] */
logo_badge       = true;  // debossed MakerX X on the flush (zero-depth) cell
badge_depth      = 1.2;
badge_width_frac = 0.72;  // X width as a fraction of cell width
side_text        = "MAKERX";
variant_text     = "";    // blank = auto-label from pattern_offset
side_text_size   = 9;
side_deboss      = 0.6;
side_font        = "DejaVu Sans:style=Bold";

/* [Hidden] */
ef_chamfer   = 0.4;   // elephant-foot compensation on the outer bottom edge
face_chamfer = 0.6;   // cosmetic chamfer on the outer top edge
fudge        = 0.01;  // boolean overlap
$fn          = $preview ? 24 : 48;

// ===========================================================================
// === DERIVED CONSTANTS =====================================================
// ===========================================================================

extrusion_width = nozzle_diameter * 1.125;      // 0.45 mm
N               = n_prime;
inner           = tile_size - 2 * rim_t;        // clear span inside the frame
cell_w          = (inner - (N - 1) * fin_t) / N;
pitch           = cell_w + fin_t;
face_z          = back_t + well_depth_max + floor_t;   // 52.0 mm
s_max           = max_seq();
unit_depth      = well_depth_max / s_max;       // 8.0 mm per sequence step

// The 2D quadratic-residue sequence, cyclically shifted by pattern_offset.
function seq_val(i, j) =
    ((pow_mod(i + pattern_offset[0]) + pow_mod(j + pattern_offset[1])) % N);
function pow_mod(k) = ((k % N) * (k % N)) % N;

// Largest value the 2D sequence takes (6 for N = 7).
function max_seq() = max([for (i = [0:n_prime-1], j = [0:n_prime-1])
                            ((((i+0)*(i+0)) % n_prime) + (((j+0)*(j+0)) % n_prime))
                            % n_prime]);

function well_depth(s) = s * unit_depth;              // below the face
function well_void(s)  = well_depth_max - well_depth(s); // sealed back cavity
function floor_top(s)  = face_z - well_depth(s);
function floor_bot(s)  = floor_top(s) - floor_t;

// --- Colour bands ---------------------------------------------------------
// One band per distinct floor level, arranged so no floor is ever split across
// two filaments. Band 0 holds the back plate and the deepest floor; the last
// band holds the acoustic face.
// Band boundaries sit one layer ABOVE each floor's top surface: that keeps every
// swap on an exact layer boundary while avoiding a cut plane coplanar with a
// floor face (which would leave non-manifold edges in the per-colour bodies).
band_shift = layer_height;
function band_edges() = concat([0],
    [for (s = [s_max : -1 : 1]) floor_top(s) + band_shift],
    [face_z]);
function n_bands()    = len(band_edges()) - 1;
// 0 = navy, 1 = magenta, 2 = gold, 3 = electric blue
function band_colour_index(k) =
    (k == 0 || k == n_bands() - 1) ? 0 : 1 + ((k - 1) % 3);

MX_NAVY    = "#0f1c57";
MX_MAGENTA = "#cc3a9d";
MX_GOLD    = "#ffc023";
MX_CYAN    = "#16acf2";
MX_COLOURS = [MX_NAVY, MX_MAGENTA, MX_GOLD, MX_CYAN];
MX_NAMES   = ["navy", "magenta", "gold", "cyan"];

// --- Keyhole cell selection ----------------------------------------------
// Hang from cells in the top row (j = N-1) that have enough sealed volume
// behind the floor to clear a screw head. Auto-selected so that changing
// pattern_offset for array modulation never breaks the mounting.
function kh_candidates() =
    [for (i = [0 : N - 1]) if (well_void(seq_val(i, N - 1)) >= keyhole_min_void) i];
function nearest_to(list, target) =
    let (best = min([for (v = list) abs(v - target)]))
    [for (v = list) if (abs(v - target) == best) v][0];
kh_left  = nearest_to(kh_candidates(), (N - 1) * 0.25);
kh_right = nearest_to(kh_candidates(), (N - 1) * 0.75);
// The reinforcing pad must stay inside its cell: at small cell_w (high n_prime)
// an unclamped pad grows through the fins and out past the tile edge.
kh_pad_w = min(keyhole_head_dia + 8, cell_w - 2 * fudge);
kh_pad_l = min(keyhole_head_dia + keyhole_travel + 8, cell_w - 2 * fudge);

// --- Zero-depth (flush) cell, where the logo badge lives ------------------
function flush_cells() =
    [for (i = [0:N-1], j = [0:N-1]) if (seq_val(i, j) == 0) [i, j]];
badge_cell = len(flush_cells()) > 0 ? flush_cells()[0] : undef;

// --- MakerX "X" outline --------------------------------------------------
// Traced from the official wordmark SVG on makerx.com.au (viewBox 0 0 1300 260,
// glyph 6). Normalised to unit width, centred on the origin, Y flipped from
// SVG's downward axis. Aspect ratio height/width = 0.73703.
MX_X_PTS = [
  [ 0.50000, 0.36852], [ 0.29816, 0.36852], [ 0.02272, 0.07489], [ 0.00000, 0.07489],
  [-0.02272, 0.07489], [-0.29816, 0.36852], [-0.50000, 0.36852], [-0.15647, 0.00003],
  [-0.50000,-0.36852], [-0.29816,-0.36852], [-0.02272,-0.07482], [ 0.00000,-0.07482],
  [ 0.02272,-0.07482], [ 0.29816,-0.36852], [ 0.50000,-0.36852], [ 0.15647, 0.00003],
];

// ===========================================================================
// === DESIGN CONTRACTS ======================================================
// ===========================================================================

// Printability and fit
assert(tile_size <= build_x - 2 * plate_margin &&
       tile_size <= build_y - 2 * plate_margin,
       str("Tile ", tile_size, " mm does not fit the ", build_x, " x ", build_y,
           " mm plate with ", plate_margin, " mm margin. Reduce tile_size or split."));
assert(face_z <= build_z, "Tile is taller than the build volume.");
assert(cell_w > 8, str("cell_w = ", cell_w, " mm is too small - reduce n_prime."));
assert(fin_t >= 2 * extrusion_width - 1e-9,
       str("fin_t must be >= 2 perimeters (", 2 * extrusion_width, " mm)."));
// Vertical walls must be whole perimeters or the slicer leaves gap-fill slivers.
assert(is_perim_multiple(fin_t),
       str("fin_t ", fin_t, " mm is ", fin_t / extrusion_width,
           " perimeters. Use a multiple of ", extrusion_width, " mm."));
assert(is_perim_multiple(rim_t),
       str("rim_t ", rim_t, " mm is ", rim_t / extrusion_width,
           " perimeters. Use a multiple of ", extrusion_width, " mm."));
assert(is_perim_multiple(gusset_t),
       str("gusset_t ", gusset_t, " mm is not a whole number of perimeters."));
// Horizontal slabs are stacks of layers, not perimeters - different rule.
assert(is_layer_multiple(back_t),
       str("back_t ", back_t, " mm is not a multiple of layer_height."));
assert(is_layer_multiple(floor_t),
       str("floor_t ", floor_t, " mm is not a multiple of layer_height."));
assert(back_t >= 3 * extrusion_width - 1e-9, "back_t must be >= 3 perimeters.");
assert(floor_t >= 6 * layer_height,
       "floor_t needs >= 6 layers so the bridged first layer is not the top surface.");
assert(neck_dia >= 1.0,
       str("neck_dia ", neck_dia, " mm prints ~0.2 mm under and will close up."));
assert(is_prime(n_prime), str("n_prime = ", n_prime, " must be prime for a QRD."));
function is_prime(p) = p >= 2 &&
    len([for (k = [2 : floor(sqrt(p))]) if (p % k == 0) k]) == 0;
function is_perim_multiple(t) =
    abs(t / extrusion_width - round(t / extrusion_width)) < 0.02;
function is_layer_multiple(t) =
    abs(t / layer_height - round(t / layer_height)) < 0.001;

// Geometry consistency
assert(neck_ring_frac * cell_w + neck_dia / 2 < cell_w / 2 - fin_t,
       "Neck ring reaches into the fins - reduce neck_ring_frac.");
assert(well_depth_max > 0 && s_max > 0, "Degenerate depth sequence.");
assert(badge_width_frac * cell_w * 0.73703 < cell_w - 2,
       "Logo badge does not fit inside a cell - reduce badge_width_frac.");
assert(badge_depth < floor_t - 3 * layer_height,
       "Badge deboss would leave the flush floor too thin.");
assert(mount_style != "keyhole" || len(kh_candidates()) >= 2,
       str("No cells in the top row have >= ", keyhole_min_void,
           " mm of back volume for a keyhole. Lower keyhole_min_void, ",
           "change pattern_offset, or set mount_style = \"none\"."));
assert(mount_style != "keyhole" ||
       keyhole_head_dia + keyhole_travel + 4 <= cell_w,
       str("Keyhole needs ", keyhole_head_dia + keyhole_travel + 4,
           " mm but the cell is only ", cell_w, " mm. Reduce keyhole_head_dia/",
           "keyhole_travel, lower n_prime, or set mount_style = \"none\"."));
assert(keyhole_slot_dia < keyhole_head_dia,
       "Keyhole slot must be narrower than the head opening.");

// Report the numbers a future session will want
echo(str("=== MakerX Acoustic Tile ", tile_size, " x ", tile_size,
         " x ", face_z, " mm ==="));
echo(N = N, cells = N * N, cell_w = cell_w, pitch = pitch);
echo(s_max = s_max, unit_depth = unit_depth, well_depth_max = well_depth_max);
echo(str("diffusion band: f_low ", round(343000 / (4 * well_depth_max)),
         " Hz, f_design ", round(s_max * 343000 / (2 * N * well_depth_max)),
         " Hz, f_high ", round(343000 / (2 * cell_w)), " Hz"));
echo(str("aperture ratio ", round(1000 * N * N * cell_w * cell_w /
                                  (tile_size * tile_size)) / 10, " %"));
echo(band_edges = band_edges(),
     band_colours = [for (k = [0 : n_bands() - 1]) MX_NAMES[band_colour_index(k)]]);
echo(keyhole_cells = [[kh_left, N - 1], [kh_right, N - 1]],
     badge_cell = badge_cell);
echo(variant = variant_label());

function variant_label() = variant_text != "" ? variant_text
    : str("N", N, "-", pattern_offset[0], pattern_offset[1]);

// ===========================================================================
// === MODULES ===============================================================
// ===========================================================================

// --- Back plate, with elephant-foot compensation on the outer bottom edge --
module back_plate(tsize) {
    hull() {
        translate([-(tsize / 2 - ef_chamfer), -(tsize / 2 - ef_chamfer), 0])
            cube([tsize - 2 * ef_chamfer, tsize - 2 * ef_chamfer, 0.01]);
        translate([-tsize / 2, -tsize / 2, ef_chamfer])
            cube([tsize, tsize, back_t - ef_chamfer]);
    }
}

// --- Outer frame: a square tube from the back plate up to the face ---------
module frame(tsize) {
    h = face_z - back_t;
    difference() {
        // Outer prism with a cosmetic chamfer at the face edge
        hull() {
            translate([-tsize / 2, -tsize / 2, back_t - fudge])
                cube([tsize, tsize, h - face_chamfer + fudge]);
            translate([-(tsize / 2 - face_chamfer), -(tsize / 2 - face_chamfer),
                       face_z - 0.01])
                cube([tsize - 2 * face_chamfer, tsize - 2 * face_chamfer, 0.01]);
        }
        translate([-(tsize / 2 - rim_t), -(tsize / 2 - rim_t), back_t - 2 * fudge])
            cube([tsize - 2 * rim_t, tsize - 2 * rim_t, h + 4 * fudge]);
    }
}

// --- Internal fin grid ----------------------------------------------------
module fin_grid(nn, tsize) {
    h    = face_z - back_t;
    span = nn * cell_w + (nn - 1) * fin_t;
    for (k = [1 : nn - 1]) {
        x = cell_lo_n(k, nn);
        // Overlap into the frame at both ends - a fin ending exactly on the
        // frame's inner face is a coincident face and makes a non-manifold edge.
        translate([x - fin_t, -span / 2 - fudge, back_t - fudge])
            cube([fin_t, span + 2 * fudge, h + fudge]);
        translate([-span / 2 - fudge, x - fin_t, back_t - fudge])
            cube([span + 2 * fudge, fin_t, h + fudge]);
    }
}

// Cell edge / centre for an arbitrary grid size (the coupon is smaller).
function cell_lo_n(k, nn)  = -(nn * cell_w + (nn - 1) * fin_t) / 2 + k * pitch;
function cell_ctr_n(k, nn) = cell_lo_n(k, nn) + cell_w / 2;

// --- Well floors ----------------------------------------------------------
module cell_floors(nn, mat) {
    for (i = [0 : nn - 1], j = [0 : nn - 1]) {
        s = mat[j][i];
        translate([cell_lo_n(i, nn) - fudge, cell_lo_n(j, nn) - fudge,
                   floor_bot(s) - fudge])
            cube([cell_w + 2 * fudge, cell_w + 2 * fudge, floor_t + fudge]);
    }
}

// --- 45-degree gussets under each floor -----------------------------------
// Four fins on the cell mid-lines, each with a 45-degree self-supporting
// underside. They cut the floor's bridge span from cell_w to cell_w/2 and
// stiffen the panel. Clipped where they would run below the back plate.
// xo overlaps the gusset into the fin/frame it lands on, for the same
// coincident-face reason as the fins.
function gusset_profile(hw, ztop, zmin) =
    let (zlow = max(ztop - hw, zmin), xo = hw + fudge)
    (zlow >= ztop - 3 * layer_height) ? []
    : (ztop - hw >= zmin)
        ? [[0, ztop], [xo, ztop], [xo, zlow]]
        : [[0, ztop], [xo, ztop], [xo, zlow], [ztop - zlow, zlow]];

// True for the two cells that carry keyhole hangers. Those cells get no
// gussets: a gusset runs straight down the cell mid-line, which is exactly
// where the screw head needs to sit and slide. Their floors bridge the full
// cell width instead - fine for PLA at this span, and the underside is inside
// a sealed void where finish does not matter.
function is_keyhole_cell(i, j, nn) =
    mount_style == "keyhole" && nn == N && j == N - 1 &&
    (i == kh_left || i == kh_right);

module cell_gussets(nn, mat) {
    hw = cell_w / 2;
    for (i = [0 : nn - 1], j = [0 : nn - 1]) {
        s    = mat[j][i];
        ztop = floor_bot(s);
        pts  = is_keyhole_cell(i, j, nn) ? [] : gusset_profile(hw, ztop, back_t);
        if (len(pts) >= 3)
            translate([cell_ctr_n(i, nn), cell_ctr_n(j, nn), 0])
                for (a = [0, 90, 180, 270])
                    rotate([0, 0, a])
                        translate([0, gusset_t / 2, 0])
                            rotate([90, 0, 0])
                                linear_extrude(height = gusset_t)
                                    polygon(pts);
    }
}

// --- Solid triangular posts in the four tile corners ----------------------
// Cheap insurance against corner lift on a 250 mm first layer, and something
// solid to grab when handling the tile.
module corner_posts(tsize) {
    L = corner_gusset_leg;
    c = tsize / 2 - rim_t;      // inner corner coordinate
    h = face_z - back_t;
    // The two legs are pushed fudge into the frame so they overlap it rather
    // than sitting exactly in its inner faces.
    for (sx = [-1, 1], sy = [-1, 1])
        translate([sx * c, sy * c, back_t - fudge])
            linear_extrude(height = h + fudge)
                polygon([[sx * fudge,  sy * fudge],
                         [-sx * L,     sy * fudge],
                         [sx * fudge, -sy * L]]);
}

// --- Helmholtz necks ------------------------------------------------------
module neck_holes(nn, mat) {
    r = neck_ring_frac * cell_w;
    for (i = [0 : nn - 1], j = [0 : nn - 1]) {
        s = mat[j][i];
        // Skip cells with no sealed volume, and the badge cell (the deboss
        // would break through into an open cavity and look like a mistake).
        is_badge = logo_badge && !is_undef(badge_cell) &&
                   badge_cell[0] == i && badge_cell[1] == j && nn == N;
        if (well_void(s) >= min_void_for_neck && !is_badge)
            translate([cell_ctr_n(i, nn), cell_ctr_n(j, nn), 0])
                for (k = [0 : neck_count - 1])
                    rotate([0, 0, neck_start_angle + k * 360 / neck_count])
                        translate([r, 0, floor_bot(s) - fudge])
                            cylinder(h = floor_t + 2 * fudge, d = neck_dia, $fn = 16);
    }
}

// --- Keyhole hangers ------------------------------------------------------
// The screw head passes through the back plate and sits in the cell's sealed
// cavity, which is free clearance. The plate is locally thickened so a 4.6 mm
// slot in 1.6 mm of PLA is not the thing holding 699 g on your wall.
module keyhole_pads(nn, mat) {
    if (mount_style == "keyhole" && nn == N)
        for (i = [kh_left, kh_right])
            translate([cell_ctr_n(i, nn) - kh_pad_w / 2,
                       cell_ctr_n(N - 1, nn) - kh_pad_l / 2, back_t - fudge])
                cube([kh_pad_w, kh_pad_l, keyhole_pad_t + fudge]);
}

module keyholes(nn, mat) {
    if (mount_style == "keyhole" && nn == N)
        for (i = [kh_left, kh_right])
            translate([cell_ctr_n(i, nn), cell_ctr_n(N - 1, nn), -fudge])
                linear_extrude(height = back_t + keyhole_pad_t + 2 * fudge)
                    hull() {
                        translate([0, -keyhole_travel / 2])
                            circle(d = keyhole_head_dia, $fn = 32);
                        translate([0, keyhole_travel / 2])
                            circle(d = keyhole_slot_dia, $fn = 24);
                    }
}

// --- Branding -------------------------------------------------------------
module badge_cut(nn, mat) {
    if (logo_badge && !is_undef(badge_cell) && nn == N) {
        i = badge_cell[0];
        j = badge_cell[1];
        s = mat[j][i];
        w = badge_width_frac * cell_w;
        translate([cell_ctr_n(i, nn), cell_ctr_n(j, nn),
                   floor_top(s) - badge_depth])
            linear_extrude(height = badge_depth + fudge)
                scale([w, w])
                    polygon(MX_X_PTS);
    }
}

module side_text_cut(tsize) {
    label = variant_label();
    // Debossed into the -Y outer frame face. Mirrored in X so it reads
    // correctly when viewed from outside the tile.
    translate([0, -tsize / 2 + side_deboss, face_z * 0.62])
        rotate([90, 0, 0])
            mirror([1, 0, 0])
                linear_extrude(height = side_deboss + fudge)
                    text(side_text, size = side_text_size, font = side_font,
                         halign = "center", valign = "center");
    translate([0, -tsize / 2 + side_deboss, face_z * 0.28])
        rotate([90, 0, 0])
            mirror([1, 0, 0])
                linear_extrude(height = side_deboss + fudge)
                    text(label, size = side_text_size * 0.6, font = side_font,
                         halign = "center", valign = "center");
}

// --- The tile -------------------------------------------------------------
// nn    = grid size, mat = nn x nn matrix of sequence values, tsize = outer square
module tile_body(nn, mat, tsize) {
    difference() {
        union() {
            back_plate(tsize);
            frame(tsize);
            fin_grid(nn, tsize);
            cell_floors(nn, mat);
            if (floor_gussets) cell_gussets(nn, mat);
            corner_posts(tsize);
            keyhole_pads(nn, mat);
        }
        neck_holes(nn, mat);
        keyholes(nn, mat);
        badge_cut(nn, mat);
        side_text_cut(tsize);
    }
}

QRD = [for (j = [0 : n_prime - 1]) [for (i = [0 : n_prime - 1]) seq_val(i, j)]];

module full_tile() { tile_body(N, QRD, tile_size); }

// A 2 x 2 test coupon at the real cell size: one deep well, one shallow, one
// with the thinnest gusset and one with no necks at all. Validates bridging,
// neck patency and floor finish in about an hour instead of 25.
COUPON = [[1, 3], [5, s_max]];
module coupon() {
    tile_body(2, COUPON, 2 * cell_w + fin_t + 2 * rim_t);
}

// --- Per-colour bodies for multi-material export --------------------------
module colour_body(idx) {
    e = band_edges();
    intersection() {
        full_tile();
        union() {
            for (k = [0 : n_bands() - 1])
                if (band_colour_index(k) == idx)
                    translate([-tile_size, -tile_size, e[k]])
                        cube([2 * tile_size, 2 * tile_size, e[k + 1] - e[k]]);
        }
    }
}

module coloured_preview() {
    e = band_edges();
    for (k = [0 : n_bands() - 1])
        color(MX_COLOURS[band_colour_index(k)])
            intersection() {
                full_tile();
                translate([-tile_size, -tile_size, e[k]])
                    cube([2 * tile_size, 2 * tile_size, e[k + 1] - e[k]]);
            }
}

// ===========================================================================
// === ASSEMBLY / RENDER =====================================================
// ===========================================================================

// Cutaway through the middle row of wells - shows the floors at their different
// heights, the sealed back cavities, the necks and the 45-degree gussets.
// Deliberately UNcoloured: colour here is banded by Z, so a coloured elevation
// collapses into flat horizontal stripes and hides the structure. Plain geometry
// lets the shading separate cut faces from cavity walls, floors and gussets.
module section_view() {
    intersection() {
        full_tile();
        translate([-tile_size, -tile_size / 2 - fudge, -fudge])
            cube([2 * tile_size, tile_size / 2 + fudge, face_z + 2 * fudge]);
    }
}

// "preview" and "section" are stacked, overlapping coloured solids for looking
// at, not printing - their STLs contain shared faces. Say so rather than let
// someone slice one by accident.
if (part == "preview" || part == "section")
    echo(str("NOTE: part=\"", part, "\" is a visualisation body (overlapping ",
             "coloured solids). Export part=\"tile\" to print, or the four ",
             "colour bodies for multi-material."));

if      (part == "tile")     full_tile();
else if (part == "coupon")   coupon();
else if (part == "preview")  coloured_preview();
else if (part == "section")  section_view();
else if (part == "navy")     colour_body(0);
else if (part == "magenta")  colour_body(1);
else if (part == "gold")     colour_body(2);
else if (part == "cyan")     colour_body(3);
else assert(false, str("Unknown part: ", part));
