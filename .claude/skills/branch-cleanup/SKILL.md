---
name: branch-cleanup
description: Periodic study and cleanup of remote branches with no further use (merged, stale, orphaned), plus detection of branches ahead of main that never had a PR. Use on "/branch-cleanup", "clean up branches", "old branches", "unused branches". Deletes only the 100%-safe subset (fully merged into main, no open PR); everything else becomes an opinion for the decider. NEVER deletes a branch with an open PR, the current branch, main or develop.
---

# `/branch-cleanup` — remote branch hygiene

## 1. Collect data (deterministic, read-only)
```bash
git fetch --prune origin
for b in $(git branch -r --format='%(refname:short)' | grep -vE 'origin/(HEAD|main|develop)$'); do
  base=$(git merge-base origin/main "$b" 2>/dev/null) || { echo "DISJOINT $b"; continue; }
  ahead=$(git rev-list --count origin/main.."$b")
  [ "$ahead" -eq 0 ] && echo "MERGED $b" || echo "REVIEW $b ahead=$ahead"
done
```
- **MERGED** — `ahead=0`, fully contained in `main`. Safe by definition.
- **DISJOINT** — no merge base with `main` (pre-rewrite history). Almost always junk; needs one look.
- **REVIEW** — unique commits sharing history with `main`: real unmerged work, or superseded work.

## 1-bis. Branches ahead of `main` that never had a PR — mandatory
Cross the REVIEW list with PR state (`gh pr list --state all --head <branch>` or the GitHub tools). A
branch ahead of `main` that **never had a PR** is not "junk to delete": it is **work with no review
layer at all** — no bot, no CI, no gate. Report it separately; the decider routes it (open a PR,
delete as abandoned, or record why it stays). Squash-merged branches whose PR merged still show
`ahead>0` — those belong to step 3, not here.
If PR state can't be queried (`gh` missing, not authenticated, offline), **fail closed**: report
`not verified: PR state — <reason>` and do not treat an empty list as "nothing found".

## 2. MERGED — delete for real, with guards
For each: confirm **no open PR** has it as head (skip if one does, even with an empty diff); confirm it
isn't `main`, `develop` or the current branch; then `git push origin --delete <branch>`. If the first
delete is refused (e.g. 403 from a proxy), stop deleting this round and list the ready-to-run commands
for the decider.

## 3. DISJOINT and REVIEW — never delete alone
Delegate judgment to the `architect` agent with the table from step 1: for REVIEW, inspect
`git log --oneline origin/main..origin/<branch>` and judge whether the work already reached `main` by
another path; for DISJOINT, confirm the content predates the rewrite. Verdict per branch: **SAFE TO
DELETE** / **PROBABLY SAFE, CONFIRM** / **KEEP — real work not in main**. Any deletion here needs the
decider to run the command explicitly.

## 4. Record and report
Save the opinion to `docs/office/architect/YYYY-MM-DD-branch-cleanup.md`. Close with: what was
actually deleted · ready commands for what's pending · the explicit **KEEP** list with reasons · the
**never-had-a-PR** list.

## Rules
- Never delete `main`, `develop`, the current branch, or any branch with an open PR.
- Never delete REVIEW/DISJOINT without this run's architect opinion — don't reuse an old verdict.
- MERGED is the only batch deleted without re-confirmation each round — still always listed, never silent.
- Scheduled runs are low-noise: notify only when something is actionable.
