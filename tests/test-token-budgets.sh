#!/usr/bin/env bash
# Guard the plugin's own token cost.
#
# This plugin's pitch is that a wiki makes agents cheaper. Text the plugin loads
# on every session is the part that makes them more expensive, so each artifact
# gets a recorded baseline and a ceiling. The Copilot numbers matter most:
# .github/copilot-instructions.md is prepended to every Copilot request and the
# path-scoped instructions fire on every matching file — there is no lazy
# loading on that surface.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

python3 - <<'PY'
from __future__ import annotations

import io
import json
import os
import sys
from pathlib import Path

root = Path.cwd()
budgets = json.loads((root / "tests" / "budgets" / "token-budgets.json").read_text(encoding="utf-8"))


def size(path):
    return os.path.getsize(root / path)


def total(pattern):
    return sum(os.path.getsize(p) for p in sorted(root.glob(pattern)))


def description_chars(path):
    for line in io.open(root / path, encoding="utf-8").read().split("\n")[:12]:
        if line.startswith("description:"):
            return len(line[len("description:"):].strip())
    return 0


plugin = json.loads((root / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))

measured = {
    "skill_llm_wiki_bytes": size("skills/llm-wiki/SKILL.md"),
    "skill_llm_wiki_description_chars": description_chars("skills/llm-wiki/SKILL.md"),
    "skill_data_sources_bytes": size("skills/data-sources/SKILL.md"),
    "skill_data_sources_description_chars": description_chars("skills/data-sources/SKILL.md"),
    "plugin_description_chars": len(plugin["description"]),
    "lazy_references_bytes": total("skills/llm-wiki/references/*.md"),
    "lazy_commands_bytes": total("commands/*.md"),
    "copilot_pointer_bytes": size("templates/pointers/copilot-instructions.md"),
    # CLAUDE.md is loaded every Claude session and AGENTS.md every Codex
    # session, so both are always-loaded text too.
    "claude_pointer_bytes": size("templates/pointers/CLAUDE.md"),
    "agents_pointer_bytes": size("templates/pointers/AGENTS.md"),
    "copilot_prompts_bytes": total("templates/copilot-prompts/*.md"),
    "copilot_path_instructions_bytes": total("templates/copilot-instructions/*.md"),
    "wiki_templates_bytes": total("templates/wiki/*.md"),
}

print("=== Token Budgets ===")
print("")
print("  %-42s %9s %9s %9s" % ("metric", "now", "baseline", "max"))

failed = []
unknown = sorted(set(measured) ^ set(budgets["metrics"]))
for name in sorted(measured):
    if name not in budgets["metrics"]:
        continue
    entry = budgets["metrics"][name]
    now, baseline, ceiling = measured[name], entry["baseline"], entry["max"]
    delta = now - baseline
    marker = "\033[32mok\033[0m"
    if now > ceiling:
        marker = "\033[31mOVER\033[0m"
        failed.append(name)
    print(
        "  %-42s %9d %9d %9d  %+6d  %s"
        % (name, now, baseline, ceiling, delta, marker)
    )

print("")
if unknown:
    print("  \033[31mFAIL\033[0m: budget file and test disagree on: %s" % ", ".join(unknown))
    print("         add the metric to both, or remove it from both")
    sys.exit(1)

if failed:
    print("  \033[31mFAIL\033[0m: %d metric(s) over budget: %s" % (len(failed), ", ".join(failed)))
    print("         shrink the text, or raise the baseline deliberately in the same commit")
    sys.exit(1)

print("  \033[32mPASS\033[0m: %d metrics within budget" % len(measured))
PY
