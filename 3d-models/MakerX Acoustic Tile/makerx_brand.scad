// =============================================================================
// makerx_brand.scad  —  Shared brand + acoustic library for MakerX tiles
// -----------------------------------------------------------------------------
// Included with include<makerx_brand.scad> by all three variant files
// (qrd / skyline / absorber). It contains ONLY parameters, functions and
// modules — NO top-level geometry — so including it is side-effect-free.
//
// BRAND SOURCE  (captured from https://makerx.com.au/ CSS + logomark SVG):
//   --color-mx-black         #0e0f10
//   --color-mx-electic-blue  #16acf2   (electric blue)
//   --color-mx-magenta       #cc3a9d
//   --color-mx-gold          #ffc023
//   signature hero gradient  electric-blue -> magenta -> gold
//   X logomark               two mirrored chevron polygons (SVG viewBox
//                            0 0 1300 1100, Y-flipped into OpenSCAD Y-up space)
//
// TERMINOLOGY -> code:
//   "brand colours"     -> MX_BLACK / MX_BLUE / MX_MAGENTA / MX_GOLD
//   "the X / logo"      -> mx_x_2d(), mx_x_placed_2d(), mx_logo_w
//   "gradient zones"    -> mx_zone_name(), mx_color_region_2d()
//   "the frame / rim"   -> frame_w, mx_frame_2d()
//   "diffusion band"    -> f_low, f_high, N, depth_unit, max_depth, max_feat_w
// =============================================================================

// ---- Brand palette (web hex; affects preview + 3MF/AMF colour only) ----------
MX_BLACK   = "#0e0f10";
MX_BLUE    = "#16acf2";   // electric blue
MX_MAGENTA = "#cc3a9d";
MX_GOLD    = "#ffc023";

// ---- Printer / derived constants --------------------------------------------
nozzle_diameter = 0.4;
layer_height    = 0.2;
ew              = nozzle_diameter * 1.125;   // extrusion width = 0.45 mm
fudge           = 0.01;                       // boolean overlap
ef_chamfer      = 0.4;                        // elephant-foot compensation
$fn            = $preview ? 24 : 48;

// ---- Tile geometry (shared defaults; a variant file may override) -----------
tile      = 250;                 // module footprint X & Y (tiles butt together)
frame_w   = 8;                   // perimeter frame / rim width (black border)
interior  = tile - 2*frame_w;    // acoustic field side length

// ---- Acoustic band targets --------------------------------------------------
c_air   = 343000;                // speed of sound in air (mm/s)
f_low   = 4000;                  // low edge of diffusion band  -> max well depth
f_high  = 10000;                 // high edge of diffusion band -> max feature width
N       = 7;                     // Schroeder prime (quadratic-residue diffuser)
periods = 2;                     // QR periods across the tile -> N*periods cells

// quadratic-residue sequence  s_n = n^2 mod N   (n = 0..N-1)
function qr_seq(n) = (n*n) % N;
function qr_max()  = max([for (n=[0:N-1]) qr_seq(n)]);   // = 4 for N=7

lambda_low  = c_air / f_low;             // 85.75 mm  (wavelength at f_low)
depth_unit  = lambda_low / (2*N);        // 6.125 mm  (QRD depth quantum)
max_depth   = qr_max() * depth_unit;     // 24.5 mm   (deepest well / tallest cell)
max_feat_w  = c_air / (2*f_high);        // 17.15 mm  (cell width must be <= this)

fin_t       = 4*ew;                      // QRD divider / structural wall = 4 perimeters (1.8mm)

// ---- X logomark polygons (Y-flipped from site SVG, viewBox 1300x1100) --------
MX_VB = 1300;   // viewBox width  (used for scaling)
MX_CX = 650;    // viewBox centre x
MX_CY = 550;    // viewBox centre y (post-flip, content is symmetric about this)

MX_X_POLY_A = [
  [900.37,1074.75], [743.06,889.31], [701.27,840.11], [691.10,828.10], [701.00,816.41],
  [719.91,794.14], [730.09,806.15], [771.87,855.40], [920.72,1030.86], [1195.18,1030.86],
  [1010.86,813.57], [982.09,779.65], [844.86,617.88], [816.04,583.92], [787.23,550.00],
  [816.04,516.08], [1195.18,69.14], [920.72,69.14], [771.87,244.61], [743.06,278.56],
  [678.81,354.31], [650.00,388.22], [605.82,440.34], [595.73,452.47], [567.28,486.75],
  [538.59,452.91], [566.96,418.55], [577.01,406.38], [621.19,354.31], [650.00,320.34],
  [663.93,303.94], [692.70,270.03], [705.59,254.82], [714.25,244.61], [734.36,220.90],
  [743.06,210.65], [900.37,25.25], [1290.00,25.25], [1035.20,325.58], [844.82,550.00],
  [873.63,583.96], [1010.86,745.70], [1039.63,779.61], [1290.00,1074.75]
];
MX_X_POLY_B = [
  [10.00,1074.75], [455.18,550.00], [324.97,396.52], [308.97,377.65], [271.46,333.43],
  [228.48,282.79], [218.55,271.10], [215.35,267.31], [10.00,25.25], [399.63,25.25],
  [404.54,31.03], [410.17,37.66], [413.40,41.45], [423.30,53.14], [609.77,269.23],
  [581.04,303.11], [394.49,87.10], [384.59,75.41], [381.36,71.62], [379.28,69.14],
  [104.82,69.14], [244.12,233.39], [247.32,237.18], [257.25,248.88], [329.00,333.43],
  [366.51,377.65], [382.51,396.52], [483.95,516.08], [512.77,550.00], [650.00,711.78],
  [678.81,745.69], [650.00,779.66], [618.79,816.41], [399.63,1074.75]
];

// 2D X logomark, centred at origin, scaled to approx width `w`
module mx_x_2d(w) {
    scale(w / MX_VB) translate([-MX_CX, -MX_CY])
        union() { polygon(MX_X_POLY_A); polygon(MX_X_POLY_B); }
}

mx_logo_w = 120;   // logomark target width (mm) on the tile
module mx_x_placed_2d() {
    translate([tile/2, tile/2]) mx_x_2d(mx_logo_w);
}

// ---- Gradient zones (diagonal electric-blue -> magenta -> gold) -------------
// Matches the makerx.com.au hero: blue at TOP-LEFT -> magenta -> gold at
// BOTTOM-RIGHT (viewer looking at the +Z tile face, Y = up). The gradient
// parameter is t = (x + (tile - y)) / (2*tile) in [0,1]; blue t<1/3,
// magenta 1/3..2/3, gold >2/3.  mx_below(cc) returns the region t*2*tile <= cc.
module mx_below(cc) {
    // triangle for (x + y <= cc), reflected about y = tile/2 so it becomes
    // (x + (tile - y) <= cc) -> the brand diagonal (blue top-left).
    translate([0, tile/2]) mirror([0,1,0]) translate([0,-tile/2])
        polygon([[-tile,-tile], [cc+tile,-tile], [-tile,cc+tile]]);
}
// 2D interior region (inside the frame) and the frame ring
module mx_interior_2d() { translate([frame_w, frame_w]) square([interior, interior]); }
module mx_frame_2d()    { difference() { square([tile, tile]); mx_interior_2d(); } }

// 2D region for one colour body. The four regions PARTITION the whole tile
// (mutually exclusive, union = full square) so colour bodies never overlap/gap:
//   black            = frame ring  +  X logomark (drawn over the field)
//   blue/magenta/gold = its diagonal interior band, minus the X footprint
module mx_color_region_2d(name) {
    if (name == "black") {
        union() {
            mx_frame_2d();
            intersection() { mx_interior_2d(); mx_x_placed_2d(); }
        }
    } else {
        difference() {
            intersection() {
                mx_interior_2d();
                if (name == "blue")          mx_below(2*tile/3);
                else if (name == "magenta")  difference() { mx_below(4*tile/3); mx_below(2*tile/3); }
                else /* gold */              difference() { square([tile,tile]); mx_below(4*tile/3); }
            }
            mx_x_placed_2d();   // X belongs to the black body, carve it out here
        }
    }
}

// Mounting: these tiles have a flat back (diffusers) or an open standoff frame
// (absorber) intended for the usual acoustic-panel mounting — removable mounting
// strips (e.g. Command) or spray/construction adhesive on the back / frame edge.
// No screw bosses are modelled (a 2 mm back is too thin for a keyhole, and bosses
// would stop the tile sitting flat).
