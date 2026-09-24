#!/usr/bin/env bash
#
# install-copilot.sh — install the llm-wiki integration for GitHub Copilot into a repo.
#
# GitHub Copilot has no plugin system; it reads repository custom instructions from
# .github/copilot-instructions.md. This script installs that pointer file (merging into any
# existing one via a managed block) so Copilot is told to read the repo's .llm-wiki/ knowledge
# base first. Optionally it also scaffolds .llm-wiki/ from the bundled templates.
#
# Usage:
#   scripts/install-copilot.sh [TARGET_REPO] [--scaffold] [--all-pointers]
#
#   TARGET_REPO     Path to the repo to install into (default: current directory).
#   --scaffold      Also copy the template wiki pages into <repo>/.llm-wiki/ if none exists.
#   --all-pointers  Also install CLAUDE.md and AGENTS.md pointers (not just Copilot).
#   -h, --help      Show this help.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$PLUGIN_ROOT/templates"

TARGET="."
SCAFFOLD=0
ALL_POINTERS=0

usage() { sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --scaffold) SCAFFOLD=1 ;;
    --all-pointers) ALL_POINTERS=1 ;;
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
    local before after
    before="$(sed '/<!-- BEGIN llm-wiki -->/,$d' "$dest")"
    after="$(sed '1,/<!-- END llm-wiki -->/d' "$dest")"
    { [ -n "$before" ] && printf '%s\n' "$before"
      cat "$tpl"
      [ -n "$after" ] && printf '%s\n' "$after"
    } > "$dest.tmp"
    mv "$dest.tmp" "$dest"
    echo "  updated  $dest (managed block)"
  else
    printf '\n' >> "$dest"
    cat "$tpl" >> "$dest"
    echo "  appended $dest (managed block)"
  fi
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
echo "  - Commit .github/copilot-instructions.md (Copilot reads committed repo files)."
echo "  - In VS Code, ensure setting 'github.copilot.chat.codeGeneration.useInstructionFiles' is on"
echo "    (default in current versions). github.com/mobile Copilot picks it up automatically."
