// Hand Pump Wall Mount Bracket v2
// Breha hand pump (Camec SKU 005543) wall mount for camp trailer
//
// Coordinate system:
//   X = width (0→115mm), left-right viewing from front
//   Y = depth (0→70mm), 0 = wall/back, 70 = front
//   Z = height (0→241mm), 0 = bottom, 241 = top
//
// Single piece — fits Bambu Lab X1C build volume (256×256×256mm).

/* [Part Selection] */
part = "full"; // ["full"]

/* [Main Dimensions] */
bracket_width  = 115;   // mm - X axis
bracket_depth  = 70;    // mm - Y axis
bracket_height = 241;   // mm - Z axis

/* [Wall Thicknesses] */
back_thick   = 4.5;    // mm - back plate (10 perimeters)
shelf_thick  = 12;     // mm - top shelf
plate_thick  = 12;     // mm - bottom plate
wall_thick   = 2.25;   // mm - side walls (5 perimeters)
rib_thick    = 2.25;   // mm - gusset ribs (5 perimeters)

/* [Holes] */
tap_hole_dia   = 32.3;  // mm - 32mm + 0.3mm PETG tolerance
hose_hole_dia  = 20;    // mm - 12mm hose + clearance
wall_bolt_dia  = 6.5;   // mm - M6 clearance

/* [Aesthetics] */
corner_radius = 3;     // mm - external corner rounding (shelf/plate front corners)
edge_round    = 1;     // mm - external vertical edge rounding
fillet_radius = 2;     // mm - internal structural fillets
top_chamfer   = 2;     // mm - top edge 45-degree chamfer

/* [Bolt Positions] */
upper_bolt_z = 201;    // mm - upper M6 wall bolt (40mm from top)
lower_bolt_z = 40;     // mm - lower M6 wall bolt (40mm from bottom)
bolt_x       = 57.5;   // mm - centered

/* [Tap & Hose Positions] */
tap_x  = 57.5;  // mm - centered on shelf
tap_y  = 40;    // mm - 40mm from wall
hose_x = 57.5;  // mm - centered on bottom plate
hose_y = 35;    // mm - centered on bottom plate

/* [Gusset Geometry] */
gusset_inboard = 15;   // mm - inboard from side walls
gusset_bot_z   = 100;  // mm - bottom of gusset ribs

/* [Resolution] */
$fn = 60;

// Derived
fudge = 0.01;  // CSG overlap for clean booleans
eps = 0.001;   // tiny dimension for hull vertices


// ============================================================
// 2D profiles
// ============================================================

// Concave fillet profile — fills the first quadrant (+X, +Y)
// Place at an internal 90-degree corner where material is in -X and -Y
module fillet_2d(r) {
    difference() {
        square(r);
        translate([r, r]) circle(r = r);
    }
}

// Rounded rectangle 2D — only front two corners rounded
// Back corners stay square (flush against wall)
module shelf_plate_2d(w, d, r) {
    hull() {
        // Back-left: square corner
        translate([fudge, fudge])
            square(fudge);
        // Back-right: square corner
        translate([w - 2 * fudge, fudge])
            square(fudge);
        // Front-left: rounded
        translate([r, d - r])
            circle(r = r);
        // Front-right: rounded
        translate([w - r, d - r])
            circle(r = r);
    }
}

// U-section 2D profile (back plate + side walls) with rounded external corners
// Uses offset(r) offset(-r) for external-only rounding
module u_section_2d() {
    r = min(edge_round, wall_thick / 2 - 0.1);  // cap rounding to fit thin walls
    offset(r = r) offset(r = -r) {
        // Back plate
        square([bracket_width, back_thick]);
        // Left wall
        square([wall_thick, bracket_depth]);
        // Right wall
        translate([bracket_width - wall_thick, 0])
            square([wall_thick, bracket_depth]);
    }
}


// ============================================================
// 3D components
// ============================================================

// Side walls + back plate — full height, using rounded 2D profile
module walls_and_back() {
    linear_extrude(height = bracket_height)
        u_section_2d();
}

// Top shelf — rounded front corners
module top_shelf() {
    translate([0, 0, bracket_height - shelf_thick])
        linear_extrude(height = shelf_thick)
            shelf_plate_2d(bracket_width, bracket_depth, corner_radius);
}

// Bottom plate — rounded front corners
module bottom_plate() {
    linear_extrude(height = plate_thick)
        shelf_plate_2d(bracket_width, bracket_depth, corner_radius);
}

// Diagonal gusset rib — triangular prism, rib_thick in X, triangle in YZ
// From shelf underside at front edge, down to back plate at gusset_bot_z
module gusset_rib() {
    gusset_top_z = bracket_height - shelf_thick;

    hull() {
        // Top-back edge
        translate([0, back_thick, gusset_top_z - eps])
            cube([rib_thick, eps, eps]);
        // Top-front edge
        translate([0, bracket_depth - eps, gusset_top_z - eps])
            cube([rib_thick, eps, eps]);
        // Bottom-back edge
        translate([0, back_thick, gusset_bot_z])
            cube([rib_thick, eps, eps]);
    }
}

// Both gusset ribs positioned symmetrically
module gusset_ribs() {
    // Left gusset — centered at X = gusset_inboard
    translate([gusset_inboard - rib_thick / 2, 0, 0])
        gusset_rib();
    // Right gusset — centered at X = bracket_width - gusset_inboard
    translate([bracket_width - gusset_inboard - rib_thick / 2, 0, 0])
        gusset_rib();
}


// ============================================================
// Holes
// ============================================================

module bolt_hole(d, h) {
    cylinder(d = d, h = h + 2 * fudge);
}

// Tap hole — 32.3mm through top shelf
module tap_hole() {
    translate([tap_x, tap_y, bracket_height - shelf_thick - fudge])
        cylinder(d = tap_hole_dia, h = shelf_thick + 2 * fudge);
}

// Hose hole — 20mm through bottom plate
module hose_hole() {
    translate([hose_x, hose_y, -fudge])
        cylinder(d = hose_hole_dia, h = plate_thick + 2 * fudge);
}

// Wall mounting bolt holes — 2x M6, through back plate along Y axis
module wall_bolt_holes() {
    for (z = [upper_bolt_z, lower_bolt_z]) {
        translate([bolt_x, -fudge, z])
            rotate([-90, 0, 0])
                bolt_hole(wall_bolt_dia, back_thick);
    }
}

// All holes combined
module all_holes() {
    tap_hole();
    hose_hole();
    wall_bolt_holes();
}


// ============================================================
// Structural fillets — additive geometry at internal corners
// ============================================================

module structural_fillets() {
    r = fillet_radius;

    // --- Back plate to bottom plate (X-aligned fillet) ---
    // Corner at Y=back_thick, Z=plate_thick; fillet fills +Y, +Z quadrant
    translate([0, back_thick, plate_thick])
        rotate([90, 0, 90])
            linear_extrude(height = bracket_width)
                fillet_2d(r);

    // --- Back plate to shelf underside (X-aligned fillet) ---
    // Corner at Y=back_thick, Z=bracket_height-shelf_thick
    // Fillet fills +Y, -Z quadrant — mirror the 2D profile in Y
    translate([0, back_thick, bracket_height - shelf_thick])
        rotate([90, 0, 90])
            linear_extrude(height = bracket_width)
                mirror([0, 1])
                    fillet_2d(r);

    // --- Left wall to back plate (Z-aligned fillet) ---
    // Corner at X=wall_thick, Y=back_thick; fillet fills +X, +Y quadrant
    translate([wall_thick, back_thick, 0])
        linear_extrude(height = bracket_height)
            fillet_2d(r);

    // --- Right wall to back plate (Z-aligned fillet) ---
    // Corner at X=bracket_width-wall_thick, Y=back_thick
    // Fillet fills -X, +Y quadrant — mirror in X
    translate([bracket_width - wall_thick, back_thick, 0])
        linear_extrude(height = bracket_height)
            mirror([1, 0])
                fillet_2d(r);
}


// ============================================================
// Top edge chamfers — 45-degree bevel on front, left, and right
// Back edge (wall side) is not chamfered.
//
// Constructed as: bounding block minus a frustum that tapers
// inward at the top. Subtracting this from the bracket creates
// the chamfer wedges on all three exposed top edges at once.
// ============================================================

module top_edge_chamfers() {
    c = top_chamfer;

    difference() {
        // Block covering the chamfer zone
        translate([-fudge, -fudge, bracket_height - c])
            cube([bracket_width + 2 * fudge,
                  bracket_depth + 2 * fudge,
                  c + fudge]);

        // Frustum to keep: full footprint at Z=bh-c, inset at Z=bh
        hull() {
            // Bottom: full bracket footprint
            translate([0, 0, bracket_height - c])
                linear_extrude(height = eps)
                    square([bracket_width, bracket_depth]);
            // Top: inset by c on left, right, and front (not back)
            translate([c, 0, bracket_height])
                linear_extrude(height = eps)
                    square([bracket_width - 2 * c, bracket_depth - c]);
        }
    }
}


// ============================================================
// Complete bracket
// ============================================================

module bracket_body() {
    union() {
        walls_and_back();
        top_shelf();
        bottom_plate();
        gusset_ribs();
        structural_fillets();
    }
}

module bracket_complete() {
    difference() {
        bracket_body();
        all_holes();
        top_edge_chamfers();
    }
}


// ============================================================
// Render
// ============================================================

bracket_complete();
