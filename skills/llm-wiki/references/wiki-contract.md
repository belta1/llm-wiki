# Wiki contract versions

The **wiki contract** is the structural shape a `.llm-wiki/` is expected to have: which pages exist,
which hooks `index.md` carries, what the pointer blocks say. It is recorded in `index.md` frontmatter:

```yaml
---
updated: 2026-10-18
covers: [overview, navigation]
status: current
wiki_contract: 2
---
```

**`CURRENT_CONTRACT = 2`**

The contract is **not** the plugin version. `plugin.json` moves on every release — bugfixes, a new
stack in `stacks.md`, a reworded recipe. The contract number moves **only** when the table below
changes, so a wiki is never reported stale for a release that didn't change its layout.

`wiki_contract` lives on `index.md` and nowhere else. It is one key per wiki, not per page.

## Levels

| Contract | Layout |
|----------|--------|
| **1** | `index.md`, `architecture.md`, `conventions.md`, `glossary.md`, `recipes.md`, `modules/`, `log.md`, `README.md`. Pointer blocks with the read-index-first / keep-current contract. No data-source tier, no view. Retroactive — no wiki was ever stamped `1`, it is what an **unstamped** wiki is assumed to be. |
| **2** | Contract 1, plus: the optional `data-sources.md` page and its three `index.md` hooks + `README.md` Layout row; the optional `## Data sources used` section on module pages; the `_Humans:_` view line in all three pointer blocks; `.llm-wiki/view/` in `.gitignore`. |

## Deltas

What `/llm-wiki:upgrade` applies to move a wiki from one level to the next. Each item is applied
**idempotently** — check whether it's already there before writing, because a wiki may have been
partly updated by hand or by `/llm-wiki:update`.

Items 2-4 are **presence of a link, not a wording**. Wikis phrase these differently and the two
reference shapes below disagree with each other on purpose. Test each by asking "does this section
contain a link to `data-sources.md`?" and, when adding one, follow the shape the wiki being upgraded
already uses — not the template's.

### 1 → 2

| # | Change | Target shape |
|---|--------|--------------|
| 1 | `data-sources.md` page, **only if** the repo connects to ≥1 external source passing the threshold | `${CLAUDE_PLUGIN_ROOT}/templates/wiki/data-sources.md`; filled example in `examples/python-analytics/.llm-wiki/data-sources.md` |
| 2 | a **Map**-table row reaching `data-sources.md` | `templates/wiki/index.md` Map table |
| 3 | a **Where to start by task** line reaching `data-sources.md` | `templates/wiki/index.md` (phrased "Read / write an external source"); `examples/python-analytics/…/index.md` phrases it "Add a data source" |
| 4 | an entry under **`## Also see`** reaching `data-sources.md` | a bullet in `templates/wiki/index.md`; an inline `·`-joined line in `examples/python-analytics/…/index.md` |
| 5 | `README.md` Layout-table row for `data-sources.md` | `templates/wiki/README.md` Layout table |
| 6 | `README.md` maintenance line names `:view` / `:upgrade` and `/llm-wiki-view` | `templates/wiki/README.md` closing paragraph |
| 7 | `## Data sources used` section on module pages that read or write external data | `templates/wiki/modules/_TEMPLATE.md` |
| 8 | the managed blocks in `CLAUDE.md` / `AGENTS.md` / `.github/copilot-instructions.md` reference `.llm-wiki/view/index.html` (wording differs per file — `_Humans:_ …` vs `For people (not Copilot): …`) | `templates/pointers/` |
| 9 | `.llm-wiki/view/` in `.gitignore`, under a `# llm-wiki` comment | same rule as `/llm-wiki:view` step 4 |
| 10 | `.github/prompts/` has every `llm-wiki-*.prompt.md` (notably `view` and `upgrade`) | `templates/copilot-prompts/` |
| 11 | `log.md`'s format line names the `upgrade` op: `<init|update|lint|upgrade>` | `templates/wiki/log.md` |

An existing `.llm-wiki/view/index.html` is **not** a delta: it's a gitignored build artifact, and
`/llm-wiki:view` only swaps its JSON blob, so one generated before contract 2 keeps its old CSS (and
would render an `upgrade` log entry without a marker colour). If the repo has a view, delete it so
`/llm-wiki:view` recopies the current template — offer that rather than regenerating unprompted.

Items 1, 2, 3, 4, 5 and 7 are **conditional on the repo connecting to something** — a repo that
connects to nothing is fully at contract 2 without them, and the `data-sources.md` row must be absent
from `README.md`'s Layout table. Items 6, 8, 9 and 10 apply to every repo.

## Bumping the contract

When the wiki layout next changes:

1. Add a row to **Levels** describing the new layout.
2. Add a `N → N+1` **Deltas** table — one row per structural change, each naming the template that
   holds the target shape.
3. Raise `CURRENT_CONTRACT` above.
4. Update `wiki_contract:` in `templates/wiki/index.md` so fresh `init`s are born current.

`/llm-wiki:upgrade` reads this file rather than hard-coding the changes, so those four edits are the
whole job — the command itself does not change.
