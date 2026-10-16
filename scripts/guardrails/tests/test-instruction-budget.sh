#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
F=$(fixture); C="$F/ceil.txt"
printf 'a\nb\n\nc\n' > "$F/CLAUDE.md"   # 3 effective lines
run() { env GOV_ROOT="$F" BUDGET_FILES="CLAUDE.md" GUARDRAIL_BUDGET_CEILING="$C" "$GR/instruction-budget.sh" "$@"; }
expect_fail "no ceiling recorded" run
expect_pass "record first ceiling" run --record
expect_pass "within ceiling" run
echo d >> "$F/CLAUDE.md"
expect_fail "above ceiling" run
expect_fail "--record never raises" run --record
grep -q '^CLAUDE.md 3 3$' "$C" && PASS=$((PASS+1)) || { FAILS=$((FAILS+1)); echo "  ✗ ceiling changed by a refused --record"; }
printf 'a\n' > "$F/CLAUDE.md"
expect_pass "--record lowers" run --record
grep -q '^CLAUDE.md 1 3$' "$C" && PASS=$((PASS+1)) || { FAILS=$((FAILS+1)); echo "  ✗ lowered ceiling / preserved target"; }
rm -rf "$F"; finish
