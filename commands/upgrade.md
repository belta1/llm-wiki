---
description: Bring an existing .llm-wiki/ up to the current structural contract — backfill missing pages, index hooks, pointer blocks and gitignore entries, then stamp the contract version.
argument-hint: "[optional: 'apply' to make the changes without confirming each]"
---

# /llm-wiki:upgrade

Retrofit this repo's `.llm-wiki/` to the layout the current plugin expects. Mode: $ARGUMENTS (if this
contains "apply", make the mechanical changes after reporting; otherwise report first and ask).

Requires an existing `.llm-wiki/`. If there is none, suggest `/llm-wiki:init`.

This command syncs the wiki with the **templates** — its structure. It does not assess whether page
*content* still matches the code; that's `/llm-wiki:lint` (drift) and `/llm-wiki:update` (code changes).

## Steps

0. **Read the stamp.** Look for `wiki_contract:` in `index.md`'s frontmatter and compare it with
   `CURRENT_CONTRACT` in `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/wiki-contract.md`:
   - **equal** — report "already at contract N" and **stop**. Nothing else to read.
   - **lower** — skip step 1. Apply only the deltas that file lists between the wiki's level and
     current, idempotently (check each is absent before writing — a wiki may have been partly fixed by
     hand or by `/llm-wiki:update`). Then go to step 5.
   - **absent** — the wiki predates the stamp. Continue to step 1 and diagnose by content.
   - **higher** than current — the wiki was built by a newer plugin. Say so and stop; don't downgrade.

1. **Detect drift by content** (unstamped wikis only). Compare against
   `${CLAUDE_PLUGIN_ROOT}/templates/`, and report each as present / missing / partial:
   - **`data-sources.md`** — absent, *and* the repo's code connects to at least one external source
     passing the threshold in `references/data-source-detection.md` (external & named, durable &
     likely shared, load-bearing). A repo that connects to nothing correctly has no page.
   - **`index.md` hooks** — three places should reach `data-sources.md`: a row in the **Map** table,
     a line in **Where to start by task**, and an entry under **`## Also see`**. Detect each by
     **whether a link to `data-sources.md` is present in that section**, not by matching a label.
     Real wikis word these differently (a router line may read "Add a data source" rather than "Read /
     write an external source") and `## Also see` may be a bullet list *or* a single `·`-joined line.
     A hook that's present in a different wording is **present** — don't add a second one.
   - **`.llm-wiki/README.md`** — the `data-sources.md` row in the Layout table (it should be absent
     when the repo connects to nothing, present otherwise); and whether the closing maintenance line
     omits `:upgrade` / `:view`. If the file was hand-rewritten, fix those two things and leave the
     rest of the prose alone.
   - **Module pages** — a `modules/<name>.md` whose key files touch an external source but which has
     no `## Data sources used` table.
   - **Pointer blocks** — the managed block in `CLAUDE.md`, `AGENTS.md` and
     `.github/copilot-instructions.md` not mentioning the human-only HTML view. Detect by whether the
     block references `.llm-wiki/view/index.html`, **not** by a literal phrase — the three templates
     word it differently (`_Humans:_ …` in `CLAUDE.md` and `AGENTS.md`, `For people (not Copilot): …`
     in the Copilot one). If a pointer file exists with no managed block at all, that counts as
     missing too.
   - **Copilot prompts** — `.github/prompts/` missing any `llm-wiki-*.prompt.md` (notably `view` and
     `upgrade`). Only relevant if the repo has a `.github/prompts/` or Copilot instructions at all.
   - **`.gitignore`** — no `.llm-wiki/view/` entry.
   - **`log.md`** — its format line still reads `<init|update|lint>` without `upgrade`.
   - **A pre-existing `.llm-wiki/view/index.html`** — a view generated before this contract keeps the
     old template's CSS (`/llm-wiki:view` only swaps the JSON blob). Don't regenerate it here; note it
     in step 4 so the user can delete it and re-run `/llm-wiki:view` against the current template.
   - **Frontmatter** — pages missing `updated` / `covers` / `status` per `references/page-formats.md`.
     `log.md` and `README.md` have none by design — don't flag or add them there.

2. **Apply the mechanical fixes.** These are unambiguous and safe:
   - Add the missing `index.md` hooks, **matching the shape this wiki already uses** — its own Map-row
     emphasis style, its own router-line phrasing, and its own `## Also see` form (append to the
     `·`-joined line if that's what it has, add a bullet if it's a list). The wiki's existing
     formatting wins over the template's; you are adding a row to *their* table, not importing ours.
     Put **this repo's real paths** in the Map row, never the template's placeholders, and slot the
     row where it fits the table's existing grouping (next to the other persistence/data rows, say)
     rather than appending it at the end.
     `${CLAUDE_PLUGIN_ROOT}/examples/python-analytics/.llm-wiki/index.md` shows one filled result (note
     its inline `## Also see` line); `${CLAUDE_PLUGIN_ROOT}/templates/wiki/index.md` shows another.
   - Add the `README.md` Layout row, and update its maintenance line to name `:view` and `:upgrade`
     and the `/llm-wiki-view` prompt.
   - Add `.llm-wiki/view/` to `.gitignore` under a `# llm-wiki` comment if that comment isn't there
     already — the same rule `/llm-wiki:view` step 4 follows, so the two never fight.
   - Replace the three pointer managed blocks from `${CLAUDE_PLUGIN_ROOT}/templates/pointers/`.
     Replace **only** between `<!-- BEGIN llm-wiki -->` and `<!-- END llm-wiki -->`; preserve every
     line of the human's own content around it. If a pointer file exists with no managed block, insert
     one rather than overwriting the file.
   - Copy any missing `${CLAUDE_PLUGIN_ROOT}/templates/copilot-prompts/*.prompt.md` into
     `.github/prompts/`. These are plugin-owned — replacing them is fine.
   - Add missing frontmatter keys, dating `updated` from the page's last real edit if you can tell
     (`git log -1 --format=%ad --date=short -- <page>`), not today.
   - Update `log.md`'s format line to `<init|update|lint|upgrade>`.

3. **Create `data-sources.md` if warranted.** From
   `${CLAUDE_PLUGIN_ROOT}/templates/wiki/data-sources.md`, filled from a **repo-local scan only**:
   real source names, the real code paths that touch each, direction, and the objects/prefixes/topics
   used. Mark each row `Catalog: yes` or `no (repo-local)`. Keep connection detail — driver, DSN, auth
   model, credential names — **off** the page; that's the user-global catalog's tier. **Never record a
   secret**; a presigned/SAS URL is itself a secret. Flag any credential you find inlined in code
   under Gotchas as `⚠ inlined in <path>` and tell the user — never silently rewrite their source.

   **Do not write `~/.claude/llm-wiki/data-sources.md` in this step.** Upgrade stays inside the repo;
   the catalog is offered in step 4.

   If the repo connects to nothing, skip the page and remove the hooks step 2 added (Map row, router
   line, Also see entry, README row).

4. **Offer the judgement work — don't do it.** List, and ask about:
   - **full two-tier data-source detection** (`/llm-wiki:update`, or step 2 of `/llm-wiki:init`) —
     say plainly that it **writes outside this repo**, to `~/.claude/llm-wiki/data-sources.md`;
   - filling `## Data sources used` tables on the module pages flagged in step 1;
   - `/llm-wiki:view` to build the human-only HTML dashboard — or, if a pre-contract view already
     exists, to **delete** `.llm-wiki/view/` first so the current template is recopied;
   - `/llm-wiki:lint` for content drift, which this command deliberately doesn't assess.

   A declined offer does **not** block the stamp — these are optional by design, and `lint` catches a
   genuinely missing `data-sources.md` on its own (check 9e), by content.

5. **Stamp and log.** Set `wiki_contract: <CURRENT>` in `index.md`'s frontmatter and bump its
   `updated:`. Append to `log.md`:
   `## [<today>] upgrade | contract <from> → <to>; <what was backfilled>`
   (write `contract — → 2` when the wiki was unstamped).

6. **Report** what you changed, what you left for the user to decide, and anything you found that
   belongs to `lint` or `update` rather than here.

## Principles

- **Idempotent.** Running it twice changes nothing and adds no second log entry. The stamp makes the
  second run cheap — it stops at step 0.
- **Structure, not content.** Never rewrite a page's prose to "modernize" it. Missing scaffolding is
  this command's job; wrong claims are `lint`'s.
- **Never clobber human content.** Pointer files get block-scoped edits only; wiki pages get additions,
  not rewrites.
- **No secrets, no out-of-repo writes** without asking.
