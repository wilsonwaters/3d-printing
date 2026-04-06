#!/usr/bin/env python3
"""
Build framework-specific adapter files from Claude Code skill sources.

Reads multi-file Claude Code skills from .claude/skills/ and produces
single-file versions for Cursor, Windsurf, Copilot, and Cline.

Usage:
    python scripts/build-adapters.py
"""

import re
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / ".claude" / "skills"
ADAPTERS_DIR = REPO_ROOT / "adapters"


def find_skills():
    """Find all skill directories (those containing SKILL.md)."""
    skills = []
    for skill_dir in SKILLS_DIR.iterdir():
        if skill_dir.is_dir() and (skill_dir / "SKILL.md").exists():
            skills.append(skill_dir)
    return skills


def read_skill(skill_dir):
    """Read SKILL.md and discover all referenced .md files."""
    skill_md = (skill_dir / "SKILL.md").read_text(encoding="utf-8")

    # Find all markdown link references to local .md files
    # Matches patterns like [filename.md](filename.md) or [display text](filename.md)
    link_pattern = re.compile(r"\[([^\]]*)\]\(([a-zA-Z0-9_-]+\.md)\)")
    referenced_files = {}

    for match in link_pattern.finditer(skill_md):
        filename = match.group(2)
        filepath = skill_dir / filename
        if filepath.exists() and filename not in referenced_files:
            referenced_files[filename] = filepath.read_text(encoding="utf-8")

    return skill_md, referenced_files


def filename_to_anchor(filename):
    """Convert a filename like 'material-pla.md' to an anchor like 'material-pla'."""
    return filename.replace(".md", "")


def filename_to_title(filename):
    """Convert a filename like 'material-pla.md' to a title like 'Material PLA'."""
    name = filename.replace(".md", "").replace("-", " ")
    return name.title()


def build_single_file(skill_md, referenced_files):
    """Combine SKILL.md and all references into one document.

    Strategy:
    - Keep the main SKILL.md content
    - Convert file links to internal anchor links
    - Append all referenced files as sections at the end
    """
    combined = skill_md

    # Convert [text](file.md) links to [text](#anchor) links
    for filename in referenced_files:
        anchor = filename_to_anchor(filename)
        # Replace all link targets pointing to this file with anchor links
        combined = re.sub(
            rf"\]\({re.escape(filename)}\)",
            f"](#{anchor})",
            combined,
        )

    # Strip the YAML frontmatter from the main content (adapters don't use it)
    combined = re.sub(r"^---\n.*?\n---\n", "", combined, count=1, flags=re.DOTALL)

    # Append reference files as sections
    combined += "\n\n---\n\n# Reference Files\n"
    for filename, content in referenced_files.items():
        anchor = filename_to_anchor(filename)
        title = filename_to_title(filename)
        combined += f"\n<a id=\"{anchor}\"></a>\n\n"
        combined += f"## {title}\n\n"
        combined += content.strip()
        combined += "\n\n---\n"

    return combined


def build_cursor_mdc(skill_name, description, content):
    """Build a Cursor .mdc file with frontmatter."""
    frontmatter = f"""---
description: {description}
globs:
alwaysApply: false
---

"""
    return frontmatter + content


def build_generic_md(skill_name, description, content):
    """Build a generic markdown file for Windsurf/Copilot/Cline."""
    return content


def write_adapter(output_dir, filename, content):
    """Write an adapter file, creating directories as needed."""
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / filename).write_text(content, encoding="utf-8")
    print(f"  wrote {output_dir / filename}")


def extract_description(skill_md):
    """Extract the description from SKILL.md YAML frontmatter."""
    match = re.search(r"^---\n.*?description:\s*(.+?)\n.*?---", skill_md, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""


def process_skill(skill_dir):
    """Process a single skill into all adapter formats."""
    skill_name = skill_dir.name
    print(f"Processing skill: {skill_name}")

    skill_md, referenced_files = read_skill(skill_dir)
    description = extract_description(skill_md)
    combined = build_single_file(skill_md, referenced_files)

    adapter_base = ADAPTERS_DIR / skill_name

    # Cursor (.mdc)
    cursor_content = build_cursor_mdc(skill_name, description, combined)
    write_adapter(adapter_base / "cursor", f"{skill_name}.mdc", cursor_content)

    # Windsurf, Copilot, Cline (all use plain .md)
    generic_content = build_generic_md(skill_name, description, combined)
    for framework in ["windsurf", "copilot", "cline"]:
        write_adapter(adapter_base / framework, f"{skill_name}.md", generic_content)

    print(f"  done ({len(referenced_files)} references inlined)")


def main():
    skills = find_skills()
    if not skills:
        print(f"No skills found in {SKILLS_DIR}")
        return

    print(f"Found {len(skills)} skill(s) in {SKILLS_DIR}\n")
    for skill_dir in sorted(skills):
        process_skill(skill_dir)

    print(f"\nAdapters written to {ADAPTERS_DIR}")


if __name__ == "__main__":
    main()
