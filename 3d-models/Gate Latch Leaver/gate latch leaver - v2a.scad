// Gate Latch Lever for 3D Printing (ASA Material)
// A lever mechanism to allow opening a gate from the other side
// Optimized for ASA filament printing with outdoor durability
// Gate clearance: 7mm available, part max 5mm width
// Gate timber depth: 25mm
// Hardware: M4 bolts and self-tapping screws

// Parameters - optimized for ASA printing and your gate specifications
lever_length = 80;          // Total length of the lever arm
lever_width = 5;            // Width constrained to 5mm max (7mm clearance available)
lever_thickness = 5;        // Thickness optimized for ASA strength
handle_diameter = 15;       // Handle diameter (reduced for better printing)
handle_thickness = 5;       // Handle thickness
pivot_hole_diameter = 4.2;  // M4 bolt clearance hole (4mm + 0.2mm tolerance)
mounting_hole_diameter = 4.2; // M4 bolt clearance holes
self_tap_hole_diameter = 2.5; // Self-tapping screw pilot holes
mounting_distance = 20;     // Distance between mounting holes
gate_timber_depth = 25;     // Depth of gate timber
bracket_offset = 15;        // Offset for right-angle mounting

// Reinforcement design notes:
// - Complete filled triangular truss from pivot point to extension tip and base
// - Enlarged pivot connection from 8mm to 12mm diameter for better strength
// - Solid triangular support eliminates all cantilever effects and provides maximum strength
// - Connection hole extends through entire triangular structure for full bolt engagement

// Quality settings - optimized for ASA printing
$fn = 32; // Good balance of smoothness vs print time for ASA

module gate_latch_lever() {
    difference() {
        union() {            // Main lever arm - extended to accommodate separated holes
            hull() {
                translate([-35, 0, 0])  // Extended 35mm to the left for twice the distance
                    cube([lever_length - handle_diameter/2 + 35, lever_thickness, lever_width]);
                
                // Smooth transition to handle
                translate([lever_length - handle_diameter/2, lever_thickness/2, lever_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=lever_width, h=lever_thickness, center=true);
            }
            
            // Handle end (ergonomic grip for outdoor use) - oriented for vertical operation
            translate([lever_length - handle_diameter/2, lever_thickness/2, lever_width/2])
                rotate([90, 0, 0])  // Original orientation
                    cylinder(d=handle_diameter, h=handle_thickness, center=true);  // 5mm height            // 25mm cylindrical extension at connection end for latch connector (one-sided)
            translate([-35, lever_thickness, lever_width/2])
                rotate([90, 0, 0])
                    cylinder(d=8, h=25);  // 25mm long cylinder, 8mm diameter, extending from lever surface            // Large triangular support from pivot point to extension connection point
            hull() {
                // Connection at pivot point (enlarged for strength) - with flat surface on bracket side
                translate([15, lever_thickness/2, lever_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=12, h=lever_thickness, center=true);  // Enlarged from 8mm to 12mm
                
                // Flat surface at pivot point for bolt head (same diameter as reinforcement)
                translate([15, -2, lever_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=12, h=4);  // Same 12mm diameter as pivot reinforcement
                
                // Connection at extension tip (where the connection hole is)
                translate([-35, -12.5, lever_width/2])  // -12.5 is middle of the 25mm extension
                    rotate([90, 0, 0])
                        cylinder(d=8, h=lever_thickness, center=true);
                
                // Connection at extension base (where it meets the lever)
                translate([-35, lever_thickness/2, lever_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=8, h=lever_thickness, center=true);
                  // Bottom support points for complete filled triangular truss (lowered at pivot point)
                translate([15, lever_thickness/2, 1.5])
                    cube([0.1, lever_thickness, 0.1], center=true);
                translate([-35, -12.5, 0])
                    cube([0.1, lever_thickness, 0.1], center=true);
                translate([-35, lever_thickness/2, 0])
                    cube([0.1, lever_thickness, 0.1], center=true);
                translate([15, -2, 1.5])  // Include flat surface in triangular structure (lowered)
                    cube([0.1, 4, 0.1], center=true);
            }// Symmetrical ramped joins on both sides for strength
            hull() {
                translate([-35, lever_thickness-0.1, 0])
                    cube([8, 0.1, lever_width]);  // Base connection to full lever width
                translate([-35, lever_thickness - 5, lever_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=8, h=0.1);  // Cylinder connection point
            }
            
            // Reinforcement at pivot point (enlarged for better strength)
            translate([15, lever_thickness/2, lever_width/2])
                rotate([90, 0, 0])
                    cylinder(d=12, h=lever_thickness, center=true);  // Increased from 8mm to 12mm
        }        // Pivot hole (M4 bolt clearance) - goes through flat mounting surface on bracket side
        translate([15, lever_thickness + 0.5, lever_width/2])
            rotate([90, 0, 0])
                cylinder(d=pivot_hole_diameter, h=lever_thickness + 9);  // Goes through flat surface + triangular support
        
        // Flat-bottomed countersink for bolt head (on bracket side where bolt enters)
        translate([15, -5.5, lever_width/2])
            rotate([90, 0, 0]) {
                cylinder(d=10, h=2.5);  // Flat-bottomed countersink for M4 bolt head
            }// Connection hole through center of 25mm cylindrical extension and triangular support (M4 bolt)
        translate([-35, lever_thickness + 0.5, lever_width/2])
            rotate([90, 0, 0])
                cylinder(d=mounting_hole_diameter, h=40);  // Extended to go through entire triangular support structure
    }
}

// L-shaped mounting bracket with 90-degree rotation and proper extension
module mounting_bracket() {
    bracket_length = 20;     // Length along gate surface (made skinnier)
    bracket_width = gate_timber_depth + 5; // Width to accommodate gate depth
    bracket_thickness = 4;   // Thickness optimized for ASA printing
    extension_length = 15;   // Extension away from gate surface (made skinnier)
    pivot_arm_width = 6;     // Width of final pivot arm (made skinnier)
    protrusion_width = 8;    // Width of protruding parts (narrower than main bracket)
    
    difference() {
        union() {
            // Main mounting plate (lies flat against gate back surface) - FULL WIDTH for screw mounting
            cube([bracket_length, bracket_thickness, bracket_width]);
            
            // Extension arm (extends perpendicular away from gate) - NARROWER WIDTH, centered
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width - protrusion_width)/2])
                cube([extension_length, 10, protrusion_width]);
            
            // Final pivot arm (perpendicular to extension for proper lever orientation) - NARROWER WIDTH, centered
            translate([bracket_length/2 - bracket_length/2, bracket_thickness + 10, (bracket_width - protrusion_width)/2])
                cube([bracket_length, 6, protrusion_width]);
            
            // Rounded fillet supports for maximum strength (critical for ASA printing)
            // Left side fillet support
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width - protrusion_width)/2 - 3])
                hull() {
                    cube([extension_length, 0.1, 3]); // Base connection
                    translate([0, 6, 3])
                        cube([extension_length, 0.1, 2]); // Top connection
                }
            
            // Right side fillet support
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width + protrusion_width)/2])
                hull() {
                    cube([extension_length, 0.1, 3]); // Base connection
                    translate([0, 6, -3])
                        cube([extension_length, 0.1, 2]); // Top connection
                }
            
            // Additional corner reinforcement at base junction
            translate([bracket_length/2 - extension_length/2, bracket_thickness, (bracket_width - protrusion_width)/2])
                hull() {
                    cube([2, 0.1, protrusion_width]); // Protrusion connection
                    translate([-2, -bracket_thickness, -2])
                        cube([2, bracket_thickness, protrusion_width + 4]); // Base connection
                }
            
            translate([bracket_length/2 + extension_length/2 - 2, bracket_thickness, (bracket_width - protrusion_width)/2])
                hull() {
                    cube([2, 0.1, protrusion_width]); // Protrusion connection
                    translate([2, -bracket_thickness, -2])
                        cube([2, bracket_thickness, protrusion_width + 4]); // Base connection
                }
        }
        
        // Pivot hole (oriented for proper lever operation) - EXTENDS ALL THE WAY THROUGH - centered on narrower protrusion
        translate([bracket_length/2, bracket_thickness + 13, bracket_width/2])
            rotate([0, 90, 0])
                cylinder(d=pivot_hole_diameter, h=bracket_length + 2, center=true); // Extended through entire bracket width
        
        // 4 conical countersunk holes for self-tapping screws on mounting plate
        // Calculate hole positions for even distribution on mounting plate
        hole_offset_x = 4;  // Distance from edges horizontally
        hole_offset_z = 6;  // Distance from edges vertically
        countersink_diameter = 5.5;  // Diameter of countersink (realistic for screw heads)
        countersink_depth = 1.5;     // Depth of countersink (reasonable for 4mm thick plate)
        
        // Top-left hole
        translate([hole_offset_x, bracket_thickness + 0.1, bracket_width - hole_offset_z])
            rotate([90, 0, 0]) {
                // Through hole for self-tapping screw
                cylinder(d=self_tap_hole_diameter, h=bracket_thickness + 0.2);
                // Conical countersink from back face (where screw heads sit)
                cylinder(d1=self_tap_hole_diameter, d2=countersink_diameter, h=countersink_depth);
            }
        
        // Top-right hole
        translate([bracket_length - hole_offset_x, bracket_thickness + 0.1, bracket_width - hole_offset_z])
            rotate([90, 0, 0]) {
                // Through hole for self-tapping screw
                cylinder(d=self_tap_hole_diameter, h=bracket_thickness + 0.2);
                // Conical countersink from back face (where screw heads sit)
                cylinder(d1=self_tap_hole_diameter, d2=countersink_diameter, h=countersink_depth);
            }
        
        // Bottom-left hole
        translate([hole_offset_x, bracket_thickness + 0.1, hole_offset_z])
            rotate([90, 0, 0]) {
                // Through hole for self-tapping screw
                cylinder(d=self_tap_hole_diameter, h=bracket_thickness + 0.2);
                // Conical countersink from back face (where screw heads sit)
                cylinder(d1=self_tap_hole_diameter, d2=countersink_diameter, h=countersink_depth);
            }
        
        // Bottom-right hole
        translate([bracket_length - hole_offset_x, bracket_thickness + 0.1, hole_offset_z])
            rotate([90, 0, 0]) {
                // Through hole for self-tapping screw
                cylinder(d=self_tap_hole_diameter, h=bracket_thickness + 0.2);
                // Conical countersink from back face (where screw heads sit)
                cylinder(d1=self_tap_hole_diameter, d2=countersink_diameter, h=countersink_depth);
            }
    }
}

// Latch connector (connects to the actual latch mechanism)
module latch_connector() {
    connector_length = 35;
    connector_width = lever_width; // Match lever width for consistency
    connector_thickness = 3;       // Thinner for flexibility in ASA
    
    difference() {
        union() {
            // Main connector rod with rounded ends for strength
            hull() {
                translate([2, connector_thickness/2, connector_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=connector_width, h=connector_thickness, center=true);
                translate([connector_length - 2, connector_thickness/2, connector_width/2])
                    rotate([90, 0, 0])
                        cylinder(d=connector_width, h=connector_thickness, center=true);
            }
            
            // Connection point to lever (reinforced)
            translate([0, connector_thickness/2, connector_width/2])
                rotate([90, 0, 0])
                    cylinder(d=connector_width + 2, h=connector_thickness, center=true);
            
            // Connection point to latch (reinforced)
            translate([connector_length, connector_thickness/2, connector_width/2])
                rotate([90, 0, 0])
                    cylinder(d=connector_width + 2, h=connector_thickness, center=true);
        }
        
        // Hole for connecting to lever (M4 bolt)
        translate([0, connector_thickness + 0.5, connector_width/2])
            rotate([90, 0, 0])
                cylinder(d=mounting_hole_diameter, h=connector_thickness + 1);
        
        // Hole for connecting to latch mechanism (M4 bolt)
        translate([connector_length, connector_thickness + 0.5, connector_width/2])
            rotate([90, 0, 0])
                cylinder(d=mounting_hole_diameter, h=connector_thickness + 1);
    }
}

// Assembly view - shows all parts in properly assembled positions
module assembly() {
    // Visual representation of gate timber (for reference)
    translate([-5, -5, -2])
        color("brown", 0.3)
            cube([4, 35, gate_timber_depth + 4]);
    
    // Mounting bracket (mounted flush against gate back surface)
    color("lightblue")
        mounting_bracket();
      // Main lever (pivot hole at position 15mm connects to bracket pivot)
    translate([10 - 15, 16, 12.5]) // Position so lever's pivot hole (at 15mm) aligns with bracket pivot
        rotate([90, 0, 0]) // Orient lever horizontally for proper operation
            rotate([0, 0, -10]) // Show slight activation angle
                gate_latch_lever();
    
    // Latch connector (attaches to lever's connection hole at 75mm from lever start)
    translate([10 - 15 + 75, 13, 12.5]) // Position at lever's connection hole (lever_length - 5 = 75mm)
        rotate([90, 0, 0]) // Match lever orientation
            rotate([0, 0, -10]) // Match lever angle
                color("orange")
                    latch_connector();
    
    // M4 bolt at pivot (goes through bracket pivot and lever's pivot hole)
    translate([10, 22, 12.5])
        rotate([0, 90, 0])
            color("silver")
                cylinder(d=4, h=25, center=true);
      // M4 bolt at lever-connector joint (at lever's connection hole)
    translate([70, 13, 12.5])
        rotate([0, 90, 0])
            color("silver")
                cylinder(d=4, h=8, center=true);
    
    // Self-tapping screws in mounting bracket
    screw_positions = [
        [4, 0, 6],     // Bottom-left
        [16, 0, 6],    // Bottom-right  
        [4, 0, 19],    // Top-left
        [16, 0, 19]    // Top-right
    ];
    
    for (pos = screw_positions) {
        translate(pos)
            rotate([90, 0, 0])
                color("darkgray") {
                    // Screw shaft
                    cylinder(d=2.5, h=12, center=true);
                    // Screw head
                    translate([0, 0, 3])
                        cylinder(d=5, h=2);
                }
    }
    
    // Arrow showing lever movement direction
    translate([75, 20, 15])
        color("red")
            rotate([0, 0, 90])
                linear_extrude(1)
                    polygon([[0,0], [5,2], [3,2], [3,8], [-3,8], [-3,2], [-5,2]]);
    
    // Labels for clarity
    translate([-15, 8, 30])
        color("black")
            text("Gate Back", size=3);
    
    translate([55, 25, 20])
        color("black")
            text("Handle", size=3);
    
    translate([47, 5, 8])
        color("black")
            text("To Latch", size=2);
    
    translate([8, 35, 15])
        color("black")
            text("Pivot", size=2);
}

// Individual parts optimized for ASA printing
module print_layout() {
    // Lever (print flat side down with protrusion facing upwards)
    translate([0, 0, lever_width])  // Move up to align with other pieces on bed
        rotate([90, 180, 0])  // Rotate 90° around X to make flat, then 180° around Y to flip right-side up
            gate_latch_lever();
    
    // Mounting bracket (print big side down for stability)
    translate([0, -40, 0])
        rotate([90, 0, 0])  // Rotate so mounting plate is flat on bed
            mounting_bracket();
    
    // Latch connector (print flat side down)
    translate([60, 0, 0])
        rotate([90, 0, 0])  // Rotate so flat side is down
            latch_connector();
}

// ASA Printing Notes Module (for documentation)
module asa_printing_notes() {
    // This module serves as documentation
    echo("=== ASA PRINTING RECOMMENDATIONS ===");
    echo("Bed Temperature: 90-100°C");
    echo("Nozzle Temperature: 250-260°C");
    echo("Print Speed: 40-60mm/s");
    echo("Layer Height: 0.2-0.25mm for strength");    echo("Infill: 50-60% for triangular support strength");
    echo("Support: Print bracket flat on bed - NO supports needed");
    echo("Orientation: Mounting plate flat on bed, protrusion pointing up");
    echo("Perimeters: 4+ walls for maximum strength at stress points");
    echo("Post-processing: Light sanding of pivot holes for smooth operation");
    echo("Hardware needed: M4 x 25mm bolt for pivot, self-tapping screws for mounting");
    echo("CRITICAL: Ensure excellent first layer adhesion - bracket failure typically starts there");    echo("REINFORCEMENT NOTES:");
    echo("- Complete filled triangular truss connects pivot, extension tip, and extension base");
    echo("- Enlarged pivot connection (12mm) provides better stress distribution");
    echo("- Solid triangular fill eliminates all bending - creates incredibly strong structure");
    echo("- Extended bolt hole (40mm) goes through entire triangular support for maximum engagement");
    echo("- Print orientation ensures layer lines follow stress direction");
}

// Stress analysis recommendations
module stress_analysis_notes() {
    echo("=== STRESS POINTS TO MONITOR ===");
    echo("1. Junction between mounting plate and extension arm - ADD FILLETS");
    echo("2. Pivot hole area - avoid sharp internal corners");
    echo("3. Mounting screw holes - use washers to distribute load");
    echo("4. Handle attachment point on lever - reinforce with extra perimeters");
    echo("5. Print with layers parallel to primary stress direction");
}

// Choose what to render:
// For assembly view: uncomment the line below
// assembly();

// For printing layout: uncomment the line below
print_layout();

// For individual parts: uncomment one of the lines below
// gate_latch_lever();
// mounting_bracket();
// latch_connector();
