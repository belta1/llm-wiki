#!/usr/bin/env bash
# Keep the GitHub Copilot surface level with the Claude Code surface.
#
# Copilot users get the same knowledge base through different plumbing: prompt
# files instead of slash commands, a repository instructions file instead of a
# skill. Nothing in the repo links the two, so a check added to commands/lint.md
# can silently fail to reach Copilot — which is exactly what happened to the
# data-source and contract checks. This test is that link.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

python3 - <<'PY'
from __future__ import annotations

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


commands_dir = root / "commands"
prompts_dir = root / "templates" / "copilot-prompts"
instructions_dir = root / "templates" / "copilot-instructions"
pointers_dir = root / "templates" / "pointers"
bash_installer = root / "scripts" / "install-copilot.sh"
ps_installer = root / "scripts" / "install-copilot.ps1"

command_stems = {p.stem for p in commands_dir.glob("*.md")}
prompt_stems = {
    p.name[len("llm-wiki-"):-len(".prompt.md")]
    for p in prompts_dir.glob("llm-wiki-*.prompt.md")
}

print("=== Copilot Parity ===")
print("")
print("--- every command has a prompt, and vice versa ---")
for stem in sorted(command_stems):
    if stem in prompt_stems:
        ok("/%s has llm-wiki-%s.prompt.md" % (stem, stem))
    else:
        bad(
            "/%s has a Copilot prompt" % stem,
            "no templates/copilot-prompts/llm-wiki-%s.prompt.md" % stem,
        )
for stem in sorted(prompt_stems - command_stems):
    bad(
        "llm-wiki-%s.prompt.md has a command" % stem,
        "no commands/%s.md" % stem,
    )

print("")
print("--- check families reach both surfaces ---")
# Each entry: the concepts a command and its prompt must BOTH carry. Matched by
# anchor token, not by diff: the two files are deliberately worded differently
# and sized differently, so a textual comparison would be pure noise.
#
# A token is a list of alternatives; any one of them satisfies it.
PARITY = {
    "lint": {
        "data-source tiers": ["data-sources.md", "data source"],
        "the user-global catalog": ["~/.claude/llm-wiki/data-sources.md", "global catalog"],
        "secret leak": ["presigned", "X-Amz-Signature", "credential"],
        "contract drift": ["wiki_contract"],
        "broken links": ["broken link", "broken cross-link", "no longer exist"],
        "orphan pages": ["orphan"],
        "frontmatter / size": ["frontmatter"],
    },
    "upgrade": {
        "the contract stamp": ["wiki_contract"],
        "the delta idea": ["contract 1", "deltas", "backfill", "idempotent"],
    },
    "update": {
        "the log entry": ["log.md"],
        "module pages": ["modules/"],
    },
    "init": {
        "the index": ["index.md"],
        "module pages": ["modules/"],
    },
    "view": {
        "the generated dashboard": ["view/index.html", "index.html"],
        "markdown stays canonical": ["Markdown"],
    },
}

for stem, tokens in sorted(PARITY.items()):
    command_path = commands_dir / ("%s.md" % stem)
    prompt_path = prompts_dir / ("llm-wiki-%s.prompt.md" % stem)
    if not command_path.is_file() or not prompt_path.is_file():
        continue
    command_text = command_path.read_text(encoding="utf-8").lower()
    prompt_text = prompt_path.read_text(encoding="utf-8").lower()
    for label, alternatives in sorted(tokens.items()):
        lowered = [a.lower() for a in alternatives]
        in_command = any(a in command_text for a in lowered)
        in_prompt = any(a in prompt_text for a in lowered)
        if in_command and in_prompt:
            ok("%s: both surfaces cover %s" % (stem, label))
        elif in_command and not in_prompt:
            bad(
                "%s: Copilot covers %s" % (stem, label),
                "commands/%s.md has it, llm-wiki-%s.prompt.md does not" % (stem, stem),
            )
        elif in_prompt and not in_command:
            bad(
                "%s: the command covers %s" % (stem, label),
                "the prompt has it, commands/%s.md does not" % stem,
            )
        else:
            bad(
                "%s: %s is covered at all" % (stem, label),
                "neither file mentions %s" % " / ".join(alternatives),
            )

print("")
print("--- prompts must not cite plugin-only paths ---")
# A prompt file lands in a target repo, where ${CLAUDE_PLUGIN_ROOT} does not
# exist. Referring to it there sends Copilot after a file it cannot read.
for prompt in sorted(prompts_dir.glob("*.prompt.md")):
    text = prompt.read_text(encoding="utf-8")
    if "CLAUDE_PLUGIN_ROOT" in text:
        bad(
            "%s avoids ${CLAUDE_PLUGIN_ROOT}" % prompt.name,
            "cites a path that does not exist in a target repo",
        )
    else:
        ok("%s avoids ${CLAUDE_PLUGIN_ROOT}" % prompt.name)

print("")
print("--- both installers ship everything ---")
bash_text = bash_installer.read_text(encoding="utf-8")
ps_text = ps_installer.read_text(encoding="utf-8")

for name, text in (("install-copilot.sh", bash_text), ("install-copilot.ps1", ps_text)):
    # Globbed, never a hardcoded list — a new template must ship automatically.
    if "copilot-prompts" in text and ("*.prompt.md" in text or "Filter \"*.prompt.md\"" in text):
        ok("%s globs copilot-prompts/*.prompt.md" % name)
    else:
        bad("%s globs copilot-prompts/*.prompt.md" % name, "hardcoded or missing")
    if "copilot-instructions" in text:
        ok("%s installs path-scoped instructions" % name)
    else:
        bad("%s installs path-scoped instructions" % name, "not referenced")
    # The PowerShell installer spells the destination with backslashes.
    if "bin/llm-wiki" in text or "bin\\llm-wiki" in text:
        ok("%s installs the lint CLI" % name)
    else:
        bad("%s installs the lint CLI" % name, "no .llm-wiki/bin/llm-wiki copy")

print("")
print("--- the two installers expose the same flags ---")
bash_flags = set()
for match in re.finditer(r"^\s*(--[a-z0-9-]+)\)", bash_text, re.M):
    bash_flags.add(match.group(1).lstrip("-").replace("-", ""))
ps_flags = set()
param_block = re.search(r"^param\((?P<body>.*?)^\)", ps_text, re.M | re.S)
if param_block:
    # Both [switch] and [string] parameters are user-facing flags.
    for match in re.finditer(r"\[(?:switch|string)\]\$(\w+)", param_block.group("body")):
        ps_flags.add(match.group(1).lower())
    for match in re.finditer(r'\[Alias\("(\w+)"\)\]', param_block.group("body")):
        ps_flags.add(match.group(1).lower())

# -RLang is exposed to users as -R (declared via [Alias("R")]).
ps_flags.discard("rlang")
# The positional target repo is an argument on both sides, not a flag.
ps_flags.discard("target")
bash_only = sorted(bash_flags - ps_flags)
ps_only = sorted(ps_flags - bash_flags)
if not bash_only and not ps_only:
    ok("flag sets match (%d flags)" % len(bash_flags))
else:
    bad(
        "flag sets match",
        "bash-only: %s; powershell-only: %s" % (bash_only or "-", ps_only or "-"),
    )

print("")
print("--- installer docs name the real prompt set ---")
for name, text in (("install-copilot.sh", bash_text), ("install-copilot.ps1", ps_text)):
    missing = [s for s in sorted(prompt_stems) if "/llm-wiki-%s" % s not in text]
    if missing:
        bad(
            "%s names every prompt" % name,
            "never mentions /llm-wiki-%s" % ", /llm-wiki-".join(missing),
        )
    else:
        ok("%s names every prompt" % name)

print("")
print("--- pointer templates carry a managed block ---")
for pointer in sorted(pointers_dir.glob("*.md")):
    text = pointer.read_text(encoding="utf-8")
    if "<!-- BEGIN llm-wiki -->" in text and "<!-- END llm-wiki -->" in text:
        ok("%s has a matched managed block" % pointer.name)
    else:
        bad("%s has a matched managed block" % pointer.name, "BEGIN/END marker missing")

print("")
print("--- contract item 8: pointers reach the HTML view ---")
for pointer in sorted(pointers_dir.glob("*.md")):
    text = pointer.read_text(encoding="utf-8")
    if "view/index.html" in text:
        ok("%s points humans at the view" % pointer.name)
    else:
        bad("%s points humans at the view" % pointer.name, "no view/index.html line")

print("")
print("%d passed, %d failed" % (len(passed), len(failed)))
sys.exit(1 if failed else 0)
PY
