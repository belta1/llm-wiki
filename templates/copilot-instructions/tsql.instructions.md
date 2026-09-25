---
applyTo: "**/*.sql"
description: T-SQL / SQL Server guidance from the llm-wiki knowledge base (installed by llm-wiki; re-running the installer replaces this file).
---

# T-SQL files in this repo

> If the `.llm-wiki/index.md` Stack block says this repo's SQL (or this folder's SQL) is
> **PostgreSQL**, ignore this file for those files.

Before editing SQL, open `.llm-wiki/index.md` and the module page for the schema or layer you're
touching — it lists the objects, who calls them, and the gotchas. Follow `.llm-wiki/conventions.md`
for naming, proc shape, and error numbers; use `.llm-wiki/recipes.md` for build / preview / deploy /
test commands. If the wiki and the code disagree, the code wins.

**Work out which deploy model this file belongs to first** (the index Stack block says):

- **State-based database project (`.sqlproj`)** — each file is the desired `CREATE` for one object.
  - Change a table by editing its `CREATE TABLE`; **never add `ALTER` statements** — the dacpac diff
    generates them at publish time.
  - **Renames** go through the project's refactorlog (IDE *Rename/Refactor*), not by editing names,
    or publish will drop and recreate the object.
  - Data changes (seed/reference data, backfills) belong in pre/post-deploy scripts and must be
    idempotent (`MERGE`, `IF NOT EXISTS`).
  - Preview what a publish will do (`sqlpackage /Action:Script`) before recommending a deploy.
- **Ordered script repo** — every script runs on every deploy, so it must be **idempotent**:
  `CREATE OR ALTER` for procs/views/functions, `IF OBJECT_ID(...) IS NULL` / `IF COL_LENGTH(...)
  IS NULL` guards for tables and columns, `MERGE` for data. Register new files in the run list
  (e.g. `:r` lines in `deploy.sql`) in dependency order.

**General T-SQL rules** (unless `.llm-wiki/conventions.md` says otherwise):

- Schema-qualify every object (`Sales.Order`, not `Order`); name constraints explicitly
  (`PK_`, `FK_`, `IX_`, `DF_`, `CK_`).
- Procs: `SET NOCOUNT ON;` and `SET XACT_ABORT ON;`, `TRY…CATCH` with `THROW` (not `RAISERROR`);
  explicit column lists — no `SELECT *`.
- Procs, views and result sets that an application or report consumes are a **contract**: changing
  parameters, result columns or error numbers is breaking — check the wiki's contract/marts page.
- Use SQLCMD variables (`$(DatabaseName)`) for cross-database references; never hard-code
  environment names, servers, or credentials.
- Set-based over row-by-row; no cursors over large tables.

After a substantive schema change, update the affected `.llm-wiki/` pages and append to
`.llm-wiki/log.md`: `## [YYYY-MM-DD] update | <summary>`.
