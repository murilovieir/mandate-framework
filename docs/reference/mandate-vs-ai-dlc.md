# Mandate and AI-DLC — what we have, what we adopted, what we rejected, what's missing

> 🇧🇷 Português: [mandate-vs-ai-dlc.pt-BR.md](mandate-vs-ai-dlc.pt-BR.md) · Author: **Murilo Vieira**
> Reference, not normative — outside the instruction budget. Short equivalence table: [`ai-dlc-rosetta.md`](ai-dlc-rosetta.md).

**AI-DLC** (AI-Driven Development Lifecycle, `awslabs/aidlc-workflows`) is AWS's method for software
development with AI at the center: phases (Ideation · Inception · Construction · Operation), work
organized in **Units of Work** and short iterations called **bolts**, 33 *stages* each with an owner
and an approval gate, manually chosen *depth levels*, a roster of 14 agents, synchronous **mob
elaboration** sessions, an audit trail and two-tier knowledge.

Mandate was evaluated against AI-DLC twice during its evolution. This document
records the outcome: the verdict, what converged, what was rejected on purpose, and what is still open.

---

## 1. The verdict

Mandate came out **in the top decile on the decision axis** — spec as contract, decider-gated
RFC → ADR, a Decision Log with reversibility, sensitivity and ratification, a rigor ladder derived
mechanically from paths — and **below average on a single axis: preventing by machine instead of
asking in text.** AI-DLC is weaker where Mandate is strongest (it has no decision log) and stronger
where Mandate was weakest (enforcement, sizing, measurement, operation).

So the decision was **converge, not adopt**: import five concepts and two names, keep the method.

## 2. The gaps found — and how each was closed

| # | Gap (as found) | How Mandate closed it | Pillar |
|---|---|---|---|
| P1 | Guardrails lived in prose — enforcement only after the diff, if at all | One script per rule, two consumers (warn hook + merge-blocking CI); `verify-all.sh` as the single authority | **N**, **T** |
| P2 | The normative surface (constitution, skills, agents) had no tests — editing the constitution was a deploy without regression | Mutation-style agent evals: golden + mutated trajectories, blob-SHA staleness gate | **T** |
| P3 | Instruction budget blown — the constitution carried narrative errata inline | Two-tier knowledge (`learned-rules.md`) + a descending instruction-budget ratchet | **N** |
| P4 | Work units too big for the propose → arbitrate loop (estimates up to "> 1 week") | Bolt sizing: RULE-TASK-01 (≤ 5 ACs, ≤ 8 files, one session) and RULE-UOW-01 (3–5, ceiling 8) | **E** |
| P5 | The process didn't measure itself — the rigor ladder couldn't be calibrated | Audit trail `process-metrics.jsonl` (`story_closed`, `rework_observed`) + aggregator | **T**, **E** |
| P6 | The Operation phase was zero — a known cliff | Registered slot with an observable activation trigger (not built until needed) | **E** |

Hypothesis tested and **discarded** (not a gap): institutional memory already existed —
`docs/office/` + the Decision Log are a more structured equivalent of AI-DLC's *method memory*.

## 3. What Mandate already had (equivalence)

| AI-DLC | Mandate | |
|---|---|---|
| Ideation / business intent | **Initiative** (optional) | ✅ |
| Inception | RFC → ADR + story spec | ✅ stronger — AI-DLC has no Decision Log |
| Construction | Unit of Work + `backlog-executor` | ✅ |
| Stages with owner + approval gate | steps of the executor loop + 5 handoff gates (G1–G5) | ✅ functional equivalent |
| Depth levels (chosen by hand) | Rigor ladder N0–N3 (**derived from touched paths**) | ✅ mechanical > manual |
| Method memory | `docs/office/` + `DECISIONS.md` | ✅ with reversibility/sensitivity/ratification |
| Domain experts + quality reviewers + composer | virtual org (`qa-engineer`/`release-manager` = reviewers) | ✅ |

## 4. What was adopted

1. **Unit of Work** — literal name convergence (replaced the former "Wave"); **Initiative** replaced
   the former top level ("Tide"). `Intent` was rejected as a name because it collided with a product
   term — names are chosen by **measured collision** (`grep` across the repo), not by taste.
2. **Bolt sizing** — adopted as a sizing rule, not as a new level of the hierarchy.
3. **Audit trail** — one structured event per story closure.
4. **Two-tier knowledge** — constitution (what) + learned rules (why).
5. **Operation phase** — as a gated slot with an observable trigger.

## 5. What was rejected — on purpose

| AI-DLC element | Why not |
|---|---|
| Adopting the whole method (33 stages, 14 agents) | Would trade Mandate's strong axis for a tie. Stages exist to coordinate people who **don't share context**; mapping the real handoff points found **five** (G1–G5), not 33 |
| Global rename to AI-DLC vocabulary | Cost in hundreds of files for terms where Mandate loses nothing (story, RFC, ADR, PD) |
| Logical architecture artifact per Unit of Work | Recorded **non-adoption** — a decision, not a backlog gap |
| Synchronous mob elaboration | Built for groups of humans in a room; a single decider with a virtual org covers it asynchronously (N2 = three independent opinions before merge). Revisited with PODs — §7 |
| Manual depth levels | Mandate's path-derived rigor is strictly better: classification is a derivation, not a choice |

## 6. What is still missing

| Gap | Where it is planned |
|---|---|
| Operation phase built (on-call roster, runbooks, incident loop), trigger as a data query | ROADMAP UoW-10 (MF-032..034) |
| Agent evals as merge-blocking, captured from real sessions, multi-runtime | ROADMAP UoW-04 (MF-011..013) |
| G1 (intent accepted) and G2 (counterpart scope acceptance) enforced, not just documented | ROADMAP UoW-06 (MF-019) |
| Ratification federated by owner instead of one decider | ROADMAP UoW-06 (MF-018, MF-020, MF-021) |
| Autonomy that adapts to evidence (AI-DLC has fixed human checkpoints; Mandate wants earned ones) | ROADMAP INI-01 |
| The multi-team operating model — **PODs** | §7 and ROADMAP UoW-07 |

## 7. PODs — the unit of parallel work

AI-DLC's mob elaboration and per-stage owners assume a team. Mandate started from one decider and one
executor; its scale-readiness gates (G1–G5) prepared the schema for more. The **POD** is the operating
unit that turns that preparation into practice.

**A POD is a small, durable team of humans and agents that owns a slice of the system end to end** —
typically 1–3 humans plus their role agents — with its own paths, backlog, decider and autonomy level.
PODs are how Mandate scales: you add PODs, not process.

| A POD has | In Mandate |
|---|---|
| **Paths it owns** | its entries in `CODEOWNERS` |
| **A decider for its domains** | `Ratified-by: owner:<pod>` — `Sensitivity` routes each PD to the owning POD |
| **Its backlog** | the Units of Work it owns (`owner:` in the UoW front matter) |
| **Its roster** | shared org agents + POD-specific overrides in `.claude/agents/` |
| **Its mandate** | an autonomy level (A0–A4) earned from **its own** audit trail |
| **Its rituals** | a short synchronous *mob* only at Inception (intent → UoW), asynchronous everywhere else |

**Contracts between PODs** are the gates that already exist:

- **G2 — counterpart acceptance.** A story touching another POD's paths needs that POD's recorded
  acceptance of its *Out of scope* — "out of scope" stops being a silent transfer of work.
- **G5 — Unit of Work exit gate.** The executable exit gate is the signal another POD waits for.
- **`Scope: org` decisions.** A decision that binds other PODs is visible, routed and ratified at org level.

**Rules of thumb:** a POD owns *outcomes*, not layers (a POD per business capability, not a "backend
POD"); two PODs never share a path without an explicit G2 contract; a POD's autonomy never exceeds the
level its own data supports; the org decider keeps only `Scope: org` and the cross-POD tie-breaks.

The POD model is planned in ROADMAP UoW-07 (MF-022..024, MF-038..041).
