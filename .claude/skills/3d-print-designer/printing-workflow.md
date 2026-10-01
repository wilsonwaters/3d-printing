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
- **Bambu project 3MF (settings baked in)** — for Bambu Lab printers, generate a `.3mf` that opens in Bambu Studio with all print settings pre-applied, skipping the manual translation in step 4. See [bambu-3mf-export.md](bambu-3mf-export.md).

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

> **Bambu Lab users can skip this section.** Generate a settings-baked-in project 3MF ([bambu-3mf-export.md](bambu-3mf-export.md)) and Bambu Studio applies these settings automatically on open.

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

### Slicer tuning by material

Starting points for the slicer; your filament brand's profile wins where it differs. The material files hold only what changes the geometry. **Always calibrate with a temperature tower for your specific filament brand/color.**

**Temperature**

| | PLA | PETG | ABS |
|---|---|---|---|
| Nozzle | 200-210C general; 215-225 max Z-strength (more stringing); 190-200 best overhangs | 240-245 structural (best layer bond); 230-235 detail, overhangs and bridges | 235-245 (start at 240, adjust ±5); 245-250 max Z-strength |
| First layer | +5C | +5C | +5C |
| Bed | 50-60C | 70-85C | 100-110C (mandatory) |
| Enclosure | not needed | not needed | 40-60C ambient; the bed's heat is usually enough |

Layer bond against nozzle temperature: PETG 80-85% at 230C, 90-95% at 240C, 95-98% at 250C (with extreme stringing). ABS 40-60% at 230C without an enclosure, 55-70% at 240C without, 70-80% at 235C with one, 80-90% at 240-250C with an enclosure and no fan.

**Cooling**: PLA uses 100% fan, PETG 30-40%, ABS 0%.

| Feature | PLA | PETG | ABS |
|---|---|---|---|
| First layer(s) | 0% | 0%, then 0-20% for layers 2-4 | 0% for the first 3-4 layers |
| Standard layers | 100% (50-70% only to favour Z-strength over surface) | **30-40%**: more cooling weakens layer adhesion | **0%**: any fan causes warping and delamination |
| Overhangs >45° | 100% | 50-70% | 0-20%: accept droop over cracking |
| Bridges | 100% | 80-100%, 5-10C cooler, 20-30 mm/s | 30-50% burst during the bridge only |
| Small parts | 100% | 50-60% under 20mm | 10-20% under 15mm, temporarily |

**Speed (mm/s)**

| Feature | PLA | PETG | ABS |
|---|---|---|---|
| Walls | 40-70 general | 30-50 (outer 25-40) | outer 30-40, inner 40-50 |
| Infill | | 50-80 | 50-60 |
| First layer | 15-20 | 15-20 | 15-25, never over 30 |
| Bridges / overhangs | | 20-30 / 20-35 | 15-25 |
| Travel | | 150-200 (fast, to cut oozing) | |

- PLA: volumetric flow limit 10-12 mm³/s on a standard hotend; above 100 mm/s, Z-strength drops 10-20%. Layer height 0.16-0.20mm balances strength and time, 0.10mm gives the best XY strength and surface (slow), and above 0.28mm Z-strength suffers.
- PETG: strength against speed is 100% at 30 mm/s, 95% at 50, 88% at 70, 80% at 90.
- ABS: if layers delaminate, slow down in 5 mm/s steps; cracking sounds mid-print mean raise the enclosure and nozzle temperatures at once. For elephant's foot, set the slicer's compensation to -0.1 to -0.2mm and first-layer flow to 90-95%.

**Retraction (ABS)**: direct drive 1-2mm at 30-40 mm/s, Bowden 3-4mm at 40-50 mm/s; minimum travel 1.0-2.0mm; optional Z-hop 0.1-0.4mm. Use combing to cut retractions. ABS strings less than PETG at the right temperature.

**Drying**

| | Temperature | Time | Notes |
|---|---|---|---|
| PLA | 45C, never over 60 | 4-6h | |
| PETG | 60-65C | 4-6h | Hygroscopic. Strength loss with moisture: 0-5% at 0.05-0.15%, 10-20% at 0.2-0.4% (bubbling, strings), 25-35% at 0.5-0.8%, 40-50% (unusable) over 1% |
| ABS | 80C | 4-6h | Store under 15% RH. Wet ABS bubbles and pops, and warps ~30% more |

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
- [ ] Filament dried if needed ([Drying](#slicer-tuning-by-material))
- [ ] Spool rotates freely, no tangles
- [ ] Enough filament for print + 20% buffer (check slicer estimate)

### Bed Adhesion

| Surface | PLA | PETG | ABS |
|---------|-----|------|-----|
| **PEI (smooth/textured)** | Excellent, no adhesive needed | Use glue stick as RELEASE agent (PETG bonds too strongly) | Excellent: sticks hot, releases cool |
| **Glass** | Use glue stick or hairspray | Use glue stick | ABS slurry (ABS dissolved in acetone), glue stick or unscented hairspray |
| **Painter's tape** | Good | Not recommended | Kapton tape instead |

ABS also wants an 8-15mm brim (8-10 lines on large parts), and a draft shield (a tall skirt that blocks air currents) without a full enclosure.

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
