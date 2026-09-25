---
description: Health-check this repo's .llm-wiki/ — find stale claims, orphan pages, missing module pages, broken links, and drift from the code.
---

# Lint the LLM Wiki

Audit `.llm-wiki/` for health and drift, report findings, then fix the safe ones (ask before larger
rewrites).

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
8. **Structure** — pages missing frontmatter or grown too large (split/link out).

## Output & fixing

Report findings grouped by check, most-impactful first, each with the file and a one-line fix. Then:

- **Apply safe fixes** — repair/remove broken links, correct index paths, add missing frontmatter,
  mark clearly-stale pages `status: stale`.
- **Propose (don't auto-apply) judgement fixes** — rewriting stale content, creating new module pages,
  resolving contradictions.
- Append a `log.md` entry: `## [<today>] lint | <summary of findings and fixes>`.
