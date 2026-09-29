# Bambu 3MF Export (print settings baked in)

`make-bambu-3mf.py` (in this skill's directory; Python 3.8+ standard library) writes a Bambu Studio **project** `.3mf`: the model plus a lean `project_settings.config` that names the user's own system presets (printer, process, filament) and flags the model's overrides. Opened in Bambu Studio or OrcaSlicer, it binds those presets, shows the overrides as a "(modified)" process, and needs no manual settings entry. It works without Bambu Studio installed, from a built-in table of Bambu's official printer profiles.

**Offer it only when** the printer is a Bambu Lab machine, the user slices in Bambu Studio or OrcaSlicer, and `python --version` (or `python3`) works. Otherwise hand off the STL and the PRINT SETTINGS header: other slicers don't read this format.

**Run it; don't read it.** `--help` lists every flag. The command below covers almost every case.

```sh
python "<skill-dir>/make-bambu-3mf.py" --scad model.scad -D 'part="clip"' --printer P1S \
  --layer-height 0.2 --walls 4 --infill 20 --infill-pattern gyroid --supports off \
  --out model.3mf
```

- **One part per file.** For an assembly, run it once per printable part, or on a `plate_*` layout part.
- **`--printer`** takes a short name (`X1C`, `X1`, `X1E`, `P1S`, `P1P`, `A1`, `"A1 mini"`, `P2S`, `H2D`, `"H2D Pro"`, `H2S`, `H2C`, `X2D`, `A2L`), plus a nozzle size if it isn't 0.4 (`"P1S 0.6"`).
- **Leave `--process` unset.** It defaults to the printer's own 0.20mm preset, and `--layer-height` goes in as an override. Preset names don't follow the printer: there is no `@BBL P1S` process, because the P1S uses the X1C presets.
- **Leave `--filament` unset** unless the user wants a material pinned, e.g. `--filament "Bambu PETG HF @BBL X1C"`. The file then opens on the printer's default filament, which the user switches in Bambu Studio.
- `--openscad` is found automatically; pass it only if the tool says it can't find OpenSCAD.

| PRINT SETTINGS header | Flag |
|---|---|
| Layer Height | `--layer-height 0.2` |
| Walls / Perimeters (count) | `--walls 4` |
| Infill % and pattern | `--infill 20 --infill-pattern gyroid` |
| Supports | `--supports off`, or `on` plus `--support-type "tree(auto)"` |
| Top/bottom layers, brim | `--top-layers N`, `--bottom-layers N`, `--brim outer_only` |
| Anything else | `--set key=value`: a raw Bambu config key; JSON values allowed, e.g. `--set 'nozzle_temperature=["230"]'` |

Pass flags only for values the header specifies; everything else comes from the named presets.

**The tool checks its own output.** It verifies the package structure, then re-imports the file through OpenSCAD's `import()`, which uses lib3mf, the library slicers use. The re-imported size must match. It ends with `verify : OK - ...` (report that line) or `verify : FAILED - ...` with a non-zero exit. Don't hand-edit the zip: anything the format needs has a flag.

**Placement.** Each run puts the part at a random spot on the plate, within its margins, to spread plate wear. `--scatter off` centres it instead, and `--scatter-seed N` makes the spot repeatable.

**Full-bed prints (X1/P1).** These printers reserve an 18×28mm front-left corner for the filament cutter, and the tool warns when a footprint covers it. Above roughly 220mm that can't be avoided. Either shrink the part, or, if the user agrees to fit Bambu's stopper-clip mod, pass `--full-bed`. Say every time that the clip disables the cutter, so no AMS or multi-colour on those prints.

**Fallbacks.** `--mesh part.stl` (or `.3mf`) packs an existing mesh instead of rendering the `.scad`. `--base-3mf existing.3mf` reuses another project's full settings as the baseline, though Bambu may then ask to confirm its embedded G-code. With no Python: *"I can't generate the Bambu 3MF here because Python isn't available, so I've exported the STL. Import it into Bambu Studio and apply the PRINT SETTINGS header (layer height, walls, infill, supports)."*
