// === DESCRIPTION ===
// MakerX Acoustic Diffuser — 500 SERIES v2 (TRUE LOGO). An ALTERNATE to the 125mm
// joinable quadrant (makerx-diffuser-tile-v2.scad), not a replacement. Both series are
// maintained; this one trades cheap failures for scale and a single 500mm statement.
//
// One printed part is a full 250 x 250 mm tile with a square notch bitten out of one
// corner. Four of them, each rotated a further 90 degrees so the notches meet in the
// middle, tile into 500 x 500 mm; the notches combine into a 71.43mm square hole that a
// separately printed KEY piece fills.
//
// WHAT CHANGED FROM tile-500-v1
//   v1 drew a symmetric diagonal X of its own invention. v2 carries the ACTUAL MakerX
//   mark, rasterised from MakerX.svg: two interlocking chevrons, the left one solid
//   #16acf2, the right one a #cc3a9d -> #ffc023 gradient flattened to solid magenta on
//   its upper arm and solid gold on its lower arm. Geometry is untouched — same notch,
//   same well-mixed relief, same acoustics — only the colour map differs.
//   It is also CHEAPER to print: each tile needs navy plus one accent (position 0 needs
//   two) rather than v1's three-colour arm, so 24-32 tool changes instead of 40.
//   The trade: the four tiles are no longer interchangeable, since the mark is not
//   symmetric. One tile STL, four 3MFs.
//
// WHY THE NOTCH
//   The X1/P1 reserves an 18 x 28mm front-left corner of the bed (bed_exclude_area,
//   protecting the filament-cutter stopper). The usual escape is Bambu's stopper-clip
//   mod, but that disables the cutter and therefore the AMS — it would forbid the
//   multi-colour this design is built around. Notching the part instead keeps the
//   exclusion zone intact AND the AMS available. Verified: a 2x2-cell (35.71mm) notch
//   clears the zone at 0, 3 and 6mm bed margin, so placement is not fussy.
//
//   Be clear about what the notch is worth: simply shifting a plain tile right to dodge
//   the zone already allows ~235mm at the same margin. The notch buys 250mm (+12.8%
//   area). Its real value is that 250 is the module where four tiles land on exactly
//   500 x 500 and the notches self-assemble into a home for the key.
//
// COLOUR IS DECOUPLED FROM HEIGHT HERE — the important difference from the 125 series.
//   The 125 series paints colour in elevation bands (3 filament changes, ~zero purge),
//   which means colour IS height: any colour pattern is necessarily a height pattern, so
//   drawing an X forces the X cells to be the tallest and biases the height field.
//   This series instead colours only the top skin_t (0.6mm) of each cell, chosen per
//   CELL rather than per height. Because cell tops sit at just 7 discrete heights, tool
//   changes are confined to 7 narrow z-ranges: roughly 42 changes and ~35g of purge per
//   tile, against ~670 changes and ~500g for naive full-height per-cell colour.
//   What that buys: the height field stays genuinely well mixed, so the diffusion is not
//   compromised to carry the branding.
//
// THE HEIGHT FIELD
//   Four 7x7 quadratic-residue blocks, s = (x^2 + y^2) mod 7, each at a different
//   rotation. The rotations break the 7-cell periodicity that would otherwise put
//   grating lobes in the scattering pattern, and because every rotation is a bijection
//   each block keeps the base histogram — so the assembled 14x14 depth distribution is
//   exactly 4x the verified 7x7 one.
//
// ACOUSTICS — unchanged from the 125 series by construction
//   Cell pitch stays 17.857mm and depth_step stays 10.8mm, so every Helmholtz tuning and
//   both grating limits transfer verbatim: design frequency 2269 Hz, upper limit 9604 Hz,
//   resonators laddered ~668-1909 Hz. See the 125 series header for the derivations and
//   for the honest limits (nothing useful below ~600 Hz; this is not a bass trap).
//
// Design decisions:
//   - base_t is 3.0mm here, NOT the 2.4mm of tile-v2. The back plate is what resists
//     warping, and a 250mm part leaves only 3mm of bed margin — too little for a brim.
//     The v2 thinning is correct at 125mm and does not scale.
//   - Only the MAIN diagonal is coloured. Rotating the tiles puts each main diagonal on
//     an arm of the 500mm X; colouring the anti-diagonal too would draw a second, smaller
//     X inside every tile and destroy the single-mark effect.
//   - The key is a plain drop-in with clearance, retained by the same adhesive that holds
//     the tiles. A mechanical catch would have to reach behind the tiles' back plates,
//     which is exactly the volume the notch exists to keep empty.
//
// Terminology -> code:
//   "tile" (the 250mm print)      -> part="tile", tile()
//   "key" (centre piece)          -> part="key", key()
//   "500 panel"                   -> part="assembly", assembly()
//   "notch"                       -> notch_cells, notch_w
//   "the logo" / "the mark"       -> TILE_COLOURS, colour_of(), SKIN_COLOURS
//   "which of the four tiles"     -> tile_index, ASSEMBLY
//   "colour skin"                 -> skin_t, cell_skin(), part="skin"/"body"
//   "cell"/"block"/"cavity"/"neck"-> as in makerx-diffuser-tile-v2.scad
//
// Common modifications:
//   Redraw the mark               -> re-run the SVG rasteriser and paste TILE_COLOURS
//   Simpler symmetric X instead   -> use makerx-diffuser-tile-500-v1.scad
//   Safer print, smaller panel    -> tile_size 240 (notch still needed; 480mm assembly)
//   Bigger/smaller notch          -> notch_cells (must stay >= exclusion, asserted)
//   Retune / relighten            -> as makerx-diffuser-tile-v2.scad
//
// Overall dimensions: 258 x 258 x 67.8 mm printed footprint per tile (250 cell field plus
//   a 4mm joining pin on each edge). Assembly 500 x 500 x 67.8 mm from 4 tiles + 1 key.
// Coordinate system: X, Y = the wall plane; Z = depth out of the wall. Print orientation.

// === PRINT SETTINGS ===
// Material: PLA. Layer Height: 0.2mm. Walls: 2 (0.8mm, shared between cells).
// Top/Bottom layers: 5 each — REQUIRED, the cavities must be gas-tight.
// Infill: 15% gyroid. Supports: none (all walls vertical; caps bridge 14.06mm).
// Orientation: as modelled, back plate on the bed, blocks up. Do not rotate.
// Bed: place the NOTCHED corner over the printer's front-left exclusion zone. Leave the
//   exclusion area ENABLED in Bambu Studio (that is the whole point — it keeps the AMS
//   usable). Any margin from 0 to 6mm works.
// WARNING: a 250mm part leaves ~3mm of bed margin, so no brim is possible and PLA corner
//   lift is a real risk on a part this size. Clean plate, good first layer, no draughts.
// Multi-colour: 4 filaments. The body is navy; the top 0.6mm of the X cells is gold,
//   magenta and electric blue outward along the arm. Expect ~42 tool changes and ~35g of
//   purge per tile. Use the supplied 4-colour 3MF, which carries the split as parts.
// Print time/mass: ~670g and ~30h per tile. A failure here costs far more than the 125
//   series' ~8h — that is the trade this design makes.

// === PARAMETERS ===
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_z         = 256;

part        = "tile";        // tile | key | assembly | tile_colour | assembly_colour
                             // body | skin | cutaway | interference
tile_index  = 0;             // which assembly position's colour map (0..3)
skin_group  = 1;             // which colour to emit when part="skin" (1 blue, 2 magenta,
                             // 3 gold)

// --- Bed / exclusion (drives the notch) ---
bed_size        = 256;
excl_x          = 18;        // bed_exclude_area, front-left corner
excl_y          = 28;
bed_margin      = 3;         // margin assumed when sizing the notch

// --- Tile geometry ---
tile_size   = 250;
grid_n      = 14;            // 2 x 7, so each 7x7 block is a full QRD period
notch_cells = 2;             // square, in cells — square is required (see assembly())
depth_step  = 10.8;
base_t      = 3.0;           // thicker than tile-v2: warp resistance at 250mm

// --- Shell / cavity (identical to tile-v2, so tunings carry over) ---
wall_t      = 0.8;           // shared between cells
cap_t       = 2.0;
cav_chamfer = 1.5;

// --- Helmholtz necks ---
neck_w          = 1.2;
slot_shrink     = 0.1;
resonator_min_s = 1;
NECK_SPAN = [0, 8.4, 13.5, 14.5, 12.7, 9.6, 7.2];

// --- Colour ---
skin_t      = 0.6;           // 3 layers: opaque over navy, cheap in tool changes
MX_NAVY = "#0f1c57"; MX_EBLUE = "#16acf2"; MX_MAGENTA = "#cc3a9d"; MX_GOLD = "#ffc023";
// Indexed by the colour codes in TILE_COLOURS. Straight from MakerX.svg: the solid
// chevron is #16acf2; the other is the #cc3a9d -> #ffc023 gradient, flattened per arm.
SKIN_COLOURS = [MX_NAVY, MX_EBLUE, MX_MAGENTA, MX_GOLD];

// --- Joining / key ---
spline_w   = 20;             // along the seam
spline_len = 12;             // across it — half sits in each tile
spline_t   = 1.2;            // depth into the 3mm back plate
tol        = 0.2;
key_gap  = 0.3;              // clearance all round so the key drops in

sound_c = 343000;

// === DERIVED CONSTANTS ===
cell_pitch       = tile_size / grid_n;
notch_w          = notch_cells * cell_pitch;
key_size         = 2 * notch_w;               // four notches meet -> 2x the notch
cav_w_int        = cell_pitch - wall_t;
cav_w_edge       = cell_pitch - 1.5 * wall_t;
cav_top_open     = cav_w_int  - 2 * cav_chamfer;
cav_top_open_min = cav_w_edge - 2 * cav_chamfer;
block_h_max      = 6 * depth_step;
total_h          = base_t + block_h_max;
fudge            = 0.01;
ef_chamfer       = 0.4;
block_expand     = wall_t / 2 - 0.01;         // see tile-v2: must stop short of wall_t/2
$fn              = $preview ? 24 : 48;

// === HEIGHT FIELD ===
function qrd7(x, y) = (x * x + y * y) % 7;

// Four 7x7 QRD blocks at four different rotations. Every rotation is a bijection on
// 0..6, so each block keeps the base histogram while the periodicity is broken.
function mixed_s(x, y) =
    let (bx = floor(x / 7), by = floor(y / 7),
         lx = x - bx * 7,   ly = y - by * 7,
         bi = by * 2 + bx,
         rx = bi == 0 ? lx : bi == 1 ? ly     : bi == 2 ? 6 - lx : 6 - ly,
         ry = bi == 0 ? ly : bi == 1 ? 6 - lx : bi == 2 ? 6 - ly : lx)
    qrd7(rx, ry);

// Colour never touches the height field in v2 — the mark is carried entirely by the top
// skin, so the relief stays exactly the well-mixed QRD arrangement.
function height_index(x, y) = mixed_s(x, y);

function block_h(x, y) = height_index(x, y) * depth_step;
function in_notch(x, y) = (x < notch_cells) && (y < notch_cells);

// === THE LOGO ===
// v2 replaces v1's symmetric diagonal X with the REAL mark. MakerX.svg holds two
// interlocking chevrons: a solid #16acf2 one on the left, and one on the right filled with
// a #cc3a9d -> #ffc023 gradient running top to bottom. Both polygons were rasterised onto
// the 28x28 cell grid of the assembly (scripted from the SVG, not eyeballed), then split
// into these four per-tile maps. The gradient becomes two solid colours at the chevron's
// own mid-height, which is what its two arms already read as.
//
// Consequences worth knowing:
//   - The four tiles are NO LONGER interchangeable. The mark is not symmetric, so each
//     assembly position gets its own colour map. The GEOMETRY is still identical for all
//     four — only the body/skin split differs — so there is one tile STL and four 3MFs.
//   - Each tile needs only navy plus ONE accent (position 0 needs two), so this is
//     CHEAPER than v1's three-colour gradient arm: 24-32 tool changes instead of 40.
//   - The logo's centre is empty, so the key comes out plain navy. That is faithful; the
//     real mark has a gap where the two chevrons' notches face each other.
//   - The logo is 1300x1100, so fitted to a square panel it letterboxes: roughly three
//     cell rows top and bottom carry no colour.
//
// 0 = navy (no skin), 1 = electric blue, 2 = magenta, 3 = gold.
// Index order matches ASSEMBLY below: (0,0)r180, (1,0)r270, (0,1)r90, (1,1)r0.
TILE_COLOURS = [
  [[0,0,0,1,1,0,0,0,0,0,0,0,0,0], [0,0,0,0,1,0,0,0,0,0,0,0,0,0], [0,3,0,0,0,1,0,0,0,0,0,0,0,0], [3,0,0,0,0,0,1,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,1,0,0,0,0,0,0], [0,1,0,0,0,0,0,0,1,0,0,0,0,0], [0,1,1,0,0,0,0,0,1,1,0,0,0,0], [0,0,1,0,0,0,0,0,0,1,1,0,0,0], [0,0,0,1,0,0,0,0,0,0,1,0,0,0], [0,0,0,0,1,0,0,0,0,0,0,1,0,0], [0,0,0,0,0,1,1,1,1,1,1,1,1,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0]],
  [[0,0,0,0,3,3,0,0,0,0,0,0,0,0], [0,0,0,0,0,3,3,0,0,0,0,0,0,0], [0,0,0,0,0,0,3,3,0,0,0,0,0,0], [3,0,0,0,0,0,0,0,3,0,0,0,0,0], [3,3,0,0,0,0,0,0,0,3,0,0,0,0], [0,0,3,0,0,0,0,0,0,0,3,0,0,0], [0,0,0,3,0,0,0,0,0,0,3,0,0,0], [0,0,0,0,3,0,0,0,0,0,3,0,0,0], [0,0,0,0,0,3,3,0,0,0,3,0,0,0], [0,0,0,0,0,0,3,3,0,0,3,0,0,0], [0,0,0,0,0,0,0,3,3,0,3,0,0,0], [0,0,0,0,0,0,0,0,0,3,3,0,0,0], [0,0,0,0,0,0,0,0,0,0,3,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0]],
  [[0,0,0,1,1,1,0,0,0,0,0,0,0,0], [0,0,1,1,1,1,1,0,0,0,0,0,0,0], [0,1,1,1,1,1,1,1,0,0,0,0,0,0], [1,1,1,1,1,1,1,1,1,0,0,0,0,0], [1,1,1,1,1,1,1,1,1,1,0,0,0,0], [0,0,1,1,1,1,1,1,1,1,1,0,0,0], [0,0,0,1,1,1,1,1,1,1,1,0,0,0], [0,0,0,0,1,1,1,1,1,1,1,0,0,0], [0,0,0,0,0,1,1,1,1,1,1,0,0,0], [0,0,0,0,0,0,1,1,1,1,1,0,0,0], [0,0,0,0,0,0,0,1,1,1,1,0,0,0], [0,0,0,0,0,0,0,0,0,1,1,0,0,0], [0,0,0,0,0,0,0,0,0,0,1,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0]],
  [[0,0,0,2,2,0,0,0,0,0,0,0,0,0], [0,0,0,0,2,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,2,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,2,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,2,0,0,0,0,0,0], [0,2,0,0,0,0,0,0,2,0,0,0,0,0], [0,2,2,0,0,0,0,0,2,2,0,0,0,0], [0,0,2,0,0,0,0,0,0,2,2,0,0,0], [0,0,0,2,0,0,0,0,0,0,2,0,0,0], [0,0,0,0,2,0,0,0,0,0,0,2,0,0], [0,0,0,0,0,2,2,2,2,2,2,2,2,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0], [0,0,0,0,0,0,0,0,0,0,0,0,0,0]],
];

function colour_of(ti, x, y) = in_notch(x, y) ? 0 : TILE_COLOURS[ti][y][x];

// === ACOUSTIC MODEL (identical to tile-v2) ===
function design_f() = sound_c / (2 * 7 * depth_step);
function f_max()    = sound_c / (2 * cell_pitch);
function cav_vol_wh(s, wx, wy) =
    let (a1 = wx * wy,
         a2 = (wx - 2 * cav_chamfer) * (wy - 2 * cav_chamfer),
         hc = s * depth_step - cap_t)
    a1 * (hc - cav_chamfer) + (cav_chamfer / 3) * (a1 + a2 + sqrt(a1 * a2));
function cav_vol(s)   = cav_vol_wh(s, cav_w_int, cav_w_int);
function neck_area(s) = 2 * NECK_SPAN[s] * neck_w - neck_w * neck_w;
function neck_leff(s) = cap_t + 1.7 * sqrt(neck_area(s) / PI);
function helmholtz_f(s) =
    (sound_c / (2 * PI)) * sqrt(neck_area(s) / (cav_vol(s) * neck_leff(s)));
function neck_bbox(s) = (NECK_SPAN[s] + neck_w + slot_shrink) / sqrt(2);

// === DESIGN CONTRACTS ===
counts = [ for (v = [0:6])
             len([ for (y = [0:grid_n-1], x = [0:grid_n-1])
                     if (!in_notch(x, y) && height_index(x, y) == v) 1 ]) ];
// Coloured-cell tally per tile position, used by the echo and the contract below.
col_counts = [ for (ti = [0:3])
                 [ for (c = [1:3])
                     len([ for (y = [0:grid_n-1], x = [0:grid_n-1])
                             if (colour_of(ti, x, y) == c) 1 ]) ] ];

assert(grid_n % 7 == 0, "grid_n must be a whole number of 7-cell QRD periods");
assert(abs(cell_pitch * grid_n - tile_size) < 1e-9, "cells must exactly fill the tile");
assert(abs(depth_step / layer_height - round(depth_step / layer_height)) < 1e-6,
       "depth_step must be a whole number of layers");
assert(abs(skin_t / layer_height - round(skin_t / layer_height)) < 1e-6,
       "skin_t must be a whole number of layers");
assert(wall_t >= 2 * nozzle_diameter - 1e-9, "wall_t < 2 perimeters — cavities will leak");
assert(cav_top_open <= 25, "cap bridge span exceeds PLA's clean-bridge limit");
assert(total_h <= build_z, "taller than the build volume");
// The PRINTED footprint, including anything that sticks out past the cell field, must fit
// the bed with the assumed margin. Nothing protrudes in this series by design; this assert
// is what stops a future edit from reintroducing pins that would not fit.
printed_footprint = tile_size;      // no protrusions
assert(printed_footprint + 2 * bed_margin <= bed_size,
       str("printed footprint ", printed_footprint, "mm + 2x", bed_margin,
           "mm margin exceeds the ", bed_size, "mm bed"));
assert(base_t - (spline_t + tol) >= 5 * layer_height,
       "too little back plate above the spline pocket — cavities would leak");
assert(spline_len / 2 + tol < cell_pitch - wall_t,
       "spline pocket reaches deeper than the first cell's wall");
// THE notch contract: with the notched corner at the bed corner and `bed_margin` of
// margin, no tile material may reach into the exclusion zone.
assert(notch_w >= excl_x - bed_margin && notch_w >= excl_y - bed_margin,
       str("notch ", notch_w, "mm does not clear the ", excl_x, "x", excl_y,
           "mm exclusion zone at ", bed_margin, "mm margin (need ",
           max(excl_x, excl_y) - bed_margin, "mm)"));
assert(tile_size + bed_margin <= bed_size,
       "tile plus margin does not fit the bed");
// The four notches only form a square hole if the notch itself is square.
assert(notch_cells >= 1 && notch_cells == floor(notch_cells),
       "notch_cells must be a whole number of cells");
assert(2 * notch_cells < grid_n, "notch consumes too much of the tile");
for (s = [resonator_min_s : 6]) {
    assert(neck_bbox(s) <= cav_top_open_min,
           str("X slot for s=", s, " overruns the flat cap of an edge cell"));
    assert(s * depth_step - cap_t > cav_chamfer + layer_height,
           str("no cavity height left for s=", s));
}
// The 14x14 field must be exactly four copies of the 7x7 histogram (minus the notch).
qrd_counts = [ for (v = [0:6])
                 len([ for (y = [0:6], x = [0:6]) if (qrd7(x, y) == v) 1 ]) ];
notch_counts = [ for (v = [0:6])
                   len([ for (y = [0:grid_n-1], x = [0:grid_n-1])
                           if (in_notch(x, y) && mixed_s(x, y) == v) 1 ]) ];
assert(counts == [for (i = [0:6]) 4 * qrd_counts[i] - notch_counts[i]],
       str("height histogram ", counts, " is not 4x the QRD histogram less the notch"));
// The four colour maps must be the right shape, and no colour may land in the notch
// (there is no cell there to carry it).
assert(len(TILE_COLOURS) == 4, "need one colour map per assembly position");
for (ti = [0:3]) {
    assert(len(TILE_COLOURS[ti]) == grid_n,
           str("colour map ", ti, " has the wrong number of rows"));
    for (r = TILE_COLOURS[ti])
        assert(len(r) == grid_n, str("colour map ", ti, " has a wrong-length row"));
    for (y = [0:notch_cells-1], x = [0:notch_cells-1])
        assert(TILE_COLOURS[ti][y][x] == 0,
               str("colour map ", ti, " puts colour in the notch at ", [x, y]));
}

echo(str("=== MakerX 500 series v2 (true logo): ", grid_n, "x", grid_n, " cells ==="));
echo(str("  tile ", tile_size, " x ", tile_size, " x ", total_h,
         " mm  (printed footprint ", printed_footprint, " sq — nothing protrudes; ",
         bed_size - printed_footprint, "mm of bed slack)"));
echo(str("  notch ", notch_w, " mm (", notch_cells, "x", notch_cells,
         " cells) clears the ", excl_x, "x", excl_y, " exclusion by ",
         round((notch_w - (excl_y - bed_margin)) * 10) / 10, " mm"));
echo(str("  assembly ", 2 * tile_size, " x ", 2 * tile_size, " mm from 4 tiles + a ",
         key_size, " mm key (", 2 * notch_cells, "x", 2 * notch_cells, " cells)"));
echo(str("  diffusion  f0 = ", round(design_f()), " Hz   upper = ", round(f_max()),
         " Hz   depths 0..", block_h_max, " mm"));
for (s = [resonator_min_s : 6])
    echo(str("    s=", s, "  ->  ", round(helmholtz_f(s)), " Hz"));
echo(str("  height histogram (excl. notch) ", counts, "  sum ",
         grid_n * grid_n - notch_cells * notch_cells));
echo(str("  colour = top ", skin_t, " mm, per cell, from MakerX.svg rasterised to ",
         2 * grid_n, "x", 2 * grid_n));
for (ti = [0:3])
    echo(str("    tile ", ti, " at ", ASSEMBLY[ti][0], " rot ", ASSEMBLY[ti][1],
             ": blue ", col_counts[ti][0], "  magenta ", col_counts[ti][1],
             "  gold ", col_counts[ti][2], "  (", col_counts[ti][0] + col_counts[ti][1]
             + col_counts[ti][2], " coloured cells)"));
echo(str("  key is plain navy — the real mark leaves its centre empty"));

// === MODULES ===
module ef_slab(w, d, h, ef) {
    hull() {
        translate([ef, ef, 0])  cube([w - 2 * ef, d - 2 * ef, 0.01]);
        translate([0, 0, ef])   cube([w, d, h - ef]);
    }
}

// NO protruding pins in this series. At 250mm the printed footprint must stay 250mm:
// the bed is 256 and anything sticking out would not fit (the 125 series' 4mm pins would
// make it 258). Alignment instead uses a pocket at the MIDDLE of each edge plus a
// separate printed SPLINE that bridges two facing pockets. The midpoint is its own
// mirror, so the joint is rotation-agnostic for free — two abutting edges always present
// their pockets to each other whatever way the tiles are turned.
module edge_socket() {
    translate([tile_size / 2 - (spline_w + 2 * tol) / 2, -fudge, -fudge])
        cube([spline_w + 2 * tol, spline_len / 2 + tol + fudge, spline_t + tol + fudge]);
}

// The loose spline: spans the seam, sitting in the pocket of each tile. It ends up
// between the panel and the wall, flush with the back face.
module spline() {
    ef_slab(spline_w - 2 * tol, spline_len - 2 * tol, spline_t, ef_chamfer / 2);
}

module on_each_edge() {
    for (i = [0:3])
        translate([tile_size / 2, tile_size / 2, 0]) rotate([0, 0, 90 * i])
            translate([-tile_size / 2, -tile_size / 2, 0]) children();
}

// The tile outline is an L: the square less the notch.
module outline_prism(h, inset = 0) {
    difference() {
        translate([inset, inset, 0])
            cube([tile_size - 2 * inset, tile_size - 2 * inset, h]);
        translate([-fudge, -fudge, -fudge])
            cube([notch_w + inset + fudge, notch_w + inset + fudge, h + 2 * fudge]);
    }
}

module base_plate() {
    difference() {
        intersection() {
            ef_slab(tile_size, tile_size, base_t, ef_chamfer);
            outline_prism(base_t + 1);
        }
        on_each_edge() edge_socket();
    }
}

module block_solid(x, y) {
    h = block_h(x, y);
    e = block_expand;
    if (h > 0 && !in_notch(x, y))
        translate([x * cell_pitch - e, y * cell_pitch - e, base_t - fudge])
            cube([cell_pitch + 2 * e, cell_pitch + 2 * e, h + fudge]);
}

module cavity(x, y) {
    s = height_index(x, y);
    if (s >= resonator_min_s && !in_notch(x, y)) {
        c = wall_t / 2;
        // Keep a full wall_t inside every outline edge — including the two notch faces,
        // which are outline edges for the cells that border them.
        lox = (x == notch_cells && y < notch_cells) ? notch_w + wall_t : wall_t;
        loy = (y == notch_cells && x < notch_cells) ? notch_w + wall_t : wall_t;
        x0  = max(x * cell_pitch + c, lox);
        x1  = min((x + 1) * cell_pitch - c, tile_size - wall_t);
        y0  = max(y * cell_pitch + c, loy);
        y1  = min((y + 1) * cell_pitch - c, tile_size - wall_t);
        wx  = x1 - x0;  wy = y1 - y0;
        top = base_t + s * depth_step - cap_t;
        zc  = top - cav_chamfer;
        translate([(x0 + x1) / 2, (y0 + y1) / 2, 0]) {
            translate([0, 0, base_t])
                linear_extrude(height = zc - base_t + fudge) square([wx, wy], center = true);
            // hull of two plates, never linear_extrude(scale=) — see tile-v2
            hull() {
                translate([0, 0, zc]) linear_extrude(height = fudge)
                    square([wx, wy], center = true);
                translate([0, 0, top - fudge]) linear_extrude(height = fudge)
                    square([wx - 2 * cav_chamfer, wy - 2 * cav_chamfer], center = true);
            }
        }
    }
}

module neck_x(x, y) {
    s = height_index(x, y);
    if (s >= resonator_min_s && !in_notch(x, y)) {
        span = NECK_SPAN[s];
        w    = neck_w + slot_shrink;
        z0   = base_t + s * depth_step - cap_t;
        translate([(x + 0.5) * cell_pitch, (y + 0.5) * cell_pitch, z0 - fudge])
            linear_extrude(height = cap_t + 2 * fudge)
                rotate(45) { square([span, w], center = true);
                             square([w, span], center = true); }
    }
}

// === TILE ===
module tile_solid() {
    difference() {
        union() {
            base_plate();
            intersection() {
                union() { for (y = [0:grid_n-1], x = [0:grid_n-1]) block_solid(x, y); }
                translate([0, 0, base_t - 2 * fudge]) outline_prism(total_h);
            }
        }
        for (y = [0:grid_n-1], x = [0:grid_n-1]) { cavity(x, y); neck_x(x, y); }
    }
}

// The slab of a cell that carries its colour: the top skin_t of that cell's block.
//
// The lateral expansion is a balance, and both ends of it bite:
//   - Zero expansion makes diagonally adjacent same-colour cells touch on a bare corner,
//     which is non-manifold. The logo is full of diagonal runs, so that is not academic.
//   - Expanding by the full block_expand reaches to the centre-line of the shared wall.
//     Where the neighbour is TALLER its wall exists at this z, so the skin steals most of
//     it and leaves the body a sliver — measured as 2 non-manifold edges on tiles 1 and 2.
// Half of block_expand clears both: diagonal neighbours share a real 0.4 x 0.4mm volume,
// and the body keeps 0.6mm of any 0.8mm wall it has to give up a slice of.
skin_expand = block_expand / 2;
module skin_box(x, y) {
    ztop = base_t + block_h(x, y);
    e    = skin_expand;
    translate([x * cell_pitch - e, y * cell_pitch - e, ztop - skin_t])
        cube([cell_pitch + 2 * e, cell_pitch + 2 * e, skin_t + fudge]);
}

module skin_boxes(ti, group) {
    for (y = [0:grid_n-1], x = [0:grid_n-1])
        if (colour_of(ti, x, y) == group) skin_box(x, y);
}

module tile_skin(ti, group) { intersection() { tile_solid(); skin_boxes(ti, group); } }
module tile_body(ti)        { difference()   { tile_solid();
                                               for (g = [1:3]) skin_boxes(ti, g); } }

module tile() { tile_solid(); }

// === KEY ===
// 4x4 cells filling the hole the four notches leave. All of it is the X crossing, so the
// whole top skin is gold. Dropped in with clearance and held by the same adhesive as the
// tiles — a mechanical catch would need the volume behind the tiles that the notch exists
// to keep clear.
KEY_MAP = [[2, 6, 3, 5],
           [6, 1, 5, 4],
           [3, 5, 6, 2],
           [5, 4, 2, 6]];
key_n = 2 * notch_cells;
function key_h(x, y) = KEY_MAP[y][x] * depth_step;

module key_solid() {
    ks = key_size - 2 * key_gap;
    difference() {
        union() {
            ef_slab(ks, ks, base_t, ef_chamfer);
            intersection() {
                union() {
                    for (y = [0:key_n-1], x = [0:key_n-1]) {
                        e = block_expand;
                        translate([x * cell_pitch - e, y * cell_pitch - e, base_t - fudge])
                            cube([cell_pitch + 2 * e, cell_pitch + 2 * e,
                                  key_h(x, y) + fudge]);
                    }
                }
                translate([0, 0, base_t - 2 * fudge]) cube([ks, ks, total_h]);
            }
        }
        for (y = [0:key_n-1], x = [0:key_n-1]) {
            s = KEY_MAP[y][x];
            c = wall_t / 2;
            x0 = max(x * cell_pitch + c, wall_t);
            x1 = min((x + 1) * cell_pitch - c, ks - wall_t);
            y0 = max(y * cell_pitch + c, wall_t);
            y1 = min((y + 1) * cell_pitch - c, ks - wall_t);
            wx = x1 - x0; wy = y1 - y0;
            top = base_t + s * depth_step - cap_t;
            zc  = top - cav_chamfer;
            translate([(x0 + x1) / 2, (y0 + y1) / 2, 0]) {
                translate([0, 0, base_t])
                    linear_extrude(height = zc - base_t + fudge)
                        square([wx, wy], center = true);
                hull() {
                    translate([0, 0, zc]) linear_extrude(height = fudge)
                        square([wx, wy], center = true);
                    translate([0, 0, top - fudge]) linear_extrude(height = fudge)
                        square([wx - 2 * cav_chamfer, wy - 2 * cav_chamfer], center = true);
                }
            }
            span = NECK_SPAN[s];
            w    = neck_w + slot_shrink;
            translate([(x + 0.5) * cell_pitch, (y + 0.5) * cell_pitch,
                       base_t + s * depth_step - cap_t - fudge])
                linear_extrude(height = cap_t + 2 * fudge)
                    rotate(45) { square([span, w], center = true);
                                 square([w, span], center = true); }
        }
    }
}

// The key is built exactly like a tile — navy body, coloured top skin — not a solid gold
// block. Same construction, and it keeps the gold to the 0.6mm that is actually seen.
// Every key cell is part of the X crossing, so the whole skin is gold.
module key_skin_boxes() {
    for (y = [0:key_n-1], x = [0:key_n-1]) {
        ztop = base_t + key_h(x, y);
        e    = block_expand;
        translate([x * cell_pitch - e, y * cell_pitch - e, ztop - skin_t])
            cube([cell_pitch + 2 * e, cell_pitch + 2 * e, skin_t + fudge]);
    }
}
// v2: the real mark leaves its centre empty, so the key is single-colour navy — no skin
// split, and its 3MF needs one filament. key_skin_boxes() is retained only so a future
// variant that does put colour at the centre has the hook ready.
key_colour = MX_NAVY;        // overridable so the key can be picked out in a preview
module key_body()     { key_solid(); }
module key_coloured() { color(key_colour) key_solid(); }

module key() { key_solid(); }

// === ASSEMBLY ===
// Rotations derived, not guessed: each tile's notch must land on the corner facing the
// assembly centre. Confirmed by construction — the four notches form one square hole of
// side 2*notch_w, centred on the assembly centre.
ASSEMBLY = [[[0, 0], 180], [[1, 0], 270], [[0, 1], 90], [[1, 1], 0]];

module assembly(coloured = false) {
    for (i = [0:3])
        translate([ASSEMBLY[i][0][0] * tile_size, ASSEMBLY[i][0][1] * tile_size, 0])
            translate([tile_size / 2, tile_size / 2, 0]) rotate([0, 0, ASSEMBLY[i][1]])
                translate([-tile_size / 2, -tile_size / 2, 0])
                    if (coloured) tile_coloured(i); else tile();
    translate([tile_size - notch_w + key_gap, tile_size - notch_w + key_gap, 0])
        if (coloured) key_coloured(); else key();
}

module tile_coloured(ti) {
    color(MX_NAVY) tile_body(ti);
    for (g = [1:3]) color(SKIN_COLOURS[g]) tile_skin(ti, g);
}

// Neighbouring tiles must share no volume, for any relative rotation.
interf_rot = 90;
interf_dir = "x";
module interference() {
    dx = interf_dir == "x" ? tile_size : 0;
    dy = interf_dir == "y" ? tile_size : 0;
    intersection() {
        tile();
        translate([dx, dy, 0]) translate([tile_size / 2, tile_size / 2, 0])
            rotate([0, 0, interf_rot])
                translate([-tile_size / 2, -tile_size / 2, 0]) tile();
    }
}

module cutaway() {
    difference() {
        tile();
        translate([-1, tile_size / 2, -1])
            cube([tile_size + 2, tile_size, total_h + 2]);
    }
}

if      (part == "tile")            tile();
else if (part == "key")             key();
else if (part == "assembly")        assembly(false);
else if (part == "assembly_colour") assembly(true);
else if (part == "tile_colour")     tile_coloured(tile_index);
else if (part == "body")            tile_body(tile_index);
else if (part == "skin")            tile_skin(tile_index, skin_group);
else if (part == "key_body")        key_body();
else if (part == "spline")          spline();
else if (part == "cutaway")         cutaway();
else if (part == "interference")    interference();
else assert(false, str("unknown part: ", part));
