---
name: analyze
description: Spec-Driven Development consistency gate. Crosses story specs ↔ ADRs ↔ code ↔ backlog ↔ DECISIONS.md and reports divergences (decision implemented but still proposed, the same gate described differently, front-matter status vs reality, orphan T-NNN/ADR-NNN refs, ID collisions, ADR contradicting the stack in CLAUDE.md §2). Use on "/analyze", "consistency audit", "check doc×code divergences", or before closing a Unit of Work. READ-ONLY — lists and proposes, never fixes.
---

# `/analyze` — SDD consistency gate

> ⛔ **READ-ONLY — reports divergences, never fixes code, ADRs or decisions, never implements
> stories.** If this file reached an agent without Claude Code's skill mechanism, the rule holds: list
> and propose; no branch, no commit (`AGENTS.md`, `LR-004`).

Goal: detect consistency debt **before** it becomes a bug or a wrong decision.

## What to cross
For the requested scope (one story, one Unit of Work, or the whole repo):
1. **Story specs** (`docs/backlog/uow-*/T-NNN-*.md`) — front matter (`status`, `depends_on`, `blocks`, `adrs`) + ACs.
2. **ADRs** (`docs/adr/`, index `docs/adr/README.md`) — status and decision.
3. **Code** — what is actually implemented.
4. **Backlog indexes** (`docs/backlog/README.md`, `_index.md`) and `CLAUDE.md` (§2 stack, §6 phases).
5. **`DECISIONS.md`** — open/resolved/default-applied PDs.

### ⛔ Method — read the block, never the field (`LR-006`)
Before claiming anything is pending or uncovered, **open the file**:
1. The `## Status` block lists the **unchecked** option first — read to the next heading (and look for
   a decision record further down the file).
2. A class name is not its scope — check what it actually does.
3. An empty grep for a symbol doesn't prove the behavior is absent — it may just be named differently.
4. The caveat may live in the body and the index, not in the field.

A false "pending" is worse than silence: it invites re-deciding what was decided and burns the
decider's attention on an inflated queue.

## Divergence categories
- **D1 — Decision implemented but not promoted:** ADR `proposed`/`refining` whose code ships → propose `accepted`.
- **D2 — Stack drift:** `accepted` ADR contradicting `CLAUDE.md` §2 (or another ADR) without reconciliation.
- **D3 — Gate/description drift:** the same item described differently across ADR × backlog × constitution.
- **D4 — Status drift:** front-matter `status:` vs reality (merged code, resolved PD). Tolerable (RULE-PM-04) — flag, don't block.
- **D5 — Orphan refs / ID collisions:** `T-NNN`/`ADR-NNN`/`RFC-NNN`/`PD-*` pointing at nothing, or one ID used twice.
- **D6 — Unregistered decision:** a decision visible in code/commits with no `DECISIONS.md` entry.

## Output
Write `docs/reports/analyze-<YYYY-MM-DD>.md`, stating first that it is read-only and changed nothing:
- **Summary** (count by severity).
- **Findings** — `ID · severity · category · evidence (file:line) · recommendation · owner (decider/agent)`.
- **Resolved since the last report.**
- **Prioritized fix list** (which story should carry each fix).

## Rules
- Never mutate ADRs or decisions — only propose (applying needs the decider's GO).
- Status divergence is tolerable; scope/AC/stack divergence is high severity.
- Idempotent: re-running updates today's report, never duplicates it.
