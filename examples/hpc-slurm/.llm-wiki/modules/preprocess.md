---
updated: 2026-09-25
covers: [python, preprocess, population]
status: current
---

# Preprocess (`py/`)

Builds a synthetic population and contact network per region from census extracts. Runs once per
study as `01_prep.sbatch`.

## Key files & entry points

- `py/sim_prep/build.py` — CLI: `python -m sim_prep.build --census <dir> --out <dir> [--region X]`.
- `py/sim_prep/households.py` — household assignment from census household-size tables.
- `py/sim_prep/contacts.py` — contact lists (household + age-mixed community contacts).
- `py/sim_prep/schema.py` — the parquet schema R depends on ([seam](../architecture.md#the-seam-between-components)).
- `py/tests/` — pytest on a tiny fake census in `py/tests/fixtures/`.

## How it works

For each region in the census extract: sample persons to match age × sex marginals, group them into
households, then draw community contacts from the age-mixing matrix in `py/data/mixing.csv`.
Regions are processed in parallel with a process pool sized from `SLURM_CPUS_PER_TASK`
(default 1 locally). Output: `$SIM_SCRATCH/pop/<region>.parquet`, written atomically.

## Gotchas

- **Schema changes are cross-language** — change `schema.py`, `R/load_pop.R`, and the parquet
  fixture in `tests/testthat/fixtures/` together.
- `contacts` is a `list<int64>` column; very large regions (> 5 M people) need the 32G in
  `01_prep.sbatch`.
- Random draws use `numpy.random.default_rng(seed)` with `--seed` from `submit.sh` (default 1), so a
  population is reproducible; the simulation seeds come from the grid, separately.
- Census extracts on `/proj/epi-sim/census/` are read-only and licensed — never copy them into the repo.

## Related

- [jobs](jobs.md) · [models](models.md) · [conventions](../conventions.md#python-py)
