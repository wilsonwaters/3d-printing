// === DESCRIPTION ===
// Wall mount bracket for Breha hand pump (camp trailer hand sink pump)
// https://camec.com.au/products/breha-hand-pump-std-white
//
// Design: Triangulated L-bracket with two side walls and open front
// - Back plate mounts to wall via M6 through-bolts
// - Top shelf holds pump via 32mm mounting hole
// - Triangulated side walls with diagonal bracing for rigidity
// - Interior ribs add stiffness without blocking pump body
// - Pipe enters from below through open bracket cavity
// - Chamfered shelf edges for hand safety
// - Rounded vertical corners on shelf and bottom plate

// === PRINT SETTINGS ===
// Printer: Bambu Lab X1 Carbon (256 x 256 x 256 mm)
// Material: PETG (dry filament first: 60-65C for 4-6 hours)
// Layer Height: 0.2mm
// Walls/Perimeters: 6 (2.7mm minimum wall sections)
// Infill: 25% gyroid
// Supports: None required (all overhangs self-supporting)
// Orientation: Print on LEFT SIDE WALL (flat on build plate)
//   -> In slicer: right-click model > "Place on face" > click left side wall
//   -> Print dims: X=70mm (depth), Y=220mm (height), Z=110mm (width)
//   -> Pumping forces align with XY layer plane = maximum strength
// Nozzle temp: 240-245C (max layer adhesion for structural part)
// Bed temp: 75-80C
// Fan: 30-40% (standard PETG, do NOT use 100%)
// Bed adhesion: Apply glue stick on PEI as PETG release agent
// Estimated material: ~150-200g
// Notes:
//   - VERIFY pump body fits through the mounting hole before final print
//   - Print a short 20mm-tall test piece first to check bolt hole sizing
//   - Two wall bolts strongly recommended for rigidity under pumping loads
//   - Pipe/hose enters from below through open bracket cavity
//   - Sand any sharp edges after printing for hand comfort

// === PARAMETERS ===

// -- Printer --
nozzle_diameter = 0.4;
layer_height    = 0.2;

// -- Bracket envelope (mounted orientation: X=width, Y=depth, Z=height) --
bracket_height = 220;   // [mm] Vertical height when wall-mounted
bracket_width  = 110;   // [mm] Horizontal width
bracket_depth  = 70;    // [mm] Extends this far from wall

// -- Structural wall thicknesses --
// Thicknesses are multiples of extrusion width (0.45mm for 0.4mm nozzle)
back_wall   = 4.5;  // [mm] Back plate: 10 perimeters (bolt bearing surface)
side_wall   = 2.7;  // [mm] Side walls: 6 perimeters (structural)
shelf_thick = 8.0;  // [mm] Top shelf: pump mounting platform
bottom_thick = 4.5; // [mm] Bottom plate: same as back wall

// -- Bottom plate (partial, for base rigidity) --
bottom_depth = 35;   // [mm] How far bottom plate extends from wall

// -- Pump mounting hole --
pump_hole_d           = 33;   // [mm] 32mm nominal + 1mm clearance (VERIFY!)
pump_center_from_wall = 45;   // [mm] Center of hole from wall (moved back 5mm)
pump_center_x         = bracket_width / 2;  // [mm] Centered on width

// -- Wall mounting bolts (M6 through metal wall) --
bolt_hole_d = 6.8;   // [mm] M6 clearance hole (6mm + 0.8mm PETG tolerance)
bolt_1_z    = bracket_height - 50;  // [mm] Primary bolt: 50mm from top
bolt_2_z    = 50;                    // [mm] Secondary bolt: 50mm from bottom
bolt_x      = bracket_width / 2;    // [mm] Centered on width

// -- Interior reinforcement ribs --
rib_thick     = 1.8;        // [mm] 4 perimeters (prints as solid wall)
rib_positions = [25, 85];   // [mm] X positions (centred, 60mm gap preserved)

// -- Aesthetics and stress relief --
ext_round = 3;       // [mm] External corner rounding on side profile
corner_r  = 3;       // [mm] Rounding radius for vertical corners (shelf/bottom plate)
fillet_r  = 5;       // [mm] Structural fillet at shelf-to-backplate junction
fillet_r_bottom = 3; // [mm] Fillet at bottom-plate-to-backplate junction
edge_chamfer = 2;    // [mm] Chamfer on exposed shelf edges for hand safety

// === DERIVED CONSTANTS ===
extrusion_width = nozzle_diameter * 1.125;  // 0.45mm
fudge = 0.01;
$fn = $preview ? 32 : 64;

// Computed values
shelf_bottom_z = bracket_height - shelf_thick;
diagonal_run   = bracket_depth - bottom_depth;
diagonal_rise  = shelf_bottom_z;

// === MODULES ===

// Cube with rounded vertical (Z-axis) edges
module rounded_cube(size, r) {
    linear_extrude(height = size[2])
        offset(r = r) offset(delta = -r)
            square([size[0], size[1]]);
}

// 2D side profile (pentagon: back plate + diagonal + shelf)
// Coordinates: X = depth from wall, Y = height
// All convex corners rounded with ext_round radius
module side_profile() {
    offset(r = ext_round) offset(delta = -ext_round)
        polygon([
            [0, 0],                       // bottom-back
            [bottom_depth, 0],            // bottom-front (base of diagonal)
            [bracket_depth, shelf_bottom_z], // under shelf at front
            [bracket_depth, bracket_height], // top-front (shelf top)
            [0, bracket_height]           // top-back
        ]);
}

// 2D interior profile for ribs
// Intersection of side profile with interior region
module interior_profile() {
    intersection() {
        side_profile();
        // Interior region: inset from structural walls with 1mm overlap
        // for solid union with surrounding structure
        translate([back_wall - 1, bottom_thick - 1])
            square([
                bracket_depth - back_wall + 2,
                bracket_height - shelf_thick - bottom_thick + 2
            ]);
    }
}

// Quarter-cylinder fillet for a concave 90-degree interior corner
// Flat faces point in local +Y and +Z directions
// Runs along X axis for 'len'
module corner_fillet(r, len) {
    difference() {
        cube([len, r, r]);
        translate([-fudge, r, r])
            rotate([0, 90, 0])
                cylinder(h = len + 2 * fudge, r = r);
    }
}

// === MAIN BRACKET ===
module bracket() {
    difference() {
        union() {
            // ---- Primary structure ----

            // Back plate (mounts against wall)
            cube([bracket_width, back_wall, bracket_height]);

            // Top shelf (pump mounting surface) — rounded vertical corners
            translate([0, 0, shelf_bottom_z])
                rounded_cube([bracket_width, bracket_depth, shelf_thick], corner_r);

            // Bottom plate (partial depth, for base rigidity) — rounded vertical corners
            rounded_cube([bracket_width, bottom_depth, bottom_thick], corner_r);

            // Left side wall (triangulated profile)
            rotate([90, 0, 90])
                linear_extrude(height = side_wall)
                    side_profile();

            // Right side wall (triangulated profile)
            translate([bracket_width - side_wall, 0, 0])
                rotate([90, 0, 90])
                    linear_extrude(height = side_wall)
                        side_profile();

            // ---- Interior reinforcement ribs ----
            for (rx = rib_positions) {
                translate([rx - rib_thick / 2, 0, 0])
                    rotate([90, 0, 90])
                        linear_extrude(height = rib_thick)
                            interior_profile();
            }

            // ---- Structural fillets (stress relief) ----

            // Fillet: shelf underside to back plate inner surface
            // (Critical: resists moment from pumping forces)
            translate([0, back_wall, shelf_bottom_z])
                mirror([0, 0, 1])
                    corner_fillet(fillet_r, bracket_width);

            // Fillet: bottom plate top to back plate inner surface
            translate([0, back_wall, bottom_thick])
                corner_fillet(fillet_r_bottom, bracket_width);
        }

        // ---- Subtractions ----

        // Pump mounting hole through shelf
        translate([pump_center_x, pump_center_from_wall,
                   shelf_bottom_z - fudge])
            cylinder(h = shelf_thick + 2 * fudge, d = pump_hole_d);

        // Wall bolt hole 1: primary (50mm from top)
        translate([bolt_x, -fudge, bolt_1_z])
            rotate([-90, 0, 0])
                cylinder(h = back_wall + 2 * fudge, d = bolt_hole_d);

        // Wall bolt hole 2: secondary (50mm from bottom)
        translate([bolt_x, -fudge, bolt_2_z])
            rotate([-90, 0, 0])
                cylinder(h = back_wall + 2 * fudge, d = bolt_hole_d);

        // Shelf edge chamfer: 45-degree chamfer on front-top edge (hand safety)
        // Rotated cube centered on the edge cuts equal amounts from top and front
        translate([bracket_width / 2, bracket_depth, bracket_height])
            rotate([45, 0, 0])
                cube([bracket_width + 2 * fudge,
                      edge_chamfer * sqrt(2),
                      edge_chamfer * sqrt(2)], center = true);
    }
}

// === RENDER ===
bracket();
