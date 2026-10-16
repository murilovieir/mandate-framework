# RFCs — decision proposals

Proposals for architectural, technological or business changes awaiting the decider.

> **Decider-gated, not IETF-style.** An RFC here is a **proposal of decision** the decider approves or
> rejects — no public comment round, no committee consensus. The acronym is kept because it is the
> industry-standard name; the semantics are those of Oxide's RFD or Shape Up's Pitch. Approved →
> promoted to an **ADR** and decomposed into stories.

## Flow

1. The agent hits a decision outside direct-implementation scope (`CLAUDE.md` §5).
2. It writes `RFC-NNN-slug.md` here from the template below.
3. **It implements nothing** until an explicit GO.
4. The decider records the decision in **both** the front matter `status` and the `## Status` block.
5. Review finds a defect after writing? Fix the body and add an `## Errata` table — never rewrite
   history silently.

## Status vocabulary (closed)

`awaiting` · `approved` · `partially-approved` · `rejected` · `superseded`

> Reading trap: the `## Status` block lists the unchecked option first. Read the front matter, or
> read the whole block — never `grep -A2`.

## Template

```markdown
---
id: RFC-NNN
title: {short title}
status: awaiting
---

# RFC-NNN — {Short title}

**Date:** YYYY-MM-DD · **Area:** backend | frontend | infra | data | ai | process
**Impact:** low | medium | high · **Related ADR:** ADR-NNN (or "new ADR needed")

## Problem identified
## Proposed solution
## Alternatives considered
## Trade-offs
## Effort estimate
## Proposed decomposition
{one story per phase, each with its own branch/PR/CI}

## Status
- [ ] Awaiting approval
- [ ] Approved — implement (decider, YYYY-MM-DD)
- [ ] Rejected — reason: ___
```

## Numbering

`RFC-001`, `RFC-002`, … — sequential, global, never reused. A commit that creates an RFC (no story
exists yet) uses the footer `Refs: RFC-NNN`.
