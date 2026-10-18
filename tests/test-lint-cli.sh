#!/usr/bin/env bash
# Assert each deterministic check fires on its defect fixture, at its severity,
# and that the golden wiki it was derived from stays clean.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

CLI="$PROJECT_ROOT/scripts/llm-wiki"
FIXTURES="tests/fixtures/defects"
PASS=0
FAIL=0

log_pass() { PASS=$((PASS + 1)); printf "  \033[32mPASS\033[0m: %s\n" "$1"; }
log_fail() { FAIL=$((FAIL + 1)); printf "  \033[31mFAIL\033[0m: %s — %s\n" "$1" "$2"; }

echo "=== Lint CLI ==="

if [ ! -d "$FIXTURES" ]; then
  echo "  defect fixtures missing — generating"
  ./tests/generate-defect-fixtures.sh > /dev/null
fi

# expect <fixture> <code> <severity>
expect() {
  local fixture="$1" code="$2" severity="$3"
  local wiki="$FIXTURES/$fixture/.llm-wiki"
  if [ ! -d "$wiki" ]; then
    log_fail "$fixture" "fixture not generated"
    return
  fi
  local json
  json=$(python3 "$CLI" lint "$wiki" --json --no-catalog 2>&1)
  if ! printf '%s' "$json" | python3 -c "
import json, sys
payload = json.load(sys.stdin)
wanted_code, wanted_severity = sys.argv[1], sys.argv[2]
for finding in payload['findings']:
    if finding['code'] == wanted_code and finding['severity'] == wanted_severity:
        sys.exit(0)
print('got: ' + ', '.join(sorted({f['code'] + '/' + f['severity'] for f in payload['findings']})) or 'nothing')
sys.exit(1)
" "$code" "$severity" > /tmp/lint-cli-$$.out 2>&1; then
    log_fail "$fixture" "expected $code/$severity; $(cat /tmp/lint-cli-$$.out)"
  else
    log_pass "$fixture reports $code ($severity)"
  fi
  rm -f /tmp/lint-cli-$$.out
}

echo ""
echo "--- defects are detected ---"
expect missing-stamp         contract-missing      warning
expect broken-link           broken-link           critical
expect bad-frontmatter       frontmatter-value     critical
expect stamp-on-module-page  contract-misplaced    critical
expect secret-in-data-sources secret-password      critical
expect oversized-index       oversized-page        suggestion
expect broken-anchor         broken-anchor         critical
expect orphan-page           orphan-page           warning
expect bad-log-entry         log-format            warning

echo ""
echo "--- the golden wiki stays clean ---"
if python3 "$CLI" lint examples/node-app/.llm-wiki --no-catalog --fail-on suggestion > /dev/null 2>&1; then
  log_pass "examples/node-app is clean at --fail-on suggestion"
else
  log_fail "examples/node-app" "the fixture source itself has findings"
fi

echo ""
echo "--- --fail-on gates on severity ---"
# oversized-index carries only a suggestion, so critical must pass and
# suggestion must fail.
if python3 "$CLI" lint "$FIXTURES/oversized-index/.llm-wiki" --no-catalog --fail-on critical > /dev/null 2>&1; then
  log_pass "--fail-on critical ignores a suggestion"
else
  log_fail "--fail-on critical" "exited non-zero on a suggestion-only wiki"
fi
if python3 "$CLI" lint "$FIXTURES/oversized-index/.llm-wiki" --no-catalog --fail-on suggestion > /dev/null 2>&1; then
  log_fail "--fail-on suggestion" "exited zero despite a suggestion"
else
  log_pass "--fail-on suggestion gates on a suggestion"
fi

echo ""
echo "--- placeholders are not mistaken for defects ---"
# templates/wiki carries `updated: YYYY-MM-DD` and `<placeholder>` links.
if python3 "$CLI" lint templates/wiki --scaffold --no-catalog --fail-on warning > /dev/null 2>&1; then
  log_pass "template placeholders produce no findings"
else
  log_fail "templates/wiki" "placeholder text was reported as a defect"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
