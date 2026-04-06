# Printing Workflow: OpenSCAD to Physical Print

Guide users from finished .scad model to successful 3D print.

## 1. Export from OpenSCAD

### Standard Export (GUI)

1. **F6** — Full CGAL render (required before export; may take minutes for complex models)
2. Wait for "Rendering finished" in status bar
3. **F7** — Export as STL (or File > Export > Export as STL)

**Format choice:**
- **STL** — Universal compatibility, works with all slicers
- **3MF** — Modern alternative (OpenSCAD 2019.05+), smaller files, recommended for PrusaSlicer/OrcaSlicer/Bambu Studio

### Export Resolution

The skill's standard `$fn = $preview ? 32 : 64` handles most cases. For models with many small curves:

```openscad
// Alternative: dynamic resolution for export
$fa = $preview ? 12 : 2;   // angle per segment
$fs = $preview ? 2 : 0.5;  // minimum segment length (mm)
```

**Rule of thumb:** `$fa=2, $fs=0.5` gives excellent print quality without excessive file size.

### Command-Line Export (Batch/Automation)

```bash
# Basic export
openscad -o output.stl input.scad

# Override parameters
openscad -D "width=100" -D "height=50" -o box.stl box.scad

# Batch: export multiple sizes (bash)
for size in 10 20 30 40 50; do
    openscad -D "size=$size" -o "part_${size}.stl" parametric_part.scad
done
```

**Windows batch:**
```batch
FOR %%s IN (10,20,30,40,50) DO (
    openscad -D "size=%%s" -o part_%%s.stl parametric_part.scad
)
```

### Common Export Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Non-manifold geometry | Coincident faces in boolean ops | Use `fudge = 0.01` overlap (skill already enforces this) |
| Model disappears after difference() | Zero-thickness result | Ensure cutting shapes don't exactly match outer geometry |
| "Polyhedron conversion failed" | Complex boolean chain | Break into simpler operations; wrap with `render()` |
| Angular small features | Global $fn too low for small radii | Set $fn locally on small cylinders/spheres |

## 2. STL Validation

**Check before slicing** — open STL in slicer and look for:
- Missing faces or holes in the mesh
- Inverted normals (inside-out surfaces)
- Non-manifold warnings from slicer

**OpenSCAD tip:** Use Thrown Together view (F12) to spot face orientation issues before export.

### Repair Tools (if needed)

| Tool | Platform | Best For |
|------|----------|----------|
| **PrusaSlicer** (Right-click > Fix through Netfabb) | All | Quick in-workflow fix |
| **Microsoft 3D Builder** | Windows | One-click auto-repair, beginner-friendly |
| **Meshmixer** | Win/Mac | Best all-around: auto + manual repair |
| **MeshLab** | All | Advanced users, scripting, Linux |

**Note:** Well-designed OpenSCAD models (using fudge overlap, no coincident faces) rarely need repair.

## 3. Slicer Import

All major slicers accept STL via drag-and-drop or Ctrl+I/Cmd+I:
- **PrusaSlicer / OrcaSlicer / Bambu Studio** — STL, 3MF, OBJ, STEP
- **Cura** — STL, 3MF, OBJ (STEP via plugin)

### Slicer Recommendations

| User | Recommended Slicer |
|------|--------------------|
| Beginners / any printer | **Cura** — 1500+ printer profiles, easiest UI |
| Prusa owners / power users | **PrusaSlicer** — three-tier UI (Simple/Advanced/Expert) |
| Bambu Lab owners | **Bambu Studio** or **OrcaSlicer** |
| Calibration-focused users | **OrcaSlicer** — best built-in calibration tools |

## 4. Translate Print Settings to Slicer

The PRINT SETTINGS header in every generated .scad file maps directly to slicer settings:

### Setting Mapping

| Print Settings Header | PrusaSlicer Location | Cura Location |
|-----------------------|---------------------|---------------|
| **Material** | Filament dropdown (top bar) | Material dropdown (top bar) |
| **Layer Height** | Print Settings > Layers and perimeters > Layer height | Quality > Layer Height |
| **Walls/Perimeters** | Print Settings > Layers and perimeters > Perimeters | Shell > Wall Line Count |
| **Infill** (density) | Print Settings > Infill > Fill density | Infill > Infill Density |
| **Infill** (pattern) | Print Settings > Infill > Fill pattern | Infill > Infill Pattern |
| **Supports** | Print Settings > Support material > Generate support | Support > Generate Support |
| **Orientation** | Rotate tool (R key) or right-click > Place on face | Rotate tool (R key) or right-click > Lay flat |

### Infill Pattern Quick Reference

| Pattern | Use Case |
|---------|----------|
| **Gyroid** | Default for structural parts (best strength-to-weight) |
| **Grid** | General purpose |
| **Triangular** | Maximum strength |
| **Lightning** | Maximum speed, decorative parts |

### Temperature (from material reference)

| Material | Nozzle (C) | Bed (C) |
|----------|-----------|---------|
| PLA | 190-220 | 50-60 |
| PETG | 230-250 | 70-85 |

**Always calibrate with a temperature tower for your specific filament brand/color.**

### Orientation in Slicer

The PRINT SETTINGS header specifies orientation. To apply in slicer:
- **PrusaSlicer/OrcaSlicer:** Right-click model > Place on face > click the specified face
- **Cura:** Right-click > Lay flat, then rotate if needed
- Verify: Primary load paths should be in XY plane (along layers, not across them)

## 5. Preview Validation Checklist

After slicing (PrusaSlicer: F5, then Preview tab; Cura: Preview button), check:

- [ ] **Walls** — Correct thickness, no gaps or missing perimeters
- [ ] **Infill** — Pattern connects to walls, density matches settings
- [ ] **Supports** — Present under overhangs >45 degrees, not excessive
- [ ] **Bridges** — Spans <20mm, anchored on both sides
- [ ] **First layer** — Full coverage, adequate bed contact area
- [ ] **Top surface** — Solid layers complete, no infill showing through
- [ ] **Travel moves** — Enable "Show travels" to check for stringing risk

**Layer-by-layer navigation:** Use Up/Down arrows (single layer), Page Up/Down (10 layers), Home/End (first/last).

### Red Flags

| What You See | Fix |
|--------------|-----|
| Single-line perimeters | Model too thin for nozzle; increase wall count or redesign |
| Gaps between infill and walls | Increase infill/perimeter overlap |
| Floating sections without support | Enable supports, lower overhang angle threshold |
| Infill pattern visible on top | Add more top solid layers |
| Massive support structures | Reorient model or switch to tree supports |

## 6. Pre-Print Checklist

### Printer Preparation
- [ ] Bed leveled at operating temperature (paper test or ABL routine)
- [ ] Z-offset calibrated (first layer not too squished or gapped)
- [ ] Build plate cleaned with IPA (isopropyl alcohol 70%+)
- [ ] Nozzle clean (no burnt filament buildup)

### Material
- [ ] Filament dried if needed (PETG: 65C for 4-6h; PLA: 45C for 4-6h, never >60C)
- [ ] Spool rotates freely, no tangles
- [ ] Enough filament for print + 20% buffer (check slicer estimate)

### Bed Adhesion

| Surface | PLA | PETG |
|---------|-----|------|
| **PEI (smooth/textured)** | Excellent, no adhesive needed | Use glue stick as RELEASE agent (PETG bonds too strongly) |
| **Glass** | Use glue stick or hairspray | Use glue stick |
| **Painter's tape** | Good | Not recommended |

### Slicer Verification
- [ ] Correct printer and filament profiles selected
- [ ] Print settings match the .scad PRINT SETTINGS header
- [ ] Preview checked (no red flags)
- [ ] Orientation matches the .scad recommendation

### First Layer Settings (for best adhesion)
- First layer speed: 15-20 mm/s
- First layer height: 0.24mm (60% of 0.4mm nozzle)
- Fan: OFF for first layer
- First layer temp: +5-10C above normal

## 7. Calibration (One-Time Per Filament)

Before printing critical parts with a new filament, run these calibrations:

### Temperature Tower
1. Print temperature tower model (available on Printables)
2. Configure temperature changes per section (OrcaSlicer has this built-in under Calibration menu)
3. Evaluate each section for: layer adhesion, surface finish, stringing, bridging
4. Save optimal temperature in a filament profile

### Flow Rate Calibration
1. Print single-wall cube (1 perimeter, 0% infill, 0 top layers)
2. Measure wall thickness with calipers at 6-10 points
3. Calculate: `New Flow = Current Flow x (Nozzle Diameter / Measured Thickness)`
4. Save per-filament (OrcaSlicer has built-in flow calibration under Calibration menu)

## Remind Users

After generating a model, include these steps:
1. Preview in OpenSCAD (F5), check Thrown Together view (F12)
2. Render (F6) and export STL (F7)
3. Import into slicer, apply the PRINT SETTINGS from the file header
4. Check slicer preview (walls, supports, first layer)
5. Run pre-print checklist
6. Print!
