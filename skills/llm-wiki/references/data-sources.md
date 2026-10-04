# Data-source catalog — recognize & remember common connections

Some data sources recur across many repos: a named SQL Server, an Oracle DSN, a Postgres service.
Re-deriving how to connect to each (driver, auth model, which env var holds the password) every time
is wasteful and error-prone. The **data-source catalog** is a small, user-global file that records
each named source **once** so any session can recognize it in code and reuse the right connection
form — without ever storing a secret.

This is a **cross-project** store: it lives in the user's home, outside any repo, and is **not**
committed. It is maintained by the `llm-wiki` skill and the `/llm-wiki:init` / `update` / `lint`
commands.

## Location

- **Claude (source of truth):** `~/.claude/llm-wiki/data-sources.md`
  (Windows: `%USERPROFILE%\.claude\llm-wiki\data-sources.md`). Create it on first need.
- **GitHub Copilot mirror (optional):** a VS Code **user-profile** instruction file
  `llm-wiki-data-sources.instructions.md`, generated from the catalog by the Copilot installer. See
  [Copilot mirror](#github-copilot-mirror) below.

## Format

A single catalog table, optionally followed by per-source detail blocks for anything that needs more
than a row. Keep it small; follow the frontmatter convention in
[page-formats.md](page-formats.md).

```markdown
---
updated: 2026-10-04
status: current
---

# Data sources (cross-project catalog)

| Name | Engine | Connect via | Driver / DSN | Auth | Credentials | Notes |
|------|--------|-------------|--------------|------|-------------|-------|
| SRVDATSCIENCE02 | SQL Server | ODBC (pyodbc / SQLAlchemy) | ODBC Driver 18 for SQL Server | Trusted (Windows) | n/a | trusted preferred |
| SRVPLATDAT      | SQL Server | ODBC (pyodbc / SQLAlchemy) | ODBC Driver 18 for SQL Server | Trusted (Windows) | n/a | trusted preferred |
| ORABIPROD       | Oracle     | ODBC via pyodbc + SQLAlchemy | DSN=ORABIPROD | User + password | env: `ORABIPROD_USER` / `ORABIPROD_PWD` (names only) | DSN-based |

## SRVDATSCIENCE02
- **Connect (SQLAlchemy):** `mssql+pyodbc://@SRVDATSCIENCE02/<db>?driver=ODBC+Driver+18+for+SQL+Server&trusted_connection=yes`
- **Connect (pyodbc):** `Driver={ODBC Driver 18 for SQL Server};Server=SRVDATSCIENCE02;Database=<db>;Trusted_Connection=yes;`
- **Used by:** _<repos, filled as discovered>_

## ORABIPROD
- **Connect (SQLAlchemy):** `create_engine("oracle+oracledb://", creator=lambda: pyodbc.connect("DSN=ORABIPROD;UID=%s;PWD=%s" % (os.environ["ORABIPROD_USER"], os.environ["ORABIPROD_PWD"])))` — password from env, never inline.
- **Connect (pyodbc):** `pyodbc.connect(f"DSN=ORABIPROD;UID={os.environ['ORABIPROD_USER']};PWD={os.environ['ORABIPROD_PWD']}")`
- **Used by:** _<repos>_
```

Columns:

- **Name** — the canonical identifier you'd recognize in code (a server host like `SRVPLATDAT`, or a
  DSN name like `ORABIPROD`). This is the match key for upserts.
- **Engine** — SQL Server / Oracle / PostgreSQL / MySQL / …
- **Connect via** — ODBC (pyodbc), SQLAlchemy URL, native driver (`oracledb`, `psycopg`), etc.
- **Driver / DSN** — the ODBC driver name (`ODBC Driver 18 for SQL Server`) or `DSN=<name>`.
- **Auth** — `Trusted (Windows)` / integrated, or `User + password`, or `Azure AD`, …
- **Credentials** — `n/a` for trusted; otherwise the **names** of the env vars or secret-store entries
  that supply user/password. **Never a value.**
- **Notes** — anything short and useful ("trusted preferred", "read replica", port, etc.).

## Detecting a data source in code (recognize)

During `init`/`update`, and whenever you touch connection code, look for these and match (or add) a
catalog entry. The **Name** is the server host or DSN you extract.

- **Python**
  - `pyodbc.connect("…")` / `pyodbc.connect(dsn=…)`
  - `sqlalchemy.create_engine("mssql+pyodbc://…")`, `"oracle+oracledb://…"` / `"oracle+cx_oracle://…"`,
    `"postgresql+psycopg://…"` / `"postgresql+psycopg2://…"`, `"mysql+pymysql://…"`
  - `oracledb.connect(...)` / `cx_Oracle.connect(...)`, `pymssql.connect(...)`,
    `psycopg2.connect(...)` / `psycopg.connect(...)`
- **R** — `DBI::dbConnect(odbc::odbc(), dsn=…, Driver=…, Server=…, Trusted_Connection=…)`,
  `RODBC::odbcConnect("<DSN>")`, `DBI::dbConnect(RPostgres::Postgres(), …)`.
- **Connection-string tokens** (any language / config file):
  - host: `Server=` / `Data Source=` / `Address=` / `HOST=`
  - DSN: `DSN=<name>`
  - driver: `Driver={…}`
  - **trusted**: `Trusted_Connection=yes` / `Integrated Security=SSPI|true` / `Authentication=ActiveDirectory*` / no `UID`
  - **user+password**: `UID=` / `User Id=` + `PWD=` / `Password=`
- **Config / env** — `pg_service.conf` + `PG*` vars, `.dsn` / `odbc.ini` / `tnsnames.ora`,
  `.env.example`, `appsettings*.json` connection strings, Django `DATABASES`.

### Auth-model inference

- `Trusted_Connection=yes`, `Integrated Security`, or no `UID`/`User Id` ⇒ **Trusted (Windows)** —
  Credentials = `n/a`.
- `UID`/`User Id` present (with `PWD`/`Password`, usually sourced from an env var) ⇒
  **User + password** — record the env-var **names** supplying them.
- `Authentication=ActiveDirectory*` / token-based ⇒ **Azure AD** — note the method, no secret.

### Upsert rules (match, don't duplicate)

- Match an existing entry by **Name** (case-insensitive host/DSN). If found, update only fields that
  changed and append the current repo to **Used by**; do **not** add a second row.
- If not found, append a new row with the inferred engine / connect-via / driver / auth, and
  credential **names** only.
- Preserve every other entry and any hand-written detail blocks — the catalog is **upsert, never
  rewrite**.

## Security — never store secrets

Record the connection *shape* and the *names* of credential sources. **Never** write a password,
token, key, or any secret value into the catalog (or into a recipe, or a Copilot instruction file).

If you find a **literal credential inlined in code** (e.g. `PWD=hunter2` in a connection string):

- record the data source **without** the secret (auth = `User + password`, Credentials = the env var
  it *should* come from, or `⚠ inlined in <path>` as a flag);
- surface it as a `lint` finding so the human can move it to an env var / secret store;
- do not copy the value anywhere.

## GitHub Copilot mirror

Copilot has no plugin system and can't read `~/.claude/…`. The cross-project path for Copilot is a
VS Code **user-profile** instruction file that embeds the catalog in its body (Copilot can't follow a
pointer to an external file). The Copilot installer generates
`llm-wiki-data-sources.instructions.md` from this catalog, inside a managed
`<!-- BEGIN llm-wiki --> … <!-- END llm-wiki -->` block, with an `applyTo` glob covering data/DB file
types. It is **VS Code-only**; github.com Copilot and other editors read committed repo files only.
See `templates/copilot-instructions/data-sources.instructions.md` and `scripts/install-copilot.*`.

## See also

- [stacks.md](stacks.md) — connection detection in context of each stack's toolchain and the
  persistence axis.
- [page-formats.md](page-formats.md) — frontmatter and size conventions this file follows.
