---
name: review-task
description: Produces a detailed execution report of one backlog story. Use on "/review-task T-NNN", "give me a breakdown of how T-NNN was executed", "what was delivered in T-NNN". Reads the story file, the delivered code and the execution notes before answering. READ-ONLY.
---

# `/review-task` — story delivery report

> ⛔ **READ-ONLY — reports on what was delivered; never implements or fixes.** The rule holds for
> agents without Claude Code's skill mechanism (`LR-004`).

## How
1. Find the story id; read `docs/backlog/uow-NN/T-NNN-*.md`.
2. Read every file created/modified that the story mentions, the execution notes and the checked ACs.
3. Read the ADRs in `adrs:`.
4. Write the report below.

## Report
### 1. What was built
Created and Modified, each with a relative link and a one-line description.
### 2. What was tested
**Automated:** test name, what it verifies, result, duration. **Manual:** table Check | Command | Result.
### 3. What was configured
What, why (ADR or decision), an illustrative snippet, the pattern it sets for future stories.
### 4. Documented deviations
Expected · done instead · why · impact.
### 5. Open items and decisions
Table: # | Item | Context | When it resolves.
### 6. What could still be done
**Quality** (missing tests, fragile config, observability) and **Security** (before exposure) — each
with why it matters and effort S/M/L.
### 7. ADR compliance
Per ADR: | ADR requirement | ✅ met / ⏳ out of scope / ❌ not met | Note |. Close with one paragraph:
how many active requirements were met, what's pending, and whether it's acceptable to move on.

## Rules
- Read files before writing — never assume what's in the code.
- `[~]` AC → explain the deviation. Expected file missing → ❌ and explain.
- Don't count what's in **Out of scope** as missing.
- Relative links everywhere. Direct over exhaustive.
