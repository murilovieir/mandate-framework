#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
F=$(fixture); U="$F/docs/backlog/uow-01"; mkdir -p "$U"
story() { printf -- '---\nid: %s\nstatus: %s\n---\n' "$1" "$2" > "$U/$1-x.md"; }
gate() { printf -- '---\nid: UOW-01\nstatus: %s\nexit_gate:\n%b---\n# UoW\n' "$1" "$2" > "$U/_index.md"; }
run() { (cd "$F" && env GOV_ROOT="$F" "$GR/uow-gate.sh" "$@"); }
story T-001 done; story T-002 todo
gate open '  stories_done: [T-001]\n  commands:\n    - true\n'
expect_pass "met gate (stories + command)" run docs/backlog/uow-01
gate open '  stories_done: [T-001, T-002]\n'
expect_fail "unmet story" run docs/backlog/uow-01
expect_pass "--all: open UoW with unmet gate is fine" run --all
gate closed '  stories_done: [T-001, T-002]\n'
expect_fail "--all: closed UoW with unmet gate" run --all
gate open '  stories_done: [T-001]\n  commands:\n    - false\n'
expect_fail "failing command" run docs/backlog/uow-01
gate open '  done_when: "the API feels stable"\n'
expect_fail "--all: prose key is refused" run --all
gate open '  stories_done: [T-001]\n  reviewed_by: [team-lead]\n'
expect_fail "--all: unknown list-shaped key is refused" run --all
printf -- '---\nid: UOW-01\nstatus: open\n---\n' > "$U/_index.md"
expect_fail "--all: missing exit_gate" run --all
echo "docs/backlog/uow-01 # legacy" > "$F/allow.txt"; mkdir -p "$F/scripts/guardrails/allowlists"; cp "$F/allow.txt" "$F/scripts/guardrails/allowlists/uow-gate.txt"
expect_pass "--all: allowlisted legacy UoW" run --all
rm -rf "$F"; finish
