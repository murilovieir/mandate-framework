# {{PROJECT_NAME}} — AI Collaboration Guide

> Read automatically by the AI coding agent at session start. It defines the rules, guardrails and
> workflows that govern all AI collaboration in this repository.
>
> **Two-tier knowledge.** This file is tier 1 — normative imperatives only. The *why* behind each
> correction (incident, previous version, origin) lives in tier 2, `docs/reference/learned-rules.md`
> (`LR-NNN`), loaded on demand. Never paste incident stories here; add an `LR-NNN` and cite it.
>
> 🔒 = enforced by a script in `scripts/guardrails/` (hook in warn mode locally, merge-blocking in CI).
> The script is the authority; this text is the index. Single command: `./scripts/guardrails/verify-all.sh`.

---

## 0. Multi-agent usage

- **Primary executor:** Claude Code — executes stories, decomposes the backlog, updates governance
  artifacts.
- **Reviewers/auditors:** any second tool (Codex, Copilot, …) follows `AGENTS.md` — reviews, validates
  ACs, runs focused tests, audits. It implements **only** when {{DECIDER}} asks explicitly.
- **Virtual org:** role agents in `.claude/agents/`, institutional memory in `docs/office/`.

### RULE-REVIEW-01 — Automated PR review and its mandatory fallback

Every PR triggers the review bots configured on the repository. Their findings are real review:
investigate; fix if small and unambiguous; ask {{DECIDER}} if ambiguous or architectural; mark
non-actionable if a false positive. Findings go to the story's execution notes (RULE-QA-02).

The review ran when there is a bot comment **or** a 👍 reaction on the PR. These all mean **it did
not run**: a bot error comment, a quota-exhausted comment, or silence within the normal follow-up
window. On any of them, in the same message, **suggest a local review layer**: `/code-review`
(user-triggered and billed — suggest, never trigger) and/or dispatch `qa-engineer` (you may run it).
Calibrate by size and sensitivity; anything N2 never merges with zero review layers unless
{{DECIDER}} decides so explicitly — and that decision is recorded. → `LR-001`

---

## 1. Project context

{{PROJECT_DESCRIPTION}}

- **Architecture source of truth:** `docs/adr/` (index: `docs/adr/README.md`)
- **Business plan:** `docs/versions/` (markdown source; binaries are exports)
- **Current phase:** {{CURRENT_PHASE}}

---

## 2. Tech stack — NON-NEGOTIABLE

Closed in ADRs. Never suggest substitutes without explicit approval from {{DECIDER}}.

| Layer | Decision | ADR | Forbidden to suggest |
|-------|----------|-----|----------------------|
| _e.g. Runtime_ | _fill in_ | ADR-001 | _alternatives_ |

**Golden rule:** a technology not in this table and without an ADR → flag the gap explicitly and
propose an RFC (§5). Never implement it directly.

### 2-B. Domain rules (add as RULE-{AREA}-NN)

Each named rule states **Correct:** and **Forbidden:**, and gets a 🔒 marker once a guardrail script
enforces it. Write a domain guardrail for every survival condition (see `scripts/guardrails/README.md`).

---

## 3. Repository structure

Tree and module list → `docs/reference/repo-structure.md` (create it once there is code).

## 4. Canonical types and core conventions

Area conventions live in per-area constitutions (`{area}/CLAUDE.md`), loaded automatically there.
Keep here only what must ALWAYS hold.

---

## 5. Workflow — RFC vs. direct implementation

### Claude Code IMPLEMENTS directly
- Code inside the stack defined by the ADRs; tests; refactors without technology/architecture change;
  bug fixes within expected behavior; documentation.

### Claude Code PROPOSES (writes `docs/rfc/RFC-NNN-slug.md`) and waits for GO
1. New dependency not in the stack.
2. New ADR needed — architectural decision not covered.
3. Change of SLA, billing or security behavior.
4. Significant change of data structures or public APIs.
5. Anything touching the business model.

### Spec-Driven Development map
| SDD phase | Artifact |
|---|---|
| Constitution | `CLAUDE.md` |
| Specify | story spec `docs/backlog/uow-NN/T-NNN-*.md` |
| Plan | plan mode + ADRs |
| Tasks | Unit of Work decomposition (mirrored to Issues) |
| Implement | skill `backlog-executor` |
| Analyze | skill `/analyze` |

RFCs are **decider-gated**, not IETF-style: a proposal {{DECIDER}} approves or rejects. Approved → ADR.

### Two governance axes — never merge them
```
DELIVERY                               DECISION
  Initiative (INI-NNN) ← optional        Proposal (RFC-NNN)
        ↓                                      ↓ {{DECIDER}} approves
  Unit of Work (= Epic)                  ADR-NNN (accepted)
        ↓                                      └─ referenced by stories/UoWs
  User Story T-NNN (= Story)
        ↓
  Acceptance Criteria
```

### RULE-TASK-01 / RULE-UOW-01 — bolt sizing 🔒 `task-spec-shape.sh`
- **New story:** fits one execution session; **≤ 5 ACs**; **≤ 8 expected files** (one bullet per
  file); useful increment alone; **one rigor level** (§7). `L` needs an indivisibility rationale.
- **New Unit of Work:** target 3–5 stories, **ceiling 8**; executable `exit_gate` 🔒 `uow-gate.sh`.
- Neither retroacts on existing specs or UoWs.

### `Operation` phase — registered slot
Not built yet: no on-call, runbooks or incident loop while nothing is in production. **Activation
trigger (observable):** {{OPERATION_TRIGGER}}. When it fires, an Operation RFC becomes mandatory.

---

## 6. Product phases — what is in scope NOW

- **IN SCOPE (implement):** _list_
- **IN SCOPE, not priority:** _list_
- **BACKLOG (do not implement, do not suggest as priority):** _list_

---

## 7. Code quality

### Rigor ladder — classify by the paths the diff touches, never by judgment
| Level | Trigger | Gates |
|---|---|---|
| N0 | docs, backlog chores; no product code | execution loop + `Refs:` footer |
| N1 | product code outside sensitive paths | N0 + self-review checklist + `task/T-NNN` branch + PR + green CI |
| N2 | diff touches a sensitive path (`SENSITIVE_PATHS` in `governance.env`) | N1 + `architect` + `qa-engineer` + `release-manager` opinions **before merge** |
| N3 | N2 opinions diverge, one-way door, or billing/security/SLA behavior change | N2 + explicit ratification by {{DECIDER}} |

Survival conditions never go below N2. **Auto-merge does not exist.**

**Sensitive domains:** see `SENSITIVE_DOMAINS` in `governance.env` — a default in one of them never
closes silently (`decision-log` skill).

### RULE-QA-01 — Execute before asserting
**No AC is checked without an execution that proves it. "It compiles" is not execution.** The gate is
the full suite of every module the diff touches (derived from the diff, never a manual list). When the
environment prevents it, run the affected tests in isolation and record which and why — a declared
partial result is fine; an AC checked by inference is not. Operationalized by `review-gate`; the rule
holds without it. → `LR-002`

### RULE-QA-02 — Review findings become records
Findings from `review-gate`, `/code-review` or PR bots go to the story's execution notes, in the same
commit as the fix. → `LR-003`

### Instruction budget 🔒 `instruction-budget.sh`
Normative files have a descending ceiling. `--record` only lowers it; raising it requires a PD.

---

## 8. Business guardrails

_Whatever is existential for the business (billing, pricing, data ownership). Never change it without
explicit approval from {{DECIDER}}._

## 9–10. Reference

- Local development → `docs/guides/` · learned rules → `docs/reference/learned-rules.md`
- Full rationale of this method → `docs/reference/governance-template.md` (EN) / `.pt-BR.md`

---

## 11. Issue tracker and branching

| Information | Canonical source |
|---|---|
| Scope, ACs, technical decisions, ADRs | repository (`docs/backlog/uow-NN/T-NNN-*.md`) |
| Status, priority, owner, deadline | GitHub Issues + Project board |
| Emergent decisions | `DECISIONS.md` |
| Proposals awaiting approval | `docs/rfc/` |

- **RULE-PM-01** — the table above.
- **RULE-PM-02** — commit footer `Refs: T-NNN[, ADR-NNN]`, or `RFC-NNN` when no story exists yet
  🔒 `commit-refs-footer.sh` (`git config core.hooksPath scripts/guardrails/git-hooks`). PR title
  `[T-NNN] Imperative description`; branch `task/T-NNN-slug`. **Two hops:** `task/T-NNN` –PR→
  `develop` –fast-forward→ `main`. PR into `develop` is mandatory, never a direct push; promote only
  with `scripts/promote-develop.sh`.
- **RULE-PM-03** — sync is one-directional (repo → Issues); scope/ACs are never edited in an issue.
- **RULE-PM-04** — update the spec's `status:` when committing related work; status divergence with
  the board is tolerable, scope divergence is not.
- **RULE-PM-05** — merged PR + all ACs checked → `done` and issue closed in the same commit. Only
  exception: ACs the spec declares blocked (`[⛔]`) — flag it to {{DECIDER}}.

---

## 12. What NEVER to do

- ❌ Commit secrets, API keys or passwords
- ❌ Reopen a decision locked in an ADR
- ❌ Create an ADR directly — propose via `docs/rfc/`
- ❌ Close a sensitive-domain default as `DEFAULT_APPLIED`
- ❌ Mark an AC without execution that proves it
- ❌ Push directly to `develop` or `main`
- ❌ Edit the `DECISIONS.md` index by hand 🔒 `decision-index.py --check`

---

## 13. Documentation versioning

Markdown in git is the source; binaries are exports; frozen snapshots go to `docs/versions/archive/`
(never deleted). Edit ADRs and the current plan in place.

| Digit | When |
|---|---|
| Major | stack change, business-model pivot, fundamental rewrite |
| Minor | a set of ADRs becomes `accepted`, a Unit of Work reaches production, or the revenue model changes |
| Patch | anything that doesn't change existing decisions (specs, RFCs, PDs, notes) |

---

*Conflict between this file and another artifact → this file prevails on process; `docs/adr/`
prevails on architecture.*
