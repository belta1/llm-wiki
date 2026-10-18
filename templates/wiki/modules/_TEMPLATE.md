---
updated: YYYY-MM-DD
covers: [<area>]
status: draft
---

# <Module / subsystem name>

_One-sentence purpose: what this subsystem is responsible for._

## Key files & entry points

- `<path>` — _what it is / the entry point._
- `<path>` — _..._

<!-- Optional, for database-shaped modules (a schema, warehouse layer, SSIS package group).
     Delete if not applicable.
## Database objects

| Object | Kind / grain | Notes |
|--------|--------------|-------|
| `<schema>.<Table>` | table | _keys, soft-delete, SCD type, …_ |
| `<schema>.usp_<Name>` | proc | _who calls it; error numbers it THROWs_ |
| `<schema>.<fn_name>(args)` | function (Postgres) | _returns; ERRCODEs it RAISEs; volatility_ |
-->

<!-- Optional, for Slurm job groups. Delete if not applicable.
## Jobs

| Script | Resources | Array | Depends on | Reads → writes |
|--------|-----------|-------|------------|----------------|
| `slurm/<job>.sbatch` | _partition, time, mem, cpus/gpus_ | _`0-99%20` → row of params.csv_ | _`afterok:<job>`_ | _`$SCRATCH/in/` → `results/<job>/`_ |
-->

<!-- Optional, for modules that read or write external data. Delete if not applicable.
## Data sources used

| Source | Direction | Objects / datasets | Via |
|--------|-----------|--------------------|-----|
| `SRVPLATDAT` | read | `dbo.Sales` | `src/etl/extract.py` (pyodbc) |
| `s3://corp-lake-raw` | write | `raw/sales/dt=<date>/` | `src/etl/land.py` (boto3) |

Full list: [data-sources](../data-sources.md). Connection details live in the user-global catalog,
never in the repo — and never a secret.
-->

## How it works

_Short description of the flow within this module and how it connects to the rest of the system.
Link to [architecture](../architecture.md) for the big picture. Summarize what isn't obvious from
reading the code — don't restate the code._

## Gotchas & constraints

- _Non-obvious behavior, invariants, footguns, or "don't do X" that an agent editing here must know._

## Related

- [<other module>](<name>.md)
- [conventions](../conventions.md), [recipes](../recipes.md)
