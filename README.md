# 3D Printing

AI-powered design skills and parametric OpenSCAD models for FDM 3D printing.

## AI Skills

| Skill | Description | Frameworks |
|-------|-------------|------------|
| [3d-print-designer](#3d-print-designer) | Designs parametric, FDM-optimized OpenSCAD models with material selection, print orientation, and structural optimization | Claude Code, Cursor, Windsurf, Copilot, Cline |

## 3d-print-designer

An AI skill that designs and generates parametric OpenSCAD (.scad) models optimized for FDM printing. It handles:

- **Printer configuration** — auto-detects specs from 20+ known printer models
- **Material selection** — PLA, PETG, ABS with material-specific design rules
- **Support-free design** — 9 techniques to eliminate supports (chamfers, teardrop holes, part splitting, etc.)
- **Structural optimization** — wall thickness, infill, ribs, layer adhesion
- **Mechanical features** — gears, threads, snap-fits, living hinges
- **Design review** — 45-item checklist covering geometry, printability, and assembly

### Install

#### Claude Code (CLI, Desktop, VS Code, JetBrains, Web)

**Plugin marketplace** (recommended):
```
/plugin marketplace add wilsonwaters/3d-printing
/plugin install 3d-print-designer
```

**Manual copy:**
```bash
git clone https://github.com/wilsonwaters/3d-printing.git
cp -r 3d-printing/.claude/skills/3d-print-designer ~/.claude/skills/
```

#### Cursor

```bash
curl -o .cursor/rules/3d-print-designer.mdc \
  https://raw.githubusercontent.com/wilsonwaters/3d-printing/main/adapters/3d-print-designer/cursor/3d-print-designer.mdc
```

#### Windsurf

```bash
curl -o .windsurf/rules/3d-print-designer.md \
  https://raw.githubusercontent.com/wilsonwaters/3d-printing/main/adapters/3d-print-designer/windsurf/3d-print-designer.md
```

#### GitHub Copilot

```bash
curl -o .github/copilot-instructions.md \
  https://raw.githubusercontent.com/wilsonwaters/3d-printing/main/adapters/3d-print-designer/copilot/3d-print-designer.md
```

#### Cline

```bash
curl -o .cline/rules/3d-print-designer.md \
  https://raw.githubusercontent.com/wilsonwaters/3d-printing/main/adapters/3d-print-designer/cline/3d-print-designer.md
```

### Example Prompts

- "Design a wall-mounted bracket for a 1kg spool holder"
- "Create a snap-fit enclosure for a Raspberry Pi 4"
- "Design a parametric cable management clip"
- "Make a gear train with a 3:1 reduction ratio"

## 3D Models

Parametric OpenSCAD models in the [3d-models/](3d-models/) directory.

## Framework Adapter Build

Adapter files in `adapters/` are auto-generated from the Claude Code skill source via GitHub Actions. They rebuild automatically when skill files change on `main`.

To build locally:
```bash
python scripts/build-adapters.py
```

## License

[MIT](LICENSE)
