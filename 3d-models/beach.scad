// 3D Beach Landscape Model
// Designed for 3D printing on Bambu X1 Carbon
// Created: June 8, 2025

// Model parameters
base_width = 120;      // Width of the base (mm)
base_depth = 80;       // Depth of the base (mm)
base_height = 3;       // Height of the base platform (mm)
water_level = 8;       // Height of water surface above base (mm)
max_dune_height = 25;  // Maximum height of sand dunes (mm)

// Water parameters
wave_amplitude = 1.5;  // Height of waves (mm)
wave_frequency = 0.3;  // Wave frequency

// Beach slope parameters
beach_slope_start = 20; // Distance from water edge where beach starts sloping up
beach_slope_end = 60;   // Distance where beach levels out

// Palm tree parameters
palm_count = 3;
palm_trunk_height = 20;
palm_trunk_radius = 1.5;

// Rock parameters
rock_count = 5;

// Main model
difference() {
    union() {
        // Base platform
        base_platform();
        
        // Water surface with waves
        water_surface();
        
        // Beach terrain
        beach_terrain();
        
        // Sand dunes
        sand_dunes();
        
        // Palm trees
        palm_trees();
        
        // Rocks and debris
        beach_rocks();
        
        // Seashells
        seashells();
    }
    
    // Optional: cut a viewing window (comment out if not needed)
    // viewing_window();
}

// Base platform module
module base_platform() {
    color([0.9, 0.85, 0.7]) // Sandy color
    cube([base_width, base_depth, base_height]);
}

// Water surface with subtle waves
module water_surface() {
    color([0.2, 0.6, 0.8, 0.7]) // Blue water with transparency
    translate([0, 0, base_height]) {
        for(x = [0:2:base_width]) {
            for(y = [0:2:base_depth/3]) {
                wave_height = water_level + sin(x * wave_frequency) * wave_amplitude + cos(y * wave_frequency * 1.5) * wave_amplitude * 0.5;
                translate([x, y, 0])
                cube([2, 2, wave_height]);
            }
        }
    }
}

// Beach terrain with gradual slope
module beach_terrain() {
    color([1, 0.95, 0.8]) // Light sand color
    translate([0, base_depth/3, base_height]) {
        for(x = [0:2:base_width]) {
            for(y = [0:2:base_depth*2/3]) {
                // Calculate height based on distance from water
                distance_from_water = y;
                terrain_height = (distance_from_water < beach_slope_start) ? 0 :
                                (distance_from_water < beach_slope_end) ? 
                                    ((distance_from_water - beach_slope_start) / (beach_slope_end - beach_slope_start)) * max_dune_height * 0.6 :
                                    max_dune_height * 0.4;
                
                // Add some random variation
                noise = sin(x * 0.1) * cos(y * 0.15) * 2;
                final_height = terrain_height + noise;
                
                if(final_height > 0) {
                    translate([x, y, 0])
                    cube([2, 2, final_height]);
                }
            }
        }
    }
}

// Sand dunes
module sand_dunes() {
    color([0.95, 0.9, 0.75]) // Slightly darker sand
    
    // Main dune
    translate([base_width * 0.3, base_depth * 0.8, base_height]) {
        scale([1, 0.8, 0.6])
        rotate([0, 0, 15])
        ellipsoid(15, 8, max_dune_height);
    }
    
    // Secondary dune
    translate([base_width * 0.7, base_depth * 0.9, base_height]) {
        scale([0.8, 0.6, 0.5])
        rotate([0, 0, -20])
        ellipsoid(12, 6, max_dune_height * 0.8);
    }
    
    // Small dune
    translate([base_width * 0.1, base_depth * 0.7, base_height]) {
        scale([0.6, 0.5, 0.4])
        ellipsoid(8, 5, max_dune_height * 0.6);
    }
}

// Ellipsoid module for dunes
module ellipsoid(rx, ry, rz) {
    scale([rx, ry, rz])
    sphere(r=1, $fn=20);
}

// Palm trees
module palm_trees() {
    // Tree 1
    translate([base_width * 0.2, base_depth * 0.85, base_height + max_dune_height * 0.4])
    palm_tree();
    
    // Tree 2
    translate([base_width * 0.6, base_depth * 0.95, base_height + max_dune_height * 0.6])
    rotate([0, 0, 30])
    palm_tree();
    
    // Tree 3
    translate([base_width * 0.8, base_depth * 0.75, base_height + max_dune_height * 0.3])
    rotate([0, 0, -45])
    palm_tree();
}

// Individual palm tree
module palm_tree() {
    // Trunk
    color([0.6, 0.4, 0.2]) // Brown trunk
    translate([0, 0, palm_trunk_height/2]) {
        cylinder(h=palm_trunk_height, r1=palm_trunk_radius, r2=palm_trunk_radius*0.7, center=true, $fn=8);
        
        // Trunk texture rings
        for(i = [0:3:palm_trunk_height]) {
            translate([0, 0, -palm_trunk_height/2 + i])
            scale([1.1, 1.1, 0.3])
            cylinder(h=1, r=palm_trunk_radius, $fn=8);
        }
    }
    
    // Palm fronds
    color([0.2, 0.6, 0.3]) // Green fronds
    translate([0, 0, palm_trunk_height]) {
        for(angle = [0:60:300]) {
            rotate([0, 0, angle])
            rotate([20, 0, 0])
            palm_frond();
        }
    }
}

// Palm frond
module palm_frond() {
    frond_length = 15;
    frond_width = 3;
    
    hull() {
        sphere(r=0.5, $fn=6);
        translate([frond_length, 0, 0])
        sphere(r=0.2, $fn=6);
    }
    
    // Frond segments
    for(i = [1:3:frond_length]) {
        translate([i, 0, 0])
        rotate([0, 0, sin(i*20)*10])
        scale([1, 0.3, 0.1])
        sphere(r=frond_width/(1 + i*0.1), $fn=6);
    }
}

// Beach rocks
module beach_rocks() {
    color([0.4, 0.4, 0.4]) // Gray rocks
    
    // Scattered rocks
    for(i = [0:rock_count-1]) {
        x_pos = (base_width * 0.1) + (rnd(i*17) * base_width * 0.8);
        y_pos = (base_depth * 0.3) + (rnd(i*23) * base_depth * 0.4);
        z_pos = base_height + 2;
        
        size = 1 + rnd(i*31) * 3;
        
        translate([x_pos, y_pos, z_pos])
        rotate([rnd(i*41)*90, rnd(i*47)*90, rnd(i*53)*90])
        scale([1, 0.7 + rnd(i*59)*0.6, 0.5 + rnd(i*61)*0.5])
        sphere(r=size, $fn=8);
    }
}

// Seashells scattered on beach
module seashells() {
    color([1, 0.9, 0.8]) // Shell color
    
    for(i = [0:6]) {
        x_pos = rnd(i*71) * base_width;
        y_pos = (base_depth * 0.25) + (rnd(i*73) * base_depth * 0.3);
        z_pos = base_height + 1;
        
        translate([x_pos, y_pos, z_pos])
        rotate([0, 0, rnd(i*79)*360])
        seashell();
    }
}

// Individual seashell
module seashell() {
    scale([1, 0.8, 0.3])
    sphere(r=1.5, $fn=12);
    
    // Shell ridges
    for(angle = [0:30:150]) {
        rotate([0, 0, angle])
        translate([0, 0, 0.2])
        scale([0.1, 0.8, 0.1])
        cylinder(h=2, r=1, center=true, $fn=4);
    }
}

// Optional viewing window for cross-section view
module viewing_window() {
    translate([base_width/2, -5, base_height + 5])
    cube([base_width * 0.8, 20, 40], center=true);
}

// Pseudo-random function (deterministic based on seed)
function rnd(seed) = abs(sin(seed * 12.9898 + 78.233) * 43758.5453) - floor(abs(sin(seed * 12.9898 + 78.233) * 43758.5453));

// Print information
echo("Beach Landscape Model Generated");
echo(str("Base dimensions: ", base_width, "mm x ", base_depth, "mm x ", base_height, "mm"));
echo(str("Total height: ~", max_dune_height + palm_trunk_height, "mm"));
echo("Recommended print settings for Bambu X1 Carbon:");
echo("- Layer height: 0.2mm");
echo("- Infill: 15-20%");
echo("- Supports: Auto-generated for palm fronds");
echo("- Print speed: Standard quality profile");

