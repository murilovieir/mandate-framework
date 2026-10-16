#!/usr/bin/env bash
# scripts/planning/sync-github-issues.sh — mirrors backlog stories into GitHub Issues (one-way,
# repo → Issues — RULE-PM-03). Idempotent: an issue is found by its `story:T-NNN` label and updated,
# never duplicated. Run it from CI on backlog changes — a board that depends on someone remembering
# lies by omission.
#
# Usage:
#   sync-github-issues.sh              # sync every story
#   sync-github-issues.sh T-003        # one story
#   sync-github-issues.sh --init       # labels + milestones (one per Unit of Work)
#   sync-github-issues.sh --dry-run    # parse only, no gh calls
#
# Requires: `gh` authenticated (not for --dry-run), awk. Env: GH_REPO=owner/name (default: current repo).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKLOG_DIR="${BACKLOG_DIR:-$ROOT/docs/backlog}"
DRY_RUN=0; SKIPPED=0
[[ " $* " == *" --dry-run "* ]] && DRY_RUN=1

log()  { printf '[sync] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
err()  { printf '[err] %s\n' "$*" >&2; exit 1; }
if [[ "$DRY_RUN" == "0" ]]; then
  command -v gh >/dev/null || err "missing dependency: gh"
  GH_REPO="${GH_REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
fi

get_fm() {  # front-matter scalar
  awk -v k="$2" '/^---$/{fm=!fm; next} fm && $1==k":" {sub(/^[^:]+:[[:space:]]*/,""); gsub(/^"|"$/,""); sub(/[[:space:]]*#.*$/,""); print; exit}' "$1"
}
get_fm_list() {
  awk -v k="$2" '/^---$/{fm=!fm; next} fm && $1==k":" {sub(/^[^:]+:[[:space:]]*/,""); sub(/[[:space:]]*#.*$/,""); gsub(/[\[\]]/,""); print; exit}' "$1"
}
# A story spec starts with front matter. Supporting documents named T-*.md (artifacts, attachments)
# don't — the criterion is the file's content, not the folder it lives in.
has_frontmatter() { [[ "$(head -n1 "$1")" == "---" ]]; }
find_story() {
  local f
  while IFS= read -r f; do has_frontmatter "$f" && { echo "$f"; return 0; }; done \
    < <(find "$BACKLOG_DIR" -name "$1-*.md" | sort)
  return 1
}
uows() { find "$BACKLOG_DIR" -maxdepth 1 -type d -name 'uow-*' -printf '%f\n' | sed 's/^uow-//' | sort -V; }

init() {
  local e name rest color desc
  for e in "status:todo:cccccc:Not started" "status:in-progress:0e8a16:In progress" \
           "status:blocked:b60205:Blocked" "status:in-review:fbca04:PR open" \
           "status:done:5319e7:Done" "status:deferred:bfdadc:Deferred" \
           "type:story:0052cc:User story" "type:task:0052cc:Task" "type:spike:f9d0c4:Spike" \
           "type:chore:e99695:Chore"; do
    name="${e%%:*}"; name="$name:$(cut -d: -f2 <<<"$e")"; rest="${e#*:*:}"
    color="${rest%%:*}"; desc="${rest#*:}"
    gh label create "$name" --color "$color" --description "$desc" --repo "$GH_REPO" --force >/dev/null
  done
  local u
  for u in $(uows); do
    gh label create "uow:$u" --color d4c5f9 --description "Unit of Work $u" --repo "$GH_REPO" --force >/dev/null
    gh api "repos/$GH_REPO/milestones" --method POST -f title="UoW $u" -f state=open >/dev/null 2>&1 || true
  done
  log "labels and milestones ready. Create the Project board in the GitHub UI (Todo/In progress/Blocked/In review/Done)."
}

sync_story() {
  local file="$1"
  if ! has_frontmatter "$file"; then warn "no front matter, not a story — skipping ${file#"$ROOT"/}"; SKIPPED=$((SKIPPED+1)); return 0; fi
  local id title uow status type adrs initiative
  id=$(get_fm "$file" id); title=$(get_fm "$file" title); uow=$(get_fm "$file" uow)
  status=$(get_fm "$file" status); type=$(get_fm "$file" type); adrs=$(get_fm_list "$file" adrs)
  [[ -n "$id" && -n "$title" ]] || err "story with front matter but no id/title: $file"
  case "$status" in todo|in-progress|blocked|in-review|done|deferred) ;; *) status=todo ;; esac
  local labels="story:$id,status:$status,type:${type:-story},uow:${uow:-0}"
  initiative=$(get_fm "$BACKLOG_DIR/uow-${uow}/_index.md" initiative 2>/dev/null || true)
  [[ -n "$initiative" ]] && labels="$labels,initiative:$initiative"
  if [[ "$DRY_RUN" == "1" ]]; then printf '  %-7s | %-11s | uow %-4s | %s\n' "$id" "$status" "$uow" "$title"; return 0; fi
  gh label create "story:$id" --color ededed --description "${file#"$ROOT"/}" --repo "$GH_REPO" --force >/dev/null 2>&1 || true
  [[ -n "$initiative" ]] && gh label create "initiative:$initiative" --color c2e0c6 --repo "$GH_REPO" --force >/dev/null 2>&1 || true
  local body; body="> 📄 Source of truth: \`${file#"$ROOT"/}\` — edit scope/ACs there, never here (RULE-PM-03).
> 🏛 ADRs: ${adrs:-—}
---
$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2' "$file")"
  local existing
  existing=$(gh issue list --repo "$GH_REPO" --label "story:$id" --state all --json number --jq '.[0].number' 2>/dev/null || true)
  if [[ -z "$existing" ]]; then
    log "creating issue for $id"
    gh issue create --repo "$GH_REPO" --title "[$id] $title" --body "$body" --label "$labels" --milestone "UoW $uow" >/dev/null
  else
    log "updating #$existing ($id)"
    local s
    for s in todo in-progress blocked in-review done deferred; do
      gh issue edit "$existing" --repo "$GH_REPO" --remove-label "status:$s" >/dev/null 2>&1 || true
    done
    gh issue edit "$existing" --repo "$GH_REPO" --title "[$id] $title" --body "$body" --add-label "$labels" --milestone "UoW $uow" >/dev/null
    case "$status" in
      done|deferred) gh issue close "$existing" --repo "$GH_REPO" >/dev/null 2>&1 || true ;;
      *) gh issue reopen "$existing" --repo "$GH_REPO" >/dev/null 2>&1 || true ;;
    esac
  fi
}

case "${1:-}" in
  --init) init; exit 0 ;;
  --dry-run) ;;
  T-*) f=$(find_story "$1") || err "story $1 not found under $BACKLOG_DIR"; sync_story "$f"; exit 0 ;;
  "") ;;
  *) sync_story "$1"; exit 0 ;;
esac
n=0
while IFS= read -r -d '' f; do sync_story "$f"; n=$((n+1)); done < <(find "$BACKLOG_DIR" -name 'T-*.md' -print0 | sort -z)
log "$((n-SKIPPED)) stories processed ($SKIPPED supporting file(s) skipped). Units of Work: $(uows | tr '\n' ' ')"
