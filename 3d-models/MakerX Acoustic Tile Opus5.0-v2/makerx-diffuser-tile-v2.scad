// === DESCRIPTION ===
// MakerX Acoustic Diffuser Tile (Opus5.0-v2) — MODEL REVISION v2: a wall-mounted 2D
// "skyline" phase-grating diffuser with built-in Helmholtz absorbers, branded in MakerX
// colours and logomark.
//
// WHAT CHANGED FROM v1 (same acoustics, 35% less plastic: 218.5 -> 140.9 cm^3 solid)
//   The v1 mass was structural, and this part carries nothing but its own weight on a
//   wall. It was also not doing acoustic work: a Helmholtz resonator's absorption comes
//   from the enclosed AIR and the slot geometry, with the plastic acting purely as an
//   airtight, non-flexing container. By the mass law a 0.8mm PLA wall (0.99 kg/m^2) still
//   reflects ~95% of incident energy at 1 kHz against ~98% for 1.2mm — inaudible.
//     1. SHARED WALLS. v1 gave every cell its own four walls, so each internal boundary
//        carried 2 x wall_t stacked back to back. v2 puts one shared wall on the boundary.
//     2. wall_t 1.2 -> 0.8 (3 perimeters -> 2, still airtight).
//     3. base_t 3.0 -> 2.4, still solid right through at 5+5 solid layers.
//   The cavities got ~22% bigger as a side effect (the doubled walls became air), so every
//   X slot was reopened to hold the original tuning. Net: 668-1909 Hz vs v1's 690-1999 Hz.
//
// The job it does: scatter mid/high-frequency reflections in a room (flutter echo,
// slap-back off a hard wall, harsh early reflections in a meeting room or studio)
// instead of letting them bounce back specularly. A secondary set of tuned cavities
// converts a slice of the low-mid energy to heat.
//
// Physical context: hangs flat on an interior wall or ceiling, no load beyond its own
// mass (~250 g per quadrant), room temperature, no UV. Mounted with double-sided foam
// tape / Command strips on the flat back, or on 15-25mm battens (a rear air gap
// measurably improves the low end). Butts edge-to-edge with neighbours; the cell grid
// runs right to the tile boundary so a wall of tiles reads as one continuous field.
//
// THE ACOUSTICS (all numbers echoed at build time — see helmholtz_f() / design_f())
//   Diffusion:  7x7 cells of pitch 17.857mm, 7 discrete depths in steps of 10.8mm
//               (0 .. 64.8mm). Design frequency f0 = c / (2*N*depth_step) * ... = 2268 Hz;
//               useful scattering extends roughly half an octave below that.
//               Upper limit f_max = c / (2*cell_pitch) = 9604 Hz — above this the cells
//               are large compared to a wavelength and stop behaving as a phase grating.
//   Absorption: 48 of the 49 cells are SEALED Helmholtz resonators (all but the one
//               full-depth cell, which has no block). Cavity = the hollow block
//               interior; neck = the X-shaped slot in its cap. Six tunings, set by cell
//               height and slot size, ladder from ~690 Hz up to ~2000 Hz — deliberately
//               meeting the phase grating's 2270 Hz design frequency so there is no
//               untreated gap between the two mechanisms. The X slot is not decoration:
//               at equal open area it has 2.26x the wetted perimeter of a round hole,
//               so ~5x the viscous resistance — that damping is what broadens each
//               resonator from a needle-sharp peak into something useful.
//   Honest limits: this is NOT broadband absorption and NOT bass trapping. Below ~600 Hz
//               a 68mm-deep rigid panel behaves essentially like the wall it is stuck to.
//               "Total internal reflection" is an optics idea with no acoustic analogue
//               at these scales — a rigid panel turns sound into heat only via resonance
//               plus viscous/thermal loss in narrow openings, which is exactly what the
//               Helmholtz cells do.
//
// THE BRANDING (sourced from https://makerx.com.au/ CSS custom properties, 2026-08-01)
//   --color-mx-blue         #0f1c57   navy      -> elevation band 0
//   --color-mx-electic-blue #16acf2   (sic)     -> elevation band 1
//   --color-mx-magenta      #cc3a9d             -> elevation band 2
//   --color-mx-gold         #ffc023             -> elevation band 3 (the peaks)
//   Band order blue -> magenta -> gold reproduces the site's hero gradient stops.
//   Colour is applied as horizontal ELEVATION BANDS (3 filament changes for the whole
//   print), never per-cell: per-cell colour would need ~4 AMS tool changes on every one
//   of 339 layers, roughly 2.7 kg of purge waste per 250mm tile.
//   Because colour tracks height, the height map is what draws the logo:
//     height_map = "logo" (default) — the 8 tallest cells trace the MakerX X, so the X
//                  lands in the gold band. Same multiset of depths as the QRD map (same
//                  mass, same scattering bandwidth) but permuted, so scattering is
//                  pseudo-random rather than optimally uniform.
//     height_map = "qrd"  — textbook 2D quadratic-residue sequence s = (x^2+y^2) mod 7.
//                  Acoustically optimal, but the peaks form a ring, not an X.
//   The MakerX two-chevron logomark is also embossed in the one full-depth (s=0) cell.
//
// Design decisions:
//   - Printed FACE UP with the flat back plate on the bed: every wall is a vertical
//     prism, so the whole part is support-free. The only overhangs are the cavity caps,
//     which bridge 11.5mm (PLA bridges 25mm cleanly) after a 45 deg self-supporting
//     chamfer narrows the opening.
//   - Split into 125mm quadrants rather than one 250mm piece. A 250mm part needs the
//     Bambu full-volume mod, which disables the filament cutter and therefore the AMS —
//     i.e. it would forbid the multi-colour the design depends on. 125mm quadrants sit
//     well inside the stock 220mm auto-centred area with the AMS available.
//   - Quadrants are rotated 0/90/180/270 when assembled into a 250mm tile. The height
//     map is deliberately NOT 4-fold symmetric, so rotation breaks the 125mm periodicity
//     that would otherwise produce grating lobes.
//   - Edge joints are rotation-agnostic: every edge, walked counter-clockwise, carries a
//     pin at 25% and a socket at 75%. Two tiles that meet traverse their shared edge in
//     opposite directions, so pin always lands on socket — for any rotation, any tiling.
//   - Blocks are hollow shells, not solids. A solid skyline would be ~430 cm^3 of PLA
//     per quadrant; hollow shells with sealed cavities are ~40% of that AND the cavity
//     is the resonator. Structure and acoustics come from the same void.
//   - Even the shortest blocks are hollowed. Hollowing an s=1 block costs the same
//     filament as letting the slicer infill it solid, but turns it into a ~2 kHz
//     resonator — the class that closes the gap up to the diffuser's design frequency.
//
// Terminology -> code:
//   "tile" (250mm, 4 pieces)   -> part="tile", tile_size (per quadrant = 125)
//   "quadrant" (the printed part) -> part="quadrant", quadrant()
//   "cell" / "block"           -> cell_pitch, block_h(), height_index()
//   "well depth" / "skyline"   -> depth_step, height_map, LOGO_MAP, qrd_s()
//   "cavity" (the resonator)   -> cavity(), cav_vol(), wall_t, cap_t, cav_chamfer
//   "X slot" / "neck"          -> neck_x(), neck_w, NECK_SPAN, neck_area(), helmholtz_f()
//   "back plate"               -> base_t, base_plate()
//   "joining pins"             -> tab_w, tab_out, tab_h, edge_pin(), edge_socket()
//   "logo emboss"              -> logomark(), emboss_w, emboss_h
//   "colour bands"             -> colour_band_z (echoed as filament-change heights)
//
// Common modifications:
//   Lower the diffusion band      -> depth_step (keep a multiple of layer_height;
//                                    f0 = 2268 Hz at 10.8; deeper = lower = heavier)
//   Retune the absorbers          -> NECK_SPAN per height class (bigger slot = higher Hz)
//                                    or depth_step (bigger cavity = lower Hz)
//   Lighter / faster print        -> wall_t 1.2 -> 0.8 (saves ~25%, slightly less rigid)
//   Optimal scattering, no X      -> height_map = "qrd"
//   Different tile size           -> tile_size (cell_pitch derives; keep grid_n prime)
//   Single-colour print           -> ignore colour_band_z; geometry is unchanged
//   Fit a smaller printer         -> tile_size (printed footprint = tile_size + tab_out)
//
// Overall dimensions: 133 x 133 x 67.2 mm printed footprint per quadrant
//   (125 x 125 nominal cell field + one 4mm joining pin protruding from each of the
//    four edges; fits the Bambu X1C stock 220mm auto-centred area, AMS available)
//   Assembled tile: 250 x 250 x 67.8 mm from 4 quadrants.
// Coordinate system: X, Y = the wall plane; Z = height from build plate = depth out of
//   the wall. Model is in PRINT orientation.
// NOTE: In use, Z becomes the wall-normal axis — the Z=0 back plate faces the wall and
//   the tall gold blocks point into the room.

// === PRINT SETTINGS ===
// Material: PLA. Chosen over PETG because nothing here is load-bearing or hot, and PLA
//   (a) bridges the 32 cavity caps cleanly, (b) does not string across the 1.2mm X-slot
//   necks — stringing there would literally change the neck area and detune the
//   resonators, (c) gives crisper colour-change boundaries. Use PETG only if the wall
//   receives direct sunlight (set tol = 0.3 if you do).
// Layer Height: 0.2mm (depth_step, base_t and cap_t are all exact multiples)
// Walls/Perimeters: 2 (0.8mm) — the airtightness floor. Do NOT drop to 1.
// Top/Bottom layers: 5 each — REQUIRED: the cavity floors and caps must be gas-tight
//   or the Helmholtz tuning is lost
// Infill: 15% gyroid (only reaches the 17 short solid blocks and the back plate)
// Supports: None required. Designed support-free: all walls are vertical prisms; the
//   cavity caps bridge 11.5mm after a 45 deg self-supporting chamfer; the joining pins
//   sit on the build plate.
// Orientation: As modeled — back plate flat on the bed, blocks pointing up (+Z).
//   Do not rotate: any other orientation needs supports inside all 32 cavities.
// Multi-colour: 4 filaments as elevation bands, bottom to top
//     #0f1c57 navy -> #16acf2 electric blue -> #cc3a9d magenta -> #ffc023 gold
//   Easiest route: open the supplied 4-colour .3mf, which carries the split already as
//   four filament-assigned parts. Otherwise insert a filament change at
//   Z = 34.8 / 45.6 / 56.4 mm (layers 175 / 229 / 283 at 0.2mm) — 3 changes for the whole
//   print. Exact heights are echoed at build time.
//   part="band" with band=1..4 exports the four bands as aligned meshes; their union is
//   exactly the whole quadrant (verified: 99.29+17.53+14.27+9.76 = 140.85 cm^3).
// Notes: 100% part cooling fan (helps the cap bridges). Brim not needed — the back
//   plate is a 125mm flat face. Print one quadrant per plate.

// === PARAMETERS ===
// --- Printer settings ---
nozzle_diameter   = 0.4;
layer_height      = 0.2;
build_x           = 256;    // Bambu X1C
build_y           = 256;
build_z           = 256;
printable_square  = 220;    // stock bed_exclude_area limit, AMS usable

// --- What to build ---
part       = "quadrant";    // "quadrant" | "tile" | "interference"
height_map = "logo";        // "logo" (X in the gold band) | "qrd" (optimal scattering)

// --- Tile geometry ---
tile_size   = 125;          // quadrant edge; 4 quadrants -> a 250mm tile
grid_n      = 7;            // cells per edge; prime (QRD modulus)
depth_step  = 10.8;         // one phase step; 54 layers at 0.2mm
base_t      = 2.4;          // back plate thickness (12 layers) — seals the cavities.
                            // v2: 3.0 -> 2.4. With 5 bottom + 5 top solid layers this is
                            // solid all the way through, so it is still gas-tight; the
                            // extra 0.6mm was only buying stiffness nobody needs.

// --- Shell / cavity ---
// v2: walls are SHARED between neighbouring cells (see block_solid/cavity) and thinned to
// 2 perimeters. Nothing here is structural — the tile hangs on a wall and carries only
// its own weight — and the acoustics do not care either: a Helmholtz resonator's work is
// done by the enclosed AIR and the slot, with the plastic acting only as an airtight,
// non-flexing container. By the mass law a 0.8mm PLA wall (0.99 kg/m^2) still reflects
// ~95% of incident energy at 1 kHz versus ~98% for 1.2mm. The floor is set by
// airtightness (2 perimeters fuse into a sealed skin), not by strength.
wall_t      = 0.8;          // 2 perimeters at 0.4mm nozzle, SHARED between cells
cap_t       = 2.0;          // block top thickness = Helmholtz neck length (10 layers)
cav_chamfer = 1.5;          // 45 deg self-supporting chamfer under the cap. v2 trims it
                            // from 2.0 to leave room for the larger X slots that the
                            // (now bigger) cavities need.

// --- Helmholtz necks (the MakerX X slots) ---
neck_w           = 1.2;     // slot arm width AS PRINTED — the printability floor, and
                            // the width the acoustic model is solved for
slot_shrink      = 0.1;     // FDM closes a narrow slot by roughly this much, so the slot
                            // is DRAWN wider by it and prints out at neck_w. Same idea as
                            // the "oversize holes" rule; here it also protects the tuning,
                            // since neck area sets the resonant frequency.
resonator_min_s  = 1;       // every cell that has a block at all is a resonator
// Tip-to-tip span of the X, indexed by height class s = 0..6.
// Bigger slot -> higher tuning; smaller cavity -> higher tuning. Both levers are used
// here to spread the six resonator classes across ~1.5 octaves, from 690 Hz up to where
// the phase grating takes over at ~2270 Hz.
// v2 cavities are ~22% larger (shared walls give back the doubled wall thickness as air),
// so every slot is opened up to hold the same tuning.
NECK_SPAN = [0, 8.4, 13.5, 14.5, 12.7, 9.6, 7.2];

// --- Edge joining (rotation-agnostic: pin at 25%, socket at 75%, CCW) ---
tab_w    = 14;              // pin width along the edge
tab_out  = 4;               // how far the pin protrudes
tab_h    = 1.0;             // pin height above the bed. Kept shallow on purpose: the
                            // socket is cut into the back plate directly beneath
                            // resonator cells, and what remains above it is those
                            // cells' cavity floor, which has to stay gas-tight.
                            // v2 trims it to buy back the thinner back plate.
tol      = 0.2;             // PLA sliding-fit clearance (use 0.3 for PETG)

// --- Logo emboss (in the single s=0 cell) ---
emboss_relief = 0.8;        // raised height
emboss_frac   = 0.78;       // fraction of the cell the mark spans
emboss_stroke = 1.6;        // chevron stroke width

// --- Colour banding ---
// The height class whose TOP surface is the last one in each of the first three colour
// bands; everything above band_top_s[2] is the fourth colour. Purely cosmetic — changing
// it moves the filament-change heights and nothing else.
//   [3,4,5] (default) — navy field for s<=3, then blue/magenta/gold on the peaks. The
//                       quiet background is what makes the X read from across a room.
//   [2,4,5]           — more blue, busier.
//   [2,3,4]           — puts 16 cells in gold; the X disappears. Verified by render.
band_top_s = [3, 4, 5];

// --- Diagnostic ---
// How far each block's outer prism reaches past its cell boundary. wall_t/2 - fudge is
// the shared-wall value; fudge reproduces v1's per-cell walls. Exposed for bisecting.
block_expand = wall_t / 2 - 0.01;
necks_on     = true;        // set false to isolate cavity geometry from neck geometry

// --- Physics ---
sound_c = 343000;           // mm/s at 20 C

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
cell_pitch      = tile_size / grid_n;
// SHARED WALLS (the v2 change that saves the most filament). Each cavity is inset by
// wall_t/2 from its cell boundary and each block's outer prism is expanded by wall_t/2
// past it, so the material between two neighbouring cavities is ONE shared wall_t — where
// v1 stacked two full walls back to back and spent 2*wall_t on every internal boundary.
// Where a tall block overlooks a short neighbour the exposed wall is still wall_t
// (inset wall_t/2 + expansion wall_t/2), so nothing gets thin.
// Cavities that touch the tile outline are clamped to keep a full wall_t of outer skin,
// which makes those slightly narrower — hence two widths.
cav_w_int        = cell_pitch - wall_t;             // interior cell
cav_w_edge       = cell_pitch - 1.5 * wall_t;       // a side that lands on the tile outline
cav_top_open     = cav_w_int  - 2 * cav_chamfer;    // flat cap span, interior cell
cav_top_open_min = cav_w_edge - 2 * cav_chamfer;    // worst case — what the fit asserts use
block_h_max     = (grid_n - 1) * depth_step;
total_h         = base_t + block_h_max;
fudge           = 0.01;
ef_chamfer      = 0.4;                              // elephant-foot compensation
$fn             = $preview ? 24 : 48;

// Filament-change heights: one per elevation band boundary. A boundary sits exactly on
// the top face of height class band_top_s[i], so that class's top surface is the last
// one printed in the band below it.
colour_band_z = [ for (s = band_top_s) base_t + s * depth_step ];
MX_NAVY = "#0f1c57"; MX_EBLUE = "#16acf2"; MX_MAGENTA = "#cc3a9d"; MX_GOLD = "#ffc023";

// === HEIGHT MAPS ===
// Textbook 2D quadratic residue diffuser: s = (x^2 + y^2) mod N.
function qrd_s(x, y) = (x * x + y * y) % grid_n;

// Logo map: the same multiset of depths (one 0, eight each of 1..6 — identical mass and
// identical depth range, therefore the same scattering bandwidth) permuted so that the
// thirteen cells on the two diagonals are the tallest: the eight s=6 cells run inward
// from each corner and the five s=5 cells sit at the corners and the centre. With the
// default banding that paints a gold X with magenta tips on a navy field.
// The three s=5 cells the histogram forces outside the X are parked on edge midpoints,
// where they read as deliberate tick marks rather than noise.
// Rows are y = 0..6 (bottom to top), columns x = 0..6.
LOGO_MAP = [
  [5, 3, 1, 5, 2, 3, 5],
  [2, 6, 4, 1, 4, 6, 1],
  [4, 1, 6, 3, 6, 2, 0],
  [5, 4, 2, 5, 2, 4, 3],
  [3, 2, 6, 3, 6, 1, 4],
  [1, 6, 4, 1, 4, 6, 2],
  [5, 3, 2, 5, 1, 3, 5]
];

function height_index(x, y) =
    height_map == "logo" ? LOGO_MAP[y][x] : qrd_s(x, y);

function block_h(x, y) = height_index(x, y) * depth_step;

// === ACOUSTIC MODEL ===
// Phase-grating design frequency. Well depths are d_s = s * lambda0 / (2N), so the
// deepest well (s = N-1) fixes lambda0 = 2 * N * depth_step.
function design_f()  = sound_c / (2 * grid_n * depth_step);
// Upper limit: above this the cell is no longer small compared to a wavelength.
function f_max()     = sound_c / (2 * cell_pitch);

// Cavity volume for height class s: a rectangular prism topped by the 45 deg chamfer
// frustum (prismatoid formula). Perimeter cells are slightly smaller, so tuning is quoted
// for an interior cell with the corner cell as the worst case — a <4% spread, well inside
// the model's own end-correction uncertainty, and a spread that mildly broadens the
// aggregate absorption rather than hurting it.
function cav_vol_wh(s, wx, wy) =
    let (a1   = wx * wy,
         a2   = (wx - 2 * cav_chamfer) * (wy - 2 * cav_chamfer),
         hcav = s * depth_step - cap_t)              // floor at base_t, roof at cap
    a1 * (hcav - cav_chamfer) + (cav_chamfer / 3) * (a1 + a2 + sqrt(a1 * a2));
function cav_vol(s)        = cav_vol_wh(s, cav_w_int,  cav_w_int);
function cav_vol_corner(s) = cav_vol_wh(s, cav_w_edge, cav_w_edge);

// Open area of the X slot: two crossed bars, overlap counted once.
function neck_area(s) = 2 * NECK_SPAN[s] * neck_w - neck_w * neck_w;
// Effective neck length: physical length plus the standard 0.85*radius end correction
// at both faces, using the equal-area radius.
function neck_leff(s) = cap_t + 1.7 * sqrt(neck_area(s) / PI);
function helmholtz_f(s) =
    (sound_c / (2 * PI)) * sqrt(neck_area(s) / (cav_vol(s) * neck_leff(s)));
function helmholtz_f_corner(s) =
    (sound_c / (2 * PI)) * sqrt(neck_area(s) / (cav_vol_corner(s) * neck_leff(s)));
// Bounding box of the X rotated 45 deg — must fit the flat part of the cap. Uses the
// DRAWN width, which is what actually has to fit.
function neck_bbox(s) = (NECK_SPAN[s] + neck_w + slot_shrink) / sqrt(2);

// === DESIGN CONTRACTS ===
counts = [ for (v = [0:grid_n-1])
             len([ for (y = [0:grid_n-1], x = [0:grid_n-1])
                     if (height_index(x, y) == v) 1 ]) ];
zero_cells = [ for (y = [0:grid_n-1], x = [0:grid_n-1])
                 if (height_index(x, y) == 0) [x, y] ];
resonator_count = len([ for (y = [0:grid_n-1], x = [0:grid_n-1])
                          if (height_index(x, y) >= resonator_min_s) 1 ]);

assert(abs(cell_pitch * grid_n - tile_size) < 1e-9, "cell grid must exactly fill the tile");
assert(abs(depth_step / layer_height - round(depth_step / layer_height)) < 1e-6,
       "depth_step must be a whole number of layers");
assert(abs(base_t / layer_height - round(base_t / layer_height)) < 1e-6,
       "base_t must be a whole number of layers");
assert(abs(cap_t / layer_height - round(cap_t / layer_height)) < 1e-6,
       "cap_t must be a whole number of layers");
assert(abs(wall_t / nozzle_diameter - round(wall_t / nozzle_diameter)) < 1e-6,
       "wall_t must be a whole number of extrusions");
// 2 perimeters is the airtightness floor (two adjacent extrusions fuse into a sealed
// skin). Strength is not a criterion here — the tile hangs on a wall — and by the mass law
// 0.8mm PLA still reflects ~95% of incident energy at 1 kHz, so thinning does not cost
// acoustic performance either.
assert(wall_t >= 2 * nozzle_diameter - 1e-9, "wall_t < 2 perimeters — cavities will leak");
assert(neck_w >= 2 * nozzle_diameter - 1e-9, "neck slot narrower than 2 nozzles will not print open");
assert(cav_top_open_min > 0, "cavity chamfer consumes the whole cavity");
assert(cav_top_open <= 25, "cap bridge span exceeds PLA's clean-bridge limit");
assert(len(zero_cells) >= 1, "need one s=0 cell to carry the logo emboss");
// Every edge carries one outward pin, so the printed footprint is the cell field plus a
// pin on each side.
assert(tile_size + 2 * tab_out <= printable_square,
       "printed footprint exceeds the AMS-usable bed area");
assert(total_h <= build_z, "taller than the build volume");
assert(tab_w + 2 * tol < cell_pitch * 1.5, "joining pin too wide for the edge");
// A socket is a void inside the back plate, and the material above it is the cavity
// floor of whatever resonator cell sits there. Keep at least 5 solid layers.
assert(base_t - (tab_h + tol) >= 5 * layer_height,
       str("only ", base_t - (tab_h + tol), "mm of back plate above the joining socket — ",
           "resonator cavities above it would leak"));
// Every resonator's slot must print and must fit the flat cap.
for (s = [resonator_min_s : grid_n - 1]) {
    assert(NECK_SPAN[s] > neck_w * 2, str("NECK_SPAN[", s, "] too small to be an X"));
    // Checked against the SMALLEST cavity (a corner cell), not the interior one.
    assert(neck_bbox(s) <= cav_top_open_min,
           str("X slot for s=", s, " (", neck_bbox(s), "mm) overruns the flat cap of a ",
               "corner cell (", cav_top_open_min, "mm)"));
    assert(s * depth_step - cap_t > cav_chamfer + layer_height,
           str("no cavity height left for s=", s));
}
// The logo map must be a true permutation of the QRD depth multiset — same mass, same
// depth range, so the two maps are directly comparable.
qrd_counts = [ for (v = [0:grid_n-1])
                 len([ for (y = [0:grid_n-1], x = [0:grid_n-1]) if (qrd_s(x, y) == v) 1 ]) ];
assert(counts == qrd_counts,
       str("height map depth histogram ", counts, " != QRD histogram ", qrd_counts));

echo(str("=== MakerX diffuser tile: ", height_map, " map ==="));
echo(str("  quadrant  ", tile_size, " x ", tile_size, " x ", total_h, " mm  (printed ",
         tile_size + 2 * tab_out, " x ", tile_size + 2 * tab_out, " incl. pins)"));
echo(str("  assembled tile  ", 2 * tile_size, " x ", 2 * tile_size, " mm"));
echo(str("  diffusion  design f0 = ", round(design_f()), " Hz   upper limit = ",
         round(f_max()), " Hz   depths 0..", block_h_max, " mm in ", depth_step, " steps"));
echo(str("  resonators ", resonator_count, " of ", grid_n * grid_n, " cells"));
for (s = [resonator_min_s : grid_n - 1])
    echo(str("    s=", s, "  h=", s * depth_step, "mm  V=", round(cav_vol(s)),
             " mm^3  Xslot=", NECK_SPAN[s], "mm (A=", round(neck_area(s) * 10) / 10,
             " mm^2)  ->  ", round(helmholtz_f(s)), " Hz",
             "  (corner cell ", round(helmholtz_f_corner(s)), " Hz)"));
echo(str("  cap bridge span ", round(cav_top_open * 100) / 100, " mm interior / ",
         round(cav_top_open_min * 100) / 100, " mm at the outline"));
echo(str("  wall ", wall_t, "mm SHARED between cells; back plate ", base_t, "mm"));
echo(str("  FILAMENT CHANGES at Z = ", colour_band_z, " mm  (layers ",
         [for (z = colour_band_z) round(z / layer_height) + 1], ")"));
echo(str("  colours bottom->top: ", MX_NAVY, " ", MX_EBLUE, " ", MX_MAGENTA, " ", MX_GOLD));

// === MODULES ===

// Elephant-foot-compensated slab: bottom face inset by ef, full size from z = ef up.
module ef_slab(w, d, h, ef) {
    hull() {
        translate([ef, ef, 0])   cube([w - 2 * ef, d - 2 * ef, 0.01]);
        translate([0,  0,  ef])  cube([w, d, h - ef]);
    }
}

// One joining pin, on the y=0 edge, centred at 25% along the CCW (+X) direction.
module edge_pin() {
    translate([tile_size / 4 - tab_w / 2, -tab_out, 0])
        ef_slab(tab_w, tab_out + fudge, tab_h, ef_chamfer / 2);
}

// The matching socket, on the y=0 edge at 75% along the CCW direction.
module edge_socket() {
    translate([tile_size * 3 / 4 - (tab_w + 2 * tol) / 2, -fudge, -fudge])
        cube([tab_w + 2 * tol, tab_out + tol + fudge, tab_h + tol + fudge]);
}

// Apply a module to all four edges, each walked counter-clockwise.
module on_each_edge() {
    for (i = [0:3])
        translate([tile_size / 2, tile_size / 2, 0])
            rotate([0, 0, 90 * i])
                translate([-tile_size / 2, -tile_size / 2, 0])
                    children();
}

module base_plate() {
    difference() {
        union() {
            ef_slab(tile_size, tile_size, base_t, ef_chamfer);
            on_each_edge() edge_pin();
        }
        on_each_edge() edge_socket();
    }
}

// Solid outer form of one cell's block, expanded laterally by wall_t/2 so it reaches the
// centre-line of each shared wall. Two things fall out of that expansion: neighbouring
// blocks meet in a real shared volume (v1 needed a fudge inflation just to dodge the
// bare-edge contact that slicers reject), and a block overlooking a shorter neighbour
// still presents a full wall_t of skin. Clipped back to the tile outline by quadrant().
module block_solid(x, y) {
    h = block_h(x, y);
    // Expansion must stop JUST SHORT of wall_t/2, never at or past it. At exactly wall_t/2
    // this face is coplanar with the neighbouring cell's cavity wall; past it, the block
    // pokes into that cavity and subtracting it shaves a 0.01mm sliver along every shared
    // edge. Either way Manifold resolves the degeneracy into a storm of triangles — 156k
    // facets against the 5k this should be (both measured). A fudge short of the
    // centre-line leaves a clean 0.01mm of solid between block face and cavity wall, and
    // the shared wall still measures wall_t because the neighbour's own block covers it.
    e = block_expand;   // DIAGNOSTIC KNOB (see parameter)
    if (h > 0)
        translate([x * cell_pitch - e, y * cell_pitch - e, base_t - fudge])
            cube([cell_pitch + 2 * e, cell_pitch + 2 * e, h + fudge]);
}

// The sealed resonator cavity: square prism from the back plate up, closed by a 45 deg
// self-supporting chamfer so the cap only has to bridge cav_top_open.
module cavity(x, y) {
    s = height_index(x, y);
    if (s >= resonator_min_s) {
        c   = wall_t / 2;                         // inset to the shared-wall centre-line
        // ...but never closer than a full wall_t to the tile outline, so the outer skin
        // stays as thick as an internal wall.
        x0  = max(x * cell_pitch + c, wall_t);
        x1  = min((x + 1) * cell_pitch - c, tile_size - wall_t);
        y0  = max(y * cell_pitch + c, wall_t);
        y1  = min((y + 1) * cell_pitch - c, tile_size - wall_t);
        wx  = x1 - x0;
        wy  = y1 - y0;
        top = base_t + s * depth_step - cap_t;    // underside of the cap
        zc  = top - cav_chamfer;                  // where the chamfer starts
        translate([(x0 + x1) / 2, (y0 + y1) / 2, 0]) {
            translate([0, 0, base_t])
                linear_extrude(height = zc - base_t + fudge)
                    square([wx, wy], center = true);
            // The chamfer is a hull() of two thin plates, NOT linear_extrude(scale=...).
            // A scaled extrude gets subdivided into hundreds of triangles per face here
            // (measured: 784 per chamfer face, 151k across the part, all with 45 deg
            // normals in regular z-bands). hull() of two plates is a flat 12 facets.
            hull() {
                translate([0, 0, zc])
                    linear_extrude(height = fudge)
                        square([wx, wy], center = true);
                translate([0, 0, top - fudge])
                    linear_extrude(height = fudge)
                        square([wx - 2 * cav_chamfer, wy - 2 * cav_chamfer],
                               center = true);
            }
        }
    }
}

// The MakerX X: two crossed bars, rotated 45 deg. This is the Helmholtz neck — its high
// perimeter-to-area ratio is what damps the resonator.
module neck_x(x, y) {
    s = height_index(x, y);
    if (s >= resonator_min_s) {
        span = NECK_SPAN[s];
        w    = neck_w + slot_shrink;              // drawn wider; prints out at neck_w
        z0   = base_t + s * depth_step - cap_t;
        translate([(x + 0.5) * cell_pitch, (y + 0.5) * cell_pitch, z0 - fudge])
            linear_extrude(height = cap_t + 2 * fudge)
                rotate(45) {
                    square([span, w], center = true);
                    square([w, span], center = true);
                }
    }
}

// One stroked chevron of the MakerX logomark, apex pointing +X.
//   w = overall width, hh = half height, t = stroke width
module chevron_2d(w, hh, t) {
    intersection() {
        difference() {
            polygon([[0, hh], [w, 0], [0, -hh]]);
            offset(delta = -t) polygon([[0, hh], [w, 0], [0, -hh]]);
        }
        translate([t, -hh - 1]) square([w, 2 * hh + 2]);   // open the V's back
    }
}

// The two-chevron MakerX mark: a right-pointing chevron and a left-pointing chevron that
// cross in the middle, as on makerx.com.au. cw > w/2 so the two overlap in the centre,
// which is what turns them into an X rather than two separate arrows.
module logomark_2d(w, h, t) {
    cw = w * 0.56;                   // each chevron's own width
    translate([0, h / 2])   chevron_2d(cw, h / 2, t);
    translate([w, h / 2])   mirror([1, 0, 0]) chevron_2d(cw, h / 2, t);
}

// Emboss the mark on the back plate inside the single full-depth (s=0) cell.
module logo_emboss() {
    c  = zero_cells[0];
    ew = cell_pitch * emboss_frac;
    eh = ew * 243 / 296;             // logomark aspect ratio from the site SVG
    translate([(c[0] + 0.5) * cell_pitch - ew / 2,
               (c[1] + 0.5) * cell_pitch - eh / 2,
               base_t - fudge])
        linear_extrude(height = emboss_relief + fudge)
            logomark_2d(ew, eh, emboss_stroke);
}

// === ASSEMBLY ===
module quadrant() {
    difference() {
        union() {
            base_plate();
            // Clip the inflated blocks back to the exact tile outline.
            intersection() {
                union() {
                    for (y = [0:grid_n-1], x = [0:grid_n-1]) block_solid(x, y);
                }
                translate([0, 0, base_t - 2 * fudge])
                    cube([tile_size, tile_size, total_h]);
            }
            logo_emboss();
        }
        for (y = [0:grid_n-1], x = [0:grid_n-1]) {
            cavity(x, y);
            if (necks_on) neck_x(x, y);
        }
    }
}

// Colour-banded preview: shows what the 4 filaments produce. Geometry is identical to
// quadrant() — this is a visual aid, not a separate part.
// One elevation band of the quadrant, as its own solid. Exporting bands 1..4 gives four
// aligned meshes that become the four filament-assigned PARTS of a single object in the
// multi-colour Bambu 3MF. Their union is exactly quadrant().
band = 1;                    // which band to emit when part="band" (1..4, bottom to top)
module quadrant_band(i) {
    e  = layer_height / 2;   // see quadrant_coloured() for why the half-layer nudge
    bz = [for (z = colour_band_z) z + e];
    lo = i <= 1 ? -tab_out - 1 : bz[i - 2];
    hi = i >= 4 ? total_h + 1  : bz[i - 1];
    intersection() {
        quadrant();
        translate([-tab_out - 1, -tab_out - 1, lo])
            cube([tile_size + 2 * tab_out + 2, tile_size + 2 * tab_out + 2, hi - lo]);
    }
}

module quadrant_coloured() {
    // Nudge each boundary half a layer up. Physically correct — a filament change takes
    // effect at the START of the next layer, so a block top sitting exactly on a boundary
    // is still printed in the band below. It also removes a rendering artifact: without
    // the nudge, a block whose top face lands exactly on a boundary yields a
    // zero-thickness intersection sheet in the band above, which z-fights.
    e  = layer_height / 2;
    bz = [for (z = colour_band_z) z + e];
    bands = [[0,     bz[0],        MX_NAVY],
             [bz[0], bz[1],        MX_EBLUE],
             [bz[1], bz[2],        MX_MAGENTA],
             [bz[2], total_h + 1,  MX_GOLD]];
    for (b = bands)
        color(b[2]) intersection() {
            quadrant();
            translate([-tab_out - 1, -tab_out - 1, b[0]])
                cube([tile_size + 2 * tab_out + 2, tile_size + 2 * tab_out + 2, b[1] - b[0]]);
        }
}

// Four quadrants, each rotated a further 90 deg, forming one 250 x 250 tile. The
// rotation breaks the 125mm periodicity that would otherwise produce grating lobes.
// tile_gap represents the real hairline seam between separately printed parts; without
// it the four solids would share coincident faces and the preview mesh would report a
// non-manifold edge that does not exist in the physical assembly.
tile_gap = 0.1;
module tile(coloured = false) {
    for (i = [0:3]) {
        px = (i % 2) * (tile_size + tile_gap);
        py = floor(i / 2) * (tile_size + tile_gap);
        translate([px, py, 0])
            translate([tile_size / 2, tile_size / 2, 0])
                rotate([0, 0, 90 * i])
                    translate([-tile_size / 2, -tile_size / 2, 0])
                        if (coloured) quadrant_coloured(); else quadrant();
    }
}

// Interference check: a quadrant and its neighbour must share NO VOLUME, for EVERY
// neighbour direction and EVERY relative rotation — that is the whole claim behind the
// "pin at 25%, socket at 75%, counter-clockwise" joint. The correct result is a
// zero-volume sheet on the seam plane (the two butting faces touching). Any result with
// non-zero volume means the joint clashes.
//   Sweep with: -D interf_dir="x"|"y"  -D interf_rot=0|90|180|270
interf_dir = "x";
interf_rot = 90;
module interference() {
    dx = interf_dir == "x" ? tile_size : 0;
    dy = interf_dir == "y" ? tile_size : 0;
    intersection() {
        quadrant();
        translate([dx, dy, 0])
            translate([tile_size / 2, tile_size / 2, 0])
                rotate([0, 0, interf_rot])
                    translate([-tile_size / 2, -tile_size / 2, 0])
                        quadrant();
    }
}

// Diagnostic only: half the quadrant removed so the sealed cavities, the 45 deg cap
// chamfer and the X necks can be inspected in section.
module cutaway() {
    difference() {
        quadrant();
        translate([-tab_out - 1, tile_size / 2, -1])
            cube([tile_size + 2 * tab_out + 2, tile_size, total_h + 2]);
    }
}

if      (part == "quadrant")     quadrant();
else if (part == "cutaway")      cutaway();
// Diagnostic: the mark on its own. The intersection is a deliberate no-op — a bare
// linear_extrude reaches the top level as an unvalidated PolySet, which the build gate
// (rightly) flags, and neither render() nor union() converts it under the Manifold
// backend. An actual boolean does. Inside quadrant() it is unioned and validated anyway.
else if (part == "logo")
    intersection() { logo_emboss(); cube(10 * tile_size, center = true); }
else if (part == "band")         quadrant_band(band);
else if (part == "tile")         tile(false);
else if (part == "tile_colour")  tile(true);
else if (part == "quad_colour")  quadrant_coloured();
else if (part == "interference") interference();
else assert(false, str("unknown part: ", part));
