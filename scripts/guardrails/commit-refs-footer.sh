#!/usr/bin/env bash
# scripts/guardrails/commit-refs-footer.sh — RULE-PM-02: every authored commit references the work
# in its footer: `Refs: T-NNN[, ADR-NNN]`, or `RFC-NNN` when the change is born from an RFC that has
# no story yet (an RFC is written BEFORE decomposition, so requiring T-NNN there would reject it by
# construction). A footer with only `ADR-NNN` fails: an ADR is the decision, not the work.
#
# Local consumer is the native git `commit-msg` hook (a PreToolUse matcher on Edit|Write never sees
# `git commit`): `git config core.hooksPath scripts/guardrails/git-hooks`. Same script in CI.
#
# Usage:
#   commit-refs-footer.sh --commit-msg-file <path>   # git hook (local) — blocks the commit
#   commit-refs-footer.sh --ci-range <base>...<head>  # CI: every non-merge commit of the range
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT" || exit 2

# MF-NNN = stories of the Mandate framework's own roadmap (ROADMAP.md); adopters use T-NNN.
PATTERN='^Refs:.*\b(T|RFC|MF)-[0-9]+'

check_message() { grep -qE "$PATTERN" <<<"$1"; }

case "${1:-}" in
  --commit-msg-file)
    file="${2:?usage: --commit-msg-file <path>}"
    msg=$(grep -v '^#' "$file")
    check_message "$msg" && exit 0
    echo "guardrail [commit-refs-footer]: commit without a 'Refs: T-NNN' (or RFC-NNN) footer (RULE-PM-02)." >&2
    echo "Add it at the end of the message, e.g. 'Refs: T-012, ADR-003'." >&2
    exit 1
    ;;
  --ci-range)
    range="${2:?usage: --ci-range <base>...<head>}"
    fail=0
    git rev-list --no-merges "$range" >/dev/null 2>&1 \
      || { echo "FAIL [commit-refs-footer]: invalid range '$range' — not verified, never OK."; exit 2; }
    # --no-merges: merge commit messages are machine-generated (including the synthetic merge GitHub
    # checks out on pull_request events) and never carry a footer.
    while IFS= read -r sha; do
      [ -z "$sha" ] && continue
      if ! check_message "$(git log -1 --format=%B "$sha")"; then
        echo "FAIL [commit-refs-footer]: $sha has no 'Refs: T-NNN' footer — $(git log -1 --format=%s "$sha")"
        fail=1
      fi
    done < <(git rev-list --no-merges "$range" 2>/dev/null)
    [ "$fail" -eq 0 ] && echo "OK [commit-refs-footer]: every commit in the range has a Refs: footer."
    exit "$fail"
    ;;
  *)
    echo "usage: $0 --commit-msg-file <path> | --ci-range <base>...<head>" >&2
    exit 2
    ;;
esac
