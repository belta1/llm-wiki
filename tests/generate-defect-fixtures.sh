#!/usr/bin/env bash
# Build one deliberately-broken wiki per defect, from a known-good example.
# Regenerated on demand and gitignored — the golden source is examples/node-app.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

GOLDEN="examples/node-app/.llm-wiki"
OUT="tests/fixtures/defects"

if [ ! -d "$GOLDEN" ]; then
  echo "FAIL: golden wiki not found at $GOLDEN" >&2
  exit 1
fi

rm -rf "$OUT"
mkdir -p "$OUT"

make_fixture() {
  # make_fixture <name> — copy the golden wiki to $OUT/<name>/.llm-wiki
  mkdir -p "$OUT/$1"
  cp -r "$GOLDEN" "$OUT/$1/.llm-wiki"
  echo "$OUT/$1/.llm-wiki"
}

# 1. missing-stamp — the drift that actually shipped.
W=$(make_fixture missing-stamp)
grep -v "^wiki_contract: " "$W/index.md" > "$W/index.md.tmp"
mv "$W/index.md.tmp" "$W/index.md"

# 2. broken-link — a module page that no longer exists.
W=$(make_fixture broken-link)
printf '\n[gone](modules/does-not-exist.md)\n' >> "$W/architecture.md"

# 3. bad-frontmatter — a status value outside the allowed set.
# Edited with python3 rather than `sed -i`: sed rewrites the file's line
# endings, which turns a one-line defect into a whole-file diff and makes the
# fixture unreadable. (`sed -i` is also one of the GNU-isms CLAUDE.md warns off.)
W=$(make_fixture bad-frontmatter)
python3 "$SCRIPT_DIR/replace-once.py" "$W/conventions.md" "status: current" "status: fresh"

# 4. stamp-on-module-page — the contract key copied where it does not belong.
W=$(make_fixture stamp-on-module-page)
MODULE=$(ls "$W/modules/"*.md | head -1)
python3 "$SCRIPT_DIR/replace-once.py" "$MODULE" "status:" "wiki_contract: 2@@EOL@@status:"

# 5. secret-in-data-sources — a literal password in a connection string.
W=$(make_fixture secret-in-data-sources)
cat >> "$W/architecture.md" <<'ENTRY'

Connection used by the nightly job:
`Server=SRVPLATDAT;Database=Sales;UID=svc_etl;PWD=hunter2SuperSecret;`
ENTRY

# 6. oversized-index — an index far past its ~150 line budget.
W=$(make_fixture oversized-index)
for i in $(seq 1 200); do echo "- filler line $i" >> "$W/index.md"; done

# 7. broken-anchor — a link to a heading that is not there.
W=$(make_fixture broken-anchor)
printf '\nSee [recipes](recipes.md#no-such-heading-here).\n' >> "$W/architecture.md"

# 8. orphan-page — a page nothing links to.
W=$(make_fixture orphan-page)
cat > "$W/modules/stranded.md" <<'ORPHAN'
---
updated: 2026-09-23
covers: [stranded]
status: current
---

# Stranded

Nothing links here.
ORPHAN

# 9. bad-log-entry — a log line that breaks the parseable prefix.
W=$(make_fixture bad-log-entry)
echo "## [2026-09-23] refactor - did some things" >> "$W/log.md"

echo "Generated $(find "$OUT" -maxdepth 1 -mindepth 1 -type d | wc -l) defect fixtures in $OUT"
