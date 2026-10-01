# Mechanical Parts Patterns for OpenSCAD

Screws, inserts, nuts, threads and bosses are in [pattern-fasteners.md](pattern-fasteners.md).

## Gears

### Recommended Libraries
- **BOSL2** (preferred): `include <BOSL2/std.scad>` + `include <BOSL2/gears.scad>` — most complete
- **PolyGear**: Lightweight, involute profile gears
- **MCAD**: `include <MCAD/involute_gears.scad>` — basic but widely available

### Gear Parameters
```openscad
// Key parameters
teeth = 20;          // Number of teeth
mod = 1.5;           // Module (tooth size) — larger = bigger teeth
pressure_angle = 20; // Standard: 20 degrees
backlash = 0.2;      // Play between meshing gears (print tolerance)
```

### Spur Gear Without Libraries

A trapezoid approximation, fine for looks and light-duty hand-turned drives. It isn't an involute, so the contact ratio and backlash vary as it turns. For gears that must mesh under load or run continuously, use BOSL2 `spur_gear()`, or generate the involute and check undercut (about 17 teeth minimum at 20°, fewer with profile shift) and a contact ratio above 1.2.
```openscad
module spur_gear(teeth, mod, thickness, pressure_angle=20, backlash=0) {
    pitch_r = teeth * mod / 2;
    addendum = mod;
    dedendum = 1.25 * mod;
    outer_r = pitch_r + addendum;
    inner_r = pitch_r - dedendum;
    tooth_angle = 360 / teeth;

    linear_extrude(height=thickness)
        union() {
            circle(r=inner_r);
            for (i = [0:teeth-1])
                rotate([0, 0, i * tooth_angle])
                    polygon([
                        [inner_r * cos(-tooth_angle/4 + backlash/2),
                         inner_r * sin(-tooth_angle/4 + backlash/2)],
                        [outer_r * cos(-tooth_angle/8 + backlash/2),
                         outer_r * sin(-tooth_angle/8 + backlash/2)],
                        [outer_r * cos(tooth_angle/8 - backlash/2),
                         outer_r * sin(tooth_angle/8 - backlash/2)],
                        [inner_r * cos(tooth_angle/4 - backlash/2),
                         inner_r * sin(tooth_angle/4 - backlash/2)]
                    ]);
        }
}
```

### Meshing Two Gears
```openscad
teeth1 = 20;
teeth2 = 40;
mod = 1.5;
center_distance = (teeth1 + teeth2) * mod / 2;

spur_gear(teeth1, mod, 5);
translate([center_distance, 0, 0])
    rotate([0, 0, 180/teeth2])  // Offset by half a tooth
        spur_gear(teeth2, mod, 5);
```

## Snap Fits

### Cantilever Snap Fit
```openscad
module snap_hook(length, width, thickness, overhang) {
    // Beam
    cube([thickness, width, length]);
    // Hook
    translate([0, 0, length])
        hull() {
            cube([thickness, width, 0.01]);
            translate([overhang, 0, -overhang])
                cube([0.01, width, 0.01]);
        }
}

module snap_catch(width, depth, overhang) {
    translate([0, 0, 0])
        cube([overhang + tolerance, width + 2*tolerance, depth]);
}
```

### Snap Fit Design Rules
- Beam length: 5-10x thickness for flexibility
- Overhang: 0.5-1.5mm typical
- Add 45-degree entry ramp for easy insertion
- Wall behind catch must be thick enough to resist force

## Living Hinges

```openscad
module living_hinge(width, segments=5, gap=0.5, bridge=0.8) {
    segment_width = (width - (segments-1) * gap) / segments;
    for (i = [0:segments-1]) {
        translate([i * (segment_width + gap), 0, 0])
            cube([segment_width, bridge, wall_thickness]);
    }
}
```

- Print with PETG or TPU for flexibility
- PLA living hinges break after few cycles
- Minimum bridge width: 0.8mm

## Pin Joints / Hinges

```openscad
module hinge_knuckle(od, id, height) {
    difference() {
        cylinder(d=od, h=height);
        translate([0, 0, -fudge])
            cylinder(d=id + tolerance, h=height + 2*fudge);
    }
}

module hinge_pin(d, length) {
    cylinder(d=d - tolerance, h=length);
}
```

Interleave knuckles from two parts, insert pin through all.

## Dovetail Joints

```openscad
module dovetail_male(width, height, length, angle=15) {
    linear_extrude(height=length)
        polygon([
            [-width/2 + height*tan(angle), 0],
            [width/2 - height*tan(angle), 0],
            [width/2, height],
            [-width/2, height]
        ]);
}

module dovetail_female(width, height, length, angle=15) {
    translate([0, 0, -fudge])
        linear_extrude(height=length + 2*fudge)
            polygon([
                [-width/2 + height*tan(angle) - tolerance, -fudge],
                [width/2 - height*tan(angle) + tolerance, -fudge],
                [width/2 + tolerance, height + tolerance],
                [-width/2 - tolerance, height + tolerance]
            ]);
}
```

## Bearing Seats

```openscad
// Common bearing dimensions: 608 (skateboard bearing)
bearing_id = 8;    // Inner diameter
bearing_od = 22;   // Outer diameter
bearing_h = 7;     // Height

module bearing_seat(od, h, press_fit=true) {
    tol = press_fit ? -0.1 : tolerance;
    cylinder(d=od + tol, h=h);
}
```
