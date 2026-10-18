# Data-source catalog — recognize & remember common connections

Some data sources recur across many repos: a named SQL Server, an Oracle DSN, a Postgres service.
Re-deriving how to connect to each (driver, auth model, which env var holds the password) every time
is wasteful and error-prone. The **data-source catalog** is a small, user-global file that records
each named source **once** so any session can recognize it in code and reuse the right connection
form — without ever storing a secret.

This is a **cross-project** store: it lives in the user's home, outside any repo, and is **not**
committed. It is maintained by the `data-sources` and `llm-wiki` skills and the `/llm-wiki:init` /
`update` / `lint` commands. Its repo-scoped counterpart — which code in *one* repo touches which
source — is the optional wiki page `.llm-wiki/data-sources.md`; see
[Two tiers](#two-tiers-this-catalog-vs-the-repos-wiki-page) below.

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
| PGANALYTICS     | PostgreSQL | `psycopg` / SQLAlchemy / `pg_service` | service=`pganalytics` (`pg_service.conf`) | User + password | env: `PGPASSWORD` or `~/.pgpass` entry (names only) | read replica |
| SASGRID         | SAS        | `saspy` (IOM) | cfgname `iomwin` in `sascfg_personal.py` | authinfo key | `~/.authinfo` key `iomwin` (name only) | SAS 9.4 metadata server |

## SRVDATSCIENCE02
- **Connect (SQLAlchemy):** `mssql+pyodbc://@SRVDATSCIENCE02/<db>?driver=ODBC+Driver+18+for+SQL+Server&trusted_connection=yes`
- **Connect (pyodbc):** `Driver={ODBC Driver 18 for SQL Server};Server=SRVDATSCIENCE02;Database=<db>;Trusted_Connection=yes;`
- **Used by:** _<repos, filled as discovered>_

## ORABIPROD
- **Connect (SQLAlchemy):** `create_engine("oracle+oracledb://", creator=lambda: pyodbc.connect("DSN=ORABIPROD;UID=%s;PWD=%s" % (os.environ["ORABIPROD_USER"], os.environ["ORABIPROD_PWD"])))` — password from env, never inline.
- **Connect (pyodbc):** `pyodbc.connect(f"DSN=ORABIPROD;UID={os.environ['ORABIPROD_USER']};PWD={os.environ['ORABIPROD_PWD']}")`
- **Used by:** _<repos>_

## SASGRID
- **Connect (saspy):** `sas = saspy.SASsession(cfgname="iomwin")` — the `iomwin` entry lives in
  `sascfg_personal.py` (`iomhost`, `iomport`, `authkey="iomwin"`); credentials come from the `iomwin`
  line in `~/.authinfo` (`%USERPROFILE%\_authinfo` on Windows), never inline.
- **Libraries:** assigned in SAS code with `libname <ref> ...` or `sas.saslib(...)`; record the key
  libraries a repo relies on, not every table.
- **Used by:** _<repos>_
```

Columns:

- **Name** — the canonical identifier you'd recognize in code (a server host like `SRVPLATDAT`, or a
  DSN name like `ORABIPROD`). This is the match key for upserts.
- **Engine** — SQL Server / Oracle / PostgreSQL / MySQL / SAS / …
- **Connect via** — ODBC (pyodbc), SQLAlchemy URL, native driver (`oracledb`, `psycopg`),
  `saspy` (SAS session), etc.
- **Driver / DSN** — the ODBC driver name (`ODBC Driver 18 for SQL Server`) or `DSN=<name>`.
- **Auth** — `Trusted (Windows)` / integrated, or `User + password`, or `Azure AD`, …
- **Credentials** — `n/a` for trusted; otherwise the **names** of the env vars or secret-store entries
  that supply user/password. **Never a value.**
- **Notes** — anything short and useful ("trusted preferred", "read replica", port, etc.).

### How each column reads per source class

The columns were designed around relational engines but generalize — reinterpret them, don't change
them (the Copilot mirror template and both installer scripts depend on this shape):

| Column | RDBMS | Warehouse | Object store / share | Queue / stream | API / SFTP | Embedded file |
|---|---|---|---|---|---|---|
| Name | host or DSN | account + warehouse | bucket or UNC root | cluster / broker host | service name | path / logical store |
| Engine | SQL Server, Oracle, … | Snowflake, BigQuery, … | S3, Azure Blob, GCS, SMB share, SharePoint | Kafka, Redis, RabbitMQ, SQS, MongoDB | REST, GraphQL, SOAP, SFTP, FTP | SQLite, DuckDB, Parquet dataset |
| Connect via | pyodbc, SQLAlchemy | snowflake-connector, `bigrquery` | boto3, s3fs, adlfs, `pd.read_parquet` | kafka-python, redis-py | httpx, requests, paramiko | `duckdb.connect` |
| Driver / DSN | ODBC driver name | account URL / `http_path` / project id | region + container/prefix | bootstrap servers + security protocol | base URL + API version | file path or glob |
| Auth | trusted, user+password, Azure AD | key-pair, SSO, OAuth, service account | IAM role, SAS token, ADC, share ACL | SASL mechanism, mTLS, none | API key, OAuth2, SSH key | filesystem ACL |
| Credentials | env-var names | env names, config-file key, SA key **path** | `AWS_PROFILE`, `AZURE_*` names | `KAFKA_*` names | `*_API_KEY` name, key path | n/a |
| Notes | read replica, port | warehouse size, billing | layout `dt=…`, retention | topics, partitions | rate limit, pagination | refresh cadence |

## Two tiers: this catalog vs. the repo's wiki page

There are two places a data source gets recorded, answering two different questions and joined on
the **Name** column (matched case-insensitively — the same key the upsert rule below uses).

| | **This catalog** `~/.claude/llm-wiki/data-sources.md` | **Repo page** `.llm-wiki/data-sources.md` |
|---|---|---|
| Question | *How do I connect to `SRVPLATDAT`?* | *What does **this** repo do with it?* |
| Scope | user-global, **never** committed | one repo, **committed** wiki canon |
| Owns | engine, connect-via, driver/DSN, auth model, credential **names**, connect snippets, the `Used by:` repo list | which code paths touch it, read/write direction, the tables/prefixes/topics actually used, repo gotchas, local/dev substitutes |
| Must not hold | repo-specific usage or code paths | driver strings, DSN detail, auth mechanism, credential names |

**Non-duplication rule:** a fact true in every repo that uses the source belongs here; a fact true
only in one repo belongs on that repo's page.

A source that exists only inside one repo or its dev environment (a DuckDB build artifact, a
`docker-compose` dev Postgres, committed fixtures) gets a repo-page row marked
`Catalog: no (repo-local)` and **no** row here. The repo page's reverse index is this catalog's
per-source **`Used by:`** line.

The repo page is committed, so where internal hostnames can't be published it may use a role name
(`<prod-sales-db>`) while the real host stays here — the role name then becomes the join key.

## Detecting a data source in code (recognize)

Detection signatures for every engine class — relational, warehouses and lakehouse, object stores
and network shares, local/embedded files, caches/queues/streams, APIs and SFTP, SAS sessions, plus
connection-string tokens and config/env signals — and the **threshold** that decides whether a
connection deserves a record at all, live in
[data-source-detection.md](data-source-detection.md). Read it before scanning a repo.

## Auth-model inference

- `Trusted_Connection=yes`, `Integrated Security`, or no `UID`/`User Id` ⇒ **Trusted (Windows)** —
  Credentials = `n/a`.
- `UID`/`User Id` present (with `PWD`/`Password`, usually sourced from an env var) ⇒
  **User + password** — record the env-var **names** supplying them.
- `Authentication=ActiveDirectory*` / token-based ⇒ **Azure AD** — note the method, no secret.
- **SAS:** an `authkey` ⇒ credentials live in an **authinfo** file entry — record the key name, never
  the value. `omruser`/`omrpw` or env-sourced creds ⇒ **User + password** — record the env-var names.
- **Cloud / object stores:** an IAM role, instance profile, `AWS_PROFILE`, managed identity or
  Application Default Credentials ⇒ record the *mechanism* and the profile/role **name**. A SAS
  token or presigned URL ⇒ **the URL is itself a secret** (see Security below).
- **Warehouses:** key-pair, SSO/external browser, OAuth client-credentials, or a service-account JSON
  key ⇒ record the method, and reference a key file **by path only**.

## Upsert rules (match, don't duplicate)

- Match an existing entry by **Name** (case-insensitive host/DSN). If found, update only fields that
  changed and append the current repo to **Used by**; do **not** add a second row.
- If not found, append a new row with the inferred engine / connect-via / driver / auth, and
  credential **names** only.
- Preserve every other entry and any hand-written detail blocks — the catalog is **upsert, never
  rewrite**.

## Security — never store secrets

Record the connection *shape* and the *names* of credential sources. **Never** write a password,
token, key, or any secret value into the catalog (or into a recipe, a repo wiki page, or a Copilot
instruction file).

Two cases that are easy to get wrong:

- A **SAS token or presigned URL** (`https://acct.blob.core.windows.net/…?sv=…&sig=…`,
  `s3://…?X-Amz-Signature=…`) *embeds* the credential. The URL is a secret — record the env-var name
  that supplies it, never the URL itself.
- A **service-account JSON key** (GCP, or a Snowflake private key) is referenced **by path or
  env-var name only**; never paste its contents or its key material.

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

- [data-source-detection.md](data-source-detection.md) — the threshold for "key data source" and the
  detection signatures for every engine class.
- [stacks.md](stacks.md) — connection detection in context of each stack's toolchain and the
  persistence axis.
- [page-formats.md](page-formats.md) — frontmatter and size conventions this file follows.
