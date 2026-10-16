---
id: T-NNN
title: <short, actionable title>
uow: <NN>
status: todo # todo | in-progress | blocked | in-review | done | deferred
type: story # story | task | spike | chore
adrs: [ADR-NNN]
depends_on: [] # T-NNN ids that must be done first
blocks: []
estimate: S # S <1d · M 1–3d · L 3–7d (L requires "Indivisibility rationale" — RULE-TASK-01)
skill: backlog-executor
---

# <title>

## Context
<1–3 paragraphs linking the story to the referenced ADRs and the Unit of Work goal. If this story
corrects a defect shipped by an earlier `done` story, name it here (rework signal).>

## Implementation Contract

### Scope (IN)
- <what this story delivers>

### Out of scope (OUT)
- <what this story explicitly does NOT do>

### Indivisibility rationale (only if `estimate: L`)
<why this cannot be two smaller stories. Delete this section for S/M.>

### Expected files (≤ 8 — RULE-TASK-01; one bullet per file)
- `path/to/file` — <description>

### Locked technical decisions
- <decisions already closed in the referenced ADRs — listed so the agent doesn't reopen them>

### Decisions left open
- <decisions that may emerge, each with a proposed default>

## Acceptance Criteria (≤ 5 AC lines — RULE-TASK-01)
- [ ] AC-1: <given / when / then — objectively verifiable>
- [ ] AC-2: ...

## Definition of Done
- Every AC checked **with an execution that proves it** (RULE-QA-01)
- Commit footer `Refs: T-NNN, ADR-NNN`; PR `[T-NNN] ...` into `develop`
- New decisions registered in `DECISIONS.md`

## Execution notes
<what ran (with counts), deviations, PDs, review findings (RULE-QA-02)>
