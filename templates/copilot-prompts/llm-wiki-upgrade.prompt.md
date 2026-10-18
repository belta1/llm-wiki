---
description: Retrofit this repo's existing .llm-wiki/ to the current structural contract — backfill missing pages, index hooks, pointer blocks and gitignore entries, then stamp the contract version.
---

# Upgrade the LLM Wiki to the current contract

This repo already has a `.llm-wiki/`, but it may predate parts of the current layout. Bring its
**structure** up to date. (If there is no `.llm-wiki/`, run the `llm-wiki-init` prompt instead.)

This is about structure, not content. Whether the pages still *describe the code correctly* is the
`llm-wiki-lint` prompt's job; reacting to code changes is `llm-wiki-update`'s.

## Steps

0. **Ask the deterministic check first.** If `.llm-wiki/bin/llm-wiki` exists, run:

   ```
   python3 .llm-wiki/bin/llm-wiki lint
   ```

   It reports the level directly as `contract-stale` (with the number), `contract-missing` (no stamp)
   or `contract-ahead` (built by a newer plugin), so step 1 needs no file reading. It also flags
   `contract-misplaced` — the stamp copied onto a page other than `index.md`, which is always wrong
   and which you should fix while you are here. If the script or Python is unavailable, do step 1 by
   hand. On Windows the interpreter is `python`, not `python3`.

1. **Read the stamp.** Check `index.md`'s YAML frontmatter for `wiki_contract:`.
   - **`wiki_contract: 2`** — already current. Say so and stop.
   - **lower than 2** — apply only the changes listed below that are actually missing, then restamp.
   - **absent** — the wiki predates the stamp. Diagnose everything below by content.

1b. **Tooling check — do this at every level, including "already current".** These are not contract
   items, so a wiki whose stamp is already correct will never acquire them any other way. Report each
   as present or missing, offer to add it, and leave `wiki_contract` alone either way:
   - `.llm-wiki/bin/llm-wiki` — the deterministic lint CLI that `/llm-wiki-lint` starts from. If it
     is missing, the llm-wiki installer adds it (`scripts/install-copilot.sh <repo>`); mention that
     rather than trying to write the script yourself.
   - `.github/prompts/llm-wiki-*.prompt.md` — there should be one per command: `init`, `update`,
     `lint`, `upgrade`, `view`. A pointer block that names a prompt whose file is absent sends
     Copilot after a command that does not exist.

   Never report the wiki as *stale* over these. A stamp means its layout is current, and that stays
   true whether or not the helpers are installed.

2. **Check each of these, and report present / missing:**
   - **`data-sources.md`** — missing, *and* this repo's code connects to at least one external data
     source that is external & named, durable & likely shared, and load-bearing. (A repo that
     connects to nothing correctly has no such page. Never count `localhost`, temp files,
     repo-relative fixtures, package registries or telemetry endpoints.)
   - **`index.md` hooks** — three sections should reach `data-sources.md`: the **Map** table, **Where
     to start by task**, and **`## Also see`**. Judge each by whether a link to `data-sources.md` is
     present in that section, **not** by matching a label — wikis word the router line differently
     ("Add a data source" vs "Read / write an external source") and `## Also see` may be a bullet list
     or one `·`-joined line. Present in different words still counts as present.
   - **`README.md`** — a `data-sources.md` row in the Layout table; whether the closing maintenance
     line still names only `/llm-wiki:init`, `:update`, `:lint`.
   - **Module pages** — any `modules/<name>.md` whose key files read or write an external source but
     which has no `## Data sources used` table.
   - **Pointer files** — whether the `<!-- BEGIN llm-wiki --> … <!-- END llm-wiki -->` block in
     `.github/copilot-instructions.md` (and `CLAUDE.md` / `AGENTS.md` if present) references
     `.llm-wiki/view/index.html`. Judge by that reference, not by a phrase — the files word it
     differently ("For people (not Copilot):" vs "_Humans:_").
   - **`.github/prompts/`** — missing any `llm-wiki-*.prompt.md`, notably `llm-wiki-view`.
   - **`.gitignore`** — no `.llm-wiki/view/` entry.
   - **Frontmatter** — pages missing `updated` / `covers` / `status`. `log.md` and `README.md` have
     none by design; leave them alone.

3. **Apply the mechanical fixes:** add the `index.md` hooks — **matching the shape this wiki already
   uses** for its Map rows, router lines and `## Also see` (append to the `·`-joined line if that's its
   form; add a bullet if it's a list), with **this repo's real paths**, not placeholders, and the Map
   row slotted where it fits the table's existing grouping rather than appended at the end — plus the
   `README.md` Layout row and refreshed maintenance line, the `.gitignore` entry under a `# llm-wiki`
   comment, the missing frontmatter keys, and the view line in each pointer's managed block. Edit pointers **only between the BEGIN/END markers** — never touch the surrounding
   content.

4. **Create `data-sources.md` if warranted,** from the repo's own code: real source names, the real
   code paths touching each, direction, and the objects/prefixes/topics used. Mark each row
   `Catalog: yes` or `no (repo-local)`. Keep driver / DSN / auth / credential detail **off** the page.
   **Never record a secret** — a presigned or SAS URL *is* the credential. If a credential is inlined
   in code, note it under Gotchas as `⚠ inlined in <path>` and tell me; don't rewrite my source.
   If the repo connects to nothing, skip the page and remove the hooks from step 3.

5. **Stamp and log.** Set `wiki_contract: 2` in `index.md`'s frontmatter, bump its `updated:`, and
   append to `log.md`: `## [<today>] upgrade | contract <from> → 2; <what was backfilled>`.

6. **Report** what changed, and what you left for me to decide — notably whether to fill the
   `## Data sources used` tables, and whether to build the HTML view with the `llm-wiki-view` prompt.

Running this twice must change nothing the second time.
