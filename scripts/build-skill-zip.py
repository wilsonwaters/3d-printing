#!/usr/bin/env python3
"""
Build installable skill ZIP archives from Claude Code skill sources.

Reads each skill in .claude/skills/ and produces a dist/<skill-name>.zip that
can be uploaded directly to Claude Desktop / claude.ai
(Customize > Skills > Create skill > Upload a skill).

The skill folder is placed at the ROOT of the archive (e.g.
"3d-print-designer/SKILL.md") because Claude expects the zip to contain the
skill folder itself, not the loose files.

Usage:
    python scripts/build-skill-zip.py
"""

import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / ".claude" / "skills"
DIST_DIR = REPO_ROOT / "dist"

# Files/dirs that should never end up inside a distributed skill.
EXCLUDE_NAMES = {".DS_Store", "Thumbs.db", "__pycache__", ".git"}


def find_skills():
    """Find all skill directories (those containing SKILL.md)."""
    skills = []
    for skill_dir in SKILLS_DIR.iterdir():
        if skill_dir.is_dir() and (skill_dir / "SKILL.md").exists():
            skills.append(skill_dir)
    return sorted(skills)


def iter_skill_files(skill_dir):
    """Yield every file under skill_dir, skipping junk, sorted for determinism."""
    for path in sorted(skill_dir.rglob("*")):
        if not path.is_file():
            continue
        if any(part in EXCLUDE_NAMES for part in path.relative_to(skill_dir).parts):
            continue
        yield path


def build_zip(skill_dir):
    """Zip a single skill into dist/<skill-name>.zip with the folder at root."""
    skill_name = skill_dir.name
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    zip_path = DIST_DIR / f"{skill_name}.zip"

    file_count = 0
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in iter_skill_files(skill_dir):
            # arcname keeps the skill folder as the top-level entry, e.g.
            # "3d-print-designer/SKILL.md"
            arcname = Path(skill_name) / path.relative_to(skill_dir)
            zf.write(path, arcname.as_posix())
            file_count += 1

    print(f"  wrote {zip_path} ({file_count} files)")
    return zip_path


def main():
    skills = find_skills()
    if not skills:
        print(f"No skills found in {SKILLS_DIR}")
        return

    print(f"Found {len(skills)} skill(s) in {SKILLS_DIR}\n")
    for skill_dir in skills:
        print(f"Packaging skill: {skill_dir.name}")
        build_zip(skill_dir)

    print(f"\nSkill archives written to {DIST_DIR}")


if __name__ == "__main__":
    main()
