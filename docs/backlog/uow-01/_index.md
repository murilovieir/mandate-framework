---
id: UOW-01
title: Foundation — governance bootstrapped and a first deployable increment
status: open
exit_gate:
  stories_done: [T-001]
  commands:
    - ./scripts/guardrails/verify-all.sh --fast
---

# UoW 01 — Foundation

**Goal:** the repository builds, CI is green through `verify-all.sh`, and the governance layer is
adopted (constitution filled, first ADRs, first domain guardrail).

**Exit gate:** executable — see the front matter (🔒 `scripts/guardrails/uow-gate.sh`). Add stories to
`stories_done` as you create them; target 3–5, ceiling 8 (RULE-UOW-01).

**Rigor level:** N0 for T-001.

## Stories

| ID | Delivers | Est. | depends_on | Status |
|----|----------|-----:|-----------|--------|
| T-001 | Governance adopted: constitution filled, stack ADRs, sensitive domains, budget recorded | S | — | todo |
