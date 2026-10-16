#!/usr/bin/env bash
# scripts/guardrails/uow-gate.sh — executable Unit of Work exit gate (scale-readiness gate G5).
#
# A gate written in prose is a wish: it declares a condition nobody evaluates. Here the gate lives in
# the `_index.md` front matter as a condition a script CAN evaluate:
#
#   ---
#   id: UOW-01
#   status: open            # open | closed
#   exit_gate:
#     stories_done: [T-001, T-002]
#     commands:
#       - ./scripts/guardrails/verify-all.sh --fast
#   ---
#
# Rules:
#   - Every Unit of Work has an exit_gate, and every key of it is one this script can evaluate.
#     Anything else is REFUSED — the main risk of this mechanism is prose creeping back inside a
#     structured field, and refusing what can't be evaluated is the mandatory mitigation.
#   - `status: closed` requires the gate to be MET.
#
# Modes:
#   uow-gate.sh <uow-dir>     evaluate one gate fully (stories + commands); exit 1 if unmet
#   uow-gate.sh --all         CI: every UoW — schema always; closed ones must meet stories_done.
#                             Commands are NOT run in --all (they usually include verify-all.sh,
#                             which runs this script: running them here would recurse).
# Legacy UoWs without a gate can be listed in allowlists/uow-gate.txt (one folder per line + reason).
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT" || exit 2

RULE="uow-gate"
ALLOWLIST="scripts/guardrails/allowlists/${RULE}.txt"
MODE="${1:?usage: $0 <uow-dir> | --all}"

if [ -n "${UOW_GATE_ACTIVE:-}" ] && [ "$MODE" != "--all" ]; then
  echo "SKIP [$RULE]: nested invocation from a gate command — refusing to recurse."; exit 0
fi

result=$(MODE="$MODE" python3 - <<'PYEOF'
import os, re, sys
from pathlib import Path

ALLOWED = {"stories_done", "commands"}
mode = os.environ["MODE"]
backlog = Path("docs/backlog")

def parse_front(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    fm, cur, cur_list = {}, None, None
    for ln in lines[1:]:
        if ln.strip() == "---":
            return fm
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        indent = len(ln) - len(ln.lstrip())
        body = re.sub(r"\s+#.*$", "", ln.strip())
        if indent == 0:
            k, _, val = body.partition(":")
            val = val.strip()
            cur = k.strip(); cur_list = None
            fm[cur] = {} if val == "" else val
        elif isinstance(fm.get(cur), dict) and body.startswith("- ") and cur_list:
            fm[cur][cur_list].append(body[2:].strip().strip('"\''))
        elif isinstance(fm.get(cur), dict):
            k, _, val = body.partition(":")
            k, val = k.strip(), val.strip()
            if val.startswith("["):
                fm[cur][k] = [x.strip().strip('"\'') for x in val.strip("[]").split(",") if x.strip()]
                cur_list = None
            elif val == "":
                fm[cur][k] = []; cur_list = k
            else:
                fm[cur][k] = val; cur_list = None
    return None  # unterminated front matter

def story_status(sid):
    for f in backlog.glob(f"*/{sid}-*.md"):
        fm = parse_front(f) or {}
        return fm.get("status", "?")
    return None

def check(d, run_commands):
    idx = d / "_index.md"
    if not idx.is_file():
        return [f"{d}: no _index.md"], [], False
    fm = parse_front(idx)
    if fm is None:
        return [f"{idx}: no (or unterminated) front matter"], [], False
    gate = fm.get("exit_gate")
    if not isinstance(gate, dict) or not gate:
        return [f"{idx}: no exit_gate — a Unit of Work needs an executable exit gate"], [], False
    bad = sorted(set(gate) - ALLOWED)
    if bad:
        return [f"{idx}: exit_gate keys {bad} cannot be evaluated (allowed: {sorted(ALLOWED)}) — prose is not a gate"], [], False
    for k in gate:
        if not isinstance(gate[k], list) or not gate[k]:
            return [f"{idx}: exit_gate.{k} must be a non-empty list"], [], False
    unmet = []
    for sid in gate.get("stories_done", []):
        st = story_status(sid)
        if st is None:
            unmet.append(f"{sid} does not exist")
        elif st != "done":
            unmet.append(f"{sid} is '{st}'")
    cmds = gate.get("commands", []) if run_commands else []
    return [], unmet + [f"CMD {c}" for c in cmds], fm.get("status") == "closed"

if mode == "--all":
    for d in sorted(p for p in backlog.glob("*/") if p.is_dir() and p.name not in ("scripts",)):
        if not (d / "_index.md").exists() and not list(d.glob("T-*.md")):
            continue
        schema, unmet, closed = check(d, run_commands=False)
        for s in schema:
            print(f"VIOLATION {d.as_posix().rstrip('/')}|{s}")
        if closed and unmet:
            print(f"VIOLATION {d.as_posix().rstrip('/')}|{d}: status closed but gate unmet: {'; '.join(unmet)}")
else:
    d = Path(mode)
    schema, unmet, closed = check(d, run_commands=True)
    for s in schema:
        print(f"VIOLATION {d.as_posix().rstrip('/')}|{s}")
    for u in unmet:
        print(u if u.startswith("CMD ") else f"UNMET {u}")
PYEOF
)
rc=$?
[ "$rc" -ne 0 ] && { echo "FAIL [$RULE]: the check itself failed (exit $rc) — not verified, never OK."; exit 2; }

if [ "$MODE" = "--all" ]; then
  violations=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    dir="${line#VIOLATION }"; dir="${dir%%|*}"
    if [ -f "$ALLOWLIST" ] && grep -vE '^\s*(#|$)' "$ALLOWLIST" | sed -E 's/\s*#.*$//; s/\s+$//' | grep -qxF "$dir"; then
      continue
    fi
    violations="${violations}${line#*|}"$'\n'
  done <<< "$result"
  gr_ci_report "$RULE" "$(printf '%s' "$violations" | sed '/^$/d')"
fi

fail=0
while IFS= read -r line; do
  case "$line" in
    "") ;;
    VIOLATION*) echo "FAIL [$RULE]: ${line#*|}"; fail=1 ;;
    UNMET*) echo "UNMET [$RULE]: ${line#UNMET }"; fail=1 ;;
    CMD*)
      cmd="${line#CMD }"
      if UOW_GATE_ACTIVE=1 bash -c "$cmd" >/dev/null 2>&1; then
        echo "MET   [$RULE]: \`$cmd\`"
      else
        echo "UNMET [$RULE]: \`$cmd\` exited non-zero"; fail=1
      fi ;;
  esac
done <<< "$result"
[ "$fail" -eq 0 ] && echo "OK [$RULE]: exit gate of $MODE is met."
exit "$fail"
