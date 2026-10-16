---
name: decision-brief
description: Executive brief of one Project Decision (PD-…) from the Decision Log — re-checks the PD's premises against the code, evaluates the resolution options (the ones the PD listed AND the ones it missed), and closes with ONE main recommendation plus the condition that would change it. Use on "/decision-brief PD-…", "how do I resolve PD-X", "what are the options for PD-X", "what do you recommend on this PD". With no argument, triages the whole ratification queue and says which PD deserves the full brief. READ-ONLY — doesn't decide, doesn't edit the PD, doesn't implement; the decider decides.
---

# `/decision-brief` — options and a recommendation for one PD

> ⛔ **READ-ONLY — recommends; never decides, never edits the PD, never implements.** Without Claude
> Code's skill mechanism the rule holds: produce the brief and stop — no branch, no commit, no change
> to any `Status:` (`LR-004`). **Agents recommend; the decider decides.**

A PD records the fork and the alternatives **as of when it was written**. This skill produces what's
missing to decide: premises re-checked against today's code, options evaluated (not transcribed), and
a recommendation that takes a position.

## Step 1 — find and read the whole PD
```bash
grep -n "^## PD-…" DECISIONS.md DECISIONS_ARCHIVE.md
```
Search **both** files — a closed `DEFAULT_APPLIED` without `Ratified-by` is still pending ratification;
a `DEFERRED` one may have its `Reopen-trigger` firing now. Also read what it references (stories, ADRs,
originating RFC). The PD is the index, not the dossier.

## Step 2 — re-check the premises against the code (`decision-log` §1-B)
Read what each premise asserts about, not the prose: doesn't exist → grep · not ready → `status:` ·
a number → run what measures it. **Before** the options: a stale premise invalidates the evaluation of
the alternatives, not just a detail. A stale premise goes **in the brief as a finding**, with evidence
— the correction in the PD body happens through `decision-log` when the decider acts. A brief that
silently edits what it briefs can't be checked afterwards.

## Step 3 — options
Start from the PD's `Alternatives:` but don't stop there:
1. **Kill what reality already killed** — say why; don't omit it (omitting hides it was considered).
2. **Add what's missing** — split the decision in two; defer *with an observable trigger*; apply the
   mechanism without fixing the number.
3. **Real cost of each** — hours, reversibility, what breaks if wrong. "Low/medium/high" alone helps
   no one decide.
Also evaluate the **cost of not deciding**: sometimes zero (say so — it's a service), sometimes it
bleeds every day.

## Step 4 — is a specialist worth it?
| PD profile | Dispatch |
|---|---|
| `internal` · operational | none — read the code and form the opinion |
| sensitive domain or architectural | `architect` |
| crosses 3+ roles | coordinator role, if you have one |
| the whole queue, not one PD | `tpm` (the ratification digest, not this brief) |
When dispatching, send the context from steps 1–3 — the specialist starts cold.

## Step 5 — the recommendation
One main recommendation. "It depends" isn't one; if it truly depends, say **on what** and recommend a
path per branch. Every recommendation carries **what would change it** — a falsifiable condition.
**Hard gate:** a sensitive PD never closes as `DEFAULT_APPLIED`, however obvious the recommendation;
say so out loud — explicit ratification remains mandatory.

## Present (always this shape, one page)
```markdown
## decision-brief — PD-… (<date>)
**<title>** · `<Status>` · `Sensitivity: <x>` · `Impact: <y>` · <N> days old · Story(s): <T-NNN>
### What is stuck
<1–2 sentences. "Nothing" is a valid, useful answer.>
### Premises (§1-B)
| PD premise | Checked in | Still holds? |
### Options
| # | Option | Real cost | Reversibility | Alive? |
### Recommendation: <option N>
<2–3 sentences of argument.>
**What would change this:** <falsifiable condition>
### If decided this way
- **Closes as:** `RESOLVED (<decider>, <date>)` | `DEFAULT_APPLIED` | stays `DEFERRED` with trigger
- **Needs a story?** <new T-NNN (estimate) | fits an existing one | none>
- **Gate:** <if sensitive: explicit ratification required>
```

## Queue mode (no argument)
`python3 scripts/planning/decision-index.py | grep -i awaiting` → one line per PD: id, one sentence,
and the classification that matters — **signature** (stamp, no debate) vs **real decision** (live
trade-off). Close by pointing at the one that deserves the full brief, and why.

## Boundaries
No PD edits · no implementation (that's a story) · no new file — the brief lives in the answer; the
durable record is the PD body, updated by `decision-log` when the decision happens.
