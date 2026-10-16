#!/usr/bin/env bash
# Tiny test harness: each test file sources this, calls expect_pass/expect_fail, then `finish`.
set -uo pipefail
GR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAILS=0
expect_pass() { local name="$1"; shift; if "$@" >/tmp/gr-test.$$ 2>&1; then PASS=$((PASS+1)); else FAILS=$((FAILS+1)); echo "  ✗ expected PASS: $name"; sed 's/^/      /' /tmp/gr-test.$$; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/tmp/gr-test.$$ 2>&1; then FAILS=$((FAILS+1)); echo "  ✗ expected FAIL: $name"; sed 's/^/      /' /tmp/gr-test.$$; else PASS=$((PASS+1)); fi; }
fixture() { local d; d=$(mktemp -d); git -C "$d" init -q -b main; git -C "$d" config user.email t@t; git -C "$d" config user.name t; echo "$d"; }
finish() { rm -f /tmp/gr-test.$$; echo "$(basename "$0"): $PASS passed, $FAILS failed"; [ "$FAILS" -eq 0 ]; }
