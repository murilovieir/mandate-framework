---
name: decision-log
description: Governance guardrail for architectural and operational decisions found during story execution. Every decision is registered in DECISIONS.md — never left only in story files, comments or conversation context. Defaults in sensitive domains (SENSITIVE_DOMAINS in governance.env) can NEVER close silently — they require explicit ratification by the decider. Apply automatically before and after every story.
---

# Decision Log governance

Every architectural or implementation decision met during execution **must** be registered in
`DECISIONS.md` — never only in a story file, a code comment or the conversation.

> `PD-` reads **"Project Decision"**. Recommend↔ratify follows RAPID: **agents recommend, the decider
> decides.** `DECISIONS.md` holds live entries + the index; closed entries live in
> `DECISIONS_ARCHIVE.md`. The index is **generated** — run `python3 scripts/planning/decision-index.py`
> after any PD change; never edit the table by hand.

## When it applies
Register a decision when it: affects more than one module/story · chooses between ≥ 2 viable
alternatives · impacts data model, API contract, security or infrastructure · is a "proposed
default"/"open" item in a spec · would surprise another developer if found buried.

## 1. Before a story — scan for embedded decisions
Look for: `decide`, `proposed default`, `open`, `alternative`, `TBD`, `Decisions left open`. For each:
register a PD, add `→ Registered in DECISIONS.md #PD-…` to the story, keep the original context there.

**ID uniqueness — both files and every branch.** `git ls-tree -r --name-only <branch>` over all remote
branches before minting. A spec or PD that lives only on an unmerged branch is invisible from where
you are. A guardrail that lives only on an unmerged branch protects nobody.

## 1-B. Before ACTING on an existing PD — re-check its premises against the code
A PD records what was true when written. Before implementing it, scoping a story from it, or advising
the decider on it, read what the premise asserts about — not the prose:
- claims something doesn't exist → grep for it;
- claims a dependency isn't ready → read its `status:`;
- claims a number → run what measures it.
A stale premise is corrected **in the PD, in the same commit**, with the evidence. Don't work around it.

> Don't try to automate this with text heuristics on PD prose — they produce mostly false positives.
> The signal is the gap between the text and the code.

## 2. During implementation — register forks immediately
- **STOP** before implementing either option; register with `Proposed-by`, `Reversibility`,
  `Sensitivity`, `Scope`.
- **Escalation rule (non-negotiable):** a decision whose `Sensitivity` is in `SENSITIVE_DOMAINS`
  (`governance.env`) can **never** close as `DEFAULT_APPLIED`. Mark `NEEDS_VALIDATION`, surface it to
  the decider, wait. This is the rule that catches a survival-condition mechanism chosen by silent
  default.
- **Operational** (`internal`, two-way, no cross-module/API/security impact): apply the safe default,
  mark `DEFAULT_APPLIED`, note it in the story. It enters the ratification queue; it blocks nothing.

## 3. Resolution — close the loop
`RESOLVED (who, YYYY-MM-DD)` (or `RESOLVED (ADR-NNN, date)`), fill `Resolved:`, link the ADR, move the
block to `DECISIONS_ARCHIVE.md`, regenerate the index.

## 4. Ratification cadence
`DEFAULT_APPLIED` closes the implementation loop, not the governance loop. The weekly
`chief-of-staff` briefing carries a **ratification digest** (one table); the decider ratifies in
batch; the `tpm` records `Ratified-by: <decider> (YYYY-MM-DD, digest)` and regenerates the index.
**Lapse (optional):** `internal` defaults with no objection for 14 days from `Resolved:` are recorded
as `Ratified-by: <decider> (auto, lapse, YYYY-MM-DD)`. **Sensitive PDs are never eligible.**

## Entry format (v3)
See the template at the top of `DECISIONS.md`. Fields that matter most:
`Proposed-by` vs `Ratified-by` (who recommended vs who ratified — a role like `owner:billing` is
accepted), `Reversibility` (one-way/two-way door), `Sensitivity`, `Scope` (`local` | `org` — does it
bind other teams?), `Reopen-trigger`.

### Verifiable premises go in structured fields, never in prose
`Reopen-trigger:` works because `decision-index.py` reads it: a trigger citing `T-NNN` fires when that
story is `done`. A premise buried in `Context:` prose is reached by nothing.
- **Prefer a data condition to a story status** — "T-NNN done" fires empty when the story merged but
  the data never materialized.
- Cite `T-NNN` when the trigger really is a story status. Premise about code → name the file/symbol.
- A data condition is only mechanical if something runs it — otherwise say so in the trigger.

## Anti-patterns
- ❌ Decision only in a story file, comment or chat · ❌ sensitive default closed as `DEFAULT_APPLIED`
- ❌ A decision the decider actually made recorded as `DEFAULT_APPLIED` (that's `RESOLVED`)
- ❌ Hand-edited index · ❌ ID minted without checking both files and all branches
- ❌ Acting on an old PD trusting its prose · ❌ re-checkable premise in prose
- ❌ Confusing a PD with an RFC (new feature/tech) or an ADR (locked)

| Artifact | Use for |
|---|---|
| `DECISIONS.md` | fork during implementation, within scope |
| `docs/rfc/` | new feature/tech, architectural change needing approval |
| `docs/adr/` | locked decision — never reopen |
| Story "Execution notes" | review findings (`LR-003`, RULE-QA-02) — not decisions |

## Checklist after every story
1. No unregistered decision in the diff · 2. every decision in Execution notes has a PD ·
3. cross-references are bidirectional · 4. no sensitive default closed as `DEFAULT_APPLIED` ·
5. if the story acted on an existing PD, its premises were re-checked (§1-B) ·
6. re-checkable premises sit in `Reopen-trigger:` · 7. `python3 scripts/planning/decision-index.py --check` passes.
