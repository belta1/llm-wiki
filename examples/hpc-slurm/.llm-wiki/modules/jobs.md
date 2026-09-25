---
updated: 2026-09-25
covers: [slurm, jobs, seam, resources]
status: current
---

# Jobs (`slurm/`) — the scheduler is the seam

How the Python and R components are run on Hydra and how they hand work to each other. If a stage's
inputs, outputs, resources or dependencies change, this page changes.

## Key files & entry points

- `slurm/submit.sh` — the only supported way to submit the full study (`--test` for a dry run).
- `slurm/01_prep.sbatch` · `slurm/02_simulate.sbatch` · `slurm/03_aggregate.sbatch`
- `slurm/env.sh` (from `env.example.sh`) — `SIM_SCRATCH`, `SIM_RESULTS`, module list.
- `logs/` — `%x_%A_%a.out` per task (git-ignored).

## Jobs

| Script | Resources | Array | Depends on | Reads → writes |
|--------|-----------|-------|------------|----------------|
| `01_prep.sbatch` | compute · 1 h · 8 CPU · 32G | — | — | `/proj/epi-sim/census/*.csv` → `$SIM_SCRATCH/pop/<region>.parquet` |
| `02_simulate.sbatch` | compute · 40 min · 4 CPU · 8G | `0-(N-1)%100`, task = grid row | `afterok:01` | `pop/<region>.parquet` + grid row → `$SIM_SCRATCH/runs/<row_id>.parquet` |
| `03_aggregate.sbatch` | compute · 2 h · 16 CPU · 64G | — | `afterok:02` (all tasks) | `runs/*.parquet` → `$SIM_RESULTS/<date>/{tables,figures}/` |

## Dependency chain

```bash
prep=$(sbatch --parsable slurm/01_prep.sbatch)
sim=$(sbatch --parsable --dependency=afterok:$prep --array=0-$((N-1))%100 slurm/02_simulate.sbatch)
sbatch --dependency=afterok:$sim slurm/03_aggregate.sbatch
```

`afterok` on an array waits for **every** task; one failed task blocks aggregation until it's rerun
([recipes](../recipes.md#rerun-failed-array-tasks)).

## Resources

- Sized from `seff` on the last full run: simulate peaks ~5.5G / 25 min for the largest region —
  `8G` / `40 min` leaves headroom. Large-`contact_scale` rows are the slowest.
- **OOM** in simulate → usually a new region with more people; raise `--mem`, not `--cpus`.
- **TIMEOUT** → check the row's parameters first (`r0 > 4` runs long); raise `--time` in the script
  only if many tasks are close to the limit.
- `debug` partition for `--test` only (2 nodes, 30 min); `compute` for real runs. No GPUs needed.

## When jobs fail

1. `sacct -j <id> --format=JobID,State,ExitCode,MaxRSS,Elapsed` — distinguishes FAILED (code
   error → read the log) from TIMEOUT / OUT_OF_MEMORY (resources).
2. Log: `logs/sim-<stage>_<A>_<a>.out`. R errors print the grid row at the top.
3. Rerun only the failed tasks, then aggregate ([recipes](../recipes.md#rerun-failed-array-tasks)).

## Gotchas

- Missing `logs/` dir → the job fails instantly with **no log**. `submit.sh` creates it; direct
  `sbatch` calls don't.
- Scratch is purged after 30 days: rerunning aggregate on an old study needs `runs/` regenerated.
- Compute nodes have no internet — `uv sync` / `renv::restore()` inside a job will hang.
- Editing a `.sbatch` while its array is queued affects nothing (Slurm copied it at submit time).

## Related

- [preprocess](preprocess.md) · [models](models.md) · [architecture](../architecture.md#the-seam-between-components) · [conventions](../conventions.md#slurm-job-scripts)
