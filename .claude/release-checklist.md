# llm-wiki Release Checklist

Process for testing and shipping a new version of the llm-wiki plugin.

## User authorization gate

- Never bump the version, create or push a tag, or publish a GitHub release without explicit user
  authorization **for that release, in the current task**.
- A request to build, fix, test, commit, or prepare release notes is **not** permission to release.
  Stop after the tested deliverable and present the proposed version and consolidated notes for
  approval.
- Batch adjacent fixes for one feature tranche into one proposed release. Don't ship a succession of
  patch releases unless the user asks.

## 1. Version bump

Three fields must match, or `tests/test-plugin-validate.sh` fails:

- `.claude-plugin/plugin.json` → `version`
- `.claude-plugin/marketplace.json` → `metadata.version`
- `.claude-plugin/marketplace.json` → `plugins[0].version`

If the **wiki layout** changed (not just the plugin), that's a separate number: bump
`CURRENT_CONTRACT` in `skills/llm-wiki/references/wiki-contract.md`, add its deltas table, update
`templates/wiki/index.md`'s stamp, and update `CURRENT_CONTRACT` in `scripts/llm-wiki`.
`tests/test-docs-consistency.sh` checks all four agree. Most releases do **not** move the contract —
a wiki should never be reported stale for a release that didn't change its layout.

## 2. Test

```bash
./tests/generate-defect-fixtures.sh
./tests/test-plugin-validate.sh
./tests/test-docs-consistency.sh
./tests/test-structure.sh
./tests/test-lint-cli.sh
./tests/test-copilot-parity.sh
./tests/test-token-budgets.sh
```

All seven are free and deterministic — no model, no API key. CI runs the same set.

If `test-token-budgets.sh` reports OVER, decide deliberately: shrink the text, or raise that
metric's `baseline` **and** `max` in `tests/budgets/token-budgets.json` in the same commit as the
growth, so the diff shows what got bigger.

## 3. Smoke-test both surfaces

A packaging change that works on the primary surface routinely breaks the other one, so test both.

**Claude Code** — in a scratch repo:

- `/llm-wiki:init` → wiki is created, three pointer files written
- `/llm-wiki:lint` → it runs `scripts/llm-wiki` first and reports its findings before its own
- `/llm-wiki:view` → `.llm-wiki/view/index.html` builds and opens
- `/llm-wiki:upgrade` on a wiki with the stamp removed → reports contract 1 and backfills

**GitHub Copilot** — in a second scratch repo:

```bash
./scripts/install-copilot.sh /tmp/scratch --scaffold --view
```

- all five `.github/prompts/*.prompt.md` land, plus `.llm-wiki/bin/llm-wiki`
- re-run it: every file reports `ok`/`updated`, nothing `created`, and
  `.github/copilot-instructions.md` still has exactly one managed block
- in VS Code Copilot Chat (Agent mode) run `/llm-wiki-lint` → it runs the local CLI
- switch to Ask mode and run it again → it still produces a sensible report without the CLI
- `--no-cli` → no `.llm-wiki/bin/llm-wiki` is written

**The parity bar:** plant `PWD=hunter2SuperSecret` in a scratch `.llm-wiki/data-sources.md` and
confirm **both** surfaces flag it. If only one does, the release is not ready.

On Windows, also run `scripts\install-copilot.ps1` against a scratch repo and confirm it writes
UTF-8 **without** a BOM and accepts the same flags as the bash script.

## 4. Ship

```bash
git add -A
git commit -m "Bump to vX.Y.Z"
```

Then tag and release only after the authorization gate above is satisfied.

## 5. Post-ship

- Add a `## Changelog` entry at the top of `README.md`, single-paragraph form, bold lead-in.
- Keep the last 5-6 entries; drop the oldest when adding a new one.
- Commit separately: `"Update README with vX.Y.Z changelog"`.

## Notes

- Marketplace plugin name: `llm-wiki`; commands are `/llm-wiki:<cmd>`; Copilot prompts are
  `/llm-wiki-<cmd>`.
- The repo is its own single-plugin marketplace (`marketplace.json` → `source: "./"`), so there is no
  separate packaging step.
- Defect fixtures under `tests/fixtures/defects/` are generated and gitignored — never commit them.
