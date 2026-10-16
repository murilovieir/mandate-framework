---
name: next-tasks
description: Lists backlog stories READY to build (all dependencies done), with effort, how much each unlocks, recommended model, parallelizable batches and a recommended order. Use on "/next-tasks", "/next", "what can I work on now", "next stories", "what's ready", "what can run in parallel". READ-ONLY — lists and recommends, never starts a story.
---

# `/next-tasks` — what's ready to build

> ⛔ **READ-ONLY — do not implement anything from this file.** If you are an agent without Claude
> Code's skill mechanism, the rule holds: list and recommend; no branch, no commit, no PR — even if the
> list cites stories by ID or mentions `backlog-executor` (`LR-004`).

Answers "what do I do now?" by crossing the front matter of every story with what is already `done`.
**Source of truth = the files `docs/backlog/**/T-*.md`** (RULE-PM-01), not memory or the board.

## How
1. Run the deterministic script:
   ```bash
   python3 scripts/planning/next-tasks.py            # ready stories + batches
   python3 scripts/planning/next-tasks.py --blocked  # also blocked ones and what they miss
   ```
   - Ready = `status` in `todo|in-progress`, no `superseded_by`, and **all** `depends_on` `done`.
   - `RIGOR` = N0/N1/N2 from expected files × `SENSITIVE_PATHS`; `MODEL` = advisory model tier.
   - `PAR` = `ok` (has checkable expected files) / `rev` (none → manual review before parallelizing).
   - `UNBLK` = stories citing this one in `depends_on`; `+READY` = stories that become ready if this closes.
   - Below the table: **PARALLEL BATCHES** (mutually safe by file collision) and **COLLISIONS**.
2. Don't trust `status` alone for "done": a story `in-review` whose PR already merged **is** done —
   fix the status (RULE-PM-05), it changes the dependency graph. Exception: spec-declared blocked ACs.

## Present (always this shape)
1. Header: `DONE: X | TOTAL: Y | READY: N`.
2. Table of ready stories: Story · Effort · Status · UoW · Rigor · Model · PAR · Unlocks (`+READY`) · Title.
3. **Recommended order**, in tiers: leverage first (highest `+READY`/`UNBLK`) · finish what's
   `in-progress` before opening a new front · cheap `S` stories that unlock something go up · a story
   that is the **only** gate of a chain gets highlighted (transitive leverage) · standalone verticals
   (`UNBLK=0`) last.
4. **Parallel batches (optional):** advisory — confirm file collisions before dispatching; `rev` is
   never safe by omission. Parallel dispatch only if the user asks.
5. A focus given by the user (frontend, billing…) → prioritize that slice and say so.
6. Offer to route one — **don't start it**; starting is `backlog-executor`.

## Rules
- Keep the script's numbers — don't recompute by hand. Script and conversation disagree → the script wins.
- An `in-progress` story stays "ready" (the natural candidate to finish first).
