# Mandate — Spec-Driven Governance for AI Coding Agents

*Method guide of the **Mandate Framework** (formerly "AI-Assisted Project Governance — Bootstrap Template").*

Created by **Murilo Vieira** (@murilovieir).

> 🇧🇷 Versão em português: [`governance-template.pt-BR.md`](governance-template.pt-BR.md)

> **Purpose.** A self-contained, stack-agnostic template for reproducing a spec-driven, AI-assisted
> engineering organization in a new project: the constitution read by the AI coding agent, two-tier
> knowledge, Architecture Decision Records (ADRs), decision proposals (RFCs), a Decision Log, an
> executable backlog (Initiative → Unit of Work → User Story), agent skills, deterministic guardrails
> with a single verification authority, a rigor ladder, a virtual org of role agents, issue-tracker
> mirroring, a two-hop branching flow, agent evals, and an optional scale-readiness module.
>
> **How to use it.** The fastest path is the executable framework —
> **Mandate** (`mandate-framework`) — a repository that already materializes every artifact below, with
> `{{PLACEHOLDER}}`s and a `scripts/init.sh` bootstrap. Clone it, run the bootstrap, then use this
> document as the *why* behind each file. To build by hand instead: copy this file into the new
> repository, replace every `{PLACEHOLDER}`, delete the sections you won't adopt, and materialize each
> artifact as described. Nothing here assumes a specific language, framework, cloud or business domain.
>
> **Changelog.**
> **v2.0** — Vocabulary converged with AI-DLC: `Tide`→`Initiative`, `Wave`→`Unit of Work`,
> task = *User Story* (§7). New: two-tier knowledge and an instruction budget (§3); machine-readable
> decision status (§4–§5); structured re-check triggers, `Scope` and role-based ratification in the
> Decision Log (§6); bolt-sized stories and Units of Work, executable exit gates (§7); the `Operation`
> phase as a registered slot (§8); the rigor ladder and "execute before asserting" (§9); four new
> skills (§10); the two-hop branching flow (§11); deterministic guardrails with a single verification
> authority (§12); automated PR review with mandatory fallback (§13); agent evals (§14.4); the audit
> trail (§15); the scale-readiness module — five handoff gates, `CODEOWNERS`, ratification federation
> (§16). The missing §13 of v1.x is gone: numbering is continuous.
> **v1.1** — Decision Log (`DECISIONS.md`) and the virtual org. **v1.0** — first version.

### The seven pillars — M.A.N.D.A.T.E.

| | Pillar | Where |
|---|---|---|
| **M** | **Markdown as source of truth** — scope, ACs and decisions live in versioned markdown; trackers are mirrors | §1, §11 |
| **A** | **Architecture by ADR** — RFC → ADR approved by the decider; locked decisions are never reopened | §4, §5 |
| **N** | **Named rules, enforced by script** — `RULE-*` marked 🔒, guardrails as hook + CI | §3, §12 |
| **D** | **Decision Log** — every fork becomes a PD; a sensitive default never closes silently | §6 |
| **A** | **Agents with bounded mandates** — a virtual org whose every role has explicit limits | §14 |
| **T** | **Tested before asserted** — no AC without an execution that proves it; one verification authority | §9, §12 |
| **E** | **Executable backlog** — Initiative → Unit of Work → Story, with executable exit gates | §7, §16 |

The name is the method's golden rule: the executor acts **within its mandate**; whatever exceeds it
becomes an RFC, and only the decider widens a mandate.

---

## 1. Philosophy — the six principles

1. **Markdown in the repo is the source of truth.** Scope, acceptance criteria, architecture
   decisions and business rules live in versioned markdown — diffable, auditable via PR. Issue
   trackers, boards and exported binaries are *mirrors or exports*, never canonical.
2. **Spec-Driven Development (SDD).** The agent never implements from vibes: every story has a
   written spec (context, scope IN/OUT, acceptance criteria) referencing locked decisions. Its job is
   to execute the contract, not relitigate it.
3. **Single-decider governance.** One person (the *decider* — founder, tech lead, owner) approves or
   rejects every architectural proposal. Proposals are RFCs; approval promotes them to ADRs. There is
   no committee round — "RFC" is kept only as the industry-standard name (semantics closer to Oxide's
   RFD or Shape Up's Pitch). §16 shows how to federate this later without migrating anything.
4. **Decisions are never lost in context.** Any fork discovered mid-implementation goes to the
   Decision Log (`DECISIONS.md`) — never only in a task file, a code comment or the chat history.
   Agents recommend; the decider decides (RAPID semantics).
5. **Two orthogonal governance axes.** *Delivery* (what to build, when) and *decision* (what was
   decided, why) are independent. An ADR crosses many Units of Work; a Unit of Work references many
   ADRs. Never merge them into one hierarchy.
6. **A rule without a script is a wish.** Every rule that *can* be checked mechanically gets an
   executable guardrail that runs both as a local hook and as a merge-blocking CI check, from one
   source (§12). Prose is reserved for what genuinely needs judgment. Corollary: *a format with no
   consumer rots* — every structured field you add needs a script that reads it.

```
DELIVERY AXIS                                DECISION AXIS (governance)
"what to build / when"                       "what to decide / why"

  Initiative (INI-NNN) ← top, optional         Proposal (RFC-NNN)
        ↓                                            ↓  decider approves
  Unit of Work   (= Epic)                       ADR-NNN (accepted)
        ↓                                            └─ referenced by stories/UoWs
  User Story T-NNN (= Story)                            (crosses many UoWs)
        ↓
  Acceptance Criteria (= sub-tasks)

TIME AXIS:  Decision (RFC→ADR)  →  Build (Initiative→UoW→Story)  →  Operation (§8, gated slot)
```

---

## 2. Repository layout for governance artifacts

```
{repo-root}/
├── CLAUDE.md                       # Constitution, tier 1 — normative imperatives only (§3)
├── AGENTS.md                       # Contract for secondary tools (reviewer role, §14.2)
├── DECISIONS.md                    # Decision Log — live decisions + generated index (§6)
├── DECISIONS_ARCHIVE.md            # Closed decisions — kept forever
├── .claude/
│   ├── settings.json               # Local hooks that run the guardrails in warn mode (§12)
│   ├── agents/                     # Virtual org — one role per file (§14.1)
│   ├── skills/                     # The processes roles execute (§10)
│   └── evals/                      # Mutation-style evals of agent invariants (§14.4)
├── .github/
│   ├── CODEOWNERS                  # Path → owner map, before there is anyone to assign (§16)
│   ├── pull_request_template.md
│   └── workflows/governance.yml    # CI calls the verification authority — and nothing else (§12)
├── scripts/
│   ├── guardrails/                 # Deterministic rules: hook + CI from one source (§12)
│   │   ├── verify-all.sh           #   THE definition of "green" — runtime-neutral
│   │   ├── git-hooks/commit-msg    #   native git hook (PreToolUse never sees `git commit`)
│   │   ├── allowlists/             #   explicit, commented exceptions
│   │   └── tests/                  #   one test per guardrail, golden + mutated
│   ├── planning/                   # decision-index.py, next-tasks.py, sync-github-issues.sh
│   └── promote-develop.sh          # develop → main, fast-forward only (§11)
├── docs/
│   ├── adr/                        # 1 file per ADR (MADR) + README.md index (§4)
│   ├── rfc/                        # Proposals awaiting the decider + README.md (§5)
│   ├── initiatives/                # Optional business-outcome layer (§7)
│   ├── backlog/                    # README.md, TEMPLATE.md, uow-NN/ folders (§7)
│   ├── office/{role}/              # Institutional memory of the virtual org (§14.1)
│   ├── reference/
│   │   ├── learned-rules.md        # Tier 2 — the *why* behind each rule, LR-NNN (§3)
│   │   └── ai-dlc-rosetta.md       # Vocabulary equivalence (§8)
│   ├── reports/                    # Dated read-only reports + process-metrics.jsonl (§15)
│   ├── design/                     # Optional — design-specialist artifacts (§14.3)
│   ├── guides/                     # How-tos (dev setup, runbooks)
│   └── versions/                   # Current business plan + archive/ of frozen snapshots (§17)
└── {area}/CLAUDE.md                # Optional per-area constitutions (backend/, frontend/, …)
```

Naming — sequential and global unless noted, **never reused**:

| Prefix | Artifact | Lives in |
|---|---|---|
| `ADR-NNN` | Locked architecture decision | `docs/adr/ADR-NNN-slug.md` |
| `RFC-NNN` | Decision proposal (decider-gated) | `docs/rfc/RFC-NNN-slug.md` |
| `T-NNN` | User Story (executable unit) | `docs/backlog/uow-NN/T-NNN-slug.md` |
| `UOW-NN` / `uow-NN` | Unit of Work | `docs/backlog/uow-NN/_index.md` |
| `INI-NNN` | Initiative — business outcome (optional) | `docs/initiatives/INI-NNN-slug.md` |
| `PD-{scope}-NN` | Project Decision (§6) | `DECISIONS.md` / `DECISIONS_ARCHIVE.md` |
| `LR-NNN` | Learned rule — the *why* of a correction (§3) | `docs/reference/learned-rules.md` |
| `DD-NNN` | Design decision (optional) | `docs/design/DESIGN_DECISIONS.md` |
| `BLOCKER-NNN` | External hard stop (not a fork) | `docs/backlog/README.md` conditional table |
| `RULE-{AREA}-NN` | Named, greppable constitution rule | `CLAUDE.md` |

> **Check uniqueness across every branch, not just the current one** (`git ls-tree` over all remote
> branches) before minting any ID. A spec that lives only on an unmerged branch is invisible from
> where you are.

---

## 3. The Constitution — `CLAUDE.md` — and two-tier knowledge

The root `CLAUDE.md` is read automatically at the start of every session. It is the **process
constitution**: on process conflicts it prevails over everything; on architecture conflicts the ADRs
prevail.

### 3.1 Two-tier knowledge

Every correction you make to the agent's behavior tends to arrive with its incident story attached
("on that day the reviewer executed a read-only skill, so…"). Left inline, those stories grow the
constitution without bound and dilute the imperatives. Split them:

| Tier | File | Contains | Loaded |
|---|---|---|---|
| **1** | `CLAUDE.md`, `AGENTS.md`, `{area}/CLAUDE.md` | **What** — normative imperatives only | every session |
| **2** | `docs/reference/learned-rules.md` | **Why** — one `LR-NNN` entry per correction | on demand, by the skills that need it |

Tier-2 entry format: `LR-NNN · observable trigger → rule · origin (T-NNN/RFC-NNN/incident) · date`,
plus an index table `LR-NNN → which rule it backs → which skill loads it`. Tier 1 cites the LR id
(`→ LR-006`) instead of telling the story. Tier 2 is plain markdown with no tool-specific mechanics,
so any agent runtime can read it.

### 3.2 Instruction budget

Measure the normative files (non-blank lines) and keep a **descending ratchet** per file in an
allowlist: `<file> <ceiling> <target>`. The guardrail (`instruction-budget.sh`) fails CI when a file
passes its ceiling; `--record` may only **lower** the ceiling, never raise it — raising requires a
hand edit citing a PD. The *target* is a decider's decision, never a measurement; the distance
ceiling↔target is printed on every run. Without the "only down" rule the mechanism ends up
*recording* growth instead of containing it.

### 3.3 Section skeleton

```markdown
# {Project} — AI Collaboration Guide
> Tier 1 — normative only. The why of each rule lives in docs/reference/learned-rules.md (LR-NNN).

## 0. Multi-agent usage
   Primary executor; reviewer tools (→ AGENTS.md, implement only on explicit request);
   RULE-REVIEW-01 — automated PR review and its mandatory fallback (§13 of the template).
## 1. Project context — one paragraph, links to the plan, ADR index, version, phase.
## 2. Tech stack — NON-NEGOTIABLE
   Table: layer | decision | ADR | forbidden alternatives.
   Golden rule: technology not in the table and with no ADR → flag the gap, propose an RFC.
## 2-B..2-x. Domain rule blocks — RULE-{AREA}-NN, each with Correct:/Forbidden: and, when a
   script enforces it, a 🔒 marker pointing to scripts/guardrails/<rule>.sh.
## 3. Repository structure — one line + link to docs/reference/repo-structure.md.
## 4. Canonical types / core conventions — link to per-area CLAUDE.md; keep only ALWAYS-rules.
## 5. Workflow — RFC vs. direct implementation; SDD map; the two axes; RULE-TASK-01 / RULE-UOW-01;
   the Operation phase slot and its activation trigger.
## 6. Product phases — IN SCOPE / IN SCOPE not priority / BACKLOG (do not implement or suggest).
## 7. Code quality — 🔒 marker legend; language rules; RULE-QA-01 (execute before asserting);
   RULE-QA-02 (review findings become records); survival conditions.
## 8. Business guardrails — whatever is existential (billing, pricing); "never change without approval".
## 9–10. Reference links — local dev, market data → docs/reference/*.
## 11. Issue tracker and branching — RULE-PM-01..05 (§11 of the template).
## 12. What NEVER to do — flat ❌ list; 🔒 where a script enforces it.
## 13. Documentation versioning (§17 of the template).
*Conflict → this file wins on process; docs/adr/ wins on architecture.*
```

**Per-area constitutions** (`backend/CLAUDE.md`, `frontend/CLAUDE.md`) hold conventions that only
matter inside that area; they load automatically when the agent works there and count toward the
instruction budget.

**The 🔒 convention.** When a rule has a script, the constitution says so and the script becomes the
authority: *"🔒 = enforced by `scripts/guardrails/`. The script is the authority; this text is the
index."* This tells every reader which rules are checked and which still depend on attention.

---

## 4. ADRs — Architecture Decision Records (`docs/adr/`)

- **One file per ADR**, MADR-style, `ADR-NNN-slug.md`; `docs/adr/README.md` is the index by domain.
- ADRs are **immutable references**: the agent never reopens a locked decision. Evolution = edit in
  place with a version note, or a new ADR that supersedes the old one.
- New ADRs are **never created directly by the agent** — always via RFC first.

**Machine-readable status (closed vocabulary).** Put the state in YAML front matter with a fixed
vocabulary, so scripts don't need a special case per spelling:

```yaml
---
id: ADR-NNN
status: proposed | refining | accepted | deprecated | superseded | rejected
superseded_by: ADR-MMM        # only when status = superseded
date: YYYY-MM-DD
domain: {e.g. cache / security / billing}
---
```

A consistency guardrail (`decision-status-consistency.sh`) checks that the front matter, the body and
the README index **agree** — it checks coherence between records, never the merit of a decision. Make
it **fail-closed**: a crash or an empty scan is an error, never "OK". Failure modes it catches:
body and index correct but the field stale; a value outside the vocabulary; "pending" written five
ways in two languages; an ADR listed twice in the index with different statuses.

```markdown
# ADR-NNN — {Short decision title}
## Context      {why a decision is needed — constraints, SLAs, licensing, prior art}
## Decision     {stated affirmatively; tables for key contracts welcome}
## Consequences {what becomes forbidden/mandatory, follow-ups, debts, cross-refs to ADRs/PDs}
```

---

## 5. RFCs — decision proposals (`docs/rfc/`)

An RFC is a **proposal the decider approves or rejects**, not an open comment round. The agent writes
one whenever work hits territory no ADR covers, and **implements nothing until an explicit GO**.

1. The agent identifies a decision outside direct-implementation scope (§3.3 block 5: new dependency,
   new ADR needed, SLA/billing/security behavior change, public API change, business model).
2. It writes `docs/rfc/RFC-NNN-slug.md` and stops.
3. The decider marks the decision **both** in the front matter and in the `## Status` block.
4. Approved → promoted to (or folded into) an ADR and decomposed into stories; the RFC stays as record.

```markdown
---
id: RFC-NNN
title: {short title}
status: awaiting | approved | rejected | superseded | partially-approved
---
# RFC-NNN — {Short title}
**Date** · **Area** · **Impact** low/medium/high · **Related ADR** (or "new ADR needed")
## Problem identified
## Proposed solution
## Alternatives considered
## Trade-offs
## Effort estimate
## Proposed decomposition   {stories per phase, each with its own branch/PR/CI}
## Status
- [ ] Awaiting approval
- [ ] Approved — implement (decider, YYYY-MM-DD)
- [ ] Rejected — reason: ___
```

> **Reading trap.** The `## Status` block lists the *unchecked* option first. A `grep -A2` reads
> "Awaiting approval" and misses the checked line below — read to the next heading, or better, read
> the front matter. This mistake turns decided items into false "pending" findings.

**Errata over silence.** When review finds a defect in an RFC after it's written, fix the body and
add an `## Errata` table (finding · verdict · correction) instead of rewriting history quietly.

---

## 6. Decision Log — `DECISIONS.md`

The registry of **emergent decisions** — the forks that appear when code meets reality, *within*
approved scope. New features/tech go to RFC; locked decisions live in ADRs. Market equivalent: the
Decision Log / Decision Register (PMBOK/PRINCE2); recommend↔ratify follows RAPID.

> **Naming lesson.** Don't call it `PENDING_DECISIONS.md`: after a while almost every entry is closed,
> and the closed audit trail is the artifact's real value. Name it `DECISIONS.md` from day one; read
> `PD-` as **"Project Decision"**.

| Artifact | When |
|---|---|
| `DECISIONS.md` | Fork during implementation — choice between viable alternatives within scope |
| `docs/rfc/` | New feature, new tech, architectural change needing decider approval |
| `docs/adr/` | Locked decision — never reopen |
| Story "Execution notes" | Review findings (§9 RULE-QA-02) — not decisions |

**Register when it:** affects more than one module/story; chooses between ≥2 viable alternatives;
impacts data model, API contract, security or infrastructure; is a "proposed default"/"open" item in
a spec; or would surprise another developer if found buried.

**Statuses:** `OPEN` · `NEEDS_VALIDATION` · `DEFAULT_APPLIED` · `DEFERRED` ·
`RESOLVED (who, YYYY-MM-DD)` · `BLOCKER_RESOLVED`.

**Scoped semantic IDs** (once past ~20–30 entries): `PD-T{story}-NN` (fork inside a story — the
dominant case), `PD-RFC{rfc}-NN` (fork while decomposing an RFC), `PD-{TOPIC}-NN` (cross-cutting
concern), `PD-T{story}-RESCOPE`, `PD-{TOPIC}-TRIAGE`. Greppable back to origin. Check uniqueness in
**both files and on every branch**.

### 6.1 Entry format (v3)

```markdown
## PD-{scope}-{NN} — {short title}

- **Status:** `OPEN` | `NEEDS_VALIDATION` | `DEFAULT_APPLIED` | `DEFERRED` | `RESOLVED (who, YYYY-MM-DD)`
- **Impact:** `architectural` | `operational` | `business`
- **Proposed-by:** {role that recommended: architect | product-owner | main-session | decider | …}
- **Reversibility:** `two-way` | `one-way`
- **Sensitivity:** `internal` | {your sensitive domains, e.g. `tenant-isolation` | `security` |
  `billing` | `privacy` | `public-api` | `schema`}
- **Scope:** `local` | `org`                         ← v3 (§16 F4)
- **Ratified-by:** — | decider (YYYY-MM-DD, digest | direct | auto, lapse) | owner:{area} (YYYY-MM-DD)
- **Story(s):** T-NNN · **ADR(s):** ADR-NNN
- **Context:** {1–2 sentences}
- **Alternatives:**
  - A: {option} — {trade-off}
  - B: {option} — {trade-off}
- **Proposed default:** {which and why}
- **Reopen-trigger:** {verifiable condition — see 6.3} _(when DEFERRED)_
- **Resolved:** {date} — {final decision + justification}
```

`Proposed-by`/`Ratified-by` separate who recommended from who ratified; `Reversibility` is Bezos's
one-way/two-way door; `Scope` says whether the decision binds other teams; `Ratified-by` accepting a
**role** (`owner:billing`) is what makes federation configuration rather than migration. Adopting a
new template version on an existing registry: set a **cut-off date** and never reprocess old entries.

### 6.2 Agent behavior (enforced by the `decision-log` skill)

1. **Before a story** — scan the spec for embedded decisions ("decide", "proposed default", "TBD",
   "open decisions"); register each, cross-reference back.
2. **Before acting on an existing PD — re-check its premises against the code**, not its prose.
   Claims something doesn't exist? grep. Claims a dependency isn't ready? read its status. A stale
   premise gets corrected in the PD, in the same commit, with evidence. (Don't try to detect stale
   premises with text heuristics over PD prose — they produce mostly false positives; the premises
   that matter are only disprovable by reading the code.)
3. **During implementation** — on any fork: STOP, register with `Proposed-by`, `Reversibility`,
   `Sensitivity` and `Scope`.
   - **Sensitive-default escalation (non-negotiable):** a default in a sensitive domain can **never**
     close as `DEFAULT_APPLIED`. Mark `NEEDS_VALIDATION`, surface it to the decider before proceeding.
   - Operational (`internal`, two-way, no cross-module impact): apply the default, mark
     `DEFAULT_APPLIED`, note it in the story; it enters the ratification queue and blocks nothing.
4. **On resolution** — `RESOLVED (who, date)`, fill `Resolved:`, link the ADR, move the block to the
   archive, regenerate the index.

### 6.3 Verifiable premises go in structured fields, never in prose

`Reopen-trigger:` works because a script reads it. Premise buried in `Context:` prose is reached by
nothing — not by script, not by casual reading. When writing a trigger:

- **Prefer a data condition to a story status.** "T-NNN done" fires empty when the story merged but
  the data never materialized; write what must be true ("≥30 observations per route, ≥14-day window").
- Cite `T-NNN` **when the trigger really is a story status** — that makes it mechanical.
- Premise about code? Name the file/symbol.
- **Make sure something resolves the field** (§16 F5): a trigger the index script never evaluates —
  or that the CI path skips — is prose in a structured costume.

### 6.4 Ratification cadence

`DEFAULT_APPLIED` closes the implementation loop, not the governance loop. Weekly, the decider gets
a **digest** of new defaults — one table, ratified in batch (~5 min), recorded in `Ratified-by`.
**Lapse rule** (optional): low-risk defaults (`internal`) with no objection for 14 days are ratified
by lapse — recorded as `Ratified-by: decider (auto, lapse, YYYY-MM-DD)`. **Sensitive defaults are
never eligible.** Rationale: low risk never competes for attention against sensitive items, so
without a lapse rule the low-risk queue is flagged forever.

### 6.5 Generated index, hard gate

Keep the index between `<!-- DECISION-INDEX:BEGIN -->`/`END` markers, **regenerated by script**
(`scripts/planning/decision-index.py [--check]`), never by hand (a hand-kept index drifts: the
header count, the index rows and the actual bodies end up disagreeing). The script reports duplicates across files, closed PDs in the
live file, missing status, unratified sensitive defaults and fired `Reopen-trigger`s — and enforces a
**hard gate**: a sensitive PD closed as `DEFAULT_APPLIED` without ratification **fails the script**
in both modes. `--check` runs in CI (§12).

**Anti-patterns:** decision only in a story/comment/chat; sensitive default closed silently; a
decider's decision recorded as `DEFAULT_APPLIED`; hand-edited index; ID minted without checking both
files and all branches; acting on an old PD trusting its prose; a re-checkable premise in prose;
confusing a PD with an RFC, an ADR-internal open question, or a `BLOCKER-NNN` (an external hard stop
with nothing to choose between).

---

## 7. Backlog — Initiatives, Units of Work, User Stories

### 7.1 Hierarchy

`Initiative → Unit of Work (= Epic) → User Story T-NNN (= Story) → Acceptance Criteria`

- **Unit of Work** (`docs/backlog/uow-NN/_index.md`) — a delivery increment with an **exit gate**
  and sequential ordering. Numeric IDs for every new UoW (named folders don't sort and break label
  cut-offs). It carries what "Epic" doesn't: a gate and an order.
- **User Story `T-NNN`** — the unit the agent executes. One markdown file, Implementation Contract
  format. The ID keeps the `T-` prefix for history even though the noun is "story".
- **Initiative `INI-NNN`** — *optional* business-outcome layer tying several UoWs to a result in the
  business plan. Absence never blocks execution; cross-cutting UoWs (infra, governance) usually have
  none. On the board: a theme label `initiative:INI-NNN`.

> **Migration note.** Older versions of this template called these `Tide` and `Wave`. The rename
> converged on AI-DLC's literal term for the middle level and dropped a metaphor the rest of the
> vocabulary no longer shared. Choose names by **measured collision** (`grep` across the repo) — a
> name that already means something in your domain produces dirty searches and confused agents.

### 7.2 Bolt sizing — RULE-TASK-01 and RULE-UOW-01

**RULE-TASK-01 (new story):** fits one execution session without context handoff; **≤ 5 ACs**;
**≤ 8 expected files** (one bullet per file — the guardrail counts bullets); produces a useful
increment alone; stays in **one rigor level** (§9) — a spec crossing levels is split. Estimate `L`
requires an "Indivisibility rationale" section; `XL` doesn't exist.
**RULE-UOW-01 (new UoW):** target 3–5 stories, **ceiling 8**.
Both are checked by `task-spec-shape.sh` (hook on spec creation + CI on the diff) and **do not
retroact** — the CI mode only evaluates specs and UoW folders that are new in the diff.

### 7.3 Statuses and the exit gate

Story statuses: `todo` · `in-progress` · `blocked` · `in-review` · `done` · `deferred`.
`in-review` requires something reviewable to exist (branch pushed, PR open). **Merged PR + all ACs
checked → `done` in the same commit**, without asking case by case — except when the spec itself
declares ACs blocked by an external dependency (`[⛔]`): those stay `in-review` and the decider
decides.

**Executable exit gate (§16 G5).** A gate in prose is a wish. Put it in the UoW front matter as a
condition a script can evaluate, and have `uow-gate.sh` refuse to declare the UoW closed otherwise —
including refusing any condition it can't evaluate:

```yaml
---
id: UOW-NN
title: {name}
initiative: INI-NNN            # optional
exit_gate:
  stories_done: [T-101, T-102, T-103]
  commands:                    # each must exit 0
    - ./scripts/guardrails/verify-all.sh --fast
---
```

### 7.4 Story spec template (`docs/backlog/TEMPLATE.md`)

```markdown
---
id: T-NNN
title: <short, actionable>
uow: <NN>
status: todo
type: story            # story | task | spike | chore
adrs: [ADR-NNN]
depends_on: []
blocks: []
estimate: S            # S <1d · M 1–3d · L 3–7d (needs indivisibility rationale)
skill: backlog-executor
---
# <title>
## Context            <1–3 paragraphs linking the story to ADRs and the UoW goal>
## Implementation Contract
### Scope (IN)
### Out of scope (OUT)
### Indivisibility rationale (only if estimate: L)
### Expected files (≤ 8 — one bullet per file)
- `path/to/file` — <description>
### Locked technical decisions
### Decisions left open   <each with a proposed default>
## Acceptance Criteria (≤ 5 AC-N lines)
- [ ] AC-1: <given / when / then — objectively verifiable>
## Definition of Done
## Execution notes        <what ran, deviations, PDs, review findings (RULE-QA-02)>
```

**Rework signal.** If a story's Context names a prior `done` story as the bug it corrects, the
executor emits a `rework_observed` event (§15) — that's how the rework rate gets measured.

### 7.5 Initiative template

```markdown
---
id: INI-NNN
status: active | done | paused
uows: [NN, NN]
plan: "<anchor in the business plan>"
---
# INI-NNN — {Business outcome}
## Business outcome · ## Why now · ## How we measure it · ## Units of Work that deliver it · ## Out of scope
```

---

## 8. Vocabulary — SDD map, AI-DLC equivalence and the `Operation` slot

| SDD phase | Artifact |
|---|---|
| Constitution | `CLAUDE.md` |
| Specify | story spec `docs/backlog/uow-NN/T-NNN-*.md` |
| Plan | agent plan mode + ADRs |
| Tasks | UoW decomposition (mirrored to the board) |
| Implement | `backlog-executor` skill |
| Analyze | `/analyze` skill — consistency gate |

Keep a short `docs/reference/ai-dlc-rosetta.md` (reference, not normative — outside the budget)
mapping your terms to AWS's AI-DLC: Intent ↔ Initiative; Unit of Work ↔ Unit of Work; User Story ↔
`T-NNN`; Bolt ↔ the session-sized story (adopted as sizing, not as a level); depth levels ↔ rigor
ladder N0–N3 (yours is derived from paths, theirs is chosen by hand); method memory ↔ `docs/office/` +
Decision Log; audit trail ↔ `process-metrics.jsonl`; domain experts and quality reviewers ↔ the
virtual org. Record **non-adoptions as decisions** (e.g. AI-DLC's 33 stages, logical-architecture
artifacts, mob elaboration) so they aren't re-proposed as gaps.

**The `Operation` phase — a registered slot, not a built phase.** Until real users depend on the
system there is no on-call agent, runbook or incident loop — correctly. Register the slot anyway, so
its absence is a visible gate instead of a silent cliff: a constitution section naming the
**observable activation trigger** (e.g. "first paying tenant in staging") and pointing to a dormant
RFC that already lists the operation roster and checklist. Write the trigger as a **data query**
something can run (§16 F5), not as prose.

---

## 9. Execution discipline — rigor ladder and "execute before asserting"

### 9.1 Rigor ladder (N0–N3)

Classify each story **mechanically by the paths its diff touches**, never by judgment, and apply the
gates as written defaults — the decider shouldn't re-specify branch/PR/CI/review per story.

| Level | Mechanical trigger | Gates |
|---|---|---|
| **N0** | docs, renumbering, comments, backlog chores; no product code | Execution loop + `Refs:` footer |
| **N1** | product code outside sensitive paths | N0 + self-review checklist + branch `task/T-NNN` + PR + green CI; specialist only on doubt; ~1 in 5 gets a QA calibration audit |
| **N2** | diff touches a **sensitive path** (migrations, isolation policies, auth, billing, privacy, public API specs) | N1 + three single-pass opinions **before merge**: `architect`, `qa-engineer` (100%, never sampled, with survival-condition evidence), `release-manager`. Emerging PDs are `NEEDS_VALIDATION`, never defaults |
| **N3** | N2 opinions diverge, or a one-way door, or changes billing/security/SLA behavior | N2 + tie-break opinion + explicit decider ratification |

Fixed rules: survival conditions never go below N2; **auto-merge does not exist** — merging is the
decider's gate at every level unless delegated explicitly, case by case.

**N1 self-review checklist** (before opening the PR): every `[x]` AC was executed (say how); tests
genuinely ran (paste the count); language guardrails clean; `Refs:` footer, `task/T-NNN` branch,
`[T-NNN]` PR title; new decisions registered; **new code with a structurally similar sibling in the
same module mirrors the sibling's defensive patterns** (abort guards, bubbling guards, shape
validation, a11y) — this is the most frequent class of review finding on new code; and
**a new helper that re-implements a parse/format another file already does** reuses or extracts it
instead (two copies drift silently).

### 9.2 RULE-QA-01 — execute before asserting

**No AC is checked without an execution that proves it. "It compiles" is not execution.** The gate
is the **full suite of every module the diff touches** — derived from `git diff`, never from a
manual list — not only the tests the executor wrote (the neighbours a new contract invalidates are
exactly the ones you didn't write). When the environment prevents the full suite, run the affected
classes in isolation and record **which and why**: a declared partial result is acceptable; an AC
checked by inference is not.

Operationalized by the `review-gate` skill (§10): run `verify-all.sh`, dispatch `qa-engineer` cold
on diff × spec ("do the tests *prove* the ACs, or just pass?"), then cross every `[x]` AC with the
test that proves it — an AC with no proving test is a finding. **The rule holds without the skill.**

### 9.3 RULE-QA-02 — review findings become records

Findings from the review gate, from a native `/code-review` or from PR bots go to the **story's
execution notes, in the same commit as the fix**. No new file: the trail lives where the story lives.

---

## 10. Agent skills (`.claude/skills/`)

Each skill is a `SKILL.md` with YAML front matter (`name`, `description` with trigger phrases) and a
procedure. **Read-only skills say so on their first line**, in a way that holds even when the file is
pasted into a tool without skill isolation (otherwise a reviewer tool can read a "list ready tasks"
skill as an implementation order).

| Skill | Trigger | What it does | Mutates? |
|---|---|---|---|
| `backlog-executor` | "execute T-NNN" | The loop: read story → read every referenced ADR **first** → `in-progress` commit → implement within scope → validate ACs (RULE-QA-01) → update spec → commit with `Refs:` → sync issue → emit audit-trail events → check the ratification queue. Applies the rigor ladder. | yes |
| `decision-log` | automatic, before/after every story | §6 — scan, re-check premises, stop-on-fork, sensitive escalation, close the loop, regenerate index, post-story checklist | yes (PDs) |
| `review-gate` | "/review-gate", before marking ACs, before a PR | §9.2 — runs `verify-all.sh`, dispatches `qa-engineer`, crosses ACs × execution; recommends `/code-review` (it can't trigger it) | no |
| `analyze` | "/analyze", before closing a UoW | Consistency gate D1–D6 (§15); dated report; **read the block, never the field** | no (report) |
| `next-tasks` | "/next", "what can I do now" | Ready stories (all `depends_on` done), leverage (`+READY`), recommended model, parallelizable batches by file collision | no |
| `decision-brief` | "/decision-brief PD-X", "how do I resolve…" | One PD: re-check premises against code → options (kill the dead ones, add the missing ones, real costs, cost of not deciding) → **one** recommendation + what would change it. No arg: triage the queue | no |
| `review-task` | "/review-task T-NNN" | Delivery report: files, tests, configuration, deviations, open items, ADR compliance table | no |
| `branch-cleanup` | "/branch-cleanup" | Scan remote branches: MERGED (delete, guarded), DISJOINT/REVIEW (architect opinion, decider deletes); **branches ahead of main that never had a PR** are surfaced as unreviewed work, fail-closed if PR state can't be read | MERGED only |
| `agents-census` | "/agents-census" | Roster × last opinion in `docs/office/` × local token usage | no |

---

## 11. Issue tracker and branching

**Model:** the tracker + board is the operational/Kanban layer; repo markdown is the source of truth
for scope. Mirroring is an **idempotent script** (`sync-github-issues.sh`): markdown → issues, labels
(`status:*`, `type:*`, `uow:*`, `initiative:*`), milestone per UoW, one board. Run it from CI on
backlog changes, not from memory — a board that depends on someone remembering **lies by omission**.

- **RULE-PM-01 — Source of truth per information type.** Scope/ACs/decisions/ADRs → repo. Status/
  priority/owner/deadline → tracker. Emergent decisions → `DECISIONS.md`. Proposals → `docs/rfc/`.
- **RULE-PM-02 — Commits and PRs reference the work.** Footer `Refs: T-NNN[, ADR-NNN]` — or
  `RFC-NNN` when the change is born from an RFC that has no story yet (an RFC is written *before*
  decomposition, so requiring `T-NNN` there rejects it by construction). Footer with only `ADR-NNN`
  fails: an ADR is the decision, not the work. PR title `[T-NNN] Imperative description`; branch
  `task/T-NNN-slug`. 🔒 `commit-refs-footer.sh` as a native `commit-msg` hook and in CI.
- **RULE-PM-03 — Sync is one-directional (repo → tracker).** Scope/ACs are never edited in an issue.
- **RULE-PM-04 — The board is live, the front matter is formal.** Status divergence is tolerable;
  scope/AC divergence is not.
- **RULE-PM-05 — Merged PR closes the story** (`in-review` → `done`, issue closed, same commit),
  except for spec-declared blocked ACs.

**Two-hop flow.**

```
task/T-NNN-slug  ──PR (squash, review, fast CI)──▶  develop  ──fast-forward only──▶  main  ──▶ deploy
```

A PR into `develop` is mandatory — never a direct push (the PR is the only place automated review
happens, §13). Promotion `develop → main` happens **only** through `promote-develop.sh`, which
refuses anything that isn't a fast-forward. Why FF and not squash: squashing `develop` into `main`
creates a commit that isn't an ancestor of `develop`, the merge base never advances, every promotion
drags everything again and `git bisect run verify-all.sh` over promoted history breaks. With FF, both
branches are identical after every promotion. `main` must never receive a direct commit — if it does,
the script refuses and says how to recover; it never "fixes" it with a merge or a reset. The heavy
verification runs on the exact combination being promoted. A detector for **branches ahead of `main`
without a PR** catches work that skipped the flow entirely — commits with no review layer at all, which
otherwise surface only when someone happens to mention the branch.

---

## 12. Deterministic guardrails and a single verification authority

### 12.1 One source, two consumers

Each guardrail is one shell script with two modes:

| Mode | Invoked by | Reads | Exit | Purpose |
|---|---|---|---|---|
| `--hook` | `.claude/settings.json` `PreToolUse` (Edit/Write) | only the content about to be written | **always 0** (warn) | early feedback; never blocks an edit |
| CI (default / `--ci-range base...head`) | `verify-all.sh` | tracked files, or only what's new in the diff | **1 on violation** | the authority — blocks the merge |

Exceptions go to `scripts/guardrails/allowlists/<rule>.txt`, one exact line per entry with a reason.
Commit-time rules use a **native git `commit-msg` hook** instead (`git config core.hooksPath
scripts/guardrails/git-hooks`), because the agent's tool hook never sees `git commit`. Aggregate
properties (instruction budget, cross-record consistency) are **CI-only**: a single write can't see
the other side of the pair.

### 12.2 Starter set (stack-agnostic)

| Guardrail | Rule |
|---|---|
| `commit-refs-footer.sh` | RULE-PM-02 (`Refs: T-NNN` or `RFC-NNN`; merge commits skipped) |
| `instruction-budget.sh` | §3.2 descending ratchet |
| `task-spec-shape.sh` | RULE-TASK-01 / RULE-UOW-01, new-in-diff only |
| `decision-status-consistency.sh` | §4 status coherence, fail-closed |
| `uow-gate.sh` | §7.3 executable exit gate (§16 G5) |
| `decision-index.py --check` | §6.5 index + sensitive hard gate |

Domain guardrails are where most of the value is — write them for your own survival conditions:
"money is never a float", "no vendor SDK in domain code", "cache namespace X only through service Y",
"no field injection". Each is ~30 lines: a grep over tracked files of the right extension, an
allowlist, a `--hook` path. **Every guardrail has a test that proves both a passing and a failing
case** — a test that only exercises the happy path (or a synthetic fixture the script never actually
reads) stays green with the bug reintroduced.

### 12.3 `verify-all.sh` — the definition of "green"

The list of what must pass lives **in one script**, runtime-neutral (human, Claude Code, Codex,
Copilot), not inside the CI YAML. The workflow only calls it:

```bash
./scripts/guardrails/verify-all.sh            # full, range main...HEAD
./scripts/guardrails/verify-all.sh --fast     # only what needs no build toolchain
./scripts/guardrails/verify-all.sh --list     # what would run, without running
./scripts/guardrails/verify-all.sh --only guardrails,planning
```

Three properties make it an authority rather than a convenience:

1. **Derives modules from the diff** — never a hand-maintained path→command table (a hand list is
   how whole modules end up outside CI and broken tests go unnoticed).
2. **A check that can't run is declared, and fails**: `not verified: <id> — <reason>`, exit ≠ 0.
   "Couldn't check" never looks like "clean". `--allow-missing-tools` degrades consciously.
3. **Anti-drift**: it fails when the workflow gains a merge-blocking job with no counterpart in the
   script, or vice versa — so the two can't silently diverge. (If the CI provider goes dark, a
   repository whose rules live only in CI YAML has zero enforcement. A script that runs anywhere is
   the hedge.)

Running it locally is feedback, not the gate — a self-attested local receipt is rejected; the gate is
the CI execution.

---

## 13. Automated PR review and its mandatory fallback — RULE-REVIEW-01

Every PR triggers review bots configured on the repository (Codex, Copilot, …). Their findings are
treated as real review: investigate; fix if small and unambiguous; ask the decider if ambiguous or
architectural; mark non-actionable if a false positive. Findings go to the story's execution notes
(RULE-QA-02).

**Proof the review ran:** a bot comment (finding) **or** a 👍 reaction on the PR (no findings).
Three failure modes all count as "did not happen":

| Mode | Looks like |
|---|---|
| Bot error | "…encountered an error and was unable to review" |
| Quota exhausted | "You have reached your … usage limits for code reviews" |
| Silence | neither comment nor 👍 within the normal follow-up window |

The first two are worse than silence because they *look* like activity. Warning is not enough —
warning and moving on lets the PR merge with **zero review layers**. On any failure, the executor
must, in the same message, **suggest a local review layer**: the native `/code-review` (user-triggered
and billed — the agent suggests, never triggers) and/or dispatching `qa-engineer` (the agent may run
it directly). Calibrate by size and sensitivity: a small docs-only PR doesn't need it; a large product
diff or anything N2 shouldn't merge without one. If the decider merges anyway, it's recorded, not
by omission.

---

## 14. Multi-agent roles — the virtual org

| Role | Mechanism | Governed by | Implements? | Produces |
|---|---|---|---|---|
| **Executor** | primary agent session | `CLAUDE.md` | yes | code, specs, RFC drafts, PDs |
| **Role agents** | `.claude/agents/*.md` | own file + `CLAUDE.md` | no | opinions in `docs/office/`, specs, digests |
| **Reviewer** | second coding tool | `AGENTS.md` | only on explicit request | findings, focused test runs, audits |
| **Design specialist** | separate design tool | brief + `DESIGN_DECISIONS.md` | no | `DD-NNN` + approved assets |
| **Housekeeping** | scheduled run, no operator | the skill it runs | never | dated reports (§15) |

### 14.1 Role agents — `.claude/agents/` + `docs/office/`

| Mechanism | Role in the org | Where |
|---|---|---|
| Subagents | the *roles* — each file is a hiring letter | `.claude/agents/{role}.md` |
| Skills | the *processes* roles execute | `.claude/skills/` |
| Routines / cron | the *recurrence* | the agent environment's scheduler |
| `docs/office/` | the *institutional memory* | `docs/office/{role}/YYYY-MM-DD-subject.md` |

**Consolidate functions, don't replicate an aspirational org chart.** Create a role only against
concrete pain. Proven core (shipped in Mandate): `architect`, `product-owner`, `qa-engineer`,
`release-manager`, `tpm`, `chief-of-staff`. Optional, add when the pain appears: `devops` (stack-
specific), `cfo` (pricing/unit economics), `pmm` (positioning/copy), `cofounder` (strategic sparring
with **mandatory dissent**: steelman → case against → premortem → own position), `coo` (single entry
point that dispatches and records — only worth it once several roles exist).

| Agent | Does | Never |
|---|---|---|
| `architect` | reviews diffs/RFCs vs ADRs and named rules; verdict approve / with caveats / reject / needs RFC | implement; create ADRs |
| `product-owner` | idea → story spec within RULE-TASK-01; checks ID collisions on every branch | approve scope; touch billing |
| `qa-engineer` | deliverable × ACs; do the tests *prove*? runs the suite; mandatory tests | fix code or write tests (independence) |
| `release-manager` | exit checklist with evidence; GO / NO-GO | waive survival conditions; merge |
| `tpm` | dependency map, sequencing, program risk, board sync, ratification bookkeeping | edit scope in an issue; decide priority |
| `chief-of-staff` | one-page weekly briefing: top 3, decisions waiting, ratification digest, yellow flags, execution pulse | decide |

**Agent file format:** front matter (`name`, `description` with triggers, `tools` limited to the
mandate, `model` sized to the role) + mandate, what to read first, minimal guardrail checklist,
output format and an explicit **limits of mandate** section ending with *"the decider is the sole
decision-maker; decisions go through RFC."*

**Dispatch in the foreground.** A coordinator agent that dispatches sub-agents in the background and
ends its turn "waiting for notifications" delivers an empty turn — ending the turn *is* returning
control; there's no passive wait. If its toolset can't collect background results, foreground
dispatch is a capability fact, not a style choice. Partial honest delivery beats an empty turn.

**`docs/office/`** — immutable after the date, never deleted; not a source of decision (a memo
contradicting an ADR is wrong by definition); not product docs. When you hire a human for a role,
the agent file + its office history *is* the onboarding.

### 14.2 Reviewer — `AGENTS.md`

Summarizes the contract for a secondary tool: read order (`CLAUDE.md` → area constitutions → ADRs →
`learned-rules.md`), reviewer role (implement only on explicit request), the **never slide from
listing to executing** rule for read-only skills, the two-hop flow (base of a PR is `develop`), the
single verification command, and a high-severity checklist mirroring §12 of the constitution for the
rules that have no script. It never overrides `CLAUDE.md`. Record role reversals as learned rules, so
an experiment that was tried and reverted isn't re-proposed from memory.

### 14.3 Design specialist — `docs/design/`

One-directional handoff for design tools outside the repo loop: **brief** (executor writes
`docs/design/briefs/{surface}-brief.md` — data contract, components, design-system constraints, open
decisions) → **session** (human runs it in the design tool, one component per conversation) →
**sync** (approved output only into `docs/design/assets/`, decision recorded as `DD-NNN`).
Implementation stories consume only files already in `assets/`.

### 14.4 Agent evals — testing the normative surface

Skills, agents and the constitution are versioned and, by default, **untested**: editing
`CLAUDE.md` is a deploy without regression. Start with mutation-style evals of the 2–3 invariants
with the highest historical cost (e.g. "the executor stops at a locked decision", "a sensitive
default never closes silently", "a read-only skill never executes"):

- `.claude/evals/invariants/inv-NN-*.yaml`: invariant, `spec_under_test` files, a **golden**
  trajectory that must pass and a **mutated** one (same scenario, violated on purpose) that must
  fail — this proves the *checker* catches the violation, not just that the happy path passes.
- `spec_pinned_sha`: the **blob** SHA (`git rev-parse HEAD:<path>`, content — not the commit, which
  breaks under shallow clones and squash merges) of each spec the trajectories were written against;
  `--check-staleness` fails when the normative text changed and the fixture wasn't re-checked.
- Runs in CI as **non-blocking** first; promote to merge-blocking after an uninterrupted window
  without infrastructure failures — any failure restarts the clock.

Be explicit about the limit: fixtures are recorded by hand; this is a regression test of the checker,
not a live monitor of agent behavior.

---

## 15. Housekeeping routines and the audit trail — `docs/reports/`

Read-only passes whose only output is a dated report: `{type}-YYYY-MM-DD.md`, append-only history,
each stating up front that it changed nothing. Starter routines:

1. **Consistency gate (`/analyze`)** — D1 decision implemented but not promoted · D2 stack drift ·
   D3 gate/description drift · D4 status drift (tolerable) · D5 orphan refs / ID collisions · D6
   unregistered decision. Each finding: `id · severity · category · evidence (file:line) ·
   recommendation · owner`. **Method rule — read the block, never the field:** before claiming
   something is pending, open the file (the unchecked status option comes first; a class name isn't
   a scope; an empty grep for a symbol doesn't prove a behavior is absent; the caveat may live in the
   body and the index but not the field). A false "pending" is worse than silence: it invites
   re-deciding what was decided.
2. **Decision-log health** — 🔴 sensitive without resolution / unratified · 🟡 ordinary open ·
   🟢 ready to close (origin story `done`, PD still open).
3. **Audit trail — `process-metrics.jsonl`.** The executor appends one line per story closure —
   the exception to "one dated file per run": append-only and **not reproducible**, so never pruned:

```json
{"ts":"<UTC>","event":"story_closed","story":"T-NNN","rigor":"N0|N1|N2|N3","model":"<id>","token_cost":null,"acs_failed_at_gate":0,"findings_by_agent":{}}
{"ts":"<UTC>","event":"rework_observed","story":"T-NNN","origin_story":"T-MMM","cause":"<short>","pr":null}
```

`token_cost: null` when unmeasurable — never skip the event for a missing number. The **correlation
key for rework is `origin_story`**, matched against the closure of the story that shipped the
defect; the rate is derived later, never declared at closure. An aggregator script feeds the
`chief-of-staff`'s weekly "execution pulse" — this is what calibrates the rigor ladder with data.

---

## 16. Scale-readiness module (optional) — five gates, not thirty-three

Adopt when a second team, a second decider or a second repository is on the horizon. Most of it pays
off even with one executor, because the defects it fixes exist today. The design question is *what
breaks when the decider stops being unique?*

| Gate | Moment | Mechanism |
|---|---|---|
| **G1 — Intent accepted** | Initiative → UoW | every new **product** UoW is born with a parent Initiative (no retroaction; cross-cutting UoWs exempt) |
| **G2 — Scope accepted by the counterpart** | spec ready, before execution | when the story touches a path owned by someone else in `CODEOWNERS`, its `Out of scope` requires recorded acceptance from that owner — **conditional on a second owner existing** (acceptance without a counterpart is an empty form) |
| **G3 — Rigor classified** | start of execution | §9.1 — mechanical by path |
| **G4 — Ready to merge** | end of execution | §9.1 N1 checklist / N2 three opinions |
| **G5 — UoW closed** | exit gate | §7.3 `exit_gate` + `uow-gate.sh`; convert every **open** UoW, not "none" — a gate that only applies to future UoWs leaves today's prose gates untouched |

Supporting phases:

- **F1 — Wire the mechanical gates that sit outside CI** (`decision-index.py --check`, agent-contract
  validators). Lines of YAML — but they depend on a CI that actually runs; unblocking CI execution is
  a prerequisite, not part of the phase.
- **F2 — `CODEOWNERS` now, with a single owner.** The value is the map existing, being diffable and
  correct *before* there is anyone to assign. Prerequisite of G2 and of routing.
- **F4 — `Scope: local | org` and role-based `Ratified-by`** (§6.1). `Sensitivity` becomes the
  routing key the day there is more than one ratifier. This prepares federation as configuration;
  it doesn't federate.
- **F5 — A machine-resolvable `Operation` trigger.** Moving the trigger from prose to a `Reopen-
  trigger` field isn't enough if the index script only resolves `T-NNN done` and its `--check` path
  returns before evaluating triggers. Deliver: (a) the condition as a **data query**, (b) a check that
  runs it, (c) wiring where it actually runs.
- **F8 — Coordination, parallelism, onboarding.** Automatic issue sync; file-collision detection
  derived from the **real diff** rather than declared "expected files"; a bootstrap job that runs the
  dev-setup guide from zero. And preserve the **method boundary**: nothing new in
  `scripts/guardrails/` gets a hardcoded product path without an env-var override — that is what
  keeps the governance layer extractable (the Mandate repository is the proof).

**PODs — the unit that scales.** The operating unit for many teams is the **POD**: a small, durable
team of humans and agents (typically 1–3 people plus their role agents) that owns a slice of the
system end to end — its `CODEOWNERS` paths, its Units of Work, a decider for its domains
(`Ratified-by: owner:<pod>`, routed by `Sensitivity`) and an autonomy level earned from its own audit
trail. PODs coordinate only through contracts that already exist: G2 (counterpart scope acceptance),
G5 (executable exit gates) and `Scope: org` decisions. A POD owns outcomes, not layers; the org decider
keeps only `Scope: org` and cross-POD tie-breaks. You scale by adding PODs, not process. The full
comparison with AWS AI-DLC — verdict, adoptions, rejections, gaps — and the POD model live in the
Mandate repository at `docs/reference/mandate-vs-ai-dlc.md`.

**Rejected, on purpose:** adopting a full 33-stage process with 14 agents (stages exist to coordinate
people who don't share context; map your real handoff points instead — five gates usually cover them);
externalizing the method to a platform outside the repo (breaks the atomicity of decision + code in
one reviewable diff). **Main risk:** `exit_gate` becoming prose inside a structured field.
Mandatory mitigation: the script refuses any condition it can't evaluate.

---

## 17. Documentation versioning

Markdown in git is the source; `.docx`/`.pdf`/`.html` are exports. Superseded snapshots live in
`docs/versions/archive/`, never deleted. **Edit in place** by default (ADRs, current plan); snapshot
only to freeze a milestone (external release, historical cut).

| Digit | Increment when | Example |
|---|---|---|
| **Major** | stack change, business-model pivot, fundamental rewrite | swapping the core runtime |
| **Minor** | a set of ADRs goes `accepted`, OR a UoW reaches production, OR the revenue model changes | UoW in prod → vX.(Y+1).0 |
| **Patch** | anything that doesn't change existing decisions: specs, RFCs, PDs, refinements, notes | new specs → vX.Y.(Z+1) |

Golden rule: revertible without impacting production → patch; locked an irreversible decision → minor.

---

## 18. Bootstrap checklist

**Fast path:** clone `mandate-framework`, run `scripts/init.sh` (fills every `{{PLACEHOLDER}}`),
`git config core.hooksPath scripts/guardrails/git-hooks`, run `./scripts/guardrails/verify-all.sh`,
then continue from step 3 below.

1. **Constitution** (§3): context, stack table with an ADR per row, named rules with 🔒 markers,
   RFC-vs-implement boundary, phases, never-do list, RULE-PM/TASK/QA/REVIEW, versioning. Record the
   instruction-budget ceiling on day one (`--record`) — it only goes down from there.
2. **Directories** (§2): `docs/adr|rfc|backlog|initiatives|reference|reports|office`, `DECISIONS.md`
   with index markers, `learned-rules.md` (empty is fine), `AGENTS.md` if a second tool will touch
   the repo.
3. **Seed ADRs** — one per stack row, `accepted`, dated, with machine-readable front matter.
4. **Sensitive domains** — list them in the constitution *and* in `decision-index.py` and the rigor
   ladder's path patterns. This is the one piece you can't retrofit after a silent default ships.
5. **UoW 01** — foundation, 3–5 stories, executable `exit_gate` ("repo builds + CI green +
   hello-world deploy").
6. **Guardrails** — the initial set + your first domain guardrail for your first survival condition;
   `verify-all.sh` as the only thing CI calls; `CODEOWNERS`.
7. **Branching** — `develop` + `main`, branch protection: PR required into `develop`, FF-only into
   `main` via `promote-develop.sh`.
8. **Issue mirroring** — sync script, labels, milestones per UoW, board; run it from CI.
9. **Review bots** — enable at least one; adopt RULE-REVIEW-01 with its fallback.
10. **Virtual org** — role by role, against concrete pain; `architect` and `product-owner` usually pay
    first; coordination and cadence roles only once several exist.
11. **Later, once registries grow:** `/analyze` before closing a UoW; decision-log health check past
    ~50 PDs; agent evals for the invariants that already cost you once; the §16 module when a second
    team is in sight.
12. **Dry run** — execute the first story end-to-end and verify: ADRs read first, scope OUT honored,
    PDs registered, ACs proven by execution, `Refs:` footer, status updated, audit-trail line written.
    Fix the constitution wherever the agent deviated — the constitution is code; debug it.

---

*This template is intentionally stack-, domain- and tool-agnostic. Everything specific to a project
belongs in the artifacts this template tells you to create — not in this file.*
