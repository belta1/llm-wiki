---
updated: 2026-09-25
covers: [recipes, how-to, slurm]
status: current
---

# Recipes

Run from the repo dir on `hydra-login`. Environments are built here; **compute happens only in
jobs** (`sbatch`) or an interactive allocation (`salloc`).

## Set up (once, and after dependency changes)

```bash
module load python/3.12 R/4.4.1 arrow/16.1
uv sync                             # py/.venv from uv.lock
Rscript -e 'renv::restore()'        # R library from renv.lock
cp slurm/env.example.sh slurm/env.sh   # set SIM_SCRATCH / SIM_RESULTS if not the defaults
```

## Test small first

```bash
bash slurm/submit.sh --test        # debug partition; prep for 1 region, array=0-1, aggregate
sbatch --test-only slurm/02_simulate.sbatch   # validate the header / estimate a start time
```

Check `logs/` and `$SIM_SCRATCH/runs/` before a full submit.

## Submit the whole study

```bash
bash slurm/submit.sh                    # uses params/grid.csv; prints three job ids
bash slurm/submit.sh params/grid_v2.csv # another grid
```

`submit.sh` runs `sbatch --parsable` for each stage and passes `--dependency=afterok:<id>` plus
`--array=0-$((N-1))%100` computed from the grid's row count.

## Watch and inspect

```bash
squeue --me                                                   # queued / running
sacct -j <jobid> --format=JobID,JobName,State,Elapsed,MaxRSS,ExitCode   # per task after the fact
seff <jobid>_<task>                                           # CPU / memory efficiency of one task
tail -f logs/sim-simulate_<A>_<a>.out
scancel <jobid>                    # whole array · scancel <jobid>_<task> for one task
```

## Rerun failed array tasks

```bash
sacct -j <A> --state=FAILED,TIMEOUT,OUT_OF_MEMORY -n -X --format=JobID | sed 's/.*_//' | paste -sd, -
sbatch --array=<comma-list>%100 slurm/02_simulate.sbatch
sbatch --dependency=afterok:<new-id> slurm/03_aggregate.sbatch
```

A downstream job whose dependency failed stays `PENDING (DependencyNeverSatisfied)` — `scancel` it
and resubmit aggregate as above. TIMEOUT/OOM → raise `--time`/`--mem` first ([jobs](modules/jobs.md#resources)).

## Debug one task interactively

```bash
salloc -p debug -A epi-sim -c 4 --mem=8G -t 00:30:00
module load R/4.4.1 arrow/16.1
SLURM_ARRAY_TASK_ID=7 Rscript scripts/simulate.R
```

## Run tests and lint

```bash
uv run pytest                                      # py/ — one test: uv run pytest py/tests/test_build.py::test_households
Rscript -e 'testthat::test_dir("tests/testthat")'  # R/ — one file: testthat::test_file("tests/testthat/test-seir.R")
uv run ruff check py && Rscript -e 'lintr::lint_dir("R")' && shellcheck slurm/*.sh slurm/*.sbatch
```

These are light enough for the login node. `scripts/run_local.sh` (what CI runs) does a 3-row grid
end to end without Slurm — use it on a laptop, not on the login node.

## Change the parameter grid

Edit `params/make_grid.R`, then `Rscript params/make_grid.R` (writes `params/grid.csv`; commit it).
Keep `row_id` stable for unchanged rows so old runs stay comparable.

## Add a job

1. Copy the closest `slurm/0N_*.sbatch`; keep the [header order](conventions.md#slurm-job-scripts),
   set a new `--job-name=sim-<stage>` and realistic resources.
2. Its entry script reads inputs from and writes outputs to `$SIM_SCRATCH` (or `$SIM_RESULTS` for
   final outputs) and exits non-zero on failure.
3. Add it to `slurm/submit.sh` with the right `--dependency=afterok:` and to `--test` mode.
4. Add a row to the Jobs table in [jobs](modules/jobs.md).
