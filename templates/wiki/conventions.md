---
updated: YYYY-MM-DD
covers: [conventions, patterns]
status: draft
---

# Conventions

How to write code that matches this repo, so agents reuse existing patterns instead of inventing new
ones. Derive these from the actual code, not from generic best practice.

## Naming & structure

- _File / module / test naming conventions._
- _Where new code of each kind goes (e.g. "endpoints in `src/routes/`, one file per resource")._
- _Project layout: e.g. TS `src/` + build to `dist/`; Python `src/`-layout vs flat `<pkg>/`; SQL
  `<Schema>/<ObjectType>/<Name>.sql` (one object per file) or run-ordered `NN_<kind>/` folders; R
  functions in `R/`, pipeline in `_targets.R`, reports in `reports/`; Slurm scripts in `slurm/`._

## Tooling & config locations

- **Package manager / toolchain:** _<e.g. pnpm — `pnpm add`; or uv — `uv add`, `uv run <tool>`; or `dotnet build` + `sqlpackage`>_
- **Runtime version:** _<e.g. `.nvmrc` → Node 20; `.python-version` → 3.12; `<DSP>` in `.sqlproj` → SQL Server 2022; compose `postgres:16`; `renv.lock` → R 4.4>_
- **Lint / format:** _<config file, e.g. `eslint.config.js` + `.prettierrc` or `biome.json`; `[tool.ruff]` in `pyproject.toml`; `.pre-commit-config.yaml`; `.sqlfluff`; `.lintr`>_
- **Types / modules:** _<e.g. TS `tsconfig.json`, `strict: true`, ESM (`"type": "module"`); or mypy `[tool.mypy]` — annotate new code>_
- **Environments / secrets:** _<e.g. `.env.example` lists required vars; publish profiles hold no passwords>_

<!-- T-SQL repos: add a "## T-SQL" section — object & constraint naming, schema ownership, proc shape
     (SET NOCOUNT ON / XACT_ABORT, TRY…CATCH + THROW, error-number ranges), no SELECT *, schema-
     qualified names, $(SqlCmdVar) cross-DB refs, idempotency rules for scripts (CREATE OR ALTER),
     "never hand-write ALTER in an SSDT project". Derive from the code; delete this comment. -->

<!-- PostgreSQL repos: add a "## PostgreSQL" section — snake_case, schema-qualified vs search_path,
     timestamptz / text / identity types, constraint & index naming, idempotency idioms per script
     kind, one-shot change mechanism, function volatility + SECURITY DEFINER search_path, ERRCODEs,
     roles/grants/RLS, online-DDL rules (CONCURRENTLY, NOT VALID, lock_timeout). -->

<!-- R repos: add a "## R" section — tidyverse vs base, |> vs %>%, pkg::fn vs library(), roxygen
     tags, here::here() paths, raw vs derived data, seeds, renv::snapshot() after dependency changes. -->

<!-- Slurm repos: add a "## Slurm" section — script header order, default resources per job kind,
     partitions/accounts, module versions, log naming (%x_%A_%a), set -euo pipefail, scratch vs
     project storage, array size / throttle limits, test-small-first rule. -->


## Patterns to reuse

- _<Pattern>_ — _where it's defined (`<path>`) and when to use it._
- _Shared utilities/helpers agents should prefer over rolling their own (`<path>`)._
- _Config/DB access singletons to reuse (e.g. typed config module, DB session/client)._

## Error handling

- _How errors are raised, wrapped, logged, surfaced to callers._

## Testing

- _Framework and how to run: `<command>`._
- _Where tests live, naming, and the expected style (unit/integration/e2e)._
- _Whether new code is expected to ship with tests._

## Do / don't

- ✅ _<a thing this repo consistently does>_
- ❌ _<a thing to avoid — e.g. "don't import across module boundary X→Y directly">_
