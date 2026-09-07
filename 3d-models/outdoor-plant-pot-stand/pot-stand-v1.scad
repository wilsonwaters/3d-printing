// === DESCRIPTION ===
// Outdoor Plant Pot Stand (pot riser / plinth): a square open-lattice slab that a
// tapered square glazed ceramic pot sits on, out on brick pavers against a house wall.
// It lifts the pot ~25mm clear of the pavers so the drain hole in the centre of the
// pot's base can actually drain: water falls straight through the open lattice, then
// runs out sideways through triangular channels cut into the bottom of every rib and
// through the outer wall. That stops the pot standing in its own water (root rot,
// mosquito water, tannin staining and lime bloom on the pavers) and lets air dry the
// pot base.
//
// The pots vary: their square bases are anywhere from 170mm to 200mm across. One
// stand size therefore has to suit the whole range, which drives the two key ideas:
//   - The whole top surface is ONE flat plane (every rib top and the outer wall top
//     are coplanar at z = stand_height). Any base from ~120mm to stand_size lands flat
//     on it, so there is no size-specific seat, ledge or locating lip to foul a
//     different pot. No rocking on a partially-supported ledge.
//   - The lattice runs edge to edge, so ribs sit under the *middle* of the smallest
//     pot AND under the outer edge of the biggest one. A 170mm base lands on 4 ribs
//     per axis; a 196mm base lands on all of them plus the outer wall.
//   Default stand_size = 196mm: 2mm inside the biggest pot (so it hides underneath
//   it) and standing 13mm proud of the smallest one, like a plinth.
//
// Design decisions:
//   - Vertical-wall lattice, no top or bottom skin. Prints as pure perimeters (no
//     infill, no solid layers): every wall is loaded in compression across the layers,
//     which is FDM's strong direction, and the ~45cm^2 of total wall cross-section puts
//     the stress from a 25kg wet pot at ~0.05MPa — ~1000x below PETG yield, so no
//     creep in summer sun. It is also the lightest way to get this stiff (~133g).
//   - Open cells top-to-bottom, so water never has to find a hole: it drops through
//     whichever cell is under the pot's drain hole. An ODD cell count (n_cells) is
//     forced so a whole open cell sits dead centre under that drain hole.
//   - Drain channels: instead of drilling holes, a 45deg triangular channel is
//     subtracted along every cell-centre line in both X and Y. That notches every
//     rib and both faces of the outer wall in one operation, giving a connected
//     drainage grid at ground level with an exit on all four sides. The 45deg apex is
//     self-supporting, so no bridge and no supports (PETG bridges poorly).
//   - Rounded corners (corner_r) + bottom chamfer: a 196mm PETG footprint wants to
//     lift at sharp corners; rounded corners and a small chamfer plus a brim fix that.
//   - The outer wall is 5 perimeters where the ribs are 4. Vertically every wall is
//     in compression (strong across the layers), but a sideways knock - boot, broom,
//     rake while weeding - bends a wall at its base, which is PETG's weaker direction.
//     The ribs are shielded by the pot; the outer wall is the member left standing
//     proud beside a smaller pot, so it gets the extra 0.45mm (+56% section modulus).
//     It is also a closed loop tied to the ribs every cell_pitch, not a free fin.
//   - Optional containment lip (rim_extra > 0) raises just the outer wall above the
//     seat plane to corral the pot. Sizing it is about the lip's INNER opening
//     (stand_size - 2*wall_thick), not the outer footprint, and these pots are
//     tapered, so the pot is wider at the top of the lip than at its base: the
//     assert requires opening >= pot base + 2*(lip_clear + pot_taper*rim_extra).
//     MEASURE the pot rim_extra mm above its base, not just its base, before trusting
//     pot_taper. For a 200mm pot and an 8mm lip that lands at stand_size = 212mm.
//
// Terminology -> code:
//   "the stand / slab"        -> stand_size, stand_height, pot_stand()
//   "the seat" (flat top)     -> stand_height (top plane of ribs AND outer wall)
//   "outer wall / rim"        -> wall_thick, rim_extra, outer_wall()
//   "ribs / lattice / grid"   -> rib_thick, n_cells, cell_pitch, ribs()
//   "cells" (the open squares)-> cell_open (clear opening), cell_centres()
//   "drain channels/notches"  -> drain_w, drain_h, drain_channels()
//   "containment lip/corral"  -> rim_extra, lip_clear, pot_taper, lip_opening
//   "pot footprint"           -> pot_base_min, pot_base_max, show_pot (preview only)
//
// Common modifications:
//   Different pots            -> pot_base_min / pot_base_max, then re-check the echoed
//                                stand_size (derived as pot_base_max - 4)
//   Force an exact footprint  -> set stand_size directly (keep <= 216 for an X1C bed)
//   Taller / more airflow     -> stand_height (keep >= drain_h + 8*layer_height)
//   Less filament / faster    -> raise cell_target (bigger cells) or drop stand_height
//   Stronger / finer grid     -> lower cell_target AND min_cell_open together (min_cell_open
//                                caps the cell count on its own), or rib_walls 4 -> 5
//   More kick-resistant edge  -> outer_walls 5 -> 6
//   Add a lip that traps the  -> rim_extra = 8 AND stand_size = 212 (and cell_target
//     pot from sliding           = 42 to keep 5 cells). The assert prints the exact
//                                minimum stand_size if you get it wrong.
//   Bigger drain channels     -> drain_w (drain_h stays drain_w/2 to keep 45deg)
//
// Overall dimensions: 196 x 196 x 25mm (default). Fits the ~220mm auto-centred square
//   an X1C/P1 can print without touching the front-left filament-cutter exclusion.
// Coordinate system: X/Y = the square footprint, centred on the origin.
//   Z = height from the build plate; z = stand_height is the flat seat the pot rests on.
// NOTE: Model is in print orientation AND in use orientation — the preview is exactly
//   how it prints and exactly how it sits on the pavers.

// === PRINT SETTINGS ===
// Material: PETG (outdoor: Tg 75-85C so it will not sag on hot pavers in summer sun,
//   tough rather than brittle if kicked, and only moderate UV loss — 1-2 years to
//   ~25% strength loss, which this part has 1000x margin on. Print it in a LIGHT
//   colour for UV life. ASA/ASA-CF is the upgrade if you have an enclosure; PLA is a
//   bad idea here — it creeps and goes chalky in the weather.)
// Layer Height: 0.2mm
// Walls/Perimeters: 5. The whole part IS perimeters: 5 fills the 2.25mm outer wall
//   exactly, and the 1.8mm ribs take the 4 that fit (the slicer prints what fits).
// Infill: 0% (no infill and no top/bottom solid layers: it is an open lattice by
//   design. Bottom solid layers 0-1, top solid layers 0.)
// Supports: None required. Every wall is vertical; the only overhangs are the drain
//   channel apexes, which are 45deg and self-supporting.
// Orientation: As modelled — flat on the plate, z=0 is the ground face.
// Notes:
//   - Dry the PETG (60-65C / 4-6h). 240C nozzle for best layer bond, 30-40% fan.
//   - Use a BRIM (5-10mm) — a 196mm PETG footprint of thin walls likes to lift.
//   - X1C/P1: 196mm centred clears the 18x28mm front-left cutter exclusion. Do not
//     let the slicer shove it into the front-left corner.
//   - Rib bottoms carry no ef_chamfer of their own (a lattice cannot be hulled without
//     filling its cells, and nothing mates with this part) - leave the slicer's own
//     elephant-foot compensation on. Only the outer wall is chamfered in the model.
//   - Measured solid volume 104.7cm^3: ~133g in PETG, ~2-3h.

// === PARAMETERS ===
// Printer settings
nozzle_diameter = 0.4;
layer_height    = 0.2;
build_x         = 256;   // Bambu Lab X1 Carbon
build_y         = 256;
build_z         = 256;
bed_safe_xy     = 220;   // usable auto-centred square (front-left cutter exclusion)

// The pots this has to suit (square base, measured across the flats)
pot_base_min = 170;      // smallest pot base
pot_base_max = 200;      // largest pot base

// Stand
stand_size   = pot_base_max - 4;  // footprint, square. Just inside the biggest pot.
stand_height = 25;                // ground clearance under the pot = drainage + airflow
cell_target  = 35;                // target open-cell pitch; actual pitch divides evenly
corner_r     = 8;                 // outer corner radius (warp + shins)
rim_extra    = 0;                 // >0 raises the outer wall above the seat as a lip
                                  //   (needs stand_size >= pot_base_max + 4)

// Wall thicknesses, in whole perimeters
rib_walls   = 4;         // internal lattice ribs (only ever loaded in compression)
outer_walls = 5;         // outer wall - thicker because it is the one member left
                         //   exposed beside a smaller pot, so it takes the broom/boot

// Drainage
drain_w = 14;            // width of the ground-level drain channels

// Cell sizing / fit limits
min_cell_open = 30;      // smallest clear cell allowed (drainage under the pot's hole)
min_lift      = 20;      // least ground clearance that still drains and airs the base
lip_clear     = 3;       // slack per side between pot and containment lip (rim_extra > 0)
pot_taper     = 0.06;    // how much wider the pot gets per mm of height, PER SIDE.
                         //   0.06 = ~30mm total flare over a ~250mm tall pot, measured
                         //   off these pots. Only used to size the containment lip.

// Inspection aids (not for printing)
show_pot = false;        // true = ghost the smallest/largest pot footprints (drawn with
                         //   % so it is excluded from the CSG and never reaches the STL)
section  = 0;            // 1 = cut the model away at Y=0 to inspect it. Export with 0.

// === DERIVED CONSTANTS ===
// No mating tolerance constant: this is a single part with nothing plugging into it.
// The only fit is pot-to-lip, handled by lip_clear + pot_taper below.
extrusion_width = nozzle_diameter * 1.125;      // 0.45
rib_thick       = rib_walls * extrusion_width;  // 1.8
wall_thick      = outer_walls * extrusion_width;// 1.8
fudge           = 0.01;                         // boolean overlap
ef_chamfer      = 0.4;                          // elephant-foot compensation (bottom)
top_chamfer     = 0.6;                          // cosmetic chamfer on the top outer edge
rib_embed       = 0.6;                          // how far ribs bury into the outer wall
$fn             = $preview ? 32 : 64;

// Odd cell count so an open cell sits centred under the pot's drain hole.
// n_target is the count nearest cell_target; n_max is the most cells that still leave
// min_cell_open clear, so a bigger stand_size can never quietly starve the drain cell.
n_target   = max(3, 2 * floor(stand_size / cell_target / 2) + 1);
n_max      = max(concat([3],
                 [ for (n = [3 : 2 : 15])
                     if (stand_size / n - rib_thick >= min_cell_open) n ]));
n_cells    = min(n_target, n_max);
cell_pitch = stand_size / n_cells;
cell_open  = cell_pitch - rib_thick;            // clear opening of one cell
drain_h    = drain_w / 2;                       // 45deg apex => self-supporting
wall_h     = stand_height + rim_extra;          // outer wall height

// Containment lip fit (rim_extra > 0): what matters is the lip's INNER opening, not the
// outer footprint, and the pot is wider at the top of the lip than at its base.
lip_opening = stand_size - 2 * wall_thick;
lip_needed  = pot_base_max + 2 * (lip_clear + pot_taper * rim_extra);

// Interior rib centrelines (the outer wall provides the boundary lines)
lines  = [ for (i = [1 : n_cells - 1]) -stand_size / 2 + i * cell_pitch ];
// Cell centres (one is exactly 0 because n_cells is odd)
centres = [ for (i = [0 : n_cells - 1]) -stand_size / 2 + (i + 0.5) * cell_pitch ];
// Interior ribs that fall under the smallest pot, with 2mm to spare from its edge
lines_under_small = [ for (p = lines) if (abs(p) < pot_base_min / 2 - 2) p ];

// === CONTRACTS (measurable acceptance criteria) ===
assert(pot_base_min <= pot_base_max,
       "pot_base_min must not exceed pot_base_max");
assert(stand_height >= min_lift,
       "stand_height below min_lift - too low to drain and air the pot base");
assert(drain_w <= 0.6 * cell_pitch,
       "drain channels wider than 60% of the cell pitch merge and undercut whole ribs");
assert(stand_size <= bed_safe_xy - 4,
       "footprint too big for the X1C's usable centred bed (220mm)");
assert(stand_size >= pot_base_max - 16,
       "stand too small: the biggest pot would overhang more than 8mm per side");
assert(len(lines_under_small) >= 4,
       "smallest pot lands on fewer than 4 ribs per axis - lower cell_target");
assert(n_cells % 2 == 1,
       "cell count must be odd so an open cell sits under the pot's centre drain hole");
assert(cell_open >= min_cell_open,
       "centre cell too small - water from the drain hole needs a clear cell");
assert(n_cells >= 3,
       "need at least 3 drain exits per side");
assert(stand_height - drain_h >= 8 * layer_height,
       "not enough wall left above the drain channels");
assert(drain_h == drain_w / 2,
       "drain channel must stay a 45deg apex to print without support");
assert(rib_thick >= 3 * extrusion_width && wall_thick >= 3 * extrusion_width,
       "walls thinner than 3 perimeters are too weak for an outdoor load-bearing part");
assert(corner_r > wall_thick,
       "corner radius must exceed the wall thickness");
assert(rim_extra == 0 || lip_opening >= lip_needed,
       str("containment lip too tight: inner opening ", lip_opening, "mm, needs ",
           lip_needed, "mm (pot base + taper over the lip height + clearance). ",
           "Raise stand_size to at least ", lip_needed + 2 * wall_thick, "mm."));

echo(stand_size = stand_size, stand_height = stand_height, wall_h = wall_h,
     lip_opening = (rim_extra > 0) ? lip_opening : 0,
     n_cells = n_cells, cell_pitch = cell_pitch, cell_open = cell_open,
     rib_thick = rib_thick, drains_per_side = n_cells);

// === MODULES ===

// Centred square with rounded corners (2D)
module rounded_sq(size, r) {
    offset(r = r) square([size - 2 * r, size - 2 * r], center = true);
}

// Outer wall: a square ring, chamfered on the bottom outside edge (elephant foot)
// and on the top outside edge (cosmetic). Inner face left square so ribs meet it flat.
module outer_wall() {
    difference() {
        hull() {
            linear_extrude(fudge)
                rounded_sq(stand_size - 2 * ef_chamfer, corner_r - ef_chamfer);
            translate([0, 0, ef_chamfer])
                linear_extrude(wall_h - ef_chamfer - top_chamfer)
                    rounded_sq(stand_size, corner_r);
            translate([0, 0, wall_h - fudge])
                linear_extrude(fudge)
                    rounded_sq(stand_size - 2 * top_chamfer, corner_r - top_chamfer);
        }
        translate([0, 0, -fudge])
            linear_extrude(wall_h + 2 * fudge)
                rounded_sq(stand_size - 2 * wall_thick, corner_r - wall_thick);
    }
}

// Lattice ribs. Length reaches rib_embed into the outer wall on both sides so the
// solids share real volume (no bare-edge contact), and never past its outer face.
module ribs() {
    rib_len = stand_size - 2 * wall_thick + 2 * rib_embed;
    for (p = lines) {
        // running along Y
        translate([p, 0, stand_height / 2])
            cube([rib_thick, rib_len, stand_height], center = true);
        // running along X
        translate([0, p, stand_height / 2])
            cube([rib_len, rib_thick, stand_height], center = true);
    }
}

// One ground-level drain channel: a 45deg triangular prism running the full width.
module drain_channel(pos, along_x) {
    len = stand_size + 10;
    rotate([0, 0, along_x ? 90 : 0])
        translate([pos, 0, -fudge])
            rotate([90, 0, 0])
                linear_extrude(height = len, center = true)
                    polygon([[-drain_w / 2, 0], [drain_w / 2, 0], [0, drain_h]]);
}

// The connected drainage grid: a channel on every cell-centre line, both directions.
// Channels cross only at cell centres, which are open cells, so they never
// over-thin a rib. Each channel notches the outer wall on both sides = an exit.
module drain_channels() {
    for (c = centres) {
        drain_channel(c, false);
        drain_channel(c, true);
    }
}

// Ghost of the pot footprints - preview only, excluded from the exported solid.
module pot_ghosts() {
    for (s = [pot_base_min, pot_base_max])
        %translate([0, 0, stand_height])
            linear_extrude(2) difference() {
                rounded_sq(s, 10);
                rounded_sq(s - 3, 10);
            }
}

// === ASSEMBLY / RENDER ===
module pot_stand() {
    difference() {
        union() {
            outer_wall();
            ribs();
        }
        drain_channels();
    }
}

if (section == 0) pot_stand();
else difference() {
    pot_stand();
    translate([-stand_size, -stand_size, -stand_size])
        cube([2 * stand_size, stand_size, 3 * stand_size]);
}
if (show_pot) pot_ghosts();
