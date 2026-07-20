# Bambu 3MF Export (print settings baked in)

Generate a Bambu Studio **project** `.3mf` that opens with all print settings already applied — so the user never has to re-dial layer height, walls, infill, supports, or material in Bambu Studio. This is a **Bambu-only convenience**; for other printers/slicers the STL path in [printing-workflow.md](printing-workflow.md) stays the default.

## Contents
- [When to use this](#when-to-use-this)
- [What a Bambu project 3MF contains](#what-a-bambu-project-3mf-contains)
- [The tool: make-bambu-3mf.py](#the-tool-make-bambu-3mfpy)
- [Mapping the PRINT SETTINGS header to flags](#mapping-the-print-settings-header-to-flags)
- [Choosing profile names](#choosing-profile-names)
- [Workflow](#workflow)
- [Verified behaviour and caveats](#verified-behaviour-and-caveats)
- [Fallbacks and graceful degradation](#fallbacks-and-graceful-degradation)

## When to use this

Offer it only when **all** of these hold:

1. The printer (from Step 0) is a **Bambu Lab** machine, **and**
2. the user slices in **Bambu Studio** (or OrcaSlicer, which reads the same project format), **and**
3. **Python 3.8+ is available** on the machine — the generator is a Python script (`python --version` / `python3 --version`).

If any of these fails, **do not generate a 3MF** — hand off the STL and the PRINT SETTINGS header for manual import instead (see [Fallbacks](#fallbacks-and-graceful-degradation)).

**Why Bambu-only:** the settings-in-3MF *project* format (`project_settings.config` + `different_settings_to_system`) is specific to Bambu Studio / OrcaSlicer, and this tool resolves Bambu's own (BBL) profiles. PrusaSlicer, Cura, and other slicers don't read this format, so for a non-Bambu printer the STL path is the only option. (An OrcaSlicer user on a non-Bambu printer could in principle use it by pointing `--profiles-dir` at Orca's own profiles with the matching preset names, but that's out of scope — treat the feature as Bambu-only.)

## What a Bambu project 3MF contains

A `.3mf` is a ZIP of XML. There are two flavours, and the difference is the whole point:

| | Geometry-only 3MF (OpenSCAD / STL) | Bambu **project** 3MF |
|---|---|---|
| Parts inside | `[Content_Types].xml`, `_rels/.rels`, `3D/3dmodel.model` | those **plus** `Metadata/project_settings.config`, `model_settings.config`, `slice_info.config` |
| Print settings | none — opens with slicer defaults | **`project_settings.config`** — a flat JSON of ~450–540 keys (layer height, walls, infill, supports, temps, G-code, …) |

OpenSCAD's own 3MF export (and any STL) is geometry-only, so opening it drops the part on the plate with default settings. A project 3MF carries the configuration; Bambu Studio restores it on open. This tool builds a **lean** project 3MF: rather than dumping a full slicer config, it writes just the preset *names* plus the settings the model overrides, and lets Bambu bind your installed system presets by name. That keeps the file small, uses your own trusted presets, and avoids Bambu's "customized preset — confirm the G-code is safe" warning (which fires whenever an embedded preset isn't byte-identical to your installed one).

## The tool: make-bambu-3mf.py

`make-bambu-3mf.py` lives in this skill's directory. It needs only **Python 3.8+** (standard library — no pip installs) and does not require Bambu Studio to be running. (On macOS/Linux the command is often `python3` rather than `python`.) It:

1. Renders the mesh (`--scad model.scad --openscad <path>`) or loads an existing mesh (`--mesh model.stl|.3mf`).
2. Reads Bambu's **official** profile JSONs (`machine` + `process`, auto-detected) *only* to look up identity values (the printer's declared default filament, bed size) and to decide which overrides genuinely differ from the process preset — it does not copy them into the file.
3. Writes the identity ids + the model's overrides, **flagging each changed key in `different_settings_to_system`**. This is essential: on open, Bambu binds the named preset and resets any key that isn't flagged back to the preset default, so an override that isn't flagged is silently discarded.
4. Assembles a Bambu-openable project `.3mf` (correct container, part centred on the plate, base resting on Z=0).

Basic invocation (forward slashes work on all platforms; quote paths with spaces):

```bash
python .claude/skills/3d-print-designer/make-bambu-3mf.py \
  --scad "3d-models/my-part/my-part.scad" \
  --openscad "C:/Program Files/OpenSCAD-2026.06.19-x86-64/openscad.exe" \
  --printer "Bambu Lab P1S 0.4 nozzle" \
  --process "0.20mm Standard @BBL X1C" \
  --layer-height 0.2 --walls 4 --infill 20 --infill-pattern gyroid --supports off \
  --out "3d-models/my-part/my-part.3mf"
```

By default no specific filament is pinned — the file uses the **printer's declared default filament** (a real system preset, freely changeable in Bambu Studio). Pass `--filament "Bambu PETG HF @BBL X1C"` to pin a specific material instead (repeat for multi-material).

Run `python .claude/skills/3d-print-designer/make-bambu-3mf.py --help` for the full flag list.

## Mapping the PRINT SETTINGS header to flags

Translate the model's `PRINT SETTINGS` header (see [SKILL.md](SKILL.md) > Print-settings header) into flags. Only pass flags for values the model actually specifies; everything else inherits from the chosen official profiles.

| PRINT SETTINGS header | Flag | Notes |
|---|---|---|
| Material (PLA/PETG/ABS) | `--filament` (optional) | Omit → uses the printer's default filament (changeable in Bambu Studio); pass it to pin a specific material |
| Layer Height | `--layer-height 0.2` | mm |
| Walls / Perimeters (count) | `--walls 4` | perimeter count, not thickness |
| Infill (density) | `--infill 20` | percent; `20` or `20%` both work |
| Infill (pattern) | `--infill-pattern gyroid` | e.g. gyroid, grid, honeycomb |
| Supports | `--supports off` / `--supports on` | add `--support-type "tree(auto)"` if on |
| — top/bottom solids | `--top-layers` / `--bottom-layers` | optional |
| Anything else | `--set key=value` | raw `project_settings.config` key; value may be JSON, e.g. `--set 'nozzle_temperature=["230"]'` |

`--printer` and `--process` come from the printer/quality choice, not the header — see below.

## Choosing profile names

The three identity flags must name presets the user actually has installed, so Bambu binds them cleanly on open.

- **`--printer`** — the machine preset for the printer from Step 0, e.g. `Bambu Lab X1 Carbon 0.4 nozzle`, `Bambu Lab P1S 0.4 nozzle`, `Bambu Lab A1 0.4 nozzle`.
- **`--process`** — the quality preset, suffixed by printer family: `0.20mm Standard @BBL X1C`, `0.20mm Standard @BBL P1S`, etc. Match the layer height to the model.
- **`--filament`** *(optional)* — omit it (recommended) and the file uses the printer's declared default filament, freely changeable in Bambu Studio. Pass it only to pin a specific material, e.g. `Bambu PETG HF @BBL X1C`; repeat for multi-material.

The `@BBL X1C` / `@BBL P1S` suffix is the printer-family the preset is tuned for. To see the exact names available, list the profile directory (auto-detected locations below):

```bash
ls "C:/Program Files/Bambu Studio/resources/profiles/BBL/machine"   # printer presets
ls "C:/Program Files/Bambu Studio/resources/profiles/BBL/process"    # quality presets
ls "C:/Program Files/Bambu Studio/resources/profiles/BBL/filament"   # material presets
```

The tool auto-detects the profiles directory on Windows (`C:\Program Files\Bambu Studio\...`), macOS, and Linux. If it's installed elsewhere (custom drive, OrcaSlicer), pass `--profiles-dir "<.../resources/profiles/BBL>"`. A misspelt preset name fails fast with a clear `... preset not found` message — fix the name and re-run.

## Full-bed prints (X1/P1 exclusion zone)

If the footprint covers the X1/P1 front-left exclusion corner (see [printer-configuration.md](printer-configuration.md)) and the user has agreed to fit the stopper clip, the print needs the bed's **`bed_exclude_area` cleared to `[]`** — otherwise Bambu Studio shows "too close to exclusion area" and refuses to slice cleanly. The cleared key must be flagged in the **printer** slot (last) of `different_settings_to_system`; the `--set` flag lands overrides in the **process** slot, so clearing the exclusion this way does not bind. Either have the user clear "Excluded bed area" in Bambu Studio's printer settings (per Bambu's guide), or edit `Metadata/project_settings.config` inside the generated `.3mf` to set `"bed_exclude_area": []` and append `bed_exclude_area` to the printer slot. Keep it **single-filament** (the clip disables the cutter — no AMS/multi-colour).

## Workflow

Run this **after** the model has passed [Verification](SKILL.md#verification) and the [Design Review](SKILL.md#design-review) — the 3MF is a delivery step, not a design step.

1. **Check preconditions.** Confirm (a) the printer is Bambu Lab and the user slices in Bambu Studio/OrcaSlicer, and (b) Python is available — run `python --version` (or `python3 --version`). If either fails, stop here and use the fallback ([Fallbacks](#fallbacks-and-graceful-degradation)): hand off the STL + PRINT SETTINGS header for manual import. Use whichever `python`/`python3` command resolved for the run in step 4.
2. Resolve the printer preset (from Step 0) and process preset (by layer height). Leave filament unset unless the user asks to pin a specific material — by default the file uses the printer's default filament, changeable in Bambu Studio. If a name is ambiguous, list the profile dir and confirm with the user.
3. Map the model's PRINT SETTINGS header to override flags (table above).
4. Run `make-bambu-3mf.py`, writing the `.3mf` next to the `.scad`.
5. Tell the user: the file opens in Bambu Studio with settings applied — review on the plate, then Slice → Print.

## Verified behaviour and caveats

Confirmed by opening a generated file in Bambu Studio (X1 Carbon · 0.20mm Standard · default PLA):

- The named system presets bind on open, the flagged overrides show as a **"(modified)"** process preset, the printer's **default filament** is selected, and **no "customized preset — confirm the G-code" warning** appears (the lean file embeds no G-code to trigger it).
- The output is also a structurally valid 3MF — it re-imports cleanly through OpenSCAD's lib3mf and matches the container structure Bambu Studio itself writes.

**Caveat:** the preset names you pass must exist in the user's install. A misspelt or absent id makes Bambu fall back to a generic profile (the overrides still load, but the dropdown won't bind cleanly) — when unsure, list the profile dir (above) to confirm exact names.

## Fallbacks and graceful degradation

- **Profiles not found** → pass `--profiles-dir`, or fall back to `--base-3mf "<an existing Bambu project .3mf>"` to reuse that project's `project_settings.config` as the baseline (the tool still swaps in the new mesh and applies overrides).
- **3MF render unavailable / prefer STL** → `--mesh model.stl` (binary or ASCII; vertices are de-duplicated) instead of `--scad`.
- **Python not available** (no `python`/`python3` on PATH) → the generator can't run, and there's no reliable non-Python way to assemble the container, so **don't attempt it**. Tell the user plainly and fall back to the STL path — e.g.:
  > "I can't auto-generate the Bambu 3MF here because Python isn't available on this machine. I've exported the STL instead — import it into Bambu Studio and apply the settings from the PRINT SETTINGS header (layer height, walls, infill, supports). If you'd like the one-click settings-baked-in 3MF next time, install Python from python.org and I can set it up."

  Then follow the STL → slicer steps in [printing-workflow.md](printing-workflow.md).
- **Not a Bambu setup** (non-Bambu printer, or a slicer other than Bambu Studio/OrcaSlicer) → the project format doesn't apply; use the STL → slicer path in [printing-workflow.md](printing-workflow.md).
- **Want a directly-printable file** (optional power route) → Bambu Studio and OrcaSlicer have a headless CLI (`--load-settings machine.json;process.json --load-filaments f.json --slice --export-3mf out.gcode.3mf model.3mf`) that emits a *pre-sliced* `.gcode.3mf`. That skips the on-plate review and needs the slicer installed; prefer the project 3MF above unless the user explicitly wants slice-and-send automation.
