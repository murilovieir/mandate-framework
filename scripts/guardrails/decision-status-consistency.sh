#!/usr/bin/env bash
# scripts/guardrails/decision-status-consistency.sh — machine-readable decision status.
#
# Checks COHERENCE BETWEEN RECORDS, never the merit of a decision. It doesn't ask whether an ADR
# *should* be accepted; it asks whether every place that states its status agrees:
#   1. ADR/RFC front matter `status` is in the closed vocabulary (no "DECIDED", "pending (x)", …).
#   2. Front-matter `id` matches the file name.
#   3. ADR status in docs/adr/README.md index == the file's front matter; an ADR listed twice with
#      different statuses is an internal contradiction.
#   4. RFC `## Status` checkbox block agrees with the front matter (approved ↔ "[x] Approved",
#      rejected ↔ "[x] Rejected", awaiting ↔ nothing checked). The block lists the UNCHECKED option
#      first — this reads the whole block, never `grep -A2`.
#   5. `superseded` ADR names `superseded_by`, and that ADR exists.
#
# CI only (no hook): consistency is an aggregate property of two files — a single write can't see the
# other side of the pair.
#
# FAIL-CLOSED: "couldn't check" never looks like "nothing to report". A crash of the python block or
# a missing docs root exits non-zero, never OK.
#
# Usage: decision-status-consistency.sh [--warn]      (DECISION_DOCS_ROOT=<dir> for fixtures)
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT" || exit 2
export LC_ALL=C.UTF-8

RULE="decision-status-consistency"
ALLOWLIST="scripts/guardrails/allowlists/${RULE}.txt"
WARN=0
case "${1:-}" in
  --warn) WARN=1 ;;
  "") ;;
  *) echo "usage: $0 [--warn]   (unknown argument: $1)" >&2; exit 2 ;;
esac

out=$(DECISION_DOCS_ROOT="${DECISION_DOCS_ROOT:-docs}" python3 - <<'PYEOF'
import os, re, sys
from pathlib import Path

root = Path(os.environ["DECISION_DOCS_ROOT"])
if not root.is_dir():
    print(f"FATAL: docs root '{root}' does not exist", file=sys.stderr); sys.exit(2)

ADR_VOCAB = {"proposed", "refining", "accepted", "deprecated", "superseded", "rejected"}
RFC_VOCAB = {"awaiting", "approved", "partially-approved", "rejected", "superseded"}
v = []

def front(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    fm = {}
    if lines and lines[0].strip() == "---":
        for ln in lines[1:]:
            if ln.strip() == "---":
                break
            m = re.match(r"^([A-Za-z_]+):\s*(.*?)\s*(#.*)?$", ln)
            if m:
                fm[m.group(1)] = m.group(2).strip().strip('"')
    return fm

def file_id(path, prefix):
    m = re.match(rf"^({prefix}-\d+[A-Za-z]?(?:-[A-Z])?)(?:-|\.md$)", path.name)
    return m.group(1) if m else None

adr_status = {}
adr_dir = root / "adr"
for f in sorted(adr_dir.glob("ADR-*.md")) if adr_dir.is_dir() else []:
    fm = front(f); fid = file_id(f, "ADR"); st = fm.get("status", "")
    if not fm:
        v.append(f"{f}: no front matter"); continue
    if fm.get("id") != fid:
        v.append(f"{f}: front-matter id '{fm.get('id')}' != file id '{fid}'")
    if st not in ADR_VOCAB:
        v.append(f"{f}: status '{st}' outside vocabulary {sorted(ADR_VOCAB)}")
    if st == "superseded":
        sb = fm.get("superseded_by", "")
        if not sb or not list(adr_dir.glob(f"{sb}-*.md")):
            v.append(f"{f}: superseded without an existing superseded_by ('{sb}')")
    adr_status[fid] = st

idx = adr_dir / "README.md"
if idx.is_file():
    seen = {}
    for n, ln in enumerate(idx.read_text(encoding="utf-8").splitlines(), 1):
        m = re.match(r"^\|\s*\[?(ADR-\d+[A-Za-z]?(?:-[A-Z])?)\]?.*\|\s*`?([a-z-]+)`?\s*\|\s*$", ln)
        if not m:
            continue
        aid, st = m.group(1), m.group(2)
        if aid in seen and seen[aid] != st:
            v.append(f"{idx}:{n}: {aid} listed twice with different statuses ({seen[aid]} vs {st})")
        seen[aid] = st
        if aid not in adr_status:
            v.append(f"{idx}:{n}: {aid} is in the index but no file exists")
        elif adr_status[aid] != st:
            v.append(f"{idx}:{n}: {aid} index says '{st}', file says '{adr_status[aid]}'")
    for aid in adr_status:
        if aid not in seen:
            v.append(f"{idx}: {aid} has a file but is missing from the index")

rfc_dir = root / "rfc"
for f in sorted(rfc_dir.glob("RFC-*.md")) if rfc_dir.is_dir() else []:
    fm = front(f); fid = file_id(f, "RFC"); st = fm.get("status", "")
    if not fm:
        v.append(f"{f}: no front matter"); continue
    if fm.get("id") != fid:
        v.append(f"{f}: front-matter id '{fm.get('id')}' != file id '{fid}'")
    if st not in RFC_VOCAB:
        v.append(f"{f}: status '{st}' outside vocabulary {sorted(RFC_VOCAB)}"); continue
    text = f.read_text(encoding="utf-8")
    m = re.search(r"^## Status\s*\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    if not m:
        v.append(f"{f}: no '## Status' block"); continue
    checked = [l.lower() for l in m.group(1).splitlines() if re.match(r"^\s*-?\s*\[x\]", l, re.I)]
    approved = any("approved" in l for l in checked)
    rejected = any("rejected" in l for l in checked)
    expect = {"approved": approved and not rejected, "partially-approved": approved and not rejected,
              "rejected": rejected and not approved, "awaiting": not checked, "superseded": True}[st]
    if not expect:
        v.append(f"{f}: front matter '{st}' disagrees with the ## Status block (checked: {checked or 'none'})")

print("\n".join(v))
PYEOF
)
rc=$?
if [ "$rc" -ne 0 ]; then
  echo "FAIL [$RULE]: the check itself failed (exit $rc) — not verified, never OK."
  exit 2
fi
violations=$(printf '%s\n' "$out" | sed '/^$/d' | gr_apply_allowlist "$ALLOWLIST")
if [ "$WARN" -eq 1 ]; then
  [ -n "$violations" ] && { echo "WARN [$RULE]:"; echo "$violations" | sed 's/^/  /'; }
  exit 0
fi
gr_ci_report "$RULE" "$violations"
