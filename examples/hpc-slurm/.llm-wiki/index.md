---
updated: 2026-09-25
covers: [overview, navigation]
status: current
---

# Index — sim-study

A **simulation study** run on the university's **Slurm** cluster (Hydra): a Python step builds
synthetic populations from census extracts, an **R** SEIR model is simulated for every row of a
parameter grid as a **Slurm job array**, and an R step aggregates the runs into summary tables and
figures. The three stages are chained with `afterok` dependencies by `slurm/submit.sh`. No web app,
no database. **Read this first, then open the files it points to.**

## Components

| Component | Path | Toolchain | Purpose | Module page |
|-----------|------|-----------|---------|-------------|
| Preprocess | `py/` | uv · Python 3.12 · polars | census extract → population parquet per region | [preprocess](modules/preprocess.md) |
| Models | `R/` `scripts/` | renv · R 4.4.1 · data.table, arrow | simulate one grid row; aggregate all runs | [models](modules/models.md) |
| Jobs | `slurm/` | Slurm · sbatch arrays | job scripts, resources, dependency chain | [jobs](modules/jobs.md) |

## Stack

- **Cluster:** Hydra · account `epi-sim` · partitions `compute` (default, 48 h max), `debug`
  (30 min, 2 nodes) · modules `R/4.4.1`, `python/3.12`, `arrow/16.1` · scratch
  `/scratch/$USER/sim-study` (purged after 30 days) · results `/proj/epi-sim/sim-study/results`
- **Set up (login node):** `module load python/3.12 R/4.4.1 && uv sync && Rscript -e 'renv::restore()'`
- **Submit everything:** `bash slurm/submit.sh [grid.csv]` (prints the three job ids)
- **Test small:** `bash slurm/submit.sh --test` (2 array tasks on `debug`)
- **Watch / inspect:** `squeue --me` · `sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,ExitCode`
- **Debug one task:** inside `salloc -p debug -c 4 --mem=8G -t 30`, or on a laptop with the sample
  population: `SLURM_ARRAY_TASK_ID=7 Rscript scripts/simulate.R` (never on the login node)
- **Test:** `uv run pytest` (py) · `Rscript -e 'testthat::test_dir("tests/testthat")'` (R)
- **Lint:** `uv run ruff check py` · `Rscript -e 'lintr::lint_dir("R")'` · `shellcheck slurm/*.sh slurm/*.sbatch`
- **CI (ground truth):** `.github/workflows/ci.yml` — lint + unit tests + a 3-row grid run *without*
  Slurm (`scripts/run_local.sh`); nothing in CI submits jobs

## Map

| Area | Key files / dirs | Purpose | More |
|------|------------------|---------|------|
| Parameter grid | `params/grid.csv` `params/make_grid.R` | one row per simulation (≈1 000 rows) | [models](modules/models.md#parameter-grid) |
| Population build | `py/sim_prep/build.py` | census → `$SCRATCH/pop/<region>.parquet` | [preprocess](modules/preprocess.md) |
| Simulation | `scripts/simulate.R` `R/seir.R` | one grid row → `$SCRATCH/runs/<row>.parquet` | [models](modules/models.md) |
| Aggregation | `scripts/aggregate.R` `R/summarise.R` | all runs → `results/<date>/` tables + figures | [models](modules/models.md#aggregation) |
| Job scripts | `slurm/01_prep.sbatch` `slurm/02_simulate.sbatch` `slurm/03_aggregate.sbatch` | resources, env setup, logs | [jobs](modules/jobs.md) |
| Submit chain | `slurm/submit.sh` | submits 01 → 02 (array) → 03 with `afterok` | [jobs](modules/jobs.md#dependency-chain) |

## Where to start by task

- **Run the study** → [recipes](recipes.md#submit-the-whole-study)
- **Some array tasks failed** → [recipes](recipes.md#rerun-failed-array-tasks), [jobs](modules/jobs.md#when-jobs-fail)
- **Change the model** → [models](modules/models.md), then [test small](recipes.md#test-small-first)
- **Jobs are OOM / out of time** → [jobs](modules/jobs.md#resources)
- **Add a pipeline stage** → [recipes](recipes.md#add-a-job)

## Also see

- [architecture](architecture.md) · [conventions](conventions.md) · [glossary](glossary.md) · [log](log.md)
