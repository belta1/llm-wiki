---
updated: 2026-09-25
covers: [architecture, slurm, pipeline]
status: current
---

# Architecture

A three-stage batch pipeline. Each stage is a Slurm job; the scheduler — not a workflow manager —
enforces order through job dependencies, and stages hand data to each other **only through files on
scratch**. Every stage can also run without Slurm, which is how CI and local debugging work.

## Flow

```
login node: bash slurm/submit.sh
  │
  ├─ 01_prep.sbatch        (1 task, Python)   census extracts → $SCRATCH/pop/<region>.parquet
  │        │ afterok
  ├─ 02_simulate.sbatch    (array 0..N-1, R)  row $SLURM_ARRAY_TASK_ID of params/grid.csv
  │        │                                  → $SCRATCH/runs/<row_id>.parquet
  │        │ afterok  (waits for *every* array task)
  └─ 03_aggregate.sbatch   (1 task, R)        $SCRATCH/runs/*.parquet
                                              → /proj/epi-sim/sim-study/results/<date>/
```

## The seam between components

- **Python → R:** population parquet files, schema in `py/sim_prep/schema.py` (`person_id int64,
  region str, age_band str, household_id int64, contacts list<int64>`). R reads them with
  `arrow::read_parquet()`. A schema change must update both `schema.py` and `R/load_pop.R`.
- **Grid → tasks:** task id *i* runs row *i* (0-based) of `params/grid.csv`; the row's `row_id`
  names its output file, so reruns overwrite rather than duplicate.
- **Tasks → aggregate:** one parquet per row in `$SCRATCH/runs/`; aggregate checks it has exactly
  `nrow(grid)` files and fails loudly otherwise.

See [jobs](modules/jobs.md) for resources and failure handling.

## Storage

| Where | What | Notes |
|-------|------|-------|
| repo (`$HOME/sim-study` or project dir) | code, `params/`, `logs/` | backed up; small quota |
| `/scratch/$USER/sim-study/` | `pop/`, `runs/` intermediates | fast, **purged after 30 days** |
| `/proj/epi-sim/sim-study/results/<date>/` | final tables + figures | backed up; shared with the group |

## Key decisions & constraints

- **Plain sbatch + `afterok`** rather than Snakemake/targets-on-crew: three stages don't justify a
  workflow manager, and plain scripts are easy to rerun piecemeal.
- **Array throttle `%100`** — the `epi-sim` account's fair-share limit; more concurrent tasks only
  queue and lower priority for the group.
- **Seeds** come from the grid (`seed` column), so any single row is reproducible on its own.
- Environments: uv `.venv` and renv library live in the repo dir and are built **once on the login
  node**; compute nodes have no internet access.
