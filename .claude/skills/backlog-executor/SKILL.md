---
name: backlog-executor
description: Use when executing a story from `docs/backlog/uow-NN/T-*.md`. Enforces the execution loop — read every referenced ADR first, implement against the Acceptance Criteria, prove each AC by execution, update front-matter status, commit with the `Refs:` footer, emit the audit-trail event, never reopen decisions locked in ADRs. Trigger whenever the user says "execute T-NNN", "pick up the next story", or hands a story file to the agent.
---

# Backlog executor

You are executing a **story** from the backlog. Stories live at `docs/backlog/uow-NN/T-NNN-*.md` and
follow the Implementation Contract format. **The story file + its referenced ADRs are the source of
truth.** If the conversation contradicts them, the files win.

## Execution loop — in this order, no skipping

### 1. Read the story
- Parse the front matter: `id`, `status`, `adrs`, `depends_on`, `blocks`.
- `status` already `done`/`deferred` → stop and ask.
- A `depends_on` story not `done` → stop and surface the dependency.
- **Rework signal:** if Context names an earlier `done` story as the defect this one corrects, note it
  for step 9.

### 2. Read every referenced ADR
- `docs/adr/ADR-NNN-*.md` for each id in `adrs:`. Always re-read — never trust memory.
- **Locked decisions are locked** — in the ADRs, in the story's "Locked technical decisions", and in
  process decisions recorded in `docs/reference/learned-rules.md`.
- `proposed`/`refining` ADR → note which parts are fixed and which are open.

### 3. Classify the rigor level and mark `in-progress`
- Rigor (N0–N3) is **mechanical, by the paths the diff will touch** — see `CLAUDE.md` §7 and
  `SENSITIVE_PATHS` in `governance.env`. Never by judgment.
- Set `status: in-progress`, commit separately:
  ```
  chore(backlog): start T-NNN

  Refs: T-NNN
  ```
- N1+: work on branch `task/T-NNN-slug`, PR into `develop`.

### 4. Implement
- Stay inside **Scope (IN)**. Drifting into **Out of scope (OUT)** → stop and ask.
- Create the files in **Expected files**; justify any extra.
- "Decisions left open" → use the proposed default; none → ask before deciding.
- New fork not covered → register it in `DECISIONS.md` (skill `decision-log`): operational with a safe
  default → `DEFAULT_APPLIED`; architectural or **sensitive** → `NEEDS_VALIDATION`, stop, surface.

### 5. Validate the Acceptance Criteria — RULE-QA-01
- Run `./scripts/guardrails/verify-all.sh` (it derives what to run from the diff), then the skill
  `review-gate` before checking any AC.
- **Never mark `[x]` without an execution that proves it. "It compiles" is not execution.**
- Not verifiable here → `[~]` plus the reason in Execution notes.

### 6. Update the story file
- Check satisfied ACs; fill **Execution notes** (what ran with counts, deviations, PDs, review
  findings, proposed follow-ups).
- `status: in-review` **only if** the branch is pushed and a PR is open — the status claims a review
  is pending, not that one is possible in principle.
- **PR merged + ACs checked → `done` in the same commit** (RULE-PM-05, `LR-005`), without asking case
  by case. Exception: ACs blocked by an external dependency (`[⛔]`) stay `in-review`.

### 7. Commit
```
<type>(<scope>): <imperative summary, ≤72 chars>

<optional body>

Refs: T-NNN, ADR-NNN
```
`<type>`: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `build`.

### 8. Sync the issue (if configured)
`bash scripts/planning/sync-github-issues.sh T-NNN` when `gh` is authenticated; otherwise note in
Execution notes that sync is pending.

### 9. Audit trail + ratification queue
**9a.** Append to `docs/reports/process-metrics.jsonl` (create it if missing):
```json
{"ts":"<UTC ISO-8601>","event":"story_closed","story":"T-NNN","rigor":"N0|N1|N2|N3","model":"<model id>","token_cost":null,"acs_failed_at_gate":0,"findings_by_agent":{}}
```
`token_cost: null` when unmeasurable — never skip the event for a missing number.
`acs_failed_at_gate`: ACs marked `[x]` that a later review reopened.

**9b.** If step 1 flagged rework (or a review traced a defect back to an earlier story):
```json
{"ts":"<UTC ISO-8601>","event":"rework_observed","story":"T-NNN","origin_story":"T-MMM","cause":"<short>","pr":null}
```
`origin_story` is the correlation key — never declare a rework rate yourself.

**9c.** Run `python3 scripts/planning/decision-index.py`. Dispatch the `tpm` agent if **any**: more
than 3 PDs awaiting ratification; any older than 7 days; any sensitive default in the queue.

## Rigor ladder (written defaults — don't wait to be told)

| Level | Trigger (by path) | Gates |
|---|---|---|
| N0 | docs, backlog chores; no product code | loop + `Refs:` footer |
| N1 | product code outside `SENSITIVE_PATHS` | + self-review checklist + branch + PR + green CI |
| N2 | diff touches `SENSITIVE_PATHS` | + `architect`, `qa-engineer` (100%), `release-manager` opinions before merge; emerging PDs are `NEEDS_VALIDATION` |
| N3 | N2 opinions diverge, one-way door, billing/security/SLA behavior change | + explicit decider ratification |

Survival conditions never go below N2. Auto-merge does not exist.

### N1 self-review checklist (before opening the PR)
- Every `[x]` AC was executed — say how. Tests ran — paste the count.
- `verify-all.sh` clean (or its `not verified:` lines copied to the notes).
- `Refs:` footer, `task/T-NNN-slug` branch, `[T-NNN] …` PR title.
- New decisions registered (sensitive → `NEEDS_VALIDATION`, stop).
- **New code with a structurally similar sibling in the same module** mirrors the sibling's defensive
  patterns (abort/race guards, event-bubbling guards, shape validation, accessibility). Ask "does my
  code differ from the nearest existing analog, and why?" — not just "does my code work?".
- **A new helper that parses/formats/derives a shape** another file already handles reuses or
  extracts the existing one — two copies drift silently.

## Hard rules
- Never reopen a locked decision. Never add a framework/library that conflicts with an ADR.
- Never commit secrets. Never mark an AC without verification. Never skip reading the ADRs.
- A `BLOCKER-NNN` blocks progress → stop and register it; don't work around it.

## Stop and ask when
- A locked decision seems wrong for this story · an AC can't be verified and the workaround isn't
  obvious · scope creep is unavoidable · the user asks to proceed despite an unmet dependency.

## Output
Story id + title · status transition · files created/modified · ACs X of Y (with how each was
proven) · PDs added · suggested next story.
