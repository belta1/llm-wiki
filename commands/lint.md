---
description: Health-check the .llm-wiki/ knowledge base — find stale claims, orphan pages, missing module pages, broken links, and drift from the code. Report, then optionally fix.
argument-hint: "[optional: 'fix' to apply safe fixes automatically]"
---

# /llm-wiki:lint

Audit the repo's `.llm-wiki/` for health and drift. Mode: $ARGUMENTS (if this contains "fix", apply
the safe, unambiguous fixes after reporting; otherwise report only and ask before changing anything).

Requires an existing `.llm-wiki/`. If there is none, suggest `/llm-wiki:init`.

## Checks

1. **Broken cross-links** — links between wiki pages, and paths cited in the index/module pages, that
   point at files or headings that no longer exist.
2. **Stale claims** — pages whose `updated:` date lags well behind the code they describe, or whose
   content contradicts the current code. Spot-check a few high-traffic areas against the source.
3. **Orphan pages** — wiki pages with no inbound links from `index.md` or any other page.
4. **Missing module pages** — significant source subsystems that have no `modules/<name>.md` and no
   index row.
5. **Index accuracy** — index rows pointing at moved/deleted/renamed files.
6. **Convention drift** — `conventions.md` claims that the current code no longer follows.
7. **Stale recipe commands** — recipe/Stack commands that no longer match the detected tooling: the
   package manager or lockfile changed (e.g. `package-lock.json` → `pnpm-lock.yaml`, `requirements.txt`
   → `uv.lock`), a referenced `package.json` script or `pyproject.toml` tool was renamed/removed, or
   a workspace package was added/removed. Check against
   `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/stacks.md`.
   - **CI drift:** recipe commands that differ from what CI runs (`.github/workflows/`,
     `azure-pipelines.yml`) — CI is the ground truth.
   - **T-SQL drift:** recipes naming a `.sqlproj`, publish profile, SQLCMD variable, SSIS package,
     or Agent job that no longer exists; a script repo whose run list (`deploy.sql` `:r` lines) omits
     scripts present on disk; `ALTER TABLE` recipes in a state-based SSDT project.
   - **PostgreSQL drift:** a `deploy.sql` `\ir` run list that omits (or names missing) scripts on
     disk; `psql` recipes without `-v ON_ERROR_STOP=1`; recipes naming a service, variable, role or
     `pg_cron` job that no longer exists; T-SQL syntax in a recipe for a Postgres repo (or vice versa).
   - **R drift:** recipes naming targets no longer in `_targets.R`, removed Quarto files, or a
     dependency manager the repo no longer uses (e.g. `renv::restore()` with no `renv.lock`).
   - **Slurm drift:** recipes/job tables naming `*.sbatch` scripts, partitions, accounts or module
     versions that no longer match the job scripts' `#SBATCH` / `module load` lines.
7b. **Stale database objects** — `schema.object` names cited in pages (contract tables, Database
   objects tables, glossary) that no longer exist in the source (`CREATE … <schema>.<name>`, incl.
   `CREATE OR REPLACE FUNCTION`), or whose parameters/result columns/error numbers/`ERRCODE`s
   changed.
8. **Structure** — pages missing frontmatter or exceeding the size budgets in
   `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/page-formats.md`. `wiki_contract:` is a
   legitimate key **on `index.md` only** — don't flag it as unexpected there, and never copy it onto
   another page. `log.md` and `README.md` carry no frontmatter by design; don't flag or add it.
9. **Data sources** — both tiers: the user-global catalog `~/.claude/llm-wiki/data-sources.md` (if
   present) and the repo page `.llm-wiki/data-sources.md` (if present).
   - **9a Secret leak** — any password/token/key *value* in either tier, or a credential inlined in a
     connection string in the repo's code or recipes (e.g. `PWD=…`, `Password=…` with a literal). Also
     flag presigned / SAS URLs (`?sig=…`, `X-Amz-Signature=…`) — the URL *is* the credential — API
     keys, and any service-account JSON key committed in-repo. The value must move to an env var /
     secret store, leaving only the env-var name behind.
   - **9b Global catalog drift** — a named data source the repo's code connects to that is **missing**
     from the catalog, or a catalog entry whose driver / auth model / connect form no longer matches
     the code.
   - **9c Repo page drift** — a `Used by (code)` path or module link on `data-sources.md` that no
     longer exists; a connection in the code with no row on the page; a row whose source the repo no
     longer touches; a `Data sources used` table on a module page that contradicts the page.
   - **9d Two-tier consistency** — a page row marked `Catalog: yes` with no matching catalog row
     (upsert it); a page row carrying driver / DSN / auth / credential-name detail that belongs in the
     catalog (a tier violation — move it); a catalog entry whose `Used by:` omits this repo.
   - **9e Page presence** — the repo's code connects to external sources but there is no
     `data-sources.md` (suggest creating it from the template, plus the `index.md` row); or
     `data-sources.md` still holds only the template's placeholder rows (suggest deleting it along
     with its `index.md` links and the `README.md` Layout row).
   See `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/data-sources.md` (tiers, formats, security)
   and `.../data-source-detection.md` (the threshold — don't report telemetry hosts, package
   registries, `localhost` or repo-relative fixtures as missing sources).
10. **Contract drift** — `index.md`'s `wiki_contract:` is **below** `CURRENT_CONTRACT` in
   `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/wiki-contract.md`, or **absent** (a wiki that
   predates the stamp). The wiki is missing structure the current templates define — pages, `index.md`
   hooks, the pointer blocks' view line, the `.gitignore` entry. Report the level it's at and the fix:
   run `/llm-wiki:upgrade`. Don't enumerate the individual gaps here — that command diagnoses them.

## Output

Report findings grouped by check, most-impactful first, each with the file and a one-line fix
suggestion. Also suggest new pages/recipes worth adding and gaps worth investigating.

## Fixing

- **Safe fixes** (apply when in "fix" mode): repair/remove broken links, correct index paths, add
  missing `status`/`updated` frontmatter, mark clearly-stale pages `status: stale`.
- **Judgement fixes** (propose, don't auto-apply): rewriting stale content, creating new module
  pages, resolving contradictions, adding/correcting data-source entries at either tier — these need the code
  read carefully; do them like `/llm-wiki:update`. **Contract drift (check 10) is never fixed here** —
  report it and let `/llm-wiki:upgrade` do it, so the backfill logic lives in one place. **Never** auto-remove a flagged secret from source
  code; report it and let the human move it to a secret store.
- Append a `log.md` entry: `## [<today>] lint | <summary of findings and fixes applied>`.
