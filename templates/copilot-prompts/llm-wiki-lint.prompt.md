---
description: Health-check this repo's .llm-wiki/ — find stale claims, orphan pages, missing module pages, broken links, leaked credentials, contract drift, and drift from the code.
---

# Lint the LLM Wiki

Audit `.llm-wiki/` for health and drift, report findings, then fix the safe ones (ask before larger
rewrites).

## Step 0 — run the deterministic checks first

If `.llm-wiki/bin/llm-wiki` exists, run it in the terminal before reading anything:

```
python3 .llm-wiki/bin/llm-wiki lint
```

On Windows the interpreter is `python`, not `python3`.

It reports frontmatter problems, the contract stamp, missing pages, broken links and anchors, orphan
pages, oversized pages, bad log entries, leaked credentials and data-source tier violations — checks
1, 3, 5, 8, 9a, 9c, 9d and 10 below — in one cheap pass. Start from its output and spend your own
reading on the checks it cannot do: the ones that need the code read (2, 4, 6, 7, 7b, 9b).

If the script is absent, or the terminal is unavailable (Ask mode, no Python), do every check below
yourself. Never skip a check because the script was missing.

## Checks

1. **Broken links** — links between pages, and file paths cited in the index/module pages, that no
   longer exist.
2. **Stale claims** — pages whose content contradicts the current code; spot-check a few busy areas.
3. **Orphan pages** — pages with no inbound link from `index.md` or elsewhere.
4. **Missing module pages** — significant subsystems with no `modules/<name>.md` and no index row.
5. **Index accuracy** — rows pointing at moved/deleted/renamed files.
6. **Stale commands** — recipe/Stack commands that no longer match the tooling (package manager or
   lockfile changed, a script was renamed/removed, a workspace package added/removed) or that differ
   from what CI runs (`.github/workflows/`, `azure-pipelines.yml` — CI is the ground truth). T-SQL:
   recipes naming a `.sqlproj`, publish profile, SQLCMD variable, SSIS package or Agent job that no
   longer exists; a `deploy.sql` run list that omits scripts on disk; `ALTER TABLE` recipes in a
   state-based `.sqlproj`. PostgreSQL: a `\ir` run list out of sync with disk, `psql` recipes without
   `-v ON_ERROR_STOP=1`, T-SQL syntax in a Postgres recipe (or vice versa). R: targets/reports named
   in recipes that no longer exist. Slurm: job tables whose resources, partitions or modules no
   longer match the scripts' `#SBATCH` / `module load` lines.
7. **Stale database objects** — `schema.object` names cited in the wiki that no longer exist in the
   source, or whose parameters/result columns/error numbers changed.
8. **Structure** — pages missing frontmatter or grown too large (split/link out). `wiki_contract:` is
   legitimate **on `index.md` only** — don't flag it there, and never copy it onto another page.
   `log.md` and `README.md` carry no frontmatter by design.
9. **Data sources** — both tiers: the repo page `.llm-wiki/data-sources.md` and the user-global
   catalog `~/.claude/llm-wiki/data-sources.md` (Windows:
   `%USERPROFILE%\.claude\llm-wiki\data-sources.md`), joined by source **Name**.
   - **9a Secret leak** — the one that matters most. Any password/token/key **value** in either tier,
     or a credential inlined in a connection string in the repo's code or recipes (`PWD=…`,
     `Password=…` with a literal). Also flag presigned / SAS URLs (`?sig=…`, `X-Amz-Signature=…`) —
     the URL *is* the credential — API keys, and any service-account JSON key committed in-repo. The
     value must move to an env var / secret store, leaving only the env-var **name** behind.
   - **9b Catalog drift** — a named data source the repo's code connects to that is missing from the
     catalog, or a catalog entry whose driver / auth model / connect form no longer matches the code.
   - **9c Repo page drift** — a `Used by (code)` path or module link that no longer exists; a
     connection in the code with no row on the page; a row whose source the repo no longer touches.
   - **9d Two-tier consistency** — a page row marked `Catalog: yes` with no matching catalog row; a
     page row carrying driver / DSN / auth / credential-name detail, which belongs in the catalog,
     not the repo page (move it); a catalog entry whose `Used by:` omits this repo.
   - **9e Page presence** — the repo's code connects to external sources but there is no
     `data-sources.md` (suggest creating it, plus the `index.md` row); or the page still holds only
     placeholder rows (suggest deleting it along with its `index.md` links and `README.md` row).
   - **Threshold** — a connection is worth recording only when it is **external & named** (a real
     host, DSN, account, bucket, share or stable base URL), **durable & likely shared** across runs,
     and **load-bearing** for the repo's actual work. Never report telemetry or APM, package
     registries (PyPI, npm, CRAN), CI/container registries, OAuth/JWKS endpoints, `localhost` or
     compose services this repo owns, temp files, or repo-relative fixtures as missing sources.
10. **Contract drift** — `index.md`'s `wiki_contract:` is below the current level, or absent (a wiki
    that predates the stamp). The wiki is missing structure the current templates define. Report the
    level it's at and the fix: run **`/llm-wiki-upgrade`**. Don't enumerate the individual gaps here —
    that prompt diagnoses them.

## Output & fixing

Report findings grouped by check, most-impactful first, each with the file and a one-line fix. Then:

- **Apply safe fixes** — repair/remove broken links, correct index paths, add missing frontmatter,
  mark clearly-stale pages `status: stale`.
- **Propose (don't auto-apply) judgement fixes** — rewriting stale content, creating new module
  pages, resolving contradictions, adding or correcting data-source entries at either tier.
- **Never auto-remove a flagged secret** from source code, and never copy its value into the wiki.
  Report it and let a human move it to a secret store. Record it on the page as
  `⚠ inlined in <path>` under Gotchas.
- **Never fix contract drift here** — `/llm-wiki-upgrade` owns that backfill, so the logic lives in
  one place.
- Append a `log.md` entry: `## [<today>] lint | <summary of findings and fixes>`.
