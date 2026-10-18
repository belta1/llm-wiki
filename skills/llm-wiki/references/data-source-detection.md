# Detecting data sources in code

How to **recognize** a data source in a repo, and — just as important — how to decide whether what
you found deserves a record at all. The record formats, auth-model inference, upsert rules and the
never-store-secrets rule live in [data-sources.md](data-sources.md); this file is detect-side only.

Read the threshold first. Breadth without it fills the catalog with telemetry hosts and package
registries, which is worse than no catalog.

## What counts as a key data source

A connection earns a **catalog row** only when all three hold:

1. **External & named** — it resolves to an identifiable endpoint outside the repo: a host, DSN,
   account, bucket, share root, cluster, broker, or a stable base URL. Not in-process, not ephemeral.
2. **Durable & likely shared** — the same endpoint is expected across runs, and plausibly across
   repos. Not a temp file, not a test fixture, not a service this repo's own `docker-compose.yml`
   defines.
3. **Load-bearing** — the repo's actual work depends on reading or writing it. Not telemetry, not a
   package registry, not an auth/licence ping.

- Passes (1) and (3) but fails (2) ⇒ **repo page only**, marked `Catalog: no (repo-local)` in
  `.llm-wiki/data-sources.md`. Keeps per-repo dev scaffolding out of the cross-project catalog.
- Fails (3) ⇒ **neither tier**. Don't record it anywhere.

### Never a catalog row

One-off `requests.get(url)` / `urllib` fetches · package registries (PyPI, npm, CRAN, conda, Maven) ·
CI / artifact / container registries · telemetry and APM (Sentry, Datadog, OTLP) · OAuth / token /
JWKS endpoints · `localhost` / `127.0.0.1` / compose services this repo owns · `tempfile`, `/tmp`,
`$TMPDIR` · repo-relative fixtures (`tests/`, `fixtures/`, `data-raw/sample/`) ·
`pd.read_csv("data/x.csv")` on a repo-relative path · stdin / stdout / clipboard · CDN asset fetches ·
webhooks this repo *receives*.

### The HTTP promotion rule

A REST/GraphQL endpoint qualifies only as a **named data service**: a stable base URL, its own auth,
and the repo pulls business data from it repeatedly (an internal `api.internal.corp/v2`, a vendor
feed, a data gateway). The **Name** is the service name plus the base-URL host. A `requests.get` to
an arbitrary URL never qualifies. Same bar for FTP/SFTP: a named drop host with credentials
qualifies; a one-off download does not.

### The granularity rule

**One row per source, never per table, file or topic.** `s3://corp-lake-raw` is one row whatever
prefixes it holds; `SRVPLATDAT` is one row whatever databases it hosts; a Kafka cluster is one row
whatever topics it serves. The specific tables / prefixes / topics a repo touches belong in the
repo page's *Objects / datasets* cell, not in extra rows.

## Signatures by category

The **Name** you extract is the match key for upserts. Detect each engine by its own driver /
connection shape, not by a file extension.

### Relational

- **Python** — `pyodbc.connect("…")` / `pyodbc.connect(dsn=…)`;
  `sqlalchemy.create_engine("mssql+pyodbc://…"` / `"oracle+oracledb://…"` / `"oracle+cx_oracle://…"`
  / `"postgresql+psycopg://…"` / `"postgresql+psycopg2://…"` / `"mysql+pymysql://…"` /
  `"mariadb+mariadbconnector://…")`; `oracledb.connect` / `cx_Oracle.connect`; `pymssql.connect`;
  `psycopg.connect` / `psycopg2.connect`; `mysql.connector.connect`; `pymysql.connect`.
- **CLI** — `sqlcmd -S <host>`, `psql -h <host>`, `psql "service=<name>"`.
- **.NET** — `new SqlConnection(...)` plus `appsettings*.json` → `ConnectionStrings`.
- **Node** — `mssql`, `pg` (`new Pool({ host })`), `mysql2`, Prisma `DATABASE_URL`, knex / TypeORM /
  Drizzle config.
- **R** — `DBI::dbConnect(odbc::odbc(), dsn=…, Driver=…, Server=…, Trusted_Connection=…)`,
  `RODBC::odbcConnect("<DSN>")`, `DBI::dbConnect(RPostgres::Postgres(), …)`,
  `DBI::dbConnect(ROracle::Oracle(), …)`, `DBI::dbConnect(RMariaDB::MariaDB(), …)`.

*Name* = the server host or the DSN.

### Warehouses & lakehouse

- **Snowflake** — `snowflake.connector.connect(account=…, warehouse=…)`, a `snowflake://`
  SQLAlchemy URL, `~/.snowflake/config`, `odbc::snowflake()`.
- **BigQuery** — `google.cloud.bigquery.Client()`, `pandas_gbq.read_gbq`, `bigquery://<project>`,
  `DBI::dbConnect(bigrquery::bigquery(), project=…)`.
- **Databricks** — `databricks.sql.connect(server_hostname=…, http_path=…)`,
  `databricks+connector://`, `~/.databrickscfg`, Unity Catalog `catalog.schema.table`,
  `sparklyr::spark_connect`.
- **Redshift** — `redshift_connector.connect`, `redshift+psycopg2://`, `awswrangler.redshift`.
- **Query engines** — `trino.dbapi.connect` / `prestodb`, `clickhouse_connect.get_client`,
  `pyathena` / `awswrangler.athena.read_sql_query`.
- **dbt** — `profiles.yml` (`account`, `host`, `warehouse`, `project`, `http_path`).

*Name* = account or host, plus the warehouse / project / catalog.

### File & object stores

- **S3** — `boto3.client("s3")` / `boto3.resource("s3")`, `s3fs.S3FileSystem`,
  `awswrangler.s3.read_parquet`, any `s3://bucket/…`.
- **Azure** — `azure.storage.blob.BlobServiceClient`, `adlfs`,
  `abfss://container@account.dfs.core.windows.net/`, `wasbs://`.
- **GCS** — `google.cloud.storage.Client`, `gcsfs`, `gs://bucket/`.
- **Network shares** — `pd.read_parquet("//share/…")`, `pd.read_csv(r"\\SRVFILES01\Data\…")`,
  `pd.read_excel`, `openpyxl.load_workbook`, `glob.glob` over a UNC or mounted path, `smbclient`,
  and `Z:\` / `/mnt/` / `/net/` paths.
- **Dataset readers** — `pyarrow.dataset.dataset`, `arrow::open_dataset`, `arrow::read_parquet`,
  `readr::read_csv("//share/…")`, `readxl::read_excel`, `haven::read_sas`.
- **SharePoint** — `Office365-REST-Python-Client`, `shareplum`, `graph.microsoft.com/v1.0/sites/…`,
  `*.sharepoint.com/sites/…`.
- **SAS** — `libname x "\\srv\share\dir"`, `proc import datafile=…`.

*Name* = the **share or bucket root**, never an individual file.

### Local & embedded

`sqlite3.connect("<path>")`, `sqlite:///`, `DBI::dbConnect(RSQLite::SQLite(), …)`;
`duckdb.connect("<file>")`, `duckdb.read_parquet`, `duckdb::dbConnect(duckdb::duckdb(), dbdir=…)`;
`.rds` / `.feather` / `.parquet` stores on disk; vector-index directories (LanceDB, Chroma, FAISS).

Catalog-worthy **only** if the file lives outside the repo (a shared path) or is a durable shared
artefact. A store this repo builds for itself is repo-page-only.

### Caches, queues & streams

- `redis.Redis(host=…)`, `redis.from_url(REDIS_URL)`, `StrictRedis`, ioredis / bull.
- `pymongo.MongoClient("mongodb://host/")`, `motor`, mongoose `MONGODB_URI`.
- `kafka.KafkaConsumer(bootstrap_servers=…)`, `KafkaProducer`, `confluent_kafka.Consumer` with
  `bootstrap.servers`, kafkajs.
- `pika.BlockingConnection(pika.ConnectionParameters(host=…))` (RabbitMQ), Celery `broker_url`.
- `boto3.client("sqs")` / `("sns")` / `("kinesis")`, `ServiceBusClient.from_connection_string`.
- `Elasticsearch(hosts=…)` / OpenSearch.

*Name* = the host / cluster / broker. Topics, queues and key prefixes go in the repo page's
*Objects* cell — **never** as separate rows.

### APIs & transfer

The threshold applies hardest here; see the HTTP promotion rule above.

- **SFTP / FTP** — `paramiko.SSHClient` / `open_sftp`, `pysftp.Connection(host=…)`,
  `ftplib.FTP(host)`, `curl sftp://`, WinSCP scripts.
- **HTTP** — `httpx.Client(base_url=…)`, `requests.Session()` driven by `API_BASE` / `*_API_URL` /
  `*_BASE_URL`, `httr2::request(<base_url>)`, `curl::curl_download`.
- **GraphQL / SOAP** — `gql.Client(transport=RequestsHTTPTransport(url=…))`, `zeep.Client(wsdl=…)`.
- **SAS** — `proc http url=…`, `filename x url=…`.

### SAS sessions & libraries

`saspy.SASsession(cfgname="…")` — the cfgname points at an entry in `sascfg_personal.py` (IOM /
STDIO / SSH). The data source is the SAS server behind that cfgname; credentials come from an
`authinfo` key or env, never inline. Record the cfgname as the **Name** and the libraries the repo
relies on, not every table. Also `*.sas` programs with `libname`, `proc sql … connect to`, or
`signon` (SAS/CONNECT).

## Connection-string tokens

In any language or config file:

- host: `Server=` / `Data Source=` / `Address=` / `HOST=`
- DSN: `DSN=<name>` · driver: `Driver={…}`
- **trusted**: `Trusted_Connection=yes` / `Integrated Security=SSPI|true` /
  `Authentication=ActiveDirectory*` / no `UID`
- **user+password**: `UID=` / `User Id=` + `PWD=` / `Password=`

Auth-model inference from these tokens is in [data-sources.md](data-sources.md).

## Config & env signals

`pg_service.conf` (+ `PG*` vars) · `odbc.ini` / `.odbc.ini` / `.dsn` · `tnsnames.ora` ·
`sascfg_personal.py` / `sascfg.py` · `~/.authinfo` / `_authinfo` · `appsettings*.json`
`ConnectionStrings` · Django `DATABASES` · dbt `profiles.yml` · `~/.aws/config` profiles ·
`~/.snowflake/config` · `~/.databrickscfg` · `rclone.conf` · Airflow `AIRFLOW_CONN_*` / connections ·
R `config.yml` + `.Renviron` · `.env` / `.env.example` keys matching `*_HOST`, `*_DSN`, `*_URL`,
`*_URI`, `*_ACCOUNT`, `*_BUCKET`, `*_CONTAINER`, `*_CONN_STR`, `*_BOOTSTRAP_SERVERS`, `*_SHARE`.

`docker-compose.yml` service hosts are **dev-only** — repo page at most, never the catalog.

## See also

- [data-sources.md](data-sources.md) — the two tiers, record formats, auth inference, upsert rules,
  security, and the Copilot mirror.
- [stacks.md](stacks.md) — connections in the context of each stack's toolchain and the persistence
  axis.
