# Learned rules (tier 2)

> **Two-tier knowledge.** Tier 1 (`CLAUDE.md`, `AGENTS.md`, area constitutions) carries only
> normative imperatives — the *what*. This file is tier 2: the **why** behind each correction, one
> entry per correction, loaded on demand by the skills that need it instead of in every session.
> Plain markdown with no tool-specific mechanics, so any agent runtime can read it.
>
> **Format:** `LR-NNN · observable trigger → rule · origin (T-NNN / RFC-NNN / incident) · date`.
> Add an entry whenever you correct the agent's behavior; cite it from tier 1 as `→ LR-NNN`.

## Index — `LR-NNN` → rule it backs → who loads it

| LR | Rule in tier 1 | Loaded by |
|---|---|---|
| LR-001 | `CLAUDE.md` §0 RULE-REVIEW-01 | — (tier 1 only) |
| LR-002 | `CLAUDE.md` §7 RULE-QA-01 | `review-gate` |
| LR-003 | `CLAUDE.md` §7 RULE-QA-02 | `review-gate`, `decision-log` |
| LR-004 | `AGENTS.md` "never slide from listing to executing" | read-only skills |
| LR-005 | `CLAUDE.md` §11 RULE-PM-05 | `backlog-executor` (step 6) |
| LR-006 | method rule of the consistency gate | `analyze` |

---

The seed entries below are the lessons behind Mandate's own rules, written in generic form. Keep them
as precedent, or replace them with your project's own as they appear.

**LR-001** · the automated PR review fails (bot error, quota exhausted, or neither a comment nor a 👍
within the follow-up window) → warn the decider **and**, in the same message, suggest a local review
layer (`/code-review` and/or `qa-engineer`) — never just warn and move on · why: a bot's error or
quota comment *looks* like a completed review, so a PR can merge with zero review layers · seed.

**LR-002** · an AC is checked on the strength of "it compiles" or of the tests the executor wrote →
the gate is the full suite of every touched module, derived from the diff · why: the tests a new
contract breaks are the neighbours the executor didn't write; a suite that never ran hides them, and
review then reopens ACs already marked done · seed.

**LR-003** · review findings scroll away in the terminal and the same defect class returns → findings
go to the story's execution notes in the same commit as the fix · why: a finding with no record
can't be counted, and a class of defect nobody counts keeps coming back · seed.

**LR-004** · a reviewer tool receives a read-only "what is ready to build" listing and implements a
listed story on its own → read-only skills declare it on their first line, and `AGENTS.md` forbids
sliding from listing into executing · why: tools without skill isolation read a list of ready work
as an order. Role experiments that were tried and reverted are recorded so they aren't re-proposed
from memory · seed.

**LR-005** · stories sit `in-review` long after their PR merged, waiting for a separate review gate
nobody runs → merged PR + checked ACs → `done` in the same commit, without asking case by case; only
spec-declared blocked ACs stay `in-review` · why: a stale status corrupts the dependency graph and
the ready-work list · seed.

**LR-006** · an audit reports false "pending" findings by reading fields instead of blocks (unchecked
status option listed first; a class name taken as its scope; an empty grep taken as proof of absence;
a caveat present in body and index but not in the field) → read the block, never the field, before
claiming something is pending · why: a false "pending" invites re-deciding what was already decided
· seed.
