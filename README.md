# Mandate Framework

> **Spec-driven governance for AI coding agents.** 🇧🇷 Português: [README.pt-BR.md](README.pt-BR.md)

Mandate is a ready-to-clone framework that gives an AI coding agent (Claude Code as primary executor;
Codex/Copilot as reviewers) a **mandate**: a constitution it reads every session, decisions it may not
reopen, a backlog it executes story by story, a small virtual org of role agents with explicit limits,
and deterministic guardrails with one verification command that runs the same way locally and in CI.

Its golden rule is its name: **the agent acts within its mandate; whatever exceeds it becomes an RFC,
and only the decider widens a mandate.**

## The seven pillars — M.A.N.D.A.T.E.

| | Pillar | In this repository |
|---|---|---|
| **M** | **Markdown as source of truth** | scope, ACs and decisions in versioned markdown; Issues mirror one-way |
| **A** | **Architecture by ADR** | `docs/rfc/` → `docs/adr/`, approved by the decider; locked decisions are never reopened |
| **N** | **Named rules, enforced by script** | `RULE-*` marked 🔒 in `CLAUDE.md`, `scripts/guardrails/` as hook + CI |
| **D** | **Decision Log** | `DECISIONS.md` — every fork is a PD; a sensitive default never closes silently |
| **A** | **Agents with bounded mandates** | `.claude/agents/` — every role ends with its "limits of mandate" |
| **T** | **Tested before asserted** | RULE-QA-01 + `verify-all.sh`, the single verification authority |
| **E** | **Executable backlog** | Initiative → Unit of Work → Story, with executable exit gates (`uow-gate.sh`) |

Method guide — the *why* behind every file: [`docs/reference/governance-template.md`](docs/reference/governance-template.md)
· [PT-BR](docs/reference/governance-template.pt-BR.md). Stack-, domain- and tool-agnostic.

## Quick start

```bash
git clone https://github.com/murilovieir/mandate-framework my-project && cd my-project
rm -rf .git && git init -b main            # start your own history
./scripts/init.sh                          # asks for project name, decider, phase… fills every {{PLACEHOLDER}}
git config core.hooksPath scripts/guardrails/git-hooks
./scripts/guardrails/verify-all.sh         # must end with "VERIFY-ALL: OK"
git add -A && git commit -m "chore: bootstrap governance" -m "Refs: T-001"
git branch develop
```

Then, in order (template §18):

1. Fill `CLAUDE.md` §1–§2 and §6 — context, stack table, phases. Write one ADR per stack row
   (`docs/adr/README.md` has the template).
2. Adjust `governance.env` — your **sensitive domains** and **sensitive paths**. This is the one thing
   you can't retrofit after a silent default ships.
3. Record the instruction budget: `./scripts/guardrails/instruction-budget.sh --record`.
4. Write your first domain guardrail for your first survival condition (`scripts/guardrails/README.md`).
5. Plan Unit of Work 01 (`docs/backlog/uow-01/_index.md`) and execute its first story:
   *"execute T-001"*.

## What's inside

| Path | What |
|---|---|
| `CLAUDE.md` | Constitution (tier 1) — normative rules with `{{PLACEHOLDER}}`s |
| `AGENTS.md` | Contract for reviewer tools |
| `DECISIONS.md` / `DECISIONS_ARCHIVE.md` | Decision Log (live + closed) with a generated index |
| `governance.env` | Project knobs: sensitive domains/paths, budget files, branch names, decider |
| `docs/adr/`, `docs/rfc/` | Decision axis: proposals → locked decisions |
| `docs/initiatives/`, `docs/backlog/` | Delivery axis: Initiative → Unit of Work → User Story |
| `docs/reference/learned-rules.md` | Tier 2 — the *why* of each rule (`LR-NNN`) |
| `docs/office/`, `docs/reports/` | Institutional memory of role agents · dated read-only reports + audit trail |
| `.claude/skills/` | `backlog-executor`, `decision-log`, `review-gate`, `analyze`, `next-tasks`, `decision-brief`, `review-task`, `branch-cleanup`, `agents-census` |
| `.claude/agents/` | `architect`, `product-owner`, `qa-engineer`, `release-manager`, `tpm`, `chief-of-staff` |
| `scripts/guardrails/` | `verify-all.sh` (the definition of green) + guardrails + tests + git hooks |
| `scripts/planning/` | `decision-index.py`, `next-tasks.py`, `sync-github-issues.sh`, `uow-gate` helpers |
| `scripts/promote-develop.sh` | `develop → main`, fast-forward only |
| `.github/` | `governance.yml` (CI calls `verify-all.sh` and nothing else), `CODEOWNERS`, PR template |
| `docs/reference/mandate-vs-ai-dlc.md` | How Mandate compares with AWS AI-DLC, and the POD model for many teams |
| `ROADMAP.md` | How the framework evolves: earned autonomy, many humans + AIs in parallel, CLI, operation |

## Principles in one breath

Markdown in the repo is the source of truth · every story has a spec · one decider approves RFCs ·
every fork goes to the Decision Log · delivery and decision are separate axes · **a rule without a
script is a wish** — so every checkable rule has one, run as a warning hook locally and as a
merge-blocking check in CI, from the same source.

## Requirements

`bash`, `git`, `python3` (≥ 3.9, standard library only), `jq` (for the Claude Code hooks). Optional:
`gh` for Issue mirroring.

## Author

Created and maintained by **Murilo Vieira** ([@murilovieir](https://github.com/murilovieir)).

Mandate was designed and evolved by using it every day and turning each correction into a rule —
and, where possible, into a script. The method grew in this order:

1. Constitution read by the agent every session; spec-driven stories (Implementation Contract); ADRs as locked decisions.
2. Decider-gated RFC flow — the agent proposes, never decides.
3. Spec-Driven Development vocabulary; `/analyze` consistency gate; one-way GitHub Issues mirroring.
4. Virtual org of role agents with bounded mandates; Decision Log v2 (sensitive-default escalation, batch ratification); rigor ladder N0–N3; parallel fan-out.
5. *Execute before asserting* — the review gate.
6. Deterministic guardrails (hook + CI, one source); two-tier knowledge; bolt sizing; agent evals; machine-readable decision status; `verify-all.sh` as the single authority; two-hop branching; scale-readiness gates.
7. **Mandate Framework v1.0.0** — the seven pillars, packaged as a framework.

What comes next: [`ROADMAP.md`](ROADMAP.md). Contributions: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Murilo Vieira. Projects bootstrapped with `scripts/init.sh` keep a copy of the
license in `docs/guides/MANDATE_LICENSE`, which satisfies the notice requirement.

> Mandate is an independent project. It is not affiliated with, endorsed by or sponsored by Anthropic
> (Claude Code), Amazon Web Services (AI-DLC), OpenAI (Codex) or GitHub (Copilot); those names are
> used only to describe compatibility and comparison. In `.github/CODEOWNERS`, `@{{DECIDER_GITHUB}}`
> is intentional: `init.sh` replaces it in your project.
