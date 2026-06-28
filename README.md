# 3D Printing

AI-powered design skills and parametric OpenSCAD models for FDM 3D printing.

## AI Skills

| Skill | Description | Frameworks |
|-------|-------------|------------|
| [3d-print-designer](#3d-print-designer) | Designs parametric, FDM-optimized OpenSCAD models with material selection, print orientation, and structural optimization | Claude Code, Claude Desktop, Cursor, Windsurf, Copilot, Cline |

## 3d-print-designer

An AI skill that designs and generates parametric OpenSCAD (.scad) models optimized for FDM printing. It handles:

- **Printer configuration** — auto-detects specs from 20+ known printer models
- **Material selection** — PLA, PETG, ABS with material-specific design rules
- **Support-free design** — 9 techniques to eliminate supports (chamfers, teardrop holes, part splitting, etc.)
- **Structural optimization** — wall thickness, infill, ribs, layer adhesion
- **Mechanical features** — gears, threads, snap-fits, living hinges
- **Design review** — 45-item checklist covering geometry, printability, and assembly

### Install

Pick the section that matches the app you run Claude in. Claude Code installs the skill as a **plugin**; the Claude **Desktop and web chat apps** install it from a **ZIP** instead — they don't use Claude Code plugins.

#### Claude Code (CLI, VS Code, JetBrains)

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

#### Claude Desktop & claude.ai

The desktop and web chat apps install skills from a ZIP — they can't add a Claude Code plugin marketplace.

1. Download [`3d-print-designer.zip`](https://github.com/wilsonwaters/3d-printing/releases/latest/download/3d-print-designer.zip) from the [latest release](https://github.com/wilsonwaters/3d-printing/releases/latest).
2. In Claude, go to **Customize → Skills → Create skill → Upload a skill** and select the ZIP.

> **Enable code execution first.** Skills require code execution to be turned on. On Free / Pro / Max, enable it under **Settings → Capabilities**. On Team / Enterprise, an admin must enable it under **Organization settings → Skills**.

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

## Building Skill Artifacts

Two artifacts are generated from the Claude Code skill source by the [Build Skill Artifacts](.github/workflows/build-skill-artifacts.yml) workflow, which runs automatically when skill files change on `main` (and can be triggered manually):

- **Framework adapters** (`adapters/`) — single-file versions for Cursor, Windsurf, Copilot, and Cline, committed back to the repo.
- **Installable skill ZIP** — `3d-print-designer.zip`, published as an asset on the [latest release](https://github.com/wilsonwaters/3d-printing/releases/latest) for upload to Claude Desktop / claude.ai.

To build either locally:
```bash
python scripts/build-adapters.py    # adapters/
python scripts/build-skill-zip.py   # dist/*.zip
```

## License

[MIT](LICENSE)
