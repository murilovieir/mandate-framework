#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
F=$(fixture); mkdir -p "$F/docs/backlog/uow-01"
spec() { # $1=ACs $2=files
  { echo "# T"; echo "### Expected files"; for i in $(seq "$2"); do echo "- \`f$i\`"; done
    echo "## Acceptance Criteria"; for i in $(seq "$1"); do echo "- [ ] AC-$i: x"; done; }; }
spec 5 8 > "$F/ok.md";   expect_pass "5 ACs / 8 files" "$GR/task-spec-shape.sh" "$F/ok.md"
spec 6 2 > "$F/acs.md";  expect_fail "6 ACs" "$GR/task-spec-shape.sh" "$F/acs.md"
spec 2 9 > "$F/fls.md";  expect_fail "9 files" "$GR/task-spec-shape.sh" "$F/fls.md"
for i in $(seq 9); do spec 1 1 > "$F/docs/backlog/uow-01/T-00$i-x.md"; done
expect_fail "UoW with 9 stories" "$GR/task-spec-shape.sh" --uow "$F/docs/backlog/uow-01"
# hook: new oversized spec warns (exit 0 + systemMessage), existing spec is ignored
json=$(jq -nc --arg p "$F/docs/backlog/uow-02/T-100-new.md" --arg c "$(spec 7 1)" '{tool_input:{file_path:$p,content:$c}}')
out=$(echo "$json" | GOV_ROOT="$F" "$GR/task-spec-shape.sh" --hook); rc=$?
[ "$rc" -eq 0 ] && grep -q systemMessage <<<"$out" && PASS=$((PASS+1)) || { FAILS=$((FAILS+1)); echo "  ✗ hook should warn and exit 0"; }
# CI range: only NEW specs count (no retroaction)
spec 9 1 > "$F/docs/backlog/uow-01/T-001-x.md"
git -C "$F" add -A && git -C "$F" commit -q -m base
spec 1 1 > "$F/docs/backlog/uow-01/T-050-new.md"; git -C "$F" add -A && git -C "$F" commit -q -m ok
expect_pass "pre-existing violation not retroactive" env GOV_ROOT="$F" "$GR/task-spec-shape.sh" --ci-range "HEAD~1...HEAD"
spec 6 1 > "$F/docs/backlog/uow-01/T-051-new.md"; git -C "$F" add -A && git -C "$F" commit -q -m bad
expect_fail "new oversized spec in range" env GOV_ROOT="$F" "$GR/task-spec-shape.sh" --ci-range "HEAD~1...HEAD"
rm -rf "$F"; finish
