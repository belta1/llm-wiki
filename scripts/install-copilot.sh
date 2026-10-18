#!/usr/bin/env bash
#
# install-copilot.sh — install the llm-wiki integration for GitHub Copilot into a repo.
#
# GitHub Copilot has no plugin system; it reads repository custom instructions from
# .github/copilot-instructions.md. This script installs that pointer file (merging into any
# existing one via a managed block) so Copilot is told to read the repo's .llm-wiki/ knowledge
# base first, plus the /llm-wiki-* prompt files (/llm-wiki-init, -update, -lint, -upgrade, -view)
# and the deterministic lint CLI at .llm-wiki/bin/llm-wiki. Optionally it also scaffolds .llm-wiki/
# from the bundled templates.
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
#   scripts/install-copilot.sh [TARGET_REPO] [--scaffold] [--view] [--all-pointers]
#                              [--tsql] [--postgres] [--r] [--slurm] [--no-path-instructions]
#                              [--no-cli]
#
#   TARGET_REPO             Path to the repo to install into (default: current directory).
#   --scaffold              Also copy the template wiki pages into <repo>/.llm-wiki/ if none exists.
#   --view                  Also scaffold the HTML view (<repo>/.llm-wiki/view/index.html) and
#                           gitignore it. It's a human-only review dashboard; regenerate with the
#                           /llm-wiki-view prompt. Agents still read the Markdown.
#   --all-pointers          Also install CLAUDE.md and AGENTS.md pointers (not just Copilot).
#   --tsql                  Install the T-SQL path-scoped instructions even if not detected.
#   --postgres              Install the PostgreSQL path-scoped instructions even if not detected.
#   --r                     Install the R path-scoped instructions even if not detected.
#   --slurm                 Install the Slurm path-scoped instructions even if not detected.
#   --no-path-instructions  Never install path-scoped instructions (.github/instructions/).
#   --no-cli                Don't install the deterministic lint CLI (.llm-wiki/bin/llm-wiki). The
#                           /llm-wiki-lint and /llm-wiki-upgrade prompts then do every check
#                           themselves instead of starting from its output.
#   --data-sources-profile-dir DIR
#                           Write/refresh the cross-project data-source instruction file
#                           (llm-wiki-data-sources.instructions.md) into this VS Code user-profile
#                           instructions DIR, generated from ~/.claude/llm-wiki/data-sources.md.
#                           Omit to only print how to set it up. VS Code-only.
#   -h, --help              Show this help.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_ROOT/templates"

TARGET="."
SCAFFOLD=0
VIEW=0
ALL_POINTERS=0
TSQL=0
POSTGRES=0
R_LANG=0
SLURM=0
NO_PATH_INSTRUCTIONS=0
NO_CLI=0
DATA_SOURCES_PROFILE_DIR=""

# Print the header comment block (everything after the shebang up to the first non-comment line).
usage() { awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --scaffold) SCAFFOLD=1 ;;
    --view) VIEW=1 ;;
    --all-pointers) ALL_POINTERS=1 ;;
    --tsql) TSQL=1 ;;
    --postgres) POSTGRES=1 ;;
    --r) R_LANG=1 ;;
    --slurm) SLURM=1 ;;
    --no-path-instructions) NO_PATH_INSTRUCTIONS=1 ;;
    --no-cli) NO_CLI=1 ;;
    --data-sources-profile-dir) DATA_SOURCES_PROFILE_DIR="${2:-}"; shift ;;
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

# Ensure the target repo's .gitignore ignores a path (idempotent).
ignore_path() {
  local line="$1" gi="$TARGET/.gitignore"
  if [ -f "$gi" ] && grep -qxF "$line" "$gi" 2>/dev/null; then
    echo "  ok       .gitignore already ignores $line"
    return
  fi
  printf '\n# llm-wiki — derived HTML view (regenerate with /llm-wiki-view)\n%s\n' "$line" >> "$gi"
  echo "  updated  $gi (ignore $line)"
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

# Write/refresh the cross-project data-source instruction file into a VS Code user-profile dir.
# The managed <!-- BEGIN/END llm-wiki --> block is regenerated from ~/.claude/llm-wiki/data-sources.md;
# frontmatter/guidance outside the block (and any other file in the dir) is preserved. The namespaced
# filename means this never collides with instruction files the user authored themselves.
install_data_sources() {
  local profile_dir="$1"
  local tpl="$TEMPLATES/copilot-instructions/data-sources.instructions.md"
  local dest="$profile_dir/llm-wiki-data-sources.instructions.md"
  local catalog="$HOME/.claude/llm-wiki/data-sources.md"
  mkdir -p "$profile_dir"

  # Block body: the catalog with a leading YAML frontmatter block stripped, else a placeholder.
  local bodyfile; bodyfile="$(mktemp)"
  if [ -f "$catalog" ]; then
    awk 'NR==1 && $0=="---"{f=1; next} f==1 && $0=="---"{f=2; next} f==2 || f==0' "$catalog" > "$bodyfile"
  else
    printf '%s\n' '_No data-source catalog found yet. Run `/llm-wiki:init` in Claude Code, or create `~/.claude/llm-wiki/data-sources.md`._' > "$bodyfile"
  fi

  # Base is the existing file, or the template scaffold on first install.
  local base created=0
  if [ -f "$dest" ]; then base="$dest"; else base="$tpl"; created=1; fi

  local tmp; tmp="$(mktemp)"
  if grep -q '<!-- BEGIN llm-wiki -->' "$base"; then
    { sed '/<!-- BEGIN llm-wiki -->/,$d' "$base"
      printf '%s\n' '<!-- BEGIN llm-wiki -->'
      cat "$bodyfile"
      printf '%s\n' '<!-- END llm-wiki -->'
      sed '1,/<!-- END llm-wiki -->/d' "$base"
    } > "$tmp"
  else
    { cat "$base"; printf '\n%s\n' '<!-- BEGIN llm-wiki -->'; cat "$bodyfile"; printf '%s\n' '<!-- END llm-wiki -->'; } > "$tmp"
  fi
  rm -f "$bodyfile"

  if [ "$created" -eq 1 ]; then
    mv "$tmp" "$dest"; echo "  created  $dest"
  elif cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"; echo "  ok       $dest (data sources already current)"
  else
    mv "$tmp" "$dest"; echo "  updated  $dest (data sources)"
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

# 1b) Optionally scaffold the human-only HTML view and gitignore it.
if [ "$VIEW" -eq 1 ]; then
  if [ -f "$TEMPLATES/view/index.html" ]; then
    install_file "$TEMPLATES/view/index.html" "$TARGET/.llm-wiki/view/index.html"
    ignore_path ".llm-wiki/view/"
  else
    echo "  skip     view template not found at $TEMPLATES/view/index.html"
  fi
fi

# 2) Install the Copilot pointer (always).
install_block "$TEMPLATES/pointers/copilot-instructions.md" "$TARGET/.github/copilot-instructions.md"

# 2b) Install Copilot prompt files — /llm-wiki-init, -update, -lint, -upgrade and -view in VS Code
# Copilot Chat. Globbed, so a prompt added to the plugin ships without editing this script.
if [ -d "$TEMPLATES/copilot-prompts" ]; then
  for f in "$TEMPLATES"/copilot-prompts/*.prompt.md; do
    install_file "$f" "$TARGET/.github/prompts/$(basename "$f")"
  done
fi

# 2b-ii) Install the deterministic lint CLI next to the wiki it checks. Copilot has no
# ${CLAUDE_PLUGIN_ROOT}, so the script has to live in the target repo for /llm-wiki-lint to run it.
if [ "$NO_CLI" -eq 0 ]; then
  if [ -f "$PLUGIN_ROOT/scripts/llm-wiki" ]; then
    install_file "$PLUGIN_ROOT/scripts/llm-wiki" "$TARGET/.llm-wiki/bin/llm-wiki"
    chmod +x "$TARGET/.llm-wiki/bin/llm-wiki" 2>/dev/null || true
  else
    echo "  skip     lint CLI not found at $PLUGIN_ROOT/scripts/llm-wiki"
  fi
fi

# 2c) Path-scoped instructions for each detected (or requested) stack.
if [ "$NO_PATH_INSTRUCTIONS" -eq 0 ]; then
  install_path_instructions tsql     "$TSQL"     has_tsql     "T-SQL sources (*.sqlproj / *.dtsx / T-SQL *.sql)"
  install_path_instructions postgres "$POSTGRES" has_postgres "PostgreSQL sources (psql / PL/pgSQL *.sql)"
  install_path_instructions r        "$R_LANG"   has_r        "R sources (*.R / *.Rmd / renv / targets)"
  install_path_instructions slurm    "$SLURM"    has_slurm    "Slurm batch scripts (#SBATCH)"
fi

# 2d) Optional: cross-project data-source catalog as a VS Code user-profile instruction file.
if [ -n "$DATA_SOURCES_PROFILE_DIR" ]; then
  echo "Installing data-source catalog instruction file (VS Code user profile):"
  install_data_sources "$DATA_SOURCES_PROFILE_DIR"
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
echo "    /llm-wiki-lint, /llm-wiki-upgrade. No VS Code? Paste the text of"
echo "    .github/prompts/llm-wiki-init.prompt.md into any Copilot agent chat."
if [ "$NO_CLI" -eq 0 ]; then
  echo "  - '/llm-wiki-lint' starts from 'python3 .llm-wiki/bin/llm-wiki lint', which does the"
  echo "    mechanical checks with no model at all. Run it yourself any time, or in CI."
fi
echo "  - For a human review dashboard, run '/llm-wiki-view' (or re-run this script with --view) to"
echo "    build .llm-wiki/view/index.html, then open it in VS Code's Simple Browser. It's derived from"
echo "    the Markdown and gitignored; agents keep reading the Markdown."
if [ -z "$DATA_SOURCES_PROFILE_DIR" ]; then
  echo
  echo "  - Cross-project data sources (VS Code, optional): run 'Chat: New Instructions File' from the"
  echo "    Command Palette and choose 'User' to find your profile instructions folder, then re-run with"
  echo "    --data-sources-profile-dir <that folder> to install a user-global"
  echo "    llm-wiki-data-sources.instructions.md generated from ~/.claude/llm-wiki/data-sources.md."
  echo "    It applies in every workspace. VS Code only."
fi
