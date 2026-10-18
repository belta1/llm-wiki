#!/usr/bin/env bash
# Validate the plugin manifests, command/skill frontmatter, and every
# ${CLAUDE_PLUGIN_ROOT} path the commands and skills cite.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

python3 - <<'PY'
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

root = Path.cwd()
passed = []
failed = []


def ok(message):
    passed.append(message)
    print("  \033[32mPASS\033[0m: %s" % message)


def bad(message, detail):
    failed.append(message)
    print("  \033[31mFAIL\033[0m: %s — %s" % (message, detail))


def frontmatter(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    data = {}
    for line in lines[1:]:
        if line.strip() == "---":
            return data
        if ":" in line and not line.startswith(" "):
            key, _, value = line.partition(":")
            data[key.strip()] = value.strip()
    return None


print("=== Plugin Validation ===")
print("")
print("--- manifests ---")

plugin_json = root / ".claude-plugin" / "plugin.json"
marketplace_json = root / ".claude-plugin" / "marketplace.json"

plugin = marketplace = None
for path in (plugin_json, marketplace_json):
    if not path.is_file():
        bad("%s exists" % path.name, "missing file")
        continue
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        ok("%s is valid JSON" % path.name)
        if path is plugin_json:
            plugin = data
        else:
            marketplace = data
    except json.JSONDecodeError as error:
        bad("%s is valid JSON" % path.name, str(error))

if plugin and marketplace:
    versions = {
        "plugin.json version": plugin.get("version"),
        "marketplace metadata.version": marketplace.get("metadata", {}).get("version"),
        "marketplace plugins[0].version": marketplace.get("plugins", [{}])[0].get("version"),
    }
    if len(set(versions.values())) == 1 and None not in versions.values():
        ok("all three version fields agree (%s)" % plugin.get("version"))
    else:
        bad(
            "version fields agree",
            "; ".join("%s=%s" % (k, v) for k, v in versions.items()),
        )

    source = marketplace.get("plugins", [{}])[0].get("source")
    if source and (root / source).is_dir():
        ok("marketplace plugins[0].source resolves (%s)" % source)
    else:
        bad("marketplace plugins[0].source resolves", "no such directory: %s" % source)

print("")
print("--- command frontmatter ---")
commands = sorted((root / "commands").glob("*.md"))
if not commands:
    bad("commands/ has command files", "none found")
for command in commands:
    data = frontmatter(command)
    name = "commands/%s" % command.name
    if data is None:
        bad("%s has frontmatter" % name, "missing or unterminated ---")
        continue
    if data.get("description"):
        ok("%s has a description" % name)
    else:
        bad("%s has a description" % name, "no description: key")
    body = command.read_text(encoding="utf-8")
    if "$ARGUMENTS" in body and "argument-hint" not in data:
        bad("%s declares argument-hint" % name, "uses $ARGUMENTS without a hint")
    elif "$ARGUMENTS" in body:
        ok("%s declares argument-hint" % name)

print("")
print("--- skill frontmatter ---")
skills = sorted((root / "skills").glob("*/SKILL.md"))
if not skills:
    bad("skills/ has SKILL.md files", "none found")
for skill in skills:
    data = frontmatter(skill)
    name = skill.relative_to(root).as_posix()
    if data is None:
        bad("%s has frontmatter" % name, "missing or unterminated ---")
        continue
    missing = [key for key in ("name", "description") if not data.get(key)]
    if missing:
        bad("%s has name + description" % name, "missing %s" % ", ".join(missing))
    else:
        ok("%s has name + description" % name)
    if data.get("name") and data["name"] != skill.parent.name:
        bad(
            "%s name matches its directory" % name,
            "name: %s vs dir %s" % (data["name"], skill.parent.name),
        )
    elif data.get("name"):
        ok("%s name matches its directory" % name)

print("")
print("--- ${CLAUDE_PLUGIN_ROOT} references resolve ---")
# A renamed reference file silently breaks every command that cites it.
# A citation may be a literal path or a glob (templates/copilot-prompts/llm-wiki-*.prompt.md).
pattern = re.compile(r"\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_.*/-]+)")
cited = {}
for path in sorted(list((root / "commands").rglob("*.md")) + list((root / "skills").rglob("*.md"))):
    for match in pattern.finditer(path.read_text(encoding="utf-8")):
        target = match.group(1).rstrip("`.,;:)")
        cited.setdefault(target, set()).add(path.relative_to(root).as_posix())

if not cited:
    bad("commands/skills cite plugin-root paths", "found none — did the convention change?")
for target in sorted(cited):
    if "*" in target:
        matches = list(root.glob(target))
        if matches:
            ok("${CLAUDE_PLUGIN_ROOT}/%s matches %d file(s)" % (target, len(matches)))
        else:
            bad(
                "${CLAUDE_PLUGIN_ROOT}/%s matches anything" % target,
                "glob cited by %s matches nothing" % ", ".join(sorted(cited[target])),
            )
        continue
    if (root / target).exists():
        ok("${CLAUDE_PLUGIN_ROOT}/%s exists" % target)
    else:
        bad(
            "${CLAUDE_PLUGIN_ROOT}/%s exists" % target,
            "cited by %s" % ", ".join(sorted(cited[target])),
        )

print("")
print("--- the lint CLI is shippable ---")
cli = root / "scripts" / "llm-wiki"
if cli.is_file():
    ok("scripts/llm-wiki exists")
    text = cli.read_text(encoding="utf-8")
    if text.startswith("#!/usr/bin/env python3"):
        ok("scripts/llm-wiki has a python3 shebang")
    else:
        bad("scripts/llm-wiki has a python3 shebang", "first line is %r" % text.split("\n")[0])
    third_party = re.findall(r"^\s*(?:import|from)\s+(\w+)", text, re.M)
    allowed = {
        "argparse", "json", "os", "re", "sys", "pathlib", "__future__", "typing",
        "dataclasses", "datetime",
    }
    extra = sorted(set(third_party) - allowed)
    if extra:
        bad("scripts/llm-wiki is stdlib-only", "imports %s" % ", ".join(extra))
    else:
        ok("scripts/llm-wiki is stdlib-only")
else:
    bad("scripts/llm-wiki exists", "missing file")

print("")
print("%d passed, %d failed" % (len(passed), len(failed)))
sys.exit(1 if failed else 0)
PY
