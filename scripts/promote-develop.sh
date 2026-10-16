#!/usr/bin/env bash
# scripts/promote-develop.sh — promotes develop → main by FAST-FORWARD, or refuses.
#
# Why fast-forward and not squash: stories already enter develop squashed (1 commit = 1 story).
# Squashing develop into main would create a commit on main that is not an ancestor of develop: the
# merge base never advances, every promotion drags everything again, review ranges get polluted and
# `git bisect run verify-all.sh` over promoted history breaks. With FF, both branches are identical
# after every promotion.
#
# The condition FF imposes: main never receives a direct commit. If it did, main is no longer an
# ancestor of develop and FF is impossible — this script REFUSES and says how to recover; it never
# "fixes" it with a merge commit or a reset (both would recreate the divergence FF exists to prevent).
#
# Usage:
#   promote-develop.sh            # check and promote
#   promote-develop.sh --check    # only check that a fast-forward is possible
#   promote-develop.sh --remote X # alternative remote (default: origin)
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 2
# shellcheck disable=SC1091
[ -f governance.env ] && eval "$(grep -E '^(MAIN_BRANCH|DEVELOP_BRANCH)=' governance.env)"
REMOTE="origin"; CHECK_ONLY=0; MAIN="${MAIN_BRANCH:-main}"; DEVELOP="${DEVELOP_BRANCH:-develop}"
while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK_ONLY=1 ;;
    --remote) REMOTE="${2:?}"; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "usage: $0 [--check] [--remote <name>]" >&2; exit 2 ;;
  esac
  shift
done

git fetch "$REMOTE" --quiet 2>/dev/null
MAIN_REF="$REMOTE/$MAIN"; DEV_REF="$REMOTE/$DEVELOP"
for ref in "$MAIN_REF" "$DEV_REF"; do
  git rev-parse --verify --quiet "$ref" >/dev/null || { echo "FAIL [promote-develop]: ref '$ref' does not exist."; exit 1; }
done
MAIN_SHA=$(git rev-parse "$MAIN_REF"); DEV_SHA=$(git rev-parse "$DEV_REF")
[ "$MAIN_SHA" = "$DEV_SHA" ] && { echo "OK [promote-develop]: $MAIN already at ${DEV_SHA:0:9} — nothing to promote."; exit 0; }

if ! git merge-base --is-ancestor "$MAIN_SHA" "$DEV_SHA"; then
  cat <<MSG
FAIL [promote-develop]: promotion is NOT a fast-forward.
'$MAIN' has $(git rev-list --count "$DEV_REF..$MAIN_REF") commit(s) that '$DEVELOP' doesn't — '$MAIN' received a direct commit:
$(git log --oneline "$DEV_REF..$MAIN_REF" | sed 's/^/  /')
To recover, bring '$DEVELOP' ahead of '$MAIN', then promote again:
  git checkout $DEVELOP && git rebase $MAIN_REF && git push --force-with-lease $REMOTE $DEVELOP
MSG
  exit 1
fi

echo "Fast-forward: $MAIN ${MAIN_SHA:0:9} → ${DEV_SHA:0:9} ($(git rev-list --count "$MAIN_REF..$DEV_REF") commit(s))"
git log --oneline "$MAIN_REF..$DEV_REF" | sed 's/^/  /'
[ "$CHECK_ONLY" -eq 1 ] && { echo "OK [promote-develop]: fast-forward possible (--check, nothing promoted)."; exit 0; }

if git push "$REMOTE" "$DEV_SHA:refs/heads/$MAIN"; then
  echo "OK [promote-develop]: $MAIN promoted to ${DEV_SHA:0:9}."; exit 0
fi
echo "FAIL [promote-develop]: push refused by the remote — if '$MAIN' is protected to require a PR, open"
echo "the promotion PR '$DEVELOP' → '$MAIN' and merge it with fast-forward only (no squash, no merge commit)."
exit 1
