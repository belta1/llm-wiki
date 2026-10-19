# Contributing to the llm-wiki plugin

This repo **is the plugin**. It has no `.llm-wiki/` of its own, so there is nothing here for you to
read an index from — that directory appears in repos the plugin is installed into. Almost everything
here is Markdown that gets copied elsewhere; the one piece of code is `scripts/llm-wiki`.

## Run the checks before saying a change is done

They need no model and no API key, and finish in seconds:

```bash
./tests/generate-defect-fixtures.sh   # rebuild the broken-wiki fixtures (gitignored)
./tests/test-plugin-validate.sh       # manifests, version sync, frontmatter, cited paths
./tests/test-docs-consistency.sh      # README tables vs what actually ships
./tests/test-structure.sh             # the lint CLI over templates/wiki and all nine examples
./tests/test-lint-cli.sh              # every lint check fires on its defect fixture
./tests/test-copilot-parity.sh        # each command has a prompt covering the same checks
./tests/test-token-budgets.sh         # the plugin's own always-loaded text stays small
```

CI runs the same set on push and pull request.

## Using the lint CLI here

In this repo the CLI is at `scripts/llm-wiki`, not `.llm-wiki/bin/llm-wiki` — the latter is where the
installer puts a copy inside a *target* repo. Point it at the wikis this repo ships:

```bash
python3 scripts/llm-wiki lint examples/node-app/.llm-wiki --no-catalog
python3 scripts/llm-wiki lint templates/wiki --scaffold --no-catalog   # --scaffold for placeholders
python3 scripts/llm-wiki lint examples/node-app/.llm-wiki --json       # machine-readable
```

On Windows the interpreter is `python`, not `python3`. Always pass `--no-catalog` in this repo: the
catalog is a developer's own file under `~/.claude/`, and tests must never read it.

`--scaffold` means "this is template or example material, not an installed wiki", and skips the
required-page, link and orphan checks — `templates/wiki/` links to module pages that only exist once
copied into a real repo.

## The parity rule

**A change to a check list in `commands/*.md` is not done until the matching
`templates/copilot-prompts/llm-wiki-*.prompt.md` carries it.**

Copilot users reach the same knowledge base through different plumbing, and nothing in the repo links
the two, so a check added on the Claude side can silently never reach Copilot — which is exactly what
happened to the data-source and contract-drift checks. `test-copilot-parity.sh` exists so it cannot
happen again. If it fails, fix the prompt; don't relax the test.

Two constraints specific to prompt files:

- They land in a *target* repo, where `${CLAUDE_PLUGIN_ROOT}` does not exist. Where a command defers
  to a reference file, the prompt must inline the one-line rule rather than cite a path.
- They are pasted into chat context, so keep them tighter than the commands. Condense, don't copy.

## Conventions

- `scripts/llm-wiki` is **stdlib-only Python 3.8+**. It gets copied into arbitrary repos, so a
  dependency would break the install. `test-plugin-validate.sh` enforces this.
- Avoid GNU-only flags in scripts (`sed -i`, `realpath`): these run on Windows/Git Bash and macOS as
  well as CI. `sed -i` also rewrites line endings — use `tests/replace-once.py` when editing a file
  in place.
- Shell is LF, PowerShell is CRLF; `.gitattributes` handles it.
- Two version numbers, and they are not the same thing: the **plugin version** (three fields, all
  must match) moves every release; **`CURRENT_CONTRACT`** moves only when the wiki *layout* changes.
  Bumping the contract has six edit sites — see *Bumping the contract* in
  `skills/llm-wiki/references/wiki-contract.md`.
- Never bump a version or publish a release unless asked to for that release. See
  `.claude/release-checklist.md`.

More detail for any of the above is in `CLAUDE.md`, which covers the same ground.
