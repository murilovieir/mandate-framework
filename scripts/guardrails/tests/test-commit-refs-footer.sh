#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
F=$(fixture); msg="$F/msg"
printf 'feat: x\n\nRefs: T-012, ADR-003\n' > "$msg"; expect_pass "T- footer" "$GR/commit-refs-footer.sh" --commit-msg-file "$msg"
printf 'docs: rfc\n\nRefs: RFC-007\n' > "$msg";       expect_pass "RFC- footer" "$GR/commit-refs-footer.sh" --commit-msg-file "$msg"
printf 'docs: x\n\nRefs: MF-042\n' > "$msg";        expect_pass "MF- footer" "$GR/commit-refs-footer.sh" --commit-msg-file "$msg"
printf 'feat: x\n\nRefs: ADR-003\n' > "$msg";         expect_fail "ADR-only footer" "$GR/commit-refs-footer.sh" --commit-msg-file "$msg"
printf 'feat: x\n' > "$msg";                           expect_fail "no footer" "$GR/commit-refs-footer.sh" --commit-msg-file "$msg"
# CI range: merge commits are skipped, authored commits are checked
git -C "$F" commit -q --allow-empty -m "base" -m "Refs: T-001"
git -C "$F" checkout -q -b feat
git -C "$F" commit -q --allow-empty -m "good" -m "Refs: T-002"
git -C "$F" checkout -q main && git -C "$F" commit -q --allow-empty -m "main moves" -m "Refs: T-003"
git -C "$F" merge -q --no-ff feat -m "Merge feat" >/dev/null
expect_pass "range with merge commit" env GOV_ROOT="$F" "$GR/commit-refs-footer.sh" --ci-range "HEAD~2...HEAD"
git -C "$F" commit -q --allow-empty -m "bad, no footer"
expect_fail "range with a bad commit" env GOV_ROOT="$F" "$GR/commit-refs-footer.sh" --ci-range "HEAD~1...HEAD"
expect_fail "invalid range is not OK (fail-closed)" env GOV_ROOT="$F" "$GR/commit-refs-footer.sh" --ci-range "0000000000000000000000000000000000000000...HEAD"
rm -rf "$F"; finish
