---
id: T-001
title: Adopt the governance layer — constitution, stack ADRs, sensitive domains
uow: 01
status: todo
type: story
adrs: []
depends_on: []
blocks: []
estimate: S
skill: backlog-executor
---

# T-001 — Adopt the governance layer

## Context
Mandate's constitution and knobs are generic. Before the first product story, they must state
this project's context, stack and sensitive domains — the one piece that can't be retrofitted after a
silent default ships.

## Implementation Contract

### Scope (IN)
- Fill `CLAUDE.md` §1, §2 (stack table) and §6 (phases).
- One ADR per stack row, `status: accepted`, indexed in `docs/adr/README.md`.
- Set `SENSITIVE_DOMAINS` and `SENSITIVE_PATHS` in `governance.env`.
- Record the instruction budget.

### Out of scope (OUT)
- Product code. Domain guardrails (next story).

### Expected files
- `CLAUDE.md` — sections 1, 2, 6
- `docs/adr/README.md` — index
- `docs/adr/ADR-001-<slug>.md` — first stack decision
- `governance.env` — sensitive domains and paths
- `scripts/guardrails/allowlists/instruction-budget.txt` — recorded ceilings

### Locked technical decisions
- The governance method itself (Mandate).

### Decisions left open
- Which stack rows deserve their own ADR — default: every row of the §2 table.

## Acceptance Criteria
- [ ] AC-1: `grep -c "_fill in_" CLAUDE.md` returns 0.
- [ ] AC-2: `./scripts/guardrails/decision-status-consistency.sh` passes with at least one ADR.
- [ ] AC-3: `./scripts/guardrails/verify-all.sh --fast` ends with `VERIFY-ALL: OK`.

## Definition of Done
- Every AC checked with the execution that proves it; commit footer `Refs: T-001`.

## Execution notes
