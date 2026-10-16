#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
DI="$GR/../planning/decision-index.py"
F=$(fixture); mkdir -p "$F/docs/backlog/uow-01"
printf 'SENSITIVE_DOMAINS="security billing"\n' > "$F/governance.env"
printf -- '---\nid: T-010\nstatus: done\n---\n' > "$F/docs/backlog/uow-01/T-010-x.md"
live() { printf '# D\n<!-- DECISION-INDEX:BEGIN -->\n<!-- DECISION-INDEX:END -->\n%b' "$1" > "$F/DECISIONS.md"; }
arch() { printf '# A\n%b' "$1" > "$F/DECISIONS_ARCHIVE.md"; }
pd() { printf '## %s — t\n- **Status:** `%s`\n- **Sensitivity:** `%s`\n- **Scope:** `local`\n- **Ratified-by:** %s\n%s\n' "$@"; }
run() { env GOV_ROOT="$F" python3 "$DI" "$@"; }
live ""; arch "$(pd PD-T001-01 DEFAULT_APPLIED internal '—' '')"
expect_pass "internal default awaiting ratification is fine" run
expect_pass "--check after regeneration" run --check
arch "$(pd PD-T001-01 DEFAULT_APPLIED billing '—' '')"
expect_fail "HARD GATE: sensitive default without ratification" run
arch "$(pd PD-T001-01 DEFAULT_APPLIED billing 'owner:billing (2026-01-02, direct)' '')"
expect_pass "ratified by a role counts" run
arch "$(pd PD-T001-01 RESOLVED internal '—' '')\n$(pd PD-T001-01 RESOLVED internal '—' '')"
run >/dev/null; expect_fail "duplicate id fails --check" run --check
arch ""; live "$(pd PD-T002-01 DEFERRED internal '—' '- **Reopen-trigger:** cmd: test -f '"$F"'/flag')"
run >/dev/null
out=$(run --check); grep -q "TRIGGER FIRED" <<<"$out" && { FAILS=$((FAILS+1)); echo "  ✗ cmd trigger fired without the condition"; } || PASS=$((PASS+1))
touch "$F/flag"; out=$(run --check)
grep -q "TRIGGER FIRED" <<<"$out" && PASS=$((PASS+1)) || { FAILS=$((FAILS+1)); echo "  ✗ cmd trigger not evaluated under --check"; echo "$out"; }
live "$(pd PD-T003-01 DEFERRED internal '—' '- **Reopen-trigger:** T-010 done')"; run >/dev/null
grep -q "TRIGGER FIRED" <<<"$(run --check)" && PASS=$((PASS+1)) || { FAILS=$((FAILS+1)); echo "  ✗ story trigger not fired"; }
rm -rf "$F"; finish
