// === DESCRIPTION ===
// MakerX Perforated Helmholtz Absorber Tile (variant 3 of 3)
//   A 250x250 mm wall tile that genuinely ABSORBS sound (the other two variants
//   only diffuse). It is a perforated-panel (Helmholtz) absorber: a thin front
//   sheet pierced by a grid of small holes, held a fixed air-gap off the wall by
//   a standoff frame. Each hole + the air behind it is a Helmholtz resonator; at
//   resonance the air in the necks oscillates hard and viscous friction in the
//   holes turns acoustic energy into heat.
//   HONEST BANDWIDTH: a bare perforated panel is a RESONANT (fairly narrow)
//   absorber — here a peak around ~4 kHz (the bottom of the user's target band),
//   not a flat 4-10 kHz response. Laying 6-10 mm of acoustic foam/felt in the
//   cavity is what broadens and deepens it, realistically to roughly 3-8 kHz.
//   It will not absorb strongly all the way to 10 kHz; pair it with the
//   diffuser tiles (which DO scatter up past 10 kHz) for full-band treatment.
//
// Physical context:
//   Mounts to a wall with the standoff frame against the wall, so the WALL
//   forms the back of the air cavity (8 mm gap). A "+" of internal ribs splits
//   the cavity into 4 quadrants (stiffens the thin panel + improves off-axis
//   absorption). Optional: lay 6-10 mm acoustic foam / felt in the quadrants
//   before mounting. Indoor, self-weight only.
//
// Design decisions:
//   - Helmholtz tuning f0 = (c/2pi)*sqrt(p / ((t + 0.8 d) * D)): thin panel
//     (1.6 mm), 4 mm holes at ~19% open area, 8 mm gap -> f0 ~3.9 kHz, the
//     bottom of the target band; foam smears it upward across 4-8 kHz.
//   - Prints FRONT-FACE-DOWN: the perforated front is on the bed (smooth
//     finish, vertical holes), the standoff frame + ribs rise up, the cavity
//     is OPEN at the back (faces the wall). Fully support-free, no bridging —
//     the thin front sheet is laid straight onto the plate.
//     (NOTE: this is the opposite print orientation to the two diffusers,
//      whose solid backs sit on the bed.)
//   - Branding is colour-only on the flat front: blue->magenta->gold gradient
//     across the perforated field, with the X logomark and frame left SOLID
//     (un-perforated) so the logo reads crisply. 4 AMS colour bodies.
//
// Terminology -> code:
//   "the holes / necks"   -> holes_2d(), hole_d, hole_pitch, perforations()
//   "front panel"         -> front_thick
//   "air gap / standoff"  -> gap
//   "the ribs"            -> cross_ribs_2d(), rib_t
//   "the X / logo"        -> mx_x_placed_2d() (solid, un-perforated)
//   "gradient zones"      -> mx_color_region_2d()
//   "the frame / rim"     -> frame_w, mx_frame_2d()
//
// Common modifications:
//   Tune lower            -> bigger gap, fewer/smaller holes (lower p)
//   Tune higher           -> smaller gap, more/bigger holes (higher p)
//   Broadband absorption  -> add foam in the cavity quadrants (biggest effect)
//   Bigger/smaller logo   -> mx_logo_w (brand)
//
// Overall dimensions: 250 x 250 x ~9.6 mm printed (sits 9.6 mm off the wall)
// Coordinate system: X,Y = tile face; Z = height from build plate.
//   Z=0 is the FRONT/ROOM face (on the bed); +Z goes back toward the WALL.
//   Model is in print orientation — preview matches the print.

// === PRINT SETTINGS ===
// Material: PETG. Layer Height: 0.2 mm. Perimeters: 3-4 (thin panel prints solid).
// Infill: n/a (panel + walls are solid/thin). Supports: None (front-down, all vertical).
// Orientation: FRONT FACE DOWN on the plate (cavity opens upward).
// Notes: Use an OUTER-perimeter brim only (5-8 mm) + Elephant-Foot Compensation
//   (~0.15 mm) for the 250 mm sheet — do NOT use an inner/expanded brim, it
//   would block the first rows of neck holes. Dry PETG; 30-40% fan. Optional
//   6-10 mm acoustic foam/felt in the 4 cavity quadrants (biggest absorption
//   gain). Mount the standoff-frame back edge to the wall with adhesive /
//   mounting strips. Import the 4 part STLs as one object for AMS colours.

include <makerx_brand.scad>

// === PARAMETERS ===
front_thick = 1.6;                          // perforated front panel thickness
gap         = 8.0;                          // standoff / air-gap depth (cavity)
hole_d      = 4.0;                          // Helmholtz neck diameter
hole_pitch  = 8.0;                          // hole grid pitch -> ~19.6% open area
rib_t       = 4*ew;                         // internal cross-rib = 4 perimeters (1.8mm)
part        = "all";                         // "all"|"black"|"blue"|"magenta"|"gold"

// === DERIVED CONSTANTS ===
total_h    = front_thick + gap;             // printed depth
holes_n    = floor((interior - hole_d) / hole_pitch);       // hole index 0..holes_n per axis
hole_off   = frame_w + (interior - holes_n*hole_pitch) / 2; // centres the grid in the interior
// solid, hole-free logo panel that hosts the X (sized from the logo + margin).
// Whole holes whose CENTRE lands inside it are skipped (no clipped/sliver holes).
panel_hw_x = mx_logo_w*0.4923 + 8;          // half-width  (X spans ~0.985*logo wide)
panel_hw_y = mx_logo_w*0.4037 + 8;          // half-height (X spans ~0.807*logo tall)
perf_p     = (PI*hole_d*hole_d/4) / (hole_pitch*hole_pitch); // intrinsic open-area ratio of the grid
t_eff      = front_thick + 0.8*hole_d;                       // effective neck length
f0         = (c_air/(2*PI)) * sqrt(perf_p / (t_eff * gap));   // Helmholtz resonance (panel only)

// === ACCEPTANCE CONTRACTS ===
assert(tile <= 256, "Tile exceeds 256mm Bambu bed");
assert(hole_d >= 2.0, "Neck too small to print cleanly on 0.4mm nozzle");
assert(hole_d < hole_pitch - 2*ew, "Holes overlap / no web left between them");
assert(front_thick >= 3*layer_height, "Front panel too thin");
assert(perf_p > 0.03 && perf_p < 0.30, "Perforation ratio outside useful range");
assert(rib_t >= 4*ew, "Rib thinner than 4 perimeters");
echo(VARIANT="ABSORBER", holes_per_axis=holes_n+1, perf_ratio=perf_p,
     f0_panel_only=f0, gap=gap, overall_depth=total_h);

// === MODULES ===
// 2-D grid of neck holes, centred in the interior. WHOLE holes whose centre
// falls inside the solid logo panel are skipped -> no clipped/sliver holes.
module holes_2d() {
    for (ix = [0:holes_n]) for (iy = [0:holes_n]) {
        cx = hole_off + ix*hole_pitch;
        cy = hole_off + iy*hole_pitch;
        if (!(cx > tile/2 - panel_hw_x && cx < tile/2 + panel_hw_x &&
              cy > tile/2 - panel_hw_y && cy < tile/2 + panel_hw_y))
            translate([cx, cy]) circle(d = hole_d);
    }
}

// Necks through the front panel, clipped to the interior (frame stays solid;
// the logo panel is already hole-free via the skip test in holes_2d()).
module perforations() {
    intersection() {
        translate([0, 0, -fudge]) linear_extrude(front_thick + 2*fudge) holes_2d();
        translate([0, 0, -fudge]) linear_extrude(front_thick + 2*fudge) mx_interior_2d();
    }
}

// "+" of ribs that splits the cavity into 4 quadrants
module cross_ribs_2d() {
    translate([tile/2 - rib_t/2, frame_w]) square([rib_t, interior]);
    translate([frame_w, tile/2 - rib_t/2]) square([interior, rib_t]);
}

module full_absorber() {
    difference() {
        union() {
            cube([tile, tile, front_thick]);                                   // front panel
            translate([0,0,front_thick-fudge]) linear_extrude(gap) mx_frame_2d();    // standoff frame
            translate([0,0,front_thick-fudge]) linear_extrude(gap) cross_ribs_2d();  // cavity ribs
        }
        perforations();
    }
}

module body(name) {
    intersection() {
        full_absorber();
        translate([0, 0, -fudge])
            linear_extrude(total_h + 2*fudge) mx_color_region_2d(name);
    }
}

module assembly() {
    color(MX_BLACK)   body("black");
    color(MX_BLUE)    body("blue");
    color(MX_MAGENTA) body("magenta");
    color(MX_GOLD)    body("gold");
}

// === RENDER ===
if (part == "all") assembly();
else body(part);
