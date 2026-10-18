# llm-wiki — development guide

This repo is the **plugin**, not a wiki. It is almost entirely Markdown: commands, skills, reference
files and templates that get copied into other repos. The one piece of code is
[scripts/llm-wiki](scripts/llm-wiki), the deterministic lint CLI.

## Testing

Run the tests before declaring any change to plugin content done. They are free, instant, and need
no model or API key.

```bash
./tests/generate-defect-fixtures.sh   # rebuild the broken-wiki fixtures (gitignored)
./tests/test-plugin-validate.sh       # manifests, version sync, frontmatter, cited paths
./tests/test-docs-consistency.sh      # README tables vs what actually ships
./tests/test-structure.sh             # the lint CLI over templates/wiki and all nine examples
./tests/test-lint-cli.sh              # every lint check fires on its defect fixture
./tests/test-copilot-parity.sh        # each command has a prompt covering the same checks
./tests/test-token-budgets.sh         # the plugin's own always-loaded text stays small
```

CI runs the same set plus a Copilot installer smoke test
([.github/workflows/plugin-tests.yml](.github/workflows/plugin-tests.yml)).

## The parity rule

**A change to a check list in `commands/*.md` is not done until the matching
`templates/copilot-prompts/llm-wiki-*.prompt.md` carries it.**

Copilot users reach the same knowledge base through different plumbing — prompt files instead of
slash commands, a repository instructions file instead of a skill — and nothing in the repo links
the two. The data-source and contract-drift checks were added to `commands/lint.md` and silently
never reached Copilot. `test-copilot-parity.sh` exists so that cannot happen again; if it fails,
fix the prompt rather than relaxing the test.

Two constraints on prompt files specifically:

- They land in a *target* repo, where `${CLAUDE_PLUGIN_ROOT}` does not exist. Where a command defers
  to a reference file, the prompt must inline the one-line rule instead of citing a path.
- They are pasted into chat context, so keep them tighter than the commands. Condense; don't copy.

## Where things live

| Path | What it is |
|------|-----------|
| `commands/` | The `/llm-wiki:*` slash commands (Claude Code) |
| `skills/llm-wiki/` | The always-on maintainer skill + its lazily-loaded `references/` |
| `skills/data-sources/` | The independently-triggering data-source recognizer |
| `templates/wiki/` | Pages copied into a target repo's `.llm-wiki/` |
| `templates/pointers/` | The managed blocks for `CLAUDE.md` / `AGENTS.md` / `copilot-instructions.md` |
| `templates/copilot-prompts/` | The `/llm-wiki-*` prompt files (Copilot) |
| `templates/copilot-instructions/` | Path-scoped `applyTo:` instructions per stack |
| `examples/` | Nine worked reference wikis — users copy these, so they must stay valid |
| `scripts/llm-wiki` | The deterministic lint CLI |
| `scripts/install-copilot.{sh,ps1}` | Install the Copilot integration without Claude Code |

## Two version numbers, and they are not the same

- **Plugin version** (`.claude-plugin/plugin.json` + both fields in `marketplace.json`) moves every
  release.
- **`CURRENT_CONTRACT`** (`skills/llm-wiki/references/wiki-contract.md`, mirrored in
  `scripts/llm-wiki` and `templates/wiki/index.md`) moves **only** when the wiki *layout* changes,
  so an installed wiki is never reported stale for a release that didn't change its shape.

`test-docs-consistency.sh` enforces that all the copies of each agree.

## Conventions

- Shell scripts are LF, PowerShell is CRLF — `.gitattributes` handles it. The extensionless
  `scripts/llm-wiki` is listed there explicitly.
- `scripts/llm-wiki` is **stdlib-only Python 3.8+**. It gets copied into arbitrary target repos, so
  a dependency would break the Copilot install. `test-plugin-validate.sh` enforces this.
- Avoid GNU-only flags in test scripts (`sed -i` without a suffix, `realpath`) — they run on
  Windows/Git Bash and macOS as well as CI.
- Release process: [.claude/release-checklist.md](.claude/release-checklist.md). Note its
  authorization gate — never bump a version or publish a release without being asked to, for that
  release.
