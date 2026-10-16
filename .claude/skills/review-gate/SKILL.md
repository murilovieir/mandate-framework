---
name: review-gate
description: Executable verification gate before checking an AC or committing (RULE-QA-01). Runs verify-all.sh (which derives the modules to test from the diff), dispatches the qa-engineer agent on diff × spec, and crosses every checked AC with the execution that proves it — flagging every [x] AC without proof. Use on "/review-gate", "/review-gate T-NNN", "run the gate", "verify before committing", and automatically before marking any AC and before opening a PR. Read-only — it verifies, it doesn't fix. Does NOT replace the native /code-review, which only the user triggers.
---

# `review-gate` — execute before asserting

> ⚠️ **This gate EXECUTES tests — that's the only thing it does that matters.** If you're an agent
> without Claude Code's skill mechanism (this file was pasted to you), the contract holds: run the
> suite for real or report that you couldn't. **Never report a gate as clean without execution.** It
> doesn't fix anything; fixing belongs to the story's normal flow. Why it exists → `LR-002`.

## When to run

| Trigger | Who | When |
|---|---|---|
| End of a layer | you, automatic | before each layer's commit |
| Before marking an AC | you, mandatory | no AC becomes `[x]` before the gate passed |
| Audit | the decider | `/review-gate T-NNN`, also on an already-delivered story |
| Before the PR | you, automatic | the output goes into the PR description |

## Step 1 — run verification (one command)

```bash
./scripts/guardrails/verify-all.sh
```

The list of *what* to run lives in `verify-all.sh`, not here — it derives modules from the diff and is
**the same command CI runs**. A second, hand-maintained list here would drift from CI silently.

- `--fast` runs what needs no build toolchain; `--only <family>` re-runs one family.
- **A check that couldn't run prints `not verified: <id> — <reason>` and exits non-zero.** That's the
  declared partial result RULE-QA-01 talks about — copy those lines into the notes, never omit them.
- **The full suite of every touched module**, not just the tests you wrote: the neighbours your new
  contract invalidated are exactly the ones you didn't write.
- Environment prevents the full suite? Run the affected tests in isolation and record **which and why**.
- Running locally is feedback, not the gate — the gate is the CI execution.

## Step 2 — `qa-engineer` on diff × spec
Dispatch the `qa-engineer` agent with the diff and the story spec. Its question differs from yours:
**"do the tests PROVE the ACs, or just pass?"** It starts cold and doesn't inherit your assumptions —
that is the value. It points; it doesn't fix.

## Step 3 — cross checked ACs × execution
For each `[x]` AC, name **which executed test proves it**. An AC marked without a proving test is a
gate finding.

## Report

```markdown
## review-gate — T-NNN (<date>)
### Executed (verify-all.sh)
| Check | Result |
### ACs × execution
| AC | Proof (executed test) | Verdict |
|----|-----------------------|---------|
| AC-1 | `FooTest#bar` — 8/8 | ✅ |
| AC-4 | — | ⚠️ marked without proof |
### qa-engineer
<findings, or "none">
### Limits of this run
<what didn't run and why — never omit>
### Verdict
GATE CLEAN / GATE WITH FINDINGS (n)
→ Next: suggest `/code-review` before the PR (only the user triggers it).
```

## Boundaries
- Doesn't fix. Doesn't trigger `/code-review` (can't — recommend it). Doesn't replace PR bots
  (RULE-REVIEW-01), which review later on the PR.
- A clean gate is not "no defects" — it is "the checked ACs have an execution behind them".
- Findings (from this gate, `/code-review` or bots) go to the story's **Execution notes** in the same
  commit as the fix (RULE-QA-02, `LR-003`).
