#!/usr/bin/env bash
# Cross-document consistency — the things that drift silently in a plugin made
# almost entirely of Markdown.
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


readme = (root / "README.md").read_text(encoding="utf-8")

print("=== Docs Consistency ===")
print("")
print("--- README documents every command ---")
command_stems = sorted(p.stem for p in (root / "commands").glob("*.md"))
documented = set(re.findall(r"`/llm-wiki:([a-z-]+)`", readme))
for stem in command_stems:
    if stem in documented:
        ok("README documents /llm-wiki:%s" % stem)
    else:
        bad("README documents /llm-wiki:%s" % stem, "no `/llm-wiki:%s` in README.md" % stem)
for stem in sorted(documented - set(command_stems)):
    bad("README's /llm-wiki:%s exists" % stem, "no commands/%s.md" % stem)

print("")
print("--- README documents every Copilot prompt ---")
prompt_stems = sorted(
    p.name[len("llm-wiki-"):-len(".prompt.md")]
    for p in (root / "templates" / "copilot-prompts").glob("llm-wiki-*.prompt.md")
)
prompt_mentions = set(re.findall(r"`/llm-wiki-([a-z-]+)`", readme))
for stem in prompt_stems:
    if stem in prompt_mentions:
        ok("README documents /llm-wiki-%s" % stem)
    else:
        bad("README documents /llm-wiki-%s" % stem, "no `/llm-wiki-%s` in README.md" % stem)

# The prose used to say "three" above a four-row table while five shipped.
count_claim = re.search(
    r"installer drops (?P<count>\w+) into `\.github/prompts/`", readme
)
WORDS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7,
    "eight": 8, "nine": 9, "ten": 10,
}
if not count_claim:
    bad("README states how many prompts ship", "sentence not found — was it reworded?")
else:
    claimed = WORDS.get(count_claim.group("count").lower())
    if claimed == len(prompt_stems):
        ok("README's prompt count matches (%d)" % len(prompt_stems))
    else:
        bad(
            "README's prompt count matches",
            "says %r, but %d prompt files ship" % (count_claim.group("count"), len(prompt_stems)),
        )

print("")
print("--- README documents every installer flag ---")
bash_text = (root / "scripts" / "install-copilot.sh").read_text(encoding="utf-8")
bash_flags = sorted({m.group(1) for m in re.finditer(r"^\s*(--[a-z0-9-]+)\)", bash_text, re.M)})
for flag in bash_flags:
    if flag in {"--help"}:
        continue
    # A flag that takes an argument is documented as `--flag DIR`.
    if re.search(r"`%s\b[^`]*`" % re.escape(flag), readme):
        ok("README documents %s" % flag)
    else:
        bad("README documents %s" % flag, "flag accepted by the installer but undocumented")

print("")
print("--- the contract constant agrees everywhere ---")
contract_doc = (root / "skills" / "llm-wiki" / "references" / "wiki-contract.md").read_text(
    encoding="utf-8"
)
match = re.search(r"\*\*`CURRENT_CONTRACT\s*=\s*(\d+)`\*\*", contract_doc)
if not match:
    bad("wiki-contract.md states CURRENT_CONTRACT", "constant not found")
else:
    current = int(match.group(1))
    ok("wiki-contract.md says CURRENT_CONTRACT = %d" % current)

    cli = (root / "scripts" / "llm-wiki").read_text(encoding="utf-8")
    cli_match = re.search(r"^CURRENT_CONTRACT\s*=\s*(\d+)", cli, re.M)
    if cli_match and int(cli_match.group(1)) == current:
        ok("scripts/llm-wiki agrees (%d)" % current)
    else:
        bad(
            "scripts/llm-wiki agrees",
            "CLI says %s" % (cli_match.group(1) if cli_match else "nothing"),
        )

    # The Copilot upgrade prompt runs in a target repo and cannot read the
    # reference, so it names the level literally — in more than one place.
    upgrade_prompt = (
        root / "templates" / "copilot-prompts" / "llm-wiki-upgrade.prompt.md"
    ).read_text(encoding="utf-8")
    levels = {int(n) for n in re.findall(r"wiki_contract: (\d+)", upgrade_prompt)}
    levels |= {int(n) for n in re.findall(r"lower than (\d+)", upgrade_prompt)}
    if not levels:
        bad("llm-wiki-upgrade.prompt.md names the level", "no contract level found in the prompt")
    elif levels == {current}:
        ok("llm-wiki-upgrade.prompt.md names contract %d everywhere" % current)
    else:
        bad(
            "llm-wiki-upgrade.prompt.md names contract %d everywhere" % current,
            "prompt mentions %s — see 'Bumping the contract' item 6"
            % ", ".join(str(n) for n in sorted(levels)),
        )

    template_index = (root / "templates" / "wiki" / "index.md").read_text(encoding="utf-8")
    tpl_match = re.search(r"^wiki_contract:\s*(\d+)", template_index, re.M)
    if tpl_match and int(tpl_match.group(1)) == current:
        ok("templates/wiki/index.md is born current (%d)" % current)
    else:
        bad(
            "templates/wiki/index.md is born current",
            "template stamps %s" % (tpl_match.group(1) if tpl_match else "nothing"),
        )

print("")
print("--- relative links in the docs resolve ---")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
doc_files = [root / "README.md", root / "CLAUDE.md"] + sorted((root / "docs").glob("*.md"))
for doc in doc_files:
    if not doc.is_file():
        continue
    broken = []
    for target in LINK_RE.findall(doc.read_text(encoding="utf-8")):
        if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
            continue
        path = target.split("#")[0]
        if not path:
            continue
        from urllib.parse import unquote

        if not (doc.parent / unquote(path)).exists():
            broken.append(target)
    if broken:
        bad("%s links resolve" % doc.name, "missing: %s" % ", ".join(sorted(set(broken))))
    else:
        ok("%s links resolve" % doc.name)

print("")
print("--- every test script is documented and runnable ---")
scripts = sorted((root / "tests").glob("test-*.sh"))
for script in scripts:
    rel = "./tests/%s" % script.name
    if rel in readme:
        ok("README lists %s" % script.name)
    else:
        bad("README lists %s" % script.name, "test exists but is not in the README Tests section")

workflow = root / ".github" / "workflows" / "plugin-tests.yml"
if workflow.is_file():
    workflow_text = workflow.read_text(encoding="utf-8")
    for script in scripts:
        if script.name in workflow_text:
            ok("CI runs %s" % script.name)
        else:
            bad("CI runs %s" % script.name, "not referenced in plugin-tests.yml")
else:
    bad("CI workflow exists", "no .github/workflows/plugin-tests.yml")

print("")
print("%d passed, %d failed" % (len(passed), len(failed)))
sys.exit(1 if failed else 0)
PY
