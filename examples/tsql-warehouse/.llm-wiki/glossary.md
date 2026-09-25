---
updated: 2026-09-25
covers: [glossary, domain, warehouse]
status: current
---

# Glossary

- **Layer** — a schema with one job: `stg` (landing), `dw` (star schema), `mart` (reporting views),
  `etl` (control). See [architecture](architecture.md#layers).
- **Business key (BK)** — the source system's identifier (`CustomerBK`). **Surrogate key** — the
  warehouse's `int IDENTITY` (`CustomerKey`) that facts reference.
- **SCD1 / SCD2** — slowly changing dimension types: overwrite in place (SCD1) vs close the current row
  and insert a new version (SCD2, `ValidFrom`/`ValidTo`/`IsCurrent`).
- **Unknown member** — the `-1` row in every dim; facts point to it when a key can't be matched.
- **Watermark** — `etl.Watermark.LastModifiedAt` per source entity; the incremental-load cursor.
- **LoadId** — one run of one package, logged in `etl.LoadLog`; stamped onto `stg` rows.
- **ispac** — built SSIS project deployed to the **SSIS catalog** (`SSISDB`).
- **SSISDB environment** — per-env variable set (`Dev`/`Test`/`Prod`) bound to project parameters.
- **Grain** — what one fact row represents; `FactSales` = one order line.
- **Nightly** — Agent job `SalesDW - Nightly`. See [jobs](modules/jobs.md).
