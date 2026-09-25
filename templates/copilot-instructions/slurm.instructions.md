---
applyTo: "**/*.{sbatch,slurm}"
description: Slurm batch-script guidance from the llm-wiki knowledge base (installed by llm-wiki; re-running the installer replaces this file). Widen applyTo if this repo's job scripts are plain *.sh files.
---

# Slurm batch scripts in this repo

Before editing a job script, open `.llm-wiki/index.md` (its **Cluster** line) and the jobs module
page — it lists each job's resources, inputs/outputs, array mapping and dependencies. Use
`.llm-wiki/recipes.md` for submit / monitor / rerun commands. If the wiki and the code disagree, the
code wins.

**Script shape:**

- `#!/bin/bash` first, then **all `#SBATCH` lines before any command** — Slurm ignores directives
  after the first executable line.
- Use only the partitions, accounts, QoS and module versions the wiki lists for this cluster; don't
  invent them. Keep `--time` / `--mem` / `--cpus-per-task` close to what the job actually needs.
- Log with the repo's pattern (e.g. `#SBATCH -o logs/%x_%A_%a.out`); the `logs/` directory must
  exist before submission.
- `set -euo pipefail` after the header; `module purge` then explicit `module load <name>/<version>`;
  activate the project's environment (venv / conda / renv) the way the other scripts do.
- Match `--cpus-per-task` to the thread count passed to the program (`$SLURM_CPUS_PER_TASK`).

**Arrays and dependencies:**

- Map `$SLURM_ARRAY_TASK_ID` to inputs the same way existing jobs do (a params-file line, a file
  index); each task writes to its own output path — never a shared file.
- Throttle large arrays (`--array=0-999%50`) per the wiki's limits.
- Chain jobs with `--dependency=afterok:<jobid>` via the repo's submit script (`sbatch --parsable`),
  not by sleeping or polling.

**Safety:**

- Heavy compute never runs on a login node — go through `sbatch`, `srun` or `salloc`.
- Test small first: `sbatch --test-only`, `--array=0-1`, or the debug partition the wiki names.
- Write large intermediates to scratch (`$SCRATCH` or the wiki's path) and copy results back to
  project storage; scratch may be purged.
- No credentials or tokens in job scripts.

After a substantive change (new job, changed resources, new dependency edge), update the jobs page
in `.llm-wiki/` and append to `.llm-wiki/log.md`: `## [YYYY-MM-DD] update | <summary>`.
