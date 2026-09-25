#!/usr/bin/env bash
#
# install-copilot.sh — install the llm-wiki integration for GitHub Copilot into a repo.
#
# GitHub Copilot has no plugin system; it reads repository custom instructions from
# .github/copilot-instructions.md. This script installs that pointer file (merging into any
# existing one via a managed block) so Copilot is told to read the repo's .llm-wiki/ knowledge
# base first, plus the /llm-wiki-* prompt files. Optionally it also scaffolds .llm-wiki/ from the
# bundled templates.
#
# It also installs path-scoped instructions (.github/instructions/<stack>.instructions.md) for
# each stack it detects in the target:
#   tsql      *.sqlproj / *.dtsx, or *.sql with T-SQL syntax (GO, SET NOCOUNT, NVARCHAR, ...)
#   postgres  *.sql with PostgreSQL syntax ($$, plpgsql, \i, JSONB, ...), .psqlrc, sqitch.plan
#   r         *.R / *.Rmd, renv.lock, *.Rproj, _targets.R, an R package DESCRIPTION
#   slurm     *.sbatch / *.slurm, or shell scripts containing #SBATCH
#
# Idempotent: re-running replaces only the managed block / plugin-owned files.
#
# Usage:
#   scripts/install-copilot.sh [TARGET_REPO] [--scaffold] [--all-pointers]
#                              [--tsql] [--postgres] [--r] [--slurm] [--no-path-instructions]
#
#   TARGET_REPO             Path to the repo to install into (default: current directory).
#   --scaffold              Also copy the template wiki pages into <repo>/.llm-wiki/ if none exists.
#   --all-pointers          Also install CLAUDE.md and AGENTS.md pointers (not just Copilot).
#   --tsql                  Install the T-SQL path-scoped instructions even if not detected.
#   --postgres              Install the PostgreSQL path-scoped instructions even if not detected.
#   --r                     Install the R path-scoped instructions even if not detected.
#   --slurm                 Install the Slurm path-scoped instructions even if not detected.
#   --no-path-instructions  Never install path-scoped instructions (.github/instructions/).
#   -h, --help              Show this help.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_ROOT/templates"

TARGET="."
SCAFFOLD=0
ALL_POINTERS=0
TSQL=0
POSTGRES=0
R_LANG=0
SLURM=0
NO_PATH_INSTRUCTIONS=0

# Print the header comment block (everything after the shebang up to the first non-comment line).
usage() { awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --scaffold) SCAFFOLD=1 ;;
    --all-pointers) ALL_POINTERS=1 ;;
    --tsql) TSQL=1 ;;
    --postgres) POSTGRES=1 ;;
    --r) R_LANG=1 ;;
    --slurm) SLURM=1 ;;
    --no-path-instructions) NO_PATH_INSTRUCTIONS=1 ;;
    -*) echo "error: unknown option '$1'" >&2; usage; exit 1 ;;
    *) TARGET="$1" ;;
  esac
  shift
done

if [ ! -d "$TEMPLATES/pointers" ]; then
  echo "error: templates not found at $TEMPLATES — run this script from within the llm-wiki plugin." >&2
  exit 1
fi

TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { echo "error: target repo '$TARGET' not found." >&2; exit 1; }

# Install a managed <!-- BEGIN llm-wiki --> ... <!-- END llm-wiki --> block from a template.
# Creates the file if absent, replaces the block if present, appends it otherwise.
install_block() {
  local tpl="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ ! -f "$dest" ]; then
    cat "$tpl" > "$dest"
    echo "  created  $dest"
  elif grep -q '<!-- BEGIN llm-wiki -->' "$dest"; then
    # Stream the parts straight to the temp file (no $(…)) so surrounding blank lines survive
    # byte-for-byte and a re-run is a true no-op.
    { sed '/<!-- BEGIN llm-wiki -->/,$d' "$dest"
      cat "$tpl"
      sed '1,/<!-- END llm-wiki -->/d' "$dest"
    } > "$dest.tmp"
    if cmp -s "$dest.tmp" "$dest"; then
      rm -f "$dest.tmp"
      echo "  ok       $dest (managed block already current)"
    else
      mv "$dest.tmp" "$dest"
      echo "  updated  $dest (managed block)"
    fi
  else
    printf '\n' >> "$dest"
    cat "$tpl" >> "$dest"
    echo "  appended $dest (managed block)"
  fi
}

# Copy a plugin-owned file, reporting created / updated / unchanged.
install_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ ! -f "$dest" ]; then
    cp "$src" "$dest"
    echo "  created  $dest"
  elif cmp -s "$src" "$dest"; then
    echo "  ok       $dest (unchanged)"
  else
    cp "$src" "$dest"
    echo "  updated  $dest"
  fi
}

# --- Stack detection (read-only; dependency/build/output dirs are skipped) ---------------------

PRUNE=( \( -name node_modules -o -name .git -o -name .venv -o -name venv -o -name bin -o -name obj \
           -o -name dist -o -name build -o -name renv -o -name .Rproj.user -o -name _targets \) -prune )

# Print the first file under $1 matching the find(1) name tests that follow.
first_file() {
  local root="$1"; shift
  find "$root" "${PRUNE[@]}" -o -type f \( "$@" \) -print 2>/dev/null | head -n 1
}

# Print the first file under $1 matching the name tests after $2 whose contents match ERE $2
# (case-insensitive).
first_file_containing() {
  local root="$1" re="$2"; shift 2
  find "$root" "${PRUNE[@]}" -o -type f \( "$@" \) -print0 2>/dev/null \
    | xargs -0 grep -liE -- "$re" 2>/dev/null | head -n 1
}

# *.sql alone doesn't tell T-SQL from PostgreSQL, so look for dialect markers.
TSQL_RE='^[[:space:]]*GO[[:space:]]*$|^:r |^:setvar |SET NOCOUNT|NVARCHAR|CREATE OR ALTER|IDENTITY\([0-9]'
POSTGRES_RE='\$\$|plpgsql|^\\i|^\\set |JSONB|TIMESTAMPTZ|BIGSERIAL|CREATE EXTENSION|ON CONFLICT'

has_tsql() {
  [ -n "$(first_file "$1" -name '*.sqlproj' -o -name '*.dtproj' -o -name '*.dtsx')" ] ||
  [ -n "$(first_file_containing "$1" "$TSQL_RE" -name '*.sql')" ]
}

has_postgres() {
  [ -n "$(first_file "$1" -name .psqlrc -o -name sqitch.plan -o -name pg_service.conf)" ] ||
  [ -n "$(first_file_containing "$1" "$POSTGRES_RE" -name '*.sql')" ]
}

has_r() {
  [ -n "$(first_file "$1" -iname '*.r' -o -iname '*.rmd' -o -name renv.lock -o -name '*.Rproj' \
                          -o -name _targets.R)" ] ||
  [ -n "$(first_file_containing "$1" '^Package:' -name DESCRIPTION)" ]
}

has_slurm() {
  [ -n "$(first_file "$1" -name '*.sbatch' -o -name '*.slurm')" ] ||
  [ -n "$(first_file_containing "$1" '^#SBATCH' -name '*.sh' -o -name '*.bash' -o -name '*.job')" ]
}

# Install templates/copilot-instructions/<name>.instructions.md if forced ($2=1) or detected ($3).
install_path_instructions() {
  local name="$1" forced="$2" detector="$3" label="$4"
  if [ "$forced" -eq 0 ]; then
    "$detector" "$TARGET" || return 0
    echo "  detected $label"
  fi
  install_file "$TEMPLATES/copilot-instructions/$name.instructions.md" \
               "$TARGET/.github/instructions/$name.instructions.md"
}

echo "Installing llm-wiki Copilot integration into: $TARGET"

[ -d "$TARGET/.git" ] || echo "  note: target is not a git repository (Copilot reads committed files — remember to commit)."

# 1) Optionally scaffold the wiki pages.
if [ "$SCAFFOLD" -eq 1 ]; then
  if [ -d "$TARGET/.llm-wiki" ]; then
    echo "  skip     .llm-wiki/ already exists — left untouched"
  else
    cp -R "$TEMPLATES/wiki" "$TARGET/.llm-wiki"
    echo "  created  $TARGET/.llm-wiki/ (placeholder pages — fill them in)"
  fi
fi

# 2) Install the Copilot pointer (always).
install_block "$TEMPLATES/pointers/copilot-instructions.md" "$TARGET/.github/copilot-instructions.md"

# 2b) Install Copilot prompt files — the /llm-wiki-init|update|lint commands for VS Code Copilot Chat.
if [ -d "$TEMPLATES/copilot-prompts" ]; then
  for f in "$TEMPLATES"/copilot-prompts/*.prompt.md; do
    install_file "$f" "$TARGET/.github/prompts/$(basename "$f")"
  done
fi

# 2c) Path-scoped instructions for each detected (or requested) stack.
if [ "$NO_PATH_INSTRUCTIONS" -eq 0 ]; then
  install_path_instructions tsql     "$TSQL"     has_tsql     "T-SQL sources (*.sqlproj / *.dtsx / T-SQL *.sql)"
  install_path_instructions postgres "$POSTGRES" has_postgres "PostgreSQL sources (psql / PL/pgSQL *.sql)"
  install_path_instructions r        "$R_LANG"   has_r        "R sources (*.R / *.Rmd / renv / targets)"
  install_path_instructions slurm    "$SLURM"    has_slurm    "Slurm batch scripts (#SBATCH)"
fi

# 3) Optionally install the other tools' pointers too.
if [ "$ALL_POINTERS" -eq 1 ]; then
  install_block "$TEMPLATES/pointers/CLAUDE.md" "$TARGET/CLAUDE.md"
  install_block "$TEMPLATES/pointers/AGENTS.md" "$TARGET/AGENTS.md"
fi

if [ ! -d "$TARGET/.llm-wiki" ]; then
  echo
  echo "  warning: $TARGET has no .llm-wiki/ yet, so Copilot is pointed at a wiki that doesn't exist."
  echo "           Re-run with --scaffold for starter pages, or generate a real one with"
  echo "           /llm-wiki:init in Claude Code, then fill it in."
fi

echo
echo "Done. Next steps for GitHub Copilot:"
echo "  - Commit .github/ (Copilot reads committed repo files)."
echo "  - In VS Code, ensure setting 'github.copilot.chat.codeGeneration.useInstructionFiles' is on"
echo "    (default in current versions). github.com/mobile Copilot picks it up automatically."
echo "  - To POPULATE the wiki, open Copilot Chat in VS Code (Agent mode) and run '/llm-wiki-init'"
echo "    (prompt files may need the 'chat.promptFiles' setting enabled). Later: /llm-wiki-update,"
echo "    /llm-wiki-lint. No VS Code? Paste the text of .github/prompts/llm-wiki-init.prompt.md into"
echo "    any Copilot agent chat."
