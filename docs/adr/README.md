# ADRs — Architecture Decision Records

**Architectural source of truth.** One file per decision, MADR style: `ADR-NNN-slug.md`.

> Any new ADR is proposed via `docs/rfc/RFC-NNN-*.md` and approved by the decider first — the agent
> never creates an ADR directly. ADRs are immutable references: evolve them by editing in place with a
> version note, or supersede them with a new ADR. The `/analyze` skill checks spec ↔ ADR ↔ code
> consistency; `decision-status-consistency.sh` checks that this index agrees with each file.

## Status vocabulary (closed)

`proposed` · `refining` · `accepted` · `deprecated` · `superseded` · `rejected`

## Index by domain

<!-- One table per domain. Keep the Status column identical to each file's front matter. -->

### Platform

| ADR | Title | Status |
|-----|-------|--------|

## File template

```markdown
---
id: ADR-NNN
title: {Short decision title}
status: proposed
date: YYYY-MM-DD
domain: {e.g. platform / security / data}
# superseded_by: ADR-MMM   # only when status: superseded
---

# ADR-NNN — {Short decision title}

## Context
{Why a decision is needed. Constraints, SLAs, licensing, prior art. 1–3 paragraphs.}

## Decision
{The decision, stated affirmatively. Tables for key contracts (interfaces, limits, namespaces).}

## Consequences
{What becomes forbidden, what becomes mandatory, follow-ups, known debts, cross-references to other
ADRs and PD entries.}
```
