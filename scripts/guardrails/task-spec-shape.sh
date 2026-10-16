#!/usr/bin/env bash
# scripts/guardrails/task-spec-shape.sh — RULE-TASK-01 and RULE-UOW-01 (bolt sizing).
#
# RULE-TASK-01 (new story): ≤ 5 ACs, ≤ 8 expected files. The other conditions of the rule ("fits one
# session", "one rigor level") are judgment — no clean mechanical signal — and stay with the
# product-owner. RULE-UOW-01 (new Unit of Work): ceiling of 8 stories per folder (the 3–5 target is
# guidance, not a gate — a new UoW is born with one story and grows).
#
# Does not retroact: --ci-range and --hook only evaluate what is NEW (an added spec; a UoW folder
# that didn't exist on the base). Never fails because of a pre-existing spec or UoW.
#
# Counting: an AC is a line `- [ ] AC-N` (any box content); an expected file is a `- ` bullet under
# the heading "Expected files" (h2 or h3; "Arquivos esperados" also accepted) until the next h2/h3.
# One bullet per file — a line listing two files counts as one.
#
# Usage:
#   task-spec-shape.sh <spec.md>                   # RULE-TASK-01 on one spec
#   task-spec-shape.sh --uow <dir>                  # RULE-UOW-01 on one folder
#   task-spec-shape.sh --ci-range <base>...<head>   # CI: only what is new in the diff
#   echo '<tool_input json>' | task-spec-shape.sh --hook
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT" || exit 2

MAX_AC=5; MAX_FILES=8; MAX_UOW_STORIES=8
SPEC_GLOB_RE='^docs/backlog/[^/]+/T-[0-9]+[a-z]?-[^/]*\.md$'

count_acs() { grep -cE '^- \[[^]]*\] AC-[0-9]+' <<<"$1" || true; }

# Alternation instead of {m,n}: some awks (mawk) mis-handle `^#{2,3} ` followed by more pattern.
count_expected_files() {
  awk '
    /^## (Expected files|Arquivos esperados)/ || /^### (Expected files|Arquivos esperados)/ { s=1; next }
    s && (/^## / || /^### /) { s=0 }
    s && /^- / { n++ }
    END { print n+0 }' <<<"$1"
}

check_spec_content() {
  local content="$1" label="$2" acs files out=""
  acs=$(count_acs "$content"); files=$(count_expected_files "$content")
  [ "$acs" -gt "$MAX_AC" ] && out="${out}${label}: ${acs} ACs > ceiling ${MAX_AC} (RULE-TASK-01). "
  [ "$files" -gt "$MAX_FILES" ] && out="${out}${label}: ${files} expected files > ceiling ${MAX_FILES} (RULE-TASK-01). "
  printf '%s' "$out"
}

uow_count_at_ref() { git ls-tree --name-only "$2" -- "$1/" 2>/dev/null | grep -cE '/T-[0-9]+[a-z]?-.*\.md$' || true; }

case "${1:-}" in
  --hook)
    json=$(cat); rel=$(gr_relpath "$(gr_hook_file_path "$json")")
    grep -qE "$SPEC_GLOB_RE" <<<"$rel" || exit 0
    [ -e "$rel" ] && exit 0      # existing spec — no retroaction
    gr_hook_report "task-spec-shape" "$(check_spec_content "$(gr_hook_new_content "$json")" "$rel")"
    ;;
  --uow)
    dir="${2:?usage: --uow <dir>}"
    [ -d "$dir" ] || { echo "FAIL [task-spec-shape]: $dir does not exist"; exit 1; }
    n=$(find "$dir" -maxdepth 1 -type f -name 'T-*.md' | wc -l | tr -d ' ')
    if [ "$n" -gt "$MAX_UOW_STORIES" ]; then
      echo "FAIL [task-spec-shape]: $dir has $n stories > ceiling $MAX_UOW_STORIES (RULE-UOW-01)."; exit 1
    fi
    echo "OK [task-spec-shape]: $dir within RULE-UOW-01 ($n/$MAX_UOW_STORIES)."; exit 0
    ;;
  --ci-range)
    range="${2:?usage: --ci-range <base>...<head>}"
    base="${range%%...*}"; head_ref="${range#*...}"
    git rev-parse --verify --quiet "$base^{commit}" >/dev/null && git rev-parse --verify --quiet "$head_ref^{commit}" >/dev/null \
      || { echo "FAIL [task-spec-shape]: invalid range '$range' — not verified, never OK."; exit 2; }
    out=""
    while IFS= read -r f; do
      grep -qE "$SPEC_GLOB_RE" <<<"$f" || continue
      out="${out}$(check_spec_content "$(git show "$head_ref:$f" 2>/dev/null)" "$f")"
    done < <(git diff --name-only --diff-filter=A "$range" 2>/dev/null)
    while IFS= read -r d; do
      [ -z "$d" ] && continue
      # only UoW folders that did not exist on the base
      [ -n "$(git ls-tree --name-only "$base" -- "$d/" 2>/dev/null)" ] && continue
      n=$(uow_count_at_ref "$d" "$head_ref")
      [ "$n" -gt "$MAX_UOW_STORIES" ] && out="${out}${d}: ${n} stories > ceiling ${MAX_UOW_STORIES} (RULE-UOW-01). "
    done < <(git diff --name-only --diff-filter=A "$range" 2>/dev/null | grep -oE '^docs/backlog/[^/]+' | sort -u)
    [ -z "$out" ] && { echo "OK [task-spec-shape]: no violations in new specs/UoWs."; exit 0; }
    echo "FAIL [task-spec-shape]: $out"; exit 1
    ;;
  "")
    echo "usage: $0 <spec.md> | --uow <dir> | --ci-range <base>...<head> | --hook" >&2; exit 2 ;;
  *)
    [ -f "$1" ] || { echo "FAIL [task-spec-shape]: $1 does not exist"; exit 1; }
    out=$(check_spec_content "$(cat "$1")" "$1")
    [ -z "$out" ] && { echo "OK [task-spec-shape]: $1 conforms to RULE-TASK-01."; exit 0; }
    echo "FAIL [task-spec-shape]: $out"; exit 1
    ;;
esac
