---
updated: 2026-09-25
covers: [conventions, slurm, python, r]
status: current
---

# Conventions

## Slurm job scripts

Every `slurm/*.sbatch` follows this header, in this order — `#SBATCH` lines must come before any
command or Slurm ignores them:

```bash
#!/bin/bash
#SBATCH --job-name=sim-simulate
#SBATCH --account=epi-sim
#SBATCH --partition=compute
#SBATCH --time=00:40:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --array=0-999%100
#SBATCH --output=logs/%x_%A_%a.out
set -euo pipefail
module purge
module load R/4.4.1 arrow/16.1
cd "$SLURM_SUBMIT_DIR"
```

- Job names are `sim-<stage>`; logs go to `logs/%x_%A_%a.out` (`%j` for non-array jobs). `logs/`
  must exist — `submit.sh` creates it.
- Pass threads explicitly: `OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK`, `data.table::setDTthreads()`.
- Paths come from `slurm/env.sh` (`SIM_SCRATCH`, `SIM_RESULTS`), sourced by every script — never
  hard-code `/scratch/<name>`.
- `--array` in the script is a default; `submit.sh` overrides it from the grid's row count.
- Check with `shellcheck`; no credentials in scripts.

## Python (`py/`)

- uv (`uv.lock`); run as `uv run python -m sim_prep.build …` — on compute nodes the job script calls
  `.venv/bin/python` directly (no network for uv to sync).
- polars, not pandas; ruff for lint + format (`[tool.ruff]` in `pyproject.toml`); pytest.

## R (`R/`, `scripts/`)

- renv (`renv.lock`); functions in `R/`, thin entry scripts in `scripts/` that read
  `SLURM_ARRAY_TASK_ID`, call functions, and write one output file.
- data.table style, `|>` pipe; `here::here()` for repo paths; no `setwd()`.
- Randomness only via the grid's `seed` column (`set.seed(row$seed)` at the top of `simulate.R`).
- lintr (`.lintr`) + testthat for `R/`.

## Outputs

- One output file per task, named by `row_id`; write to a temp name and `file.rename()` at the end,
  so a killed task never leaves a half-written file that aggregate would read.
- Never write into `params/` or the repo from a job except `logs/`.

## Do / don't

- ✅ Test with `bash slurm/submit.sh --test` before a full submit.
- ✅ Build/refresh environments on the login node (`uv sync`, `renv::restore()`), then submit.
- ❌ Don't run simulations or aggregation on the login node — use `sbatch` or `salloc`.
- ❌ Don't raise the array throttle above `%100` or use partitions other than `compute`/`debug`.
- ❌ Don't chain jobs with `sleep`/polling loops — use `--dependency=afterok`.
