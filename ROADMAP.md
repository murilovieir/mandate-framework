# Mandate Framework — Roadmap

> 🇧🇷 Português: [ROADMAP.pt-BR.md](ROADMAP.pt-BR.md) · Author: **Murilo Vieira** (@murilovieir)

Where Mandate goes after v1.0.0, organized with Mandate's own vocabulary: **Initiatives** (outcomes)
→ **Units of Work** (increments with an exit gate) → **stories**. Framework stories use the `MF-NNN`
prefix so they never collide with the `T-NNN` stories of a project that adopts Mandate.

Two lines carry most of the value, and both follow the same principle — **autonomy and parallelism are
earned by evidence, never granted by default**:

1. **Autonomy** — the agent doing more on its own, as the data shows it can.
2. **Many humans + many AIs in parallel** — moving from one decider and one executor to **PODs**:
   teams of people and agents working at the same time without stepping on each other.

How Mandate compares with AWS's AI-DLC — what it already has, what it adopted, what it rejected and
what is missing — is in [`docs/reference/mandate-vs-ai-dlc.md`](docs/reference/mandate-vs-ai-dlc.md).

Horizons: **Now** (next releases) · **Next** (needs Now) · **Later** (needs a real second team or
real production use to design well). Status of every item today: `todo`.

---

## Done

| ID | Story | Done when |
|---|---|---|
| MF-042 | **v1.0.0 release hygiene** — content review for references to any origin project; repository About | ✅ zero matches in the scan · About text ready (applied by the author in the repository settings) |

---

## INI-01 — Earned autonomy

*Outcome: the agent's mandate widens automatically where the audit trail proves it is safe, and
narrows where it doesn't — instead of staying fixed by hand.*

### UoW-01 — Autonomy levels as configuration · **Now**
Exit gate: the autonomy level of every path is declared, machine-read, and enforced by `verify-all.sh`.

| ID | Story | Done when |
|---|---|---|
| MF-001 | **Autonomy ladder A0–A4** in `governance.env` (A0 propose only · A1 implement, human merges · A2 auto-merge N0 when green · A3 auto-merge N1 with clean review gate · A4 autonomous loops), declared per path pattern | a guardrail rejects a merge that exceeds the path's level |
| MF-002 | **Mandate file per story** — the spec declares what the agent may touch (paths, commands, external calls); a hook warns on anything outside it | an edit outside the story's declared paths produces a warning, and CI fails it |
| MF-003 | **Budgets** — token/cost/time ceiling per story and per rigor level; the executor stops and escalates when exceeded | `story_closed` records cost, and an over-budget run stops with an escalation note |
| MF-004 | **Kill switch** — one flag that drops every agent to A0 instantly (incident, audit, holiday) | flipping the flag makes every autonomous loop exit at its next step |

### UoW-02 — Autonomy earned from the audit trail · **Next**
Exit gate: a script proposes level changes from `process-metrics.jsonl`; the decider ratifies them as PDs.

| ID | Story | Done when |
|---|---|---|
| MF-005 | **Metrics aggregator** — rework rate, ACs failed at the gate, review findings per agent, lead time, cost per rigor level | `scripts/planning/process-metrics.py` prints the table from the JSONL |
| MF-006 | **Autonomy proposals** — "path X: 20 stories, 0 rework, 0 gate failures → propose A2"; and the reverse on regressions | the script writes a `PD-AUTONOMY-NN` draft with the evidence, never applies it |
| MF-007 | **Automatic demotion** — a rework event on an A2/A3 path drops it one level until re-earned | a `rework_observed` event lowers the level in the next run, recorded as a PD |

### UoW-03 — Autonomous loops · **Next**
Exit gate: the recurring routines run unattended on a schedule, each one read-only or bounded by its level.

| ID | Story | Done when |
|---|---|---|
| MF-008 | **Scheduled routines** — weekly `chief-of-staff` briefing, `/analyze` before closing a UoW, decision-log health; templates for GitHub Actions cron and agent schedulers | the routines run on schedule and write to `docs/reports/` without a human starting them |
| MF-009 | **Self-healing PRs** — the executor watches its own PR: fixes red CI, answers review threads, re-runs the gate; escalates after N rounds | a red PR opened by the agent returns to green without a human, or produces an escalation |
| MF-010 | **Backlog autopilot** (A4) — pick the next ready story from `next-tasks`, execute, open PR, stop at the merge gate | a story goes from `todo` to an open PR with no human prompt, inside its budget |

### UoW-04 — Testing the agent, not only the code · **Now**
Exit gate: the normative surface (constitution, skills, agents) has regression tests that block merges.

| ID | Story | Done when |
|---|---|---|
| MF-011 | **Agent evals in the framework** — port the mutation-style invariant evals (golden + mutated trajectories, blob-SHA staleness) | `verify-all.sh` runs the evals; three invariants shipped |
| MF-012 | **Trajectory capture** — record real sessions as eval fixtures instead of writing them by hand | a captured session can be replayed as a fixture |
| MF-013 | **Multi-runtime evals** — the same invariant checked against Claude Code, Codex and others | one invariant passes on at least two runtimes |

---

## INI-02 — Many humans and many AIs, in parallel

*Outcome: several people and several agents work on the same repository at the same time, with
clear ownership, no silent collisions and decisions ratified by the right person.*

### UoW-05 — Claims and coordination · **Now**
Exit gate: nobody — human or agent — can start a story someone else holds, and stale claims expire.

| ID | Story | Done when |
|---|---|---|
| MF-014 | **Claim/lease protocol** — `claimed_by` (human or agent id) + `lease_until` in the story front matter, mirrored to the issue assignee | starting a claimed story is refused by the executor and flagged in CI |
| MF-015 | **Collision detection from the real diff** — compare open branches/PRs by touched files, not by declared "expected files" | two open PRs touching the same file are reported before either merges |
| MF-016 | **Worktree fan-out** — one git worktree per agent, batches from `next-tasks`, a merge order computed from dependencies | three ready stories run in parallel worktrees and merge in a consistent order |
| MF-017 | **Session handoff capsule** — a standard `HANDOFF.md` per in-flight story (state, next step, open questions) so any human or agent can resume | a fresh session resumes an interrupted story from the capsule alone |

### UoW-06 — Federated decisions · **Next**
Exit gate: decisions are routed to the right owner and ratified by role, not by one person.

| ID | Story | Done when |
|---|---|---|
| MF-018 | **Ratification routing** — `Sensitivity` + `CODEOWNERS` decide who must ratify a PD; `decision-index.py` enforces it | a PD ratified by the wrong owner fails `--check` |
| MF-019 | **Counterpart scope acceptance (G2)** — a story touching another owner's paths needs that owner's recorded acceptance of its Out of scope | the guardrail fails a story spec without the acceptance line |
| MF-020 | **Org-scoped decisions** — `Scope: org` PDs replicated to a shared decision registry across repositories | an org PD written in one repo is visible and checked in another |
| MF-021 | **Multi-decider RFCs** — RFCs with explicit approvers per area and a quorum rule when areas overlap | an RFC touching two areas needs both approvals to become `approved` |

### UoW-07 — PODs: teams of humans and agents · **Later**
Exit gate: two PODs work on one codebase, each with its own paths, backlog, roster, decider and autonomy level, coordinated only through G2/G5 contracts. Concept: [`docs/reference/mandate-vs-ai-dlc.md` §7](docs/reference/mandate-vs-ai-dlc.md).

| ID | Story | Done when |
|---|---|---|
| MF-022 | **Pairing modes** — human-drives/agent-reviews and agent-drives/human-reviews as explicit story modes with different gates | the mode in the spec changes which gates apply |
| MF-023 | **Per-team rosters** — each team with its own `.claude/agents/` overrides on top of the shared org | two teams run different rosters in one repo without conflict |
| MF-024 | **Cross-team dependency board** — UoW exit gates as the signal another team waits for | a team's blocked story unblocks automatically when the other team's gate is met |
| MF-038 | **POD manifest** — `pods/<name>.yaml`: members (humans + agents), owned paths, decider, autonomy level; `CODEOWNERS` generated from it | adding a POD is one file, and `CODEOWNERS` is regenerated and checked in CI |
| MF-039 | **POD-aware planning** — `next-tasks` and the board filter by POD; Units of Work carry `owner: <pod>` | each POD sees only its ready stories and its cross-POD blockers |
| MF-040 | **Per-POD metrics and autonomy** — the audit trail split by POD; autonomy earned and demoted per POD | one POD at A2 and another at A1 on the same repo, both justified by their own data |
| MF-041 | **Inception mob ritual** — a short synchronous session (humans + architect/product-owner agents) that turns an Initiative into Units of Work, recorded as an RFC/UoW | the ritual's output is a ready UoW with an executable exit gate |

---

## INI-03 — Mandate as a product

*Outcome: adopting and upgrading Mandate takes minutes, and adopters get improvements without
re-copying files.*

### UoW-08 — CLI and upgrades · **Now**
Exit gate: `mandate init`, `mandate verify` and `mandate upgrade` work from a package.

| ID | Story | Done when |
|---|---|---|
| MF-025 | **`mandate` CLI** — `init`, `verify`, `new story|rfc|pd|adr`, `status`, packaged for npm and pipx | `npx mandate-cli init` bootstraps a repo |
| MF-026 | **Framework vs project files** — a manifest of which files belong to Mandate and which to the adopter | `mandate upgrade` updates framework files and never touches project files |
| MF-027 | **Brownfield adoption** — a guide plus an `adopt` mode that maps an existing repo's docs/issues into Mandate | an existing repository gets Mandate without losing its history |
| MF-028 | **Claude Code plugin** — skills, agents and hooks distributed as a plugin | installing the plugin gives the skills without copying files |

### UoW-09 — Visibility · **Next**
Exit gate: the state of the method is visible without reading markdown.

| ID | Story | Done when |
|---|---|---|
| MF-029 | **Governance dashboard** — stories, PDs awaiting ratification, autonomy levels, rework, cost | one page renders from the repository files |
| MF-030 | **PR evidence summary** — a generated PR section with rigor level, `verify-all` result and AC × execution table | every PR opened by the agent carries the section |
| MF-031 | **Docs site** — method guide, pillars and examples published, EN + PT-BR | site published from `docs/` |

---

## INI-04 — Operation and trust

*Outcome: Mandate covers the system after it reaches production, and its own actions are auditable.*

### UoW-10 — The Operation phase · **Later**
Exit gate: activating the Operation trigger installs a working on-call loop.

| ID | Story | Done when |
|---|---|---|
| MF-032 | **Operation roster** — `sre-oncall`, `incident-commander`, `customer-success` agents with runbook skills | the trigger activates the roster with no manual setup |
| MF-033 | **Incident loop** — incident → timeline → postmortem → `LR-NNN` → guardrail, closing the learning cycle | a postmortem produces a learned rule and a proposed guardrail |
| MF-034 | **Machine-resolvable Operation trigger** — the activation condition as a data query in CI | the trigger fires from data, not from someone remembering |

### UoW-11 — Security and audit of agent actions · **Next**
Exit gate: every agent action is attributable, and the riskiest ones need a second key.

| ID | Story | Done when |
|---|---|---|
| MF-035 | **Security guardrails** — secret scanning, dependency allowlist, no new dependency without an RFC | a commit with a secret or an unapproved dependency fails CI |
| MF-036 | **Agent action ledger** — signed, append-only record of what each agent did (commands, files, PRs) | the ledger answers "which agent changed this, under which story and level" |
| MF-037 | **Two-key actions** — destructive or one-way operations need a human confirmation recorded in the ledger | a one-way action without a recorded confirmation is blocked |

---

## How this roadmap is governed

- Items become real stories (`MF-NNN` spec files) only when their Unit of Work starts — specs written
  too early go stale.
- Priorities move with evidence: `process-metrics` data and real adoption feedback, not wish lists.
- Every new rule ships with its script (pillar **N**) and its test — a roadmap item that adds a rule
  without enforcement is not done.
