#!/usr/bin/env bash
# scripts/init.sh — turns Mandate into YOUR project: fills every {{PLACEHOLDER}}, moves
# Mandate's own README/CHANGELOG to docs/guides/, writes a project README and regenerates the
# Decision Log index. Idempotent: refuses to run twice (no placeholders left = already initialized).
#
# Usage:
#   scripts/init.sh                                   # interactive
#   scripts/init.sh --name "Acme" --description "…" --decider "founder" --github acme-founder \
#                   --phase "Phase 1 — MVP" --operation-trigger "first paying customer in staging" --yes
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$0"/..)"

# Mandate's own method docs mention placeholders on purpose — they are never filled.
EXCLUDE_RE='^(docs/reference/governance-template(\.pt-BR)?\.md|docs/guides/MANDATE.*|scripts/init\.sh)$'
PH_RE='\{\{[A-Z][A-Z_]*\}\}'

remaining() { git ls-files -co --exclude-standard | grep -vE "$EXCLUDE_RE" | xargs -r grep -lE "$PH_RE" 2>/dev/null || true; }

[ -z "$(remaining)" ] && { echo "Already initialized — no {{PLACEHOLDER}} left. Nothing to do."; exit 0; }

declare -A V=( [PROJECT_NAME]="" [PROJECT_DESCRIPTION]="" [DECIDER]="" [DECIDER_GITHUB]="" [CURRENT_PHASE]="" [OPERATION_TRIGGER]="" )
YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --name) V[PROJECT_NAME]="$2"; shift ;;
    --description) V[PROJECT_DESCRIPTION]="$2"; shift ;;
    --decider) V[DECIDER]="$2"; shift ;;
    --github) V[DECIDER_GITHUB]="${2#@}"; shift ;;
    --phase) V[CURRENT_PHASE]="$2"; shift ;;
    --operation-trigger) V[OPERATION_TRIGGER]="$2"; shift ;;
    --yes|-y) YES=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

ask() { # key prompt default
  local k="$1" p="$2" d="$3" a
  [ -n "${V[$k]}" ] && return
  if [ "$YES" -eq 1 ]; then V[$k]="$d"; return; fi
  read -r -p "$p [$d]: " a; V[$k]="${a:-$d}"
}
ask PROJECT_NAME        "Project name"                                   "$(basename "$PWD")"
ask PROJECT_DESCRIPTION "One-paragraph description"                      "${V[PROJECT_NAME]} — describe the product in one paragraph."
ask DECIDER             "Who ratifies decisions (role or name)"          "the founder"
ask DECIDER_GITHUB      "Decider's GitHub handle (for CODEOWNERS)"       "$(git config user.name 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo owner)"
ask CURRENT_PHASE       "Current product phase"                          "Phase 1 — foundation"
ask OPERATION_TRIGGER   "Observable trigger that activates the Operation phase" "first real user depending on the system in production"

# Move Mandate's own docs out of the way, then write a project README.
mkdir -p docs/guides
for f in README.md README.pt-BR.md CHANGELOG.md ROADMAP.md ROADMAP.pt-BR.md LICENSE CONTRIBUTING.md CONTRIBUTING.pt-BR.md CODE_OF_CONDUCT.md SECURITY.md; do
  [ -f "$f" ] || continue
  case "$f" in
    README.md)        dst=docs/guides/MANDATE.md ;;
    README.pt-BR.md)  dst=docs/guides/MANDATE.pt-BR.md ;;
    CHANGELOG.md)     dst=docs/guides/MANDATE_CHANGELOG.md ;;
    ROADMAP.md)       dst=docs/guides/MANDATE_ROADMAP.md ;;
    ROADMAP.pt-BR.md) dst=docs/guides/MANDATE_ROADMAP.pt-BR.md ;;
    LICENSE)          dst=docs/guides/MANDATE_LICENSE ;;   # MIT notice travels with the copy
    CONTRIBUTING.md)  dst=docs/guides/MANDATE_CONTRIBUTING.md ;;
    CONTRIBUTING.pt-BR.md) dst=docs/guides/MANDATE_CONTRIBUTING.pt-BR.md ;;
    CODE_OF_CONDUCT.md) dst=docs/guides/MANDATE_CODE_OF_CONDUCT.md ;;
    SECURITY.md)      dst=docs/guides/MANDATE_SECURITY.md ;;
  esac
  sed -E 's#\]\((docs/)#](../#g; s#\]\(README(\.pt-BR)?\.md\)#](MANDATE\1.md)#g; s#\]\(ROADMAP(\.pt-BR)?\.md\)#](MANDATE_ROADMAP\1.md)#g; s#\]\(CHANGELOG\.md\)#](MANDATE_CHANGELOG.md)#g; s#\]\(LICENSE\)#](MANDATE_LICENSE)#g; s#\]\(CONTRIBUTING(\.pt-BR)?\.md\)#](MANDATE_CONTRIBUTING\1.md)#g' "$f" > "$dst"
  git rm -q --cached "$f" 2>/dev/null || true; rm -f "$f"
done
# The framework's issue templates point at its own repository — not the adopter's.
rm -rf .github/ISSUE_TEMPLATE
cat > README.md <<README
# {{PROJECT_NAME}}

{{PROJECT_DESCRIPTION}}

## Governance

This repository is governed by [\`CLAUDE.md\`](CLAUDE.md) (process constitution) and
[\`docs/adr/\`](docs/adr/README.md) (architecture). Decisions in flight: [\`DECISIONS.md\`](DECISIONS.md).
Backlog: [\`docs/backlog/\`](docs/backlog/README.md). How this method works:
[\`docs/guides/MANDATE.md\`](docs/guides/MANDATE.md).

\`\`\`bash
git config core.hooksPath scripts/guardrails/git-hooks   # once per clone
./scripts/guardrails/verify-all.sh                        # the definition of "green"
\`\`\`
README

python3 - "${V[PROJECT_NAME]}" "${V[PROJECT_DESCRIPTION]}" "${V[DECIDER]}" "${V[DECIDER_GITHUB]}" \
          "${V[CURRENT_PHASE]}" "${V[OPERATION_TRIGGER]}" "$EXCLUDE_RE" <<'PY'
import re, subprocess, sys
keys = ["PROJECT_NAME", "PROJECT_DESCRIPTION", "DECIDER", "DECIDER_GITHUB", "CURRENT_PHASE", "OPERATION_TRIGGER"]
vals = dict(zip(keys, sys.argv[1:7])); exclude = re.compile(sys.argv[7])
files = subprocess.run(["git", "ls-files", "-co", "--exclude-standard"], capture_output=True, text=True).stdout.split()
for f in files:
    if exclude.match(f):
        continue
    try:
        s = open(f, encoding="utf-8").read()
    except (UnicodeDecodeError, FileNotFoundError, IsADirectoryError):
        continue
    n = s
    for k, v in vals.items():
        n = n.replace("{{" + k + "}}", v)
    if n != s:
        open(f, "w", encoding="utf-8").write(n)
        print(f"  filled {f}")
PY

left=$(remaining)
if [ -n "$left" ]; then
  echo "Placeholders still present (unknown keys?) in:"; echo "$left" | sed 's/^/  /'; exit 1
fi
python3 scripts/planning/decision-index.py >/dev/null
cat <<NEXT

Initialized ${V[PROJECT_NAME]}. Next (docs/guides/MANDATE.md has the details):
  git config core.hooksPath scripts/guardrails/git-hooks
  ./scripts/guardrails/verify-all.sh
  git add -A && git commit -m "chore: bootstrap governance" -m "Refs: T-001"
  git branch develop
Then execute T-001: fill CLAUDE.md §1/§2/§6, write the stack ADRs, set SENSITIVE_* in governance.env.
NEXT
