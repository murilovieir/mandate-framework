#!/usr/bin/env bash
# scripts/guardrails/verify-all.sh — THE definition of "green", runnable anywhere.
#
# The list of what must pass lives here, in one runtime-neutral script (human, Claude Code, Codex,
# Copilot) — never inside the CI YAML. The workflow only calls this script. Three properties make it
# an authority instead of a convenience:
#
#   1. What to run is derived (from the diff, from the files present) — never a hand-kept path table.
#   2. A check that cannot run is DECLARED and FAILS the run: `not verified: <id> — <reason>`.
#      "Couldn't check" never looks like "clean". --allow-missing-tools degrades consciously.
#   3. anti-drift: CI runs this script and nothing else. A workflow `run:` step that doesn't call
#      verify-all.sh, or that asks for a family that doesn't exist, fails here — so "green" can't be
#      silently redefined in YAML.
#
# Running it locally is feedback; the gate is the CI execution.
#
# Usage:
#   verify-all.sh                         # everything, range <base>...HEAD
#   verify-all.sh --fast                  # skip the `project` family (build toolchains)
#   verify-all.sh --only guardrails,planning
#   verify-all.sh --ci-range <base>...<head>
#   verify-all.sh --list                  # what would run, without running
#   verify-all.sh --allow-missing-tools   # report missing tools as "not verified" but exit 0
set -uo pipefail
GR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$GR_DIR/lib.sh"
cd "$REPO_ROOT" || exit 2

FAMILIES="guardrails guardrail-tests planning anti-drift project"
FAST=0; LIST=0; ALLOW_MISSING=0; ONLY=""; RANGE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --fast) FAST=1 ;;
    --list) LIST=1 ;;
    --allow-missing-tools) ALLOW_MISSING=1 ;;
    --only) ONLY="${2:?--only needs a comma-separated list}"; shift ;;
    --ci-range) RANGE="${2:?--ci-range needs <base>...<head>}"; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

for f in ${ONLY//,/ }; do
  grep -qw -- "$f" <<<"$FAMILIES" || { echo "unknown family '$f' (known: $FAMILIES)" >&2; exit 2; }
done

want() {  # is this family selected?
  local fam="$1"
  if [ -n "$ONLY" ]; then grep -qw -- "$fam" <<<"${ONLY//,/ }"; return; fi
  [ "$fam" = "project" ] && [ "$FAST" -eq 1 ] && return 1
  return 0
}

# Base of the diff: explicit range > merge-base with origin/develop > origin/main > none.
default_base() {
  local ref
  for ref in "origin/${DEVELOP_BRANCH:-develop}" "origin/${MAIN_BRANCH:-main}"; do
    if git rev-parse --verify --quiet "$ref" >/dev/null; then
      git merge-base "$ref" HEAD 2>/dev/null && return
    fi
  done
}
# An unresolvable base (e.g. GitHub's all-zeros `before` on a new branch) must never turn range
# checks into a silent no-op: fall back to the default base, or to "no base" (everything is new).
if [ -n "$RANGE" ] && ! git rev-parse --verify --quiet "${RANGE%%...*}^{commit}" >/dev/null; then
  echo "note: range base '${RANGE%%...*}' is not a commit — falling back to the default base"
  RANGE=""
fi
if [ -z "$RANGE" ]; then
  base=$(default_base)
  [ -n "$base" ] && RANGE="$base...HEAD"
fi

PASSED=0; FAILED=0; UNVERIFIED=0; FAILED_IDS=""; UNVERIFIED_IDS=""

# run_check <id> <required tool or -> <command...>
run_check() {
  local id="$1" tool="$2"; shift 2
  if [ "$LIST" -eq 1 ]; then printf '  %-34s %s\n' "$id" "$*"; return; fi
  if [ "$tool" != "-" ] && ! command -v "$tool" >/dev/null 2>&1; then
    echo "not verified: $id — '$tool' not installed"
    UNVERIFIED=$((UNVERIFIED+1)); UNVERIFIED_IDS="$UNVERIFIED_IDS $id"; return
  fi
  local out rc
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "✓ $id"; PASSED=$((PASSED+1))
  else
    echo "✗ $id"; echo "$out" | sed 's/^/    /'
    FAILED=$((FAILED+1)); FAILED_IDS="$FAILED_IDS $id"
  fi
}

# ── range-based checks degrade explicitly when there is no base (first commit, no remote) ──
commit_refs() {
  if [ -n "$RANGE" ]; then "$GR_DIR/commit-refs-footer.sh" --ci-range "$RANGE"; return; fi
  git rev-parse --verify --quiet HEAD >/dev/null || { echo "no commits yet — nothing to check"; return 0; }
  # no base (first push, no remote): every authored commit is new
  local rc=0 s
  for s in $(git rev-list --no-merges HEAD); do
    git log -1 --format=%B "$s" | grep -qE '^Refs:.*\b(T|RFC|MF)-[0-9]+' \
      || { echo "FAIL: $s has no 'Refs: T-NNN' footer — $(git log -1 --format=%s "$s")"; rc=1; }
  done
  return "$rc"
}
spec_shape() {
  if [ -n "$RANGE" ]; then "$GR_DIR/task-spec-shape.sh" --ci-range "$RANGE"; return; fi
  # no base: every spec and every UoW is new
  local rc=0 f d
  while IFS= read -r f; do "$GR_DIR/task-spec-shape.sh" "$f" >/dev/null || { "$GR_DIR/task-spec-shape.sh" "$f"; rc=1; }; done \
    < <(git ls-files 'docs/backlog/*/T-*.md')
  for d in docs/backlog/*/; do [ -d "$d" ] && { "$GR_DIR/task-spec-shape.sh" --uow "${d%/}" >/dev/null || rc=1; }; done
  return "$rc"
}

guardrail_tests() {
  local rc=0 t
  for t in "$GR_DIR"/tests/test-*.sh; do bash "$t" || rc=1; done
  return "$rc"
}

# anti-drift: every `run:` step of every workflow calls verify-all.sh, with known families only.
anti_drift() {
  local wf rc=0 line fam
  shopt -s nullglob
  local files=(.github/workflows/*.yml .github/workflows/*.yaml)
  [ "${#files[@]}" -eq 0 ] && { echo "no workflow found — CI enforces nothing"; return 1; }
  for wf in "${files[@]}"; do
    while IFS= read -r line; do
      case "$line" in
        *scripts/guardrails/verify-all.sh*)
          for fam in $(grep -oE -- '--only[ =][a-z,-]+' <<<"$line" | sed -E 's/--only[ =]//; s/,/ /g'); do
            grep -qw -- "$fam" <<<"$FAMILIES" || { echo "$wf: asks for unknown family '$fam'"; rc=1; }
          done ;;
        *) echo "$wf: run step defines 'green' outside verify-all.sh → $line"; rc=1 ;;
      esac
    done < <(grep -E '^\s*(-\s+)?run:' "$wf" | sed -E 's/^\s*(-\s+)?run:\s*//')
  done
  return "$rc"
}

# ── PROJECT CHECKS — add your build/test commands here, derived from the diff ─────────────────
# Example (Maven multi-module): test every module whose files changed.
#   for m in $(git diff --name-only "$RANGE" | grep -oE '^backend/[^/]+' | sort -u); do
#     run_check "maven:$m" mvn mvn -q -pl "$m" -am verify
#   done
# Example (npm workspace):
#   git diff --name-only "$RANGE" | grep -q '^frontend/' && run_check "frontend" npm npm --prefix frontend test
project_checks() {
  :
}

[ "$LIST" -eq 1 ] && echo "verify-all would run (range: ${RANGE:-none — every spec/commit treated as new}):"

if want guardrails; then
  run_check "guardrails:commit-refs-footer"          git     commit_refs
  run_check "guardrails:task-spec-shape"             -       spec_shape
  run_check "guardrails:instruction-budget"          -       "$GR_DIR/instruction-budget.sh"
  run_check "guardrails:decision-status-consistency" python3 "$GR_DIR/decision-status-consistency.sh"
  run_check "guardrails:uow-gate"                    python3 "$GR_DIR/uow-gate.sh" --all
fi
want guardrail-tests && run_check "guardrail-tests"  jq      guardrail_tests
if want planning; then
  run_check "planning:decision-index"                python3 python3 scripts/planning/decision-index.py --check
  run_check "planning:next-tasks"                    python3 python3 scripts/planning/next-tasks.py --self-check
fi
want anti-drift && run_check "anti-drift"            -       anti_drift
want project && project_checks

[ "$LIST" -eq 1 ] && exit 0

echo
if [ "$FAILED" -gt 0 ] || { [ "$UNVERIFIED" -gt 0 ] && [ "$ALLOW_MISSING" -eq 0 ]; }; then
  echo "VERIFY-ALL: FAIL — $PASSED passed · $FAILED failed [${FAILED_IDS# }] · $UNVERIFIED not verified [${UNVERIFIED_IDS# }]"
  exit 1
fi
[ "$UNVERIFIED" -gt 0 ] && echo "VERIFY-ALL: OK (degraded — $UNVERIFIED not verified:$UNVERIFIED_IDS)" && exit 0
echo "VERIFY-ALL: OK — $PASSED checks passed"
