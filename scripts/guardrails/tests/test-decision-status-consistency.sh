#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
F=$(fixture); mkdir -p "$F/docs/adr" "$F/docs/rfc"
run() { env GOV_ROOT="$F" "$GR/decision-status-consistency.sh"; }
adr() { printf -- '---\nid: %s\nstatus: %s\n---\n# %s\n' "$1" "$2" "$1" > "$F/docs/adr/$1-x.md"; }
index() { printf '| ADR | Title | Status |\n|---|---|---|\n' > "$F/docs/adr/README.md"; for r in "$@"; do echo "$r" >> "$F/docs/adr/README.md"; done; }
rfc() { printf -- '---\nid: %s\nstatus: %s\n---\n# x\n## Status\n- [ ] Awaiting approval\n- [%s] Approved — implement\n- [ ] Rejected\n' "$1" "$2" "$3" > "$F/docs/rfc/$1-x.md"; }
adr ADR-001 accepted; index '| [ADR-001](ADR-001-x.md) | X | `accepted` |'; rfc RFC-001 approved x
expect_pass "coherent records" run
index '| [ADR-001](ADR-001-x.md) | X | `proposed` |'
expect_fail "index disagrees with file" run
index '| [ADR-001](ADR-001-x.md) | X | `accepted` |'; adr ADR-001 DECIDED
expect_fail "status outside vocabulary" run
adr ADR-001 accepted; rfc RFC-001 approved " "
expect_fail "RFC front matter approved, block unchecked" run
rfc RFC-001 awaiting " "
expect_pass "awaiting with nothing checked" run
expect_fail "missing docs root is not OK (fail-closed)" env GOV_ROOT="$F" DECISION_DOCS_ROOT="$F/nope" "$GR/decision-status-consistency.sh"
rm -rf "$F"; finish
