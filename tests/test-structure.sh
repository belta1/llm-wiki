#!/usr/bin/env bash
# Run the deterministic lint over every wiki this repo ships: the scaffold in
# templates/wiki/ and all nine examples/*/.llm-wiki/. The examples are copied by
# users as starting points, so they must satisfy the contract they demonstrate.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

CLI="$PROJECT_ROOT/scripts/llm-wiki"
PASS=0
FAIL=0

log_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m: %s\n" "$1"; }
log_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m: %s\n" "$1"; }

echo "=== Wiki Structure ==="

if [ ! -f "$CLI" ]; then
  log_fail "scripts/llm-wiki not found"
  exit 1
fi

# The user-global catalog is a developer's own file; never read it from a test.
LINT="python3 $CLI lint --no-catalog --fail-on warning"

echo ""
echo "--- templates/wiki (scaffold) ---"
OUTPUT=$($LINT templates/wiki --scaffold 2>&1)
if [ $? -eq 0 ]; then
  log_pass "templates/wiki is clean"
else
  log_fail "templates/wiki has findings"
  echo "$OUTPUT" | sed 's/^/      /'
fi

echo ""
echo "--- examples ---"
for dir in examples/*/; do
  name=$(basename "$dir")
  wiki="$dir.llm-wiki"
  if [ ! -d "$wiki" ]; then
    log_fail "$name has no .llm-wiki/"
    continue
  fi
  OUTPUT=$($LINT "$wiki" 2>&1)
  if [ $? -eq 0 ]; then
    log_pass "$name is clean"
  else
    log_fail "$name has findings"
    echo "$OUTPUT" | sed 's/^/      /'
  fi
done

echo ""
echo "--- contract stamps ---"
# Regression guard: this is the drift that shipped once already.
for dir in examples/*/; do
  name=$(basename "$dir")
  index="$dir.llm-wiki/index.md"
  [ -f "$index" ] || continue
  if grep -q "^wiki_contract: " "$index"; then
    log_pass "$name/index.md carries a wiki_contract stamp"
  else
    log_fail "$name/index.md has no wiki_contract stamp"
  fi
done

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
