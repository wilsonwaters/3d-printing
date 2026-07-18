// === DESCRIPTION ===
// MakerX Skyline Acoustic Tile (Fable v2): a 250x250mm wall tile set that
// scatters (diffuses) mid/high-frequency sound reflections and traps a
// narrow band of speech-frequency energy in internal Helmholtz resonators.
// Branded for MakerX (makerx.com.au) using the exact logo vector geometry
// and the official brand palette.
//
// Physical context: hangs on an interior wall (office / studio / meeting
// room) via two keyhole slots or adhesive strips. Zero mechanical load
// beyond its own weight (~0.5kg). Indoor, room temperature.
//
// Acoustic design (honest numbers):
//   - The relief is a 13x13 "skyline" diffuser: column heights follow the
//     2D quadratic-residue sequence s(m,n) = (m^2 + n^2) mod 13, scaled to
//     4mm steps (0..48mm). QR sequences have a flat spatial power spectrum,
//     which is what makes them scatter sound evenly instead of specularly.
//   - Effective scattering band ~1.8kHz (depth limit, c/(4*0.048m)) up to
//     ~8.9kHz (cell-width limit, c/(2*0.0192m)). Partial scattering roughly
//     an octave below. A single 250mm tile CANNOT treat bass - physics.
//   - Columns 32mm and taller are hollow Helmholtz resonators: a square
//     neck in the cap opens into the internal cavity. Neck sizes vary with
//     column height, spreading resonances over ~700-1300Hz (speech band).
//     This is narrowband resonant absorption, not broadband deadening.
//   - Multiple tiles: tile_index shifts the QR sequence (toroidal offset)
//     so adjacent tiles are decorrelated - avoids periodic grating lobes.
//     Also rotate alternate tiles 90/180 degrees when mounting.
//
// Design decisions:
//   - Print orientation: flat, back on bed, columns straight up. Columns
//     are vertical extrusions = zero overhangs; internal cavity roofs are
//     45-degree pyramid hips converging on the neck = support-free.
//   - Logo tile uses a shallower field (1.2mm steps) so the X mark relief
//     (18mm) always reads above it; it is decorative-first. The full-height
//     diffuser tiles do the acoustic work.
//   - Logo geometry is the website's inline SVG polygons verbatim (solid
//     left chevron + outlined right chevron with kerf slashes), mirrored to
//     Y-up and scaled - not a redrawing.
//   - Colour separation is by disjoint bodies (select with `body`), plus a
//     0.8mm shadow gap around the X so colour edges stay crisp. The logo
//     tile has no accent columns - the X owns the colour on a navy field.
//
// Terminology -> code:
//   "column / block"      -> column(), cell_size, height_unit
//   "sequence / pattern"  -> s_val(), seq_N, tile_index
//   "resonator / cavity"  -> helm_* params, helm_cavity()
//   "the X / logo"        -> x_solid_raw, x_outline_raw, x_mark_*, logo_width
//   "shadow gap"          -> shadow_gap
//   "accent columns"      -> accent gold s==12, magenta s==11 (diffuser only)
//   "keyhole hangers"     -> key_* params, keyhole()
//
// Common modifications:
//   Different tile pattern     -> tile_index (0..12; each is a unique shift)
//   Deeper diffusion (lower f) -> height_unit (4 -> 5 = 60mm max, more mass)
//   Lighter tile               -> height_unit down, or base_thick 6 -> 5
//   Bigger/smaller logo        -> logo_width (keep <= tile_size - 40)
//   No resonators              -> helmholtz = false
//   Different grid             -> seq_N (use a prime: 7, 11, 13) = n_cells
//   Smaller tile (bed margin)  -> tile_size (everything rescales)
//
// Overall dimensions: 250 x 250 x max 54 mm (fits Bambu Lab 256x256x256)
// Coordinate system: X = width, Y = height-on-wall (keyholes at top, +Y up),
//   Z = out from wall. Z=0 = build plate = back face against the wall.
// NOTE: modeled in print orientation; on the wall, Z points at the listener.
//
// v2 changes (from v1):
//   - Columns overlap laterally by col_lap and bodies are clipped back to
//     the exact tile outline: diagonal-neighbour columns previously touched
//     along a bare vertical edge, which slicers flag as non-manifold.
//   - 250mm tiles need Bambu's official full-volume mod on X1/P1 (see
//     full_volume_mod below and README); stock printers cap at 238mm.
//   - key_y and logo_width now derive from tile_size, so resizing the tile
//     keeps the keyholes and logo proportionate.

// === PRINT SETTINGS ===
// Material: PLA (matte recommended). Decorative zero-load indoor part: PLA
//   is stiffer (better acoustic reflector), bridges cavity roofs cleanly,
//   and holds crisp logo edges. PETG also fine (expect softer bridges).
// Layer Height: 0.2mm
// Walls/Perimeters: 3 (1.35mm) - column shells and neck walls
// Infill: 10% gyroid (columns are mostly shell; base gets top/bottom skins)
// Top/Bottom: 4 layers each
// Supports: None required (vertical columns; 45-degree internal cavity
//   roofs; keyhole + cavity ceilings are short bridges <= 16mm)
// Brim: OFF - 250mm footprint leaves only 3mm bed margin per side
// Orientation: as modeled (back face on plate)
// Bed: at 250mm this REQUIRES Bambu's official full-volume setup on X1/P1
//   (cutter-stopper clip + clear "Excluded bed area" in Studio printer
//   settings; AMS cannot be used on those prints). Stock printers: set
//   tile_size <= 238 (manual right-shift placement) or <= 220 (centred).
// Notes: ~0.4-0.6kg and 15-25h per tile at these settings. For multi-colour
//   print the aligned per-body STLs as one object with per-part filaments
//   (or print each tile in a single different brand colour - zero purge).
//   Multi-colour needs the AMS cutter, so multi-colour tiles must be
//   stock-size (<=220mm); full-size 250mm tiles are single-colour.

// === PARAMETERS ===
// Printer settings (Bambu Lab P1/X1, 0.4mm nozzle)
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_x = 256;
build_y = 256;
build_z = 256;
full_volume_mod = true; // Stock X1/P1 exclude an 18x28mm front-left corner
                        // (filament-cutter stopper), capping a square tile
                        // at 238mm. Bambu's official full-volume mod (a
                        // printed stopper clip + clearing "Excluded bed
                        // area" in Studio) unlocks the whole 256x256 bed,
                        // but AMS/multi-colour can't be used on such prints.
                        // Set false to enforce a stock-safe tile size.

// Which geometry to emit
part = "diffuser";  // "diffuser" | "logo"
body = "all";       // "all" | "field" | "accent_gold" | "accent_magenta"
                    //       | "x_solid" | "x_outline"
tile_index = 0;     // 0..12 - shifts the QR sequence so tiles differ
section = 0;        // 1 = cut away y > section_y, 2 = cut away y < section_y
                    // (inspect cavities/keyholes)
section_y = 125;    // [mm] section plane position

// Tile + field
tile_size   = 250;   // [mm] square tile edge
n_cells     = 13;    // grid count per side - MUST equal seq_N for uniform
                     // height distribution regardless of tile_index
seq_N       = 13;    // prime modulus of the quadratic-residue sequence
base_thick  = 6;     // [mm] backing plate thickness
height_unit = 4;     // [mm] per sequence step on diffuser tiles (max 12*4=48)
logo_height_unit = 1.2; // [mm] per step on the logo tile (max 14.4)

// Helmholtz resonators (diffuser tiles; auto-off on short columns)
helmholtz    = true;
helm_min_h   = 32;    // [mm] hollow out columns at least this tall (s>=8)
helm_wall    = 1.8;   // [mm] shell around cavity (4 extrusion widths)
helm_cap     = 2.4;   // [mm] cap above cavity roof (12 layers)
helm_neck_lo = 3;     // [mm] square neck on the TALLEST column (s=12)
helm_neck_hi = 5;     // [mm] square neck on the shortest hollow column
                      // (small neck on big cavity spreads f down to ~700Hz)

// Logo (verbatim polygons from makerx.com.au inline SVG, viewBox 1300x1100)
logo_width  = tile_size * 0.8;   // [mm] X-mark width on the logo tile
x_relief    = 18;    // [mm] X extrusion height above the base
shadow_gap  = 0.8;   // [mm] moat between X and surrounding columns (>=0.8
                     // keeps adjacent perimeters from merging at 0.4 nozzle)
logo_gap_close = 4;  // [mm] morphological closing radius: clears column
                     // slivers from the logo's internal kerf slashes so
                     // navy base shows through them cleanly

// Keyhole hangers (back face, near top edge, hang on 4mm pan-head screws)
key_spacing = 150;   // [mm] center-to-center, symmetric about tile center
key_y       = tile_size - 60;  // [mm] entry-hole center from bottom edge
key_entry_d = 10;    // [mm] head drop-in hole
key_slot_w  = 4.5;   // [mm] shank slot width
key_slot_l  = 14;    // [mm] upward travel
key_lip     = 1.6;   // [mm] lip that captures the head (8 layers)
key_head_d  = 10;    // [mm] head channel width
key_head_h  = 2.8;   // [mm] head channel depth (pan head ~2.7mm)

// Brand palette (official site CSS custom properties)
col_navy    = "#0f1c57"; // --color-mx-blue        : field + base
col_white   = "#f2f2f2"; // --color-mx-white       : X solid half
col_magenta = "#cc3a9d"; // --color-mx-magenta     : X outline + accents
col_gold    = "#ffc023"; // --color-mx-gold        : accent columns

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;
fudge      = 0.01;
col_lap    = fudge;                  // lateral column overlap: without it,
                                     // diagonal-neighbour columns touch on a
                                     // bare vertical edge -> non-manifold
ef_chamfer = 0.4;                    // elephant-foot compensation
cell_size  = tile_size / n_cells;    // 19.23mm at defaults
unit       = (part == "logo") ? logo_height_unit : height_unit;
max_relief = (seq_N - 1) * unit;
off_m      = (tile_index * 3) % seq_N;   // toroidal sequence shift
off_n      = (tile_index * 7) % seq_N;
helm_inner = cell_size - 2 * helm_wall;  // cavity width, 15.63mm
c_sound    = 343000;                     // [mm/s] speed of sound
$fn = $preview ? 32 : 64;

// Sequence value for cell (m,n) - quadratic residue, offset per tile
function s_val(m, n) =
    ((m + off_m) * (m + off_m) + (n + off_n) * (n + off_n)) % seq_N;

// Column height for sequence value s
function col_h(s) = s * unit;

// Helmholtz resonators exist only on full-height diffuser tiles
helm_active = helmholtz && part != "logo";
function is_helm(h) = helm_active && h >= helm_min_h;

// Square neck edge for sequence value s (linear: tall column -> small neck)
function neck_d(s) =
    helm_neck_hi - (helm_neck_hi - helm_neck_lo)
                   * (col_h(s) - helm_min_h) / (max_relief - helm_min_h);

// Helmholtz geometry helpers (heights measured above base top)
function pyr_h(s)   = (helm_inner - neck_d(s)) / 2;          // 45-deg roof
function prism_h(s) = col_h(s) - helm_cap - pyr_h(s);        // straight part
function cav_vol(s) =                                        // [mm^3]
    helm_inner * helm_inner * prism_h(s)
    + pyr_h(s) / 3 * (helm_inner * helm_inner + neck_d(s) * neck_d(s)
                      + helm_inner * neck_d(s));
// End-corrected neck length and resonance (square neck, r_eq = d/sqrt(pi))
function neck_leff(s) = helm_cap + 1.7 * neck_d(s) / sqrt(PI);
function helm_f(s) =
    c_sound / (2 * PI)
    * sqrt(neck_d(s) * neck_d(s) / (cav_vol(s) * neck_leff(s)));

// Logo polygon transform: SVG (y-down, center 650,550, width 1280) ->
// tile-local mm (y-up, centered on tile)
logo_scale = logo_width / 1280;
function xf(pts) = [for (p = pts)
    [(p[0] - 650) * logo_scale + tile_size / 2,
     (550 - p[1]) * logo_scale + tile_size / 2]];

// Verbatim from makerx.com.au logo SVG - outlined right chevron (44 pts)
x_outline_raw = [
    [900.37,25.25],[743.06,210.69],[701.27,259.89],[691.1,271.9],
    [701,283.59],[719.91,305.86],[730.09,293.85],[771.87,244.6],
    [920.72,69.14],[1195.18,69.14],[1010.86,286.43],[982.09,320.35],
    [844.86,482.12],[816.04,516.08],[787.23,550],[816.04,583.92],
    [1195.18,1030.86],[920.72,1030.86],[771.87,855.39],[743.06,821.44],
    [678.81,745.69],[650,711.78],[605.82,659.66],[595.73,647.53],
    [567.28,613.25],[538.59,647.09],[566.96,681.45],[577.01,693.62],
    [621.19,745.69],[650,779.66],[663.93,796.06],[692.7,829.97],
    [705.59,845.18],[714.25,855.39],[734.36,879.1],[743.06,889.35],
    [900.37,1074.75],[1290,1074.75],[1035.2,774.42],[844.82,550],
    [873.63,516.04],[1010.86,354.3],[1039.63,320.39],[1290,25.25]];

// Verbatim from makerx.com.au logo SVG - solid left chevron (34 pts)
x_solid_raw = [
    [10,25.25],[455.18,550],[324.97,703.48],[308.97,722.35],
    [271.46,766.57],[228.48,817.21],[218.55,828.9],[215.35,832.69],
    [10,1074.75],[399.63,1074.75],[404.54,1068.97],[410.17,1062.34],
    [413.4,1058.55],[423.3,1046.86],[609.77,830.77],[581.04,796.89],
    [394.49,1012.9],[384.59,1024.59],[381.36,1028.38],[379.28,1030.86],
    [104.82,1030.86],[244.12,866.61],[247.32,862.82],[257.25,851.12],
    [329,766.57],[366.51,722.35],[382.51,703.48],[483.95,583.92],
    [512.77,550],[650,388.22],[678.81,354.31],[650,320.34],
    [618.79,283.59],[399.63,25.25]];

// === CONTRACTS ===
assert(tile_size <= min(build_x, build_y) - 4,
    "tile must leave >=2mm bed margin per side");
// Stock X1/P1: front-left 18x28mm exclusion (cutter stopper) caps a square
// at 238mm shoved fully right, 220mm auto-centred
assert(full_volume_mod || tile_size <= 238,
    "stock X1/P1 caps a square tile at 238mm; shrink tile_size or do the full-volume mod and set full_volume_mod=true");
if (!full_volume_mod && tile_size > 220)
    echo("NOTE: 220-238mm tiles clear the stock exclusion zone only when dragged fully right on the plate (auto-centre overlaps it)");
assert(n_cells == seq_N,
    "grid must span one full residue period (n_cells == seq_N)");
assert(base_thick + max_relief <= build_z, "tile too tall for build volume");
assert(part == "logo" || max_relief == 48,
    "diffuser relief expected 48mm - acoustic band claims assume this");
// Logo printability: thinnest kerf gap in SVG is ~15.3 units, thinnest
// outline stroke ~29 units perpendicular
assert(15.3 * logo_scale >= 2 * extrusion_width, "logo kerf gap too thin");
assert(29 * logo_scale >= 8 * extrusion_width, "logo stroke too thin");
assert(logo_width <= tile_size - 40, "logo needs >=20mm margin per side");
assert(x_relief > (seq_N - 1) * logo_height_unit + 2,
    "X relief must stand >=2mm above the tallest logo-tile column");
// Helmholtz sanity: neck fits the cavity, straight cavity section exists,
// resonances land in the intended speech band
assert(!helm_active || helm_neck_hi < helm_inner - 2,
    "neck too wide for cavity");
assert(!helm_active || prism_h(8) > 4, "cavity too short at s=8");
assert(!helm_active || (helm_f(12) > 500 && helm_f(8) < 1500),
    "resonances left the 500-1500Hz target band");
// Keyholes: stay inside the tile, keep a bridgeable roof under the columns
assert(key_y + key_slot_l + key_head_d / 2 < tile_size - 10,
    "keyhole slot too close to top edge");
assert(key_lip + key_head_h <= base_thick - 1.5,
    "keyhole must leave >=1.5mm roof in the base");

echo(str("cell = ", cell_size, "mm; relief 0..", max_relief,
    "mm in ", unit, "mm steps; seq offset (", off_m, ",", off_n, ")"));
echo(str("diffusion band ~", round(c_sound / (4 * max_relief)), "Hz to ~",
    round(c_sound / (2 * cell_size)), "Hz (depth / cell-width limits)"));
if (helmholtz && part != "logo")
    for (s = [8:12])
        echo(str("Helmholtz s=", s, ": h=", col_h(s), "mm, neck ",
            neck_d(s), "mm sq, V=", round(cav_vol(s) / 1000),
            "cm3, f0 ~ ", round(helm_f(s)), "Hz"));

// === MODULES ===

// Backing plate with elephant-foot chamfer on the bottom perimeter
module base_plate() {
    difference() {
        intersection() {
            cube([tile_size, tile_size, base_thick]);
            hull() {  // bottom inset by ef_chamfer, full size from z=ef up
                translate([ef_chamfer, ef_chamfer, 0])
                    cube([tile_size - 2 * ef_chamfer,
                          tile_size - 2 * ef_chamfer, fudge]);
                translate([0, 0, ef_chamfer])
                    cube([tile_size, tile_size, base_thick - ef_chamfer]);
            }
        }
        keyhole(tile_size / 2 - key_spacing / 2, key_y);
        keyhole(tile_size / 2 + key_spacing / 2, key_y);
    }
}

// Keyhole hanger cavity, cut into the back (z=0) face. Lip layers print
// first; the wider head channel above them bridges at its ceiling.
module keyhole(x, y) {
    translate([x, y, 0]) {
        // head drop-in entry - full depth
        translate([0, 0, -fudge])
            cylinder(h = key_lip + key_head_h + fudge, d = key_entry_d);
        // shank slot - full depth, runs upward (+Y)
        translate([0, 0, -fudge]) linear_extrude(key_lip + key_head_h + fudge)
            hull() {
                circle(d = key_slot_w);
                translate([0, key_slot_l, 0]) circle(d = key_slot_w);
            }
        // head channel - behind the lip only
        translate([0, 0, key_lip]) linear_extrude(key_head_h + fudge)
            hull() {
                circle(d = key_head_d);
                translate([0, key_slot_l, 0]) circle(d = key_head_d);
            }
    }
}

// Internal Helmholtz cavity for a hollow column: straight prism, 45-degree
// pyramid roof converging on a square neck through the cap. All measured
// from the base top (z = base_thick).
module helm_cavity(cx, cy, s) {
    nd = neck_d(s);
    translate([cx, cy, 0]) {
        // straight cavity
        translate([-helm_inner / 2, -helm_inner / 2, base_thick])
            cube([helm_inner, helm_inner, prism_h(s) + fudge]);
        // pyramid roof (hull of two thin squares, 45-degree hips)
        hull() {
            translate([-helm_inner / 2, -helm_inner / 2,
                       base_thick + prism_h(s)])
                cube([helm_inner, helm_inner, fudge]);
            translate([-nd / 2, -nd / 2, base_thick + prism_h(s) + pyr_h(s)])
                cube([nd, nd, fudge]);
        }
        // square neck through the cap
        translate([-nd / 2, -nd / 2, base_thick + prism_h(s) + pyr_h(s) - fudge])
            cube([nd, nd, helm_cap + 3 * fudge]);
    }
}

// One skyline column (full cell footprint plus col_lap so neighbours share
// volume, never a bare edge), hollowed if tall enough
module column(m, n) {
    s = s_val(m, n);
    h = col_h(s);
    cx = (m + 0.5) * cell_size;
    cy = (n + 0.5) * cell_size;
    if (s > 0) difference() {
        translate([m * cell_size - col_lap, n * cell_size - col_lap,
                   base_thick - fudge])
            cube([cell_size + 2 * col_lap, cell_size + 2 * col_lap,
                  h + fudge]);
        if (is_helm(h)) helm_cavity(cx, cy, s);
    }
}

// Clip overhanging col_lap back to the exact tile outline
module clip_tile() {
    intersection() {
        children();
        translate([0, 0, -1])
            cube([tile_size, tile_size,
                  base_thick + max_relief + x_relief + 2]);
    }
}

// All columns matching a selector: "field", "accent_gold", "accent_magenta".
// The logo tile keeps a calm all-navy field so the X mark owns the colour
// (matches the website's white/magenta-on-navy look); accents exist only on
// diffuser tiles.
function col_class(s) =
    part == "logo" ? "field" :
    s == 12 ? "accent_gold" :
    s == 11 ? "accent_magenta" : "field";

module columns(selector) {
    for (m = [0 : n_cells - 1], n = [0 : n_cells - 1])
        if (col_class(s_val(m, n)) == selector)
            column(m, n);
}

// X-mark 2D footprints
module x_footprint() {
    polygon(xf(x_solid_raw));
    polygon(xf(x_outline_raw));
}

// Cutter that clears the X footprint plus the shadow gap through the full
// relief height (logo tile only). Morphological closing (+r then -r) fills
// the logo's internal kerf slashes so no column slivers survive inside
// them - the navy base floor shows through the cuts, as on the website.
module x_cutter() {
    translate([0, 0, base_thick])
        linear_extrude(max_relief + x_relief + fudge)
            offset(r = shadow_gap)
                offset(r = -logo_gap_close)
                    offset(r = logo_gap_close)
                        x_footprint();
}

// Raised X bodies
module x_mark_solid() {
    translate([0, 0, base_thick - fudge])
        linear_extrude(x_relief + fudge) polygon(xf(x_solid_raw));
}
module x_mark_outline() {
    translate([0, 0, base_thick - fudge])
        linear_extrude(x_relief + fudge) polygon(xf(x_outline_raw));
}

// Field body = base plate + non-accent columns (minus X moat on logo tile)
module body_field() {
    clip_tile() difference() {
        union() { base_plate(); columns("field"); }
        if (part == "logo") x_cutter();
    }
}
module body_accent(selector) {
    clip_tile() difference() {
        columns(selector);
        if (part == "logo") x_cutter();
    }
}

// === ASSEMBLY / RENDER ===
module render_bodies() {
    if (body == "all" || body == "field")
        color(col_navy) body_field();
    if (part != "logo" && (body == "all" || body == "accent_gold"))
        color(col_gold) body_accent("accent_gold");
    if (part != "logo" && (body == "all" || body == "accent_magenta"))
        color(col_magenta) body_accent("accent_magenta");
    if (part == "logo" && (body == "all" || body == "x_solid"))
        color(col_white) x_mark_solid();
    if (part == "logo" && (body == "all" || body == "x_outline"))
        color(col_magenta) x_mark_outline();
}

if (section == 0) render_bodies();
else difference() {
    render_bodies();
    translate([-1, section == 1 ? section_y : section_y - tile_size - 2, -1])
        cube([tile_size + 2, tile_size + 2,
              base_thick + max_relief + x_relief + 2]);
}
