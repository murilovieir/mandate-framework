#!/usr/bin/env bash
# scripts/guardrails/instruction-budget.sh — instruction budget of the normative files (tier 1).
#
# Descending ratchet per file, stored in allowlists/instruction-budget.txt as
# `<file> <ceiling> <target>`. CI fails when a file passes its ceiling. `--record` may only LOWER a
# ceiling — raising one requires a hand edit citing a PD (decision-log), never the result of running
# a command. The TARGET is the decider's decision, never a measurement: --record never touches it. The
# ceiling↔target distance is printed on every run.
#
# "Effective line" = non-blank. Consistency between the measurement that records and the one that
# checks matters more than surgical precision.
#
# Files: BUDGET_FILES in governance.env. Aggregate property → CI only (the hook is a no-op: a single
# write can't know whether it pushes the total up or compensates a removal elsewhere).
#
# Usage: instruction-budget.sh [--record | --hook]
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT" || exit 2

IFS=' ' read -ra FILES <<< "${BUDGET_FILES:-CLAUDE.md AGENTS.md}"
CEILING_FILE="${GUARDRAIL_BUDGET_CEILING:-scripts/guardrails/allowlists/instruction-budget.txt}"

effective_lines() { grep -cve '^\s*$' "$1" 2>/dev/null || echo 0; }
lookup() { grep -E "^${1//\//\\/} " "$CEILING_FILE" 2>/dev/null | awk '{print $2, $3}'; }

[ "${1:-}" = "--hook" ] && exit 0

if [ "${1:-}" = "--record" ]; then
  refused=""
  {
    echo "# instruction-budget.txt — <file> <ceiling> <target> (effective = non-blank lines)."
    echo "# Ceiling only goes DOWN via --record; raising it is a hand edit citing a PD."
    echo "# Target is the decider's decision — --record never changes it."
  } > "$CEILING_FILE.new"
  for f in "${FILES[@]}"; do
    [ -f "$f" ] || continue
    current=$(effective_lines "$f")
    read -r old_ceiling old_target <<< "$(lookup "$f")"
    if [ -z "$old_ceiling" ]; then
      echo "$f $current $current" >> "$CEILING_FILE.new"; continue
    fi
    if [ "$current" -gt "$old_ceiling" ]; then
      refused="${refused}${f}: current ${current} > recorded ceiling ${old_ceiling} — --record never raises it.\n"
      echo "$f $old_ceiling $old_target" >> "$CEILING_FILE.new"; continue
    fi
    echo "$f $current $old_target" >> "$CEILING_FILE.new"
  done
  mv "$CEILING_FILE.new" "$CEILING_FILE"
  if [ -n "$refused" ]; then
    printf 'REFUSED [instruction-budget --record]:\n%b' "$refused"; exit 1
  fi
  echo "Ceilings recorded in $CEILING_FILE:"; grep -v '^#' "$CEILING_FILE"; exit 0
fi

violations=""; report=""
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  read -r ceiling target <<< "$(lookup "$f")"
  if [ -z "$ceiling" ]; then
    violations="${violations}${f}: no ceiling recorded — run '$0 --record' and commit the result.\n"; continue
  fi
  current=$(effective_lines "$f")
  if [ "$current" -gt "$ceiling" ]; then
    violations="${violations}${f}: ${current} effective lines > ceiling ${ceiling} (+$((current-ceiling))).\n"; continue
  fi
  if [ -n "$target" ] && [ "$current" -gt "$target" ]; then
    report="${report}  ${f}: ${current} (ceiling ${ceiling}, target ${target}) — $((current-target)) lines to target.\n"
  else
    report="${report}  ${f}: ${current} (ceiling ${ceiling}, target ${target:-—}) — within target.\n"
  fi
done

if [ -n "$violations" ]; then
  printf 'FAIL [instruction-budget]:\n%b' "$violations"
  echo "Shrink the file — or, if the addition is legitimate, register a PD and raise the ceiling by hand."
  exit 1
fi
echo "OK [instruction-budget]: no normative file above its ceiling."
[ -n "$report" ] && printf 'Distance to target (informative):\n%b' "$report"
exit 0
