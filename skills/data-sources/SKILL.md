---
name: data-sources
description: Use when code reads or writes data that lives outside the repo — any database connection, warehouse query, object-store or network-share read, API or SFTP pull, or queue/stream consumer. Triggers on pyodbc.connect, SQLAlchemy create_engine, psycopg/oracledb/pymssql/pymysql, saspy.SASsession, DBI::dbConnect, RODBC, snowflake.connector, bigquery/pandas_gbq, databricks.sql, redshift_connector, trino, boto3.client("s3"), azure.storage.blob/adlfs, gcsfs, SharePoint or UNC share paths, pd.read_parquet/read_csv/read_excel over a share, arrow::open_dataset, duckdb.connect, sqlite3.connect, redis.Redis, pymongo.MongoClient, KafkaConsumer/confluent_kafka, pika, SQS/Service Bus, Elasticsearch, paramiko/pysftp/ftplib, httpx/requests clients with a configured base URL, GraphQL or SOAP clients, .sas libname and proc http, DSN=/Server=/Data Source= connection strings, pg_service.conf, odbc.ini, tnsnames.ora, sascfg_personal.py, dbt profiles.yml, appsettings ConnectionStrings, or .env connection settings — in any language. Identify the named source and its engine, reuse the connection form already recorded in the user-global catalog ~/.claude/llm-wiki/data-sources.md instead of inventing a connection string, upsert anything new there by name, record which of this repo's code touches it in .llm-wiki/data-sources.md when that wiki exists, and never store a password, token or key — only the names of the env vars or secret-store entries that supply them. Works in any repo, with or without a .llm-wiki/ directory.
---

# Data sources — recognize, reuse, remember

Named data sources recur across repos: a SQL Server like `SRVPLATDAT`, an ODBC DSN like `ORABIPROD`,
a Snowflake account, an `s3://` lake bucket, a `\\SRVFILES01\` share. Re-deriving how to connect to
each one — which driver, which auth model, which env var holds the password — every session is
wasteful and error-prone.

So: **recognize** what a connection points at, **reuse** the form already recorded for it, and
**remember** anything new. Never store a secret, at either tier.

## What counts as a key data source

Not every outbound call is a data source. A **catalog row** requires all three:

1. **External & named** — resolves to an identifiable endpoint outside the repo: a host, DSN,
   account, bucket, share root, cluster, broker, or a stable base URL.
2. **Durable & likely shared** — the same endpoint across runs, and plausibly across repos. Not a
   temp file, not a fixture, not a service this repo's own `docker-compose.yml` defines.
3. **Load-bearing** — the repo's real work depends on reading or writing it.

Passes (1) and (3) but fails (2) ⇒ **repo page only**, `Catalog: no (repo-local)`. Fails (3) ⇒
record it nowhere.

**Never a catalog row:** one-off `requests.get(url)` fetches · package registries (PyPI, npm, CRAN) ·
CI / container registries · telemetry and APM (Sentry, Datadog, OTLP) · OAuth / JWKS endpoints ·
`localhost` and compose services this repo owns · `tempfile` / `/tmp` · repo-relative fixtures and
`pd.read_csv("data/x.csv")` · CDN assets · webhooks this repo *receives*.

**One row per source, never per table, file or topic.** `s3://corp-lake-raw` is one row whatever
prefixes it holds. The specific tables, prefixes and topics belong in the repo page.

## Two tiers

| | **Global catalog** `~/.claude/llm-wiki/data-sources.md` | **Repo page** `.llm-wiki/data-sources.md` |
|---|---|---|
| Question | *How do I connect to it?* | *What does **this** repo do with it?* |
| Scope | user-global, **never** committed | one repo, committed wiki canon |
| Owns | engine, connect-via, driver/DSN, auth model, credential **names**, connect snippets, `Used by:` repos | which code paths touch it, direction, the objects actually used, repo gotchas, dev substitutes |
| Must not hold | repo-specific usage or code paths | driver strings, DSN detail, auth mechanism, credential names |

Joined on **Name**, matched case-insensitively. A fact true in every repo that uses the source is
catalog; a fact true only here is the repo page.

## Recognize

Match a connection to a source by its driver/connection shape, not by file extension. The highest-value
signatures:

- **Relational** — `pyodbc.connect`, `sqlalchemy.create_engine("mssql+pyodbc://" | "oracle+oracledb://" |
  "postgresql+psycopg://" | "mysql+pymysql://")`, `oracledb.connect`, `psycopg.connect`,
  `pymssql.connect`; `DBI::dbConnect(odbc::odbc(), …)`, `RODBC::odbcConnect`; Node `pg` /
  `mssql` / Prisma `DATABASE_URL`; .NET `SqlConnection` + `appsettings` `ConnectionStrings`.
  *Name* = host or DSN.
- **Warehouses** — `snowflake.connector.connect(account=, warehouse=)`, `pandas_gbq.read_gbq` /
  `bigquery.Client()`, `databricks.sql.connect(server_hostname=, http_path=)`,
  `redshift_connector.connect`, `trino.dbapi.connect`, dbt `profiles.yml`.
  *Name* = account/host + warehouse|project|catalog.
- **Object stores & shares** — `boto3.client("s3")`, `s3fs`, `s3://`; `BlobServiceClient`, `adlfs`,
  `abfss://`; `gcsfs`, `gs://`; `pd.read_parquet("//share/…")`, `pd.read_excel(r"\\SRVFILES01\…")`,
  `arrow::open_dataset`, `haven::read_sas`; SharePoint / Graph `sites/…`.
  *Name* = the bucket or share **root**.
- **Local / embedded** — `duckdb.connect`, `sqlite3.connect`, `.parquet` / `.rds` stores. Catalog only
  if the file lives outside the repo.
- **Caches, queues & streams** — `redis.Redis(host=)`, `pymongo.MongoClient`,
  `KafkaConsumer(bootstrap_servers=)`, `pika.BlockingConnection`, `boto3.client("sqs")`,
  `Elasticsearch(hosts=)`. *Name* = host/cluster/broker.
- **APIs & transfer** — `paramiko`/`pysftp`/`ftplib`, `httpx.Client(base_url=)`, `zeep.Client(wsdl=)`.
  Only a *named data service* with its own auth qualifies.
- **SAS** — `saspy.SASsession(cfgname="…")` → an entry in `sascfg_personal.py`; `*.sas` `libname`,
  `proc sql … connect to`, `signon`, `proc http`.
- **Config / env** — `pg_service.conf`, `odbc.ini`, `tnsnames.ora`, `sascfg_personal.py`,
  `~/.aws/config`, `~/.databrickscfg`, Airflow `AIRFLOW_CONN_*`, and `.env` keys matching `*_HOST`,
  `*_DSN`, `*_URL`, `*_ACCOUNT`, `*_BUCKET`, `*_BOOTSTRAP_SERVERS`, `*_SHARE`.

Full signature catalog by category:
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/data-source-detection.md`.

## Reuse before you invent

Consult the catalog **before** writing connection code. If the source already has an entry, use its
recorded driver, connect-via form and auth model — don't compose a second connection string for the
same server, and don't switch auth models (a trusted connection stays trusted). If the code you're
reading disagrees with the catalog, the code wins: fix the entry.

## Remember (the global catalog)

Catalog location: `~/.claude/llm-wiki/data-sources.md` (Windows:
`%USERPROFILE%\.claude\llm-wiki\data-sources.md`). Create it on first need; it lives in the user's
home and is never committed.

- Columns: `Name | Engine | Connect via | Driver / DSN | Auth | Credentials | Notes`, plus an
  optional per-source detail block with connect snippets and a `Used by:` repo list.
- **Upsert by Name** (case-insensitive). If the source is already there, update only what changed and
  append this repo to `Used by:` — never add a second row. Preserve every other entry and all
  hand-written detail: **upsert, never rewrite.**
- Auth inference: `Trusted_Connection=yes` / `Integrated Security` / no `UID` ⇒ trusted, Credentials
  `n/a`. `UID` + `PWD` ⇒ user+password, record the env-var **names**. An `authkey` ⇒ an authinfo key
  name. An IAM role, `AWS_PROFILE`, managed identity or ADC ⇒ the mechanism plus the profile name.

Format, the per-class reading of each column, full auth inference and the Copilot mirror:
`${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/data-sources.md`.

## Record (the repo page)

**Only when the repo has a `.llm-wiki/` directory.** Create
`.llm-wiki/data-sources.md` from `${CLAUDE_PLUGIN_ROOT}/templates/wiki/data-sources.md` the first
time the repo gains an external source, add a Map row for it in `.llm-wiki/index.md`, and keep it
current afterwards.

What goes on the page: the sources this repo touches, the real code paths and module pages that
touch them, direction (read / write / read-write), the tables, prefixes, topics or file patterns
actually used, repo-specific gotchas (refresh windows, row limits, "never write to PROD from here"),
and any local/dev substitutes.

What does **not** go on the page: driver strings, DSN detail, auth mechanisms, credential names —
those are catalog facts. Keep the page short; it is a map, not an inventory.

## Never store secrets

Record the connection *shape* and the *names* of credential sources. Never a password, token, key or
any secret value — in the catalog, the repo page, a recipe, or a Copilot instruction file. A SAS
token or presigned URL **is** a secret (it embeds the credential): record the env-var name, never the
URL. A service-account JSON key is referenced by path only.

If you find a credential inlined in code (e.g. `PWD=hunter2` in a connection string): record the
source **without** the secret, note `⚠ inlined in <path>` where the credential should come from,
report it so the human can move it to an env var or secret store, and do not copy the value
anywhere. Never silently rewrite their source to "fix" it.

## References & related commands

- `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/data-sources.md` — record format, two tiers,
  auth inference, upsert rules, security, Copilot mirror.
- `${CLAUDE_PLUGIN_ROOT}/skills/llm-wiki/references/data-source-detection.md` — the threshold and
  the full detection catalog.
- `/llm-wiki:init` scans a repo and seeds both tiers · `/llm-wiki:update` keeps them current ·
  `/llm-wiki:lint` checks for secret leaks and drift between the two.
