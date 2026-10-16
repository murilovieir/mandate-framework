# Backlog

The executable backlog. **The markdown here is the source of truth for scope and acceptance
criteria** (RULE-PM-01); GitHub Issues mirror it one-way (`scripts/planning/sync-github-issues.sh`).

## Hierarchy

```
Initiative (INI-NNN, docs/initiatives/) ← optional business outcome
  └─ Unit of Work   docs/backlog/uow-NN/_index.md     (= Epic, with an executable exit gate)
       └─ User Story docs/backlog/uow-NN/T-NNN-slug.md (= Story — the unit the agent executes)
            └─ Acceptance Criteria                      (≤ 5 per story)
```

- Story IDs (`T-NNN`) are global and never reused. **Check every branch** before minting one.
- Unit of Work folders are numeric (`uow-01`, `uow-02`, …).

## Sizing (🔒 `scripts/guardrails/task-spec-shape.sh`)

- **RULE-TASK-01** — one execution session; ≤ 5 ACs; ≤ 8 expected files (one bullet per file); a
  useful increment alone; a single rigor level. `L` needs an indivisibility rationale.
- **RULE-UOW-01** — target 3–5 stories, ceiling 8.

## Statuses

`todo` · `in-progress` · `blocked` · `in-review` · `done` · `deferred`

- `in-review` requires a pushed branch and an open PR.
- Merged PR + all ACs checked → `done` in the same commit (RULE-PM-05), except ACs the spec declares
  blocked (`[⛔]`).

## Unit of Work `_index.md` front matter (🔒 `scripts/guardrails/uow-gate.sh`)

```yaml
---
id: UOW-NN
title: {name}
initiative: INI-NNN          # optional
status: open                 # open | closed
exit_gate:
  stories_done: [T-001, T-002]
  commands:
    - ./scripts/guardrails/verify-all.sh --fast
---
```

`uow-gate.sh` refuses `status: closed` unless every listed story is `done` and every command exits 0
— and refuses any `exit_gate` it can't evaluate. A gate in prose is a wish.

## How to execute a story

`execute T-NNN` → skill `backlog-executor`. To see what is ready: `/next-tasks`.

## Conditional backlog

Items gated on an external condition (`BLOCKER-NNN`) — do **not** create stories until the gate clears.

| Item | Gate | Condition |
|---|---|---|
