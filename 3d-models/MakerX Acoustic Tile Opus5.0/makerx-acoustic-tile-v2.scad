// ===========================================================================
// === DESCRIPTION ===========================================================
// ===========================================================================
// MakerX Acoustic Tile v2 (Opus 5.0): a 190 x 190 x 52 mm acoustic diffuser
// MODULE plus a separately-printed bowtie KEY that locks modules edge-to-edge
// into a panel of any size. Same acoustics as v1, but re-proportioned so the
// whole thing prints on a STOCK Bambu X1/P1 with the AMS available.
//
// Why v2 exists. v1 was 250 x 250 mm, which overlaps the X1/P1's 18 x 28 mm
// front-left filament-cutter exclusion. The only way to print it was Bambu's
// stopper-clip mod - and that clip disables the cutter, so the AMS was off and
// colour had to be done with manual filament swaps. v2 solves it by shrinking
// the module until a prime tower fits beside it:
//
//   tile at x [4,194], y [30,220]  ->  54 mm free column at x [198,252]
//
// That is enough for a four-filament prime tower, so v2 can colour PER CELL
// rather than per height band - which is what makes colour_mode = "logo_x"
// possible: a full-face MakerX X picked out in magenta against depth-coded
// gold and electric blue. The v1 "strata" mode is still here for anyone who
// would rather do manual swaps and skip the purge waste.
//
// The key. Each module edge carries two blind bowtie pockets in the BACK
// plate. Butt two modules, drop a printed bowtie key into the paired pockets,
// and the joint is locked in-plane: the flared ends cannot pass back through
// the pinched waist, exactly like a woodworker's butterfly key. Consequences:
//   - Modules butt at exactly tile_size, so the well grid stays continuous.
//   - The pockets are BLIND (1.6 mm of plate is left above them), so no cell
//     cavity is breached and mechanism 2 is untouched.
//   - Pockets sit symmetrically about each edge's midpoint and use the same
//     cell indices on all four edges, so any edge mates any edge at any 90
//     degree rotation. Modules stay interchangeable.
//   - A key costs ~4 g and about 8 minutes. Panels extend indefinitely.
//
// Physical context: as v1 - studio/office/podcast wall at first-reflection
// points, indoor only, PLA. A 3 x 3 panel is 570 x 570 mm and needs 12 keys.
//
// Design decisions:
//   - 190 mm chosen from the bed budget above, not from acoustics. It happens
//     to help: smaller cells raise f_high from 5038 Hz (v1) to ~6700 Hz.
//   - Keys go on the BACK, not the face. The face is the acoustic surface and
//     a joiner there would add a flat land across every joint. The back plate
//     is against the wall and otherwise dead real estate.
//   - Pocket cells are auto-selected from cells with enough sealed volume to
//     host the boss, so changing pattern_offset never breaks the key system.
//   - rim_t dropped to fin_t so a butted joint reads as a 2.7 mm land against
//     a 1.35 mm internal fin - close enough to keep the grating continuous.
//
// Terminology -> code:
//   "module" / "tile"        -> tile_size, tile_body()
//   "key" / "bowtie"         -> part="key", bowtie_key(), key_* parameters
//   "pocket"                 -> key_pockets_cut(), key_bosses()
//   "the X"                  -> colour_mode="logo_x", on_logo_x()
//   "colour skin"            -> colour_skin, floor_skin()
//   everything else          -> as v1, see makerx-acoustic-tile.scad
//
// Common modifications:
//   Bigger module (needs mod) -> tile_size up to 220 stock-centred, or 250
//                                with bed_clip_fitted=true (loses the AMS).
//   Skip the key system       -> key_pockets=false, mount each module alone.
//   Manual swaps instead      -> colour_mode="strata" (v1 scheme, no tower).
//   Positively fix a joint    -> print part="key-mount" (countersunk M4).
//
// Overall dimensions: 190.0 x 190.0 x 52.0 mm module; key 34 x 20 x 4 mm.
//   Fits a STOCK Bambu X1/P1 plate with a 54 mm prime-tower column. No mod.
// Coordinate system / print orientation: as v1. Z = 0 is the BACK of the tile.

// ===========================================================================
// === PRINT SETTINGS ========================================================
// ===========================================================================
// Material: PLA, as v1.
// Layer Height: 0.20 mm.
// Walls/Perimeters: 3 (1.35 mm).
// Infill: 15% gyroid.
// Supports: NONE - the key pockets are flat-bottomed blind pockets opening
//   downward onto the build plate, so they are not overhangs at all.
// Orientation: module back-plate-down, wells up. Key flat on the plate.
// Plate layout (X1/P1, stock, AMS): place the module at x 4..194, y 30..220 -
//   this clears the 18 x 28 mm front-left exclusion in Y - and let the prime
//   tower take the 54 mm column at x 198..252. Do NOT auto-arrange; Bambu
//   Studio will centre the part and collide with the exclusion.
// Keys: print 8-12 per plate alongside nothing else, ~8 min each. Print them
//   in mx-magenta so a disassembled panel is obvious, or in mx-blue to vanish.
// Notes:
//   - Key fit is a 0.15 mm push fit per side. If your dimensional accuracy runs
//     tight, raise key_clear rather than forcing the key in - PLA splits.
//   - Assemble face-DOWN on a flat surface: butt the modules, drop the keys in,
//     then lift onto the wall. Keys are captured once the panel is hung.
//   - Everything else as v1.

// ===========================================================================
// === PARAMETERS ============================================================
// ===========================================================================

/* [Output] */
// Which body to render
part = "tile";  // ["tile","key","key-mount","keyplate","pair","fit","preview","section","coupon","navy","magenta","gold","cyan"]

/* [Printer] */
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_x         = 256;   // Bambu Lab X1C
build_y         = 256;
build_z         = 256;
plate_margin    = 2.0;   // keep this much clear of each bed edge
// Bambu X1/P1 reserve a front-left corner for the filament-cutter stopper, so
// the usable square is ~220 mm auto-centred (~238 mm shoved hard right), NOT
// the full 256 mm. A 250 mm tile overlaps it either way and needs Bambu's
// stopper-clip mod. The clip disables the cutter, so the AMS cannot be used -
// which is fine here because the colour scheme runs on manual filament swaps.
bed_exclude_x   = 18;    // front-left exclusion, mm (0 for non-Bambu printers)
bed_exclude_y   = 28;
bed_clip_fitted = true;  // stopper-clip mod fitted? Frees the full bed, no AMS.

/* [Tile] */
tile_size      = 190;    // outer square, mm. Modules butt at this dimension.
n_prime        = 7;      // QRD modulus. Prime. 5, 7, 11 or 13.
pattern_offset = [4, 4]; // cyclic shift of the sequence - array modulation
well_depth_max = 48;     // depth of the deepest well below the face, mm
floor_t        = 2.4;    // well floor / Helmholtz neck plate thickness, mm
fin_t          = 1.35;   // internal fin thickness (3 perimeters), mm
rim_t          = 1.35;   // outer frame = one fin, so joints read as 2.7 mm
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

/* [Key / joiner system] */
key_pockets   = true;  // blind bowtie pockets in the back plate, 2 per edge
key_t         = 4.0;   // key thickness = pocket depth, mm
key_half      = 17;    // key reach each side of the joint (key is 2x this long)
key_end_w     = 10;    // key half-width at the flared ends, mm
key_waist_w   = 7;     // key half-width at the pinched waist, mm
key_clear     = 0.15;  // per-side clearance, push fit in PLA
key_boss_h    = 4.0;   // back-plate thickening that gives the pocket its depth
key_min_void  = 8;     // pocket cells need at least this much sealed volume
key_screw_dia = 4.4;   // part="key-mount": M4 clearance
key_csk_dia   = 8.6;   // countersunk head, sits flush in the 4 mm key

/* [Colour] */
// "strata" = v1 scheme, colour banded by height, 6 manual swaps, no prime
//            tower, works on any printer.
// "logo_x" = per-cell colour forming a full-face MakerX X. Needs the AMS and a
//            prime tower, which is exactly what the 190 mm module buys you.
colour_mode  = "logo_x";  // ["logo_x","strata"]
colour_skin  = 1.2;       // depth of the colour layer on floor tops, mm

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

// --- Key pocket cell selection -------------------------------------------
// A pocket needs a cell with enough sealed volume behind its floor to host the
// boss. For the key system to be rotation-safe the SAME index pair must work
// on all four edges, so a candidate p is only valid if cells p and N-1-p have
// the volume on the top, bottom, left AND right edge.
function edge_void(i, j) = well_void(seq_val(i, j));
function pocket_ok(p) =
    let (q = N - 1 - p)
    min([for (k = [p, q]) min(edge_void(k, 0), edge_void(k, N - 1),
                              edge_void(0, k), edge_void(N - 1, k))])
        >= key_min_void;
// Score each candidate by the tightest cavity it would need, and take the best.
// Every index is usable - the boss guarantees 1.6 mm above the pocket whatever
// is above it - so this only expresses a preference, never a hard failure. A
// pocket landing on a zero-cavity cell leaves a 1.6 mm pad in that well.
function pocket_score(p) =
    let (q = N - 1 - p)
    min([for (k = [p, q]) min(edge_void(k, 0), edge_void(k, N - 1),
                              edge_void(0, k), edge_void(N - 1, k))]);
// Exclude the corner cells (they carry the corner posts) and, for odd N, the
// middle cell - there p and N-1-p are the SAME cell, which would silently give
// one pocket per edge instead of two.
function pocket_candidates() =
    let (ps = [for (p = [1 : floor((N - 1) / 2)]) if (p < N - 1 - p) p],
         best = max([for (p = ps) pocket_score(p)]))
    [for (p = ps) if (pocket_score(p) == best) p];
kp_a = len(pocket_candidates()) > 0
     ? nearest_to(pocket_candidates(), (N - 1) * 0.30) : undef;
kp_b = is_undef(kp_a) ? undef : N - 1 - kp_a;

// Boss footprint, clamped so it can never grow through the fins.
kb_deep = min(key_half + 2, cell_w + rim_t - 1);
kb_wide = min(2 * key_end_w + 4, cell_w - 1);

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
// A footprint only clears the front-left exclusion if its near edge starts
// beyond it: centred needs build_x - 2*bed_exclude_x, hard right needs
// build_x - bed_exclude_x.
max_centred   = build_x - 2 * bed_exclude_x;
max_hard_right = build_x - bed_exclude_x;
assert(bed_clip_fitted || bed_exclude_x == 0 || tile_size <= max_hard_right,
       str("Tile ", tile_size, " mm overlaps the ", bed_exclude_x, "x",
           bed_exclude_y, " mm front-left exclusion zone even positioned hard ",
           "right (max ", max_hard_right, " mm). Either fit Bambu's stopper ",
           "clip and set bed_clip_fitted = true (this disables the AMS - fine ",
           "here, the colour scheme uses manual swaps), or set tile_size <= ",
           max_centred, "."));
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
           "keyhole_travel, lower n_prime, or set mount_style = \"none\" and ",
           "mount the panel through screwed keys (part = \"key-mount\")."));
// --- Key system contracts -------------------------------------------------
assert(!key_pockets || !is_undef(kp_a),
       str("No non-corner cell is available for a key pocket at N = ", N,
           ". Raise n_prime or set key_pockets = false."));
assert(!key_pockets || key_waist_w < key_end_w,
       "key_waist_w must be less than key_end_w or the key does not lock.");
assert(!key_pockets || 2 * key_end_w + 4 <= cell_w + 1,
       str("Key is ", 2 * key_end_w, " mm wide but the cell is only ", cell_w,
           " mm - the pocket would cut the fins. Reduce key_end_w."));
assert(!key_pockets || key_t + 1.6 <= back_t + key_boss_h + 1e-9,
       str("A ", key_t, " mm pocket in a ", back_t + key_boss_h,
           " mm boss leaves under 1.6 mm of plate. Raise key_boss_h."));
assert(!key_pockets || key_half + 2 <= cell_w + rim_t,
       "Key reach exceeds one cell - the pocket would cross a fin.");
assert(colour_mode == "strata" || colour_mode == "logo_x",
       "colour_mode must be \"strata\" or \"logo_x\".");
assert(colour_mode != "logo_x" || colour_skin < floor_t - 2 * layer_height,
       "colour_skin must be thinner than the floor it sits on.");
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
echo(variant = variant_label(), colour_mode = colour_mode);
if (key_pockets)
    echo(str("key pockets in cells ", kp_a, " and ", kp_b,
             " on every edge; key ", 2 * key_half, " x ", 2 * key_end_w,
             " x ", key_t, " mm, waist ", 2 * key_waist_w, " mm"));
if (bed_clip_fitted && bed_exclude_x > 0 && tile_size > max_centred)
    echo(str("NOTE: ", tile_size, " mm exceeds the ", max_centred, " mm ",
             "auto-centred limit on a stock Bambu X1/P1. This assumes the ",
             "stopper-clip mod is fitted and bed_exclude_area cleared in the ",
             "printer profile. The clip disables the filament cutter, so print ",
             "single-filament with manual swaps - do NOT use the AMS."));

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
                polygon([[ sx * rim_t / 2,  sy * rim_t / 2],
                         [-sx * L,           sy * rim_t / 2],
                         [ sx * rim_t / 2,  -sy * L]]);
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

// --- Bowtie key and its pockets -------------------------------------------
// Full key outline in the joint frame: long axis X, joint at x = 0. Flared to
// key_end_w at both ends, pinched to key_waist_w at the joint - the flare
// cannot pass back through the waist, which is what locks the two modules.
function key_outline() = [
    [-key_half, -key_end_w], [0, -key_waist_w],
    [ key_half, -key_end_w], [ key_half,  key_end_w],
    [0,  key_waist_w], [-key_half,  key_end_w],
];

module bowtie_key(with_screw = false) {
    difference() {
        linear_extrude(height = key_t) polygon(key_outline());
        if (with_screw) {
            translate([0, 0, -fudge])
                cylinder(h = key_t + 2 * fudge, d = key_screw_dia, $fn = 32);
            // Countersink opens on the BACK face (z = key_t), which faces away
            // from the wall, so an M4 CSK head finishes flush.
            translate([0, 0, key_t - (key_csk_dia - key_screw_dia) / 2])
                cylinder(h = (key_csk_dia - key_screw_dia) / 2 + fudge,
                         d1 = key_screw_dia, d2 = key_csk_dia, $fn = 32);
        }
    }
}

// One plate of keys, laid out for a single quick print job.
module key_plate(nx = 4, ny = 3, gap = 4) {
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([(i - (nx - 1) / 2) * (2 * key_half + gap),
                   (j - (ny - 1) / 2) * (2 * key_end_w + gap), 0])
            bowtie_key(j == 0);   // front row countersunk, for mounting
}

// Where the pockets sit: for each of the four edges, at the centres of cells
// kp_a and kp_b. Returns [x, y, rotation] triples.
function pocket_sites(nn) = is_undef(kp_a) ? [] : [
    for (p = [kp_a, kp_b])
        for (e = [0 : 3])
            let (c = cell_ctr_n(p, nn), h = tile_size / 2)
            e == 0 ? [ h,  c,   0] :   // +X edge
            e == 1 ? [-h,  c, 180] :   // -X edge
            e == 2 ? [ c,  h,  90] :   // +Y edge
                     [ c, -h, 270]     // -Y edge
];

// Solid thickening inside the cell, so a 4 mm pocket still leaves 1.6 mm of
// plate above it and the sealed cavity is never breached.
module key_bosses(nn) {
    if (key_pockets && nn == N)
        for (st = pocket_sites(nn))
            translate([st[0], st[1], back_t - fudge])
                rotate([0, 0, st[2]])
                    translate([-kb_deep, -kb_wide / 2, 0])
                        cube([kb_deep - rim_t / 2, kb_wide, key_boss_h + fudge]);
}

// The pocket itself: half the bowtie, opening at the module edge.
module key_pockets_cut(nn) {
    if (key_pockets && nn == N)
        for (st = pocket_sites(nn))
            translate([st[0], st[1], -fudge])
                rotate([0, 0, st[2]])
                    linear_extrude(height = key_t + fudge)
                        intersection() {
                            // true normal offset, not a coordinate nudge
                            offset(delta = key_clear) polygon(key_outline());
                            // keep only the half on this module's side, and
                            // run it past the edge so the pocket opens
                            translate([-key_half - 1, -key_end_w - 2])
                                square([key_half + 1 + fudge,
                                        2 * key_end_w + 4]);
                        }
}

// --- Per-cell colour (colour_mode = "logo_x") ------------------------------
// At 7x7 the MakerX letterform reduces to its two diagonal strokes, which is
// what is drawn here - a 13-cell X. Off-X floors alternate gold / electric
// blue by depth so the magenta X reads against them.
function on_logo_x(i, j) = (i == j) || (i + j == N - 1);
function cell_colour(i, j, s) =
    on_logo_x(i, j) ? 1 : (s % 2 == 0 ? 2 : 3);

// The coloured layer is only the top colour_skin of each floor: the colour
// change costs a few layers, not a whole body.
module floor_skin(i, j, nn, mat) {
    s = mat[j][i];
    translate([cell_lo_n(i, nn) - fudge, cell_lo_n(j, nn) - fudge,
               floor_top(s) - colour_skin])
        cube([cell_w + 2 * fudge, cell_w + 2 * fudge, colour_skin + fudge]);
}

module logo_skins(idx, nn, mat) {
    for (i = [0 : nn - 1], j = [0 : nn - 1])
        if (cell_colour(i, j, mat[j][i]) == idx) floor_skin(i, j, nn, mat);
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
            key_bosses(nn);
        }
        key_pockets_cut(nn);
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
// Both modes partition the tile exactly: the four bodies union back to
// full_tile() with no overlap and no gap.
module colour_body(idx) {
    if (colour_mode == "strata") {
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
    } else {
        if (idx == 0)
            difference() {                       // navy = the structure
                full_tile();
                for (c = [1, 2, 3]) logo_skins(c, N, QRD);
            }
        else
            intersection() {                     // accent = floor-top skins
                full_tile();
                logo_skins(idx, N, QRD);
            }
    }
}

module coloured_preview() {
    if (colour_mode == "strata") {
        e = band_edges();
        for (k = [0 : n_bands() - 1])
            color(MX_COLOURS[band_colour_index(k)])
                intersection() {
                    full_tile();
                    translate([-tile_size, -tile_size, e[k]])
                        cube([2 * tile_size, 2 * tile_size, e[k + 1] - e[k]]);
                }
    } else {
        for (idx = [0 : 3]) color(MX_COLOURS[idx]) colour_body(idx);
    }
}

// ===========================================================================
// === ASSEMBLY / RENDER =====================================================
// ===========================================================================

// Two modules butted with keys dropped in - the deliverable the key system is
// for, and the thing to look at when judging the joint.
module module_pair() {
    for (sx = [-1, 1])
        translate([sx * tile_size / 2, 0, 0]) coloured_preview();
    // keys sit in the shared joint, back-plate side
    if (key_pockets && !is_undef(kp_a))
        for (p = [kp_a, kp_b])
            color(MX_MAGENTA)
                translate([0, cell_ctr_n(p, N), 0]) bowtie_key(false);
}

// Interference gate: the key against one module, at its installed position.
// A correct clearance fit renders EMPTY. Any solid here is metal-on-metal.
module key_fit_test() {
    intersection() {
        full_tile();
        for (p = [kp_a, kp_b])
            translate([tile_size / 2, cell_ctr_n(p, N), 0]) bowtie_key(false);
    }
}

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
else if (part == "key")      bowtie_key(false);
else if (part == "key-mount") bowtie_key(true);
else if (part == "keyplate") key_plate();
else if (part == "pair")     module_pair();
else if (part == "fit")      key_fit_test();
else if (part == "coupon")   coupon();
else if (part == "preview")  coloured_preview();
else if (part == "section")  section_view();
else if (part == "navy")     colour_body(0);
else if (part == "magenta")  colour_body(1);
else if (part == "gold")     colour_body(2);
else if (part == "cyan")     colour_body(3);
else assert(false, str("Unknown part: ", part));
