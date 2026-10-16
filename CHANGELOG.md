# Changelog — Mandate Framework

## v1.0.0 — 2026-10-16

Author: **Murilo Vieira** (@murilovieir).
License: MIT. Includes `SECURITY.md`, `CONTRIBUTING.md` (EN/PT-BR), `CODE_OF_CONDUCT.md` and issue templates.

First release of **Mandate** — spec-driven governance for AI coding agents, organized in seven pillars
(M.A.N.D.A.T.E.). Executable form of the method guide v2.0 (`docs/reference/governance-template.md` · `.pt-BR.md`).

- **Constitution model** (`CLAUDE.md`, tier 1) with `{{PLACEHOLDER}}`s, two-tier knowledge
  (`docs/reference/learned-rules.md`, six seed `LR-NNN`), `AGENTS.md` reviewer contract.
- **Decision axis:** `docs/adr/` (closed status vocabulary), `docs/rfc/` (decider-gated), Decision Log
  v3 (`DECISIONS.md`: `Scope`, role-based `Ratified-by`, structured `Reopen-trigger`).
- **Delivery axis:** Initiative → Unit of Work (executable `exit_gate`) → User Story; `UoW-01` with
  story `T-001` (adopt the governance layer).
- **Skills (9):** backlog-executor, decision-log, review-gate, analyze, next-tasks, decision-brief,
  review-task, branch-cleanup, agents-census.
- **Virtual org (6):** architect, product-owner, qa-engineer, release-manager, tpm, chief-of-staff.
- **Guardrails:** commit-refs-footer, instruction-budget, task-spec-shape,
  decision-status-consistency, uow-gate (scale-readiness G5) — each with golden + mutated tests;
  `verify-all.sh` as the single verification authority (fail-closed, anti-drift); CI calls it and
  nothing else.
- **Planning:** decision-index (sensitive-default hard gate; `T-NNN done` and `cmd:` triggers
  evaluated under `--check` too), next-tasks (rigor, model tier, parallel batches, self-check),
  sync-github-issues (one-way, idempotent), promote-develop (fast-forward only).
- **Scale readiness (optional, template §16):** `CODEOWNERS` from day one, `Scope` in PDs,
  role ratification, executable UoW gates. G1/G2 are documented, not enforced — adopt with a second team.

Not shipped in v1.0.0 — planned in [`ROADMAP.md`](ROADMAP.md): agent evals (§14.4), optional roles
(devops, cfo, pmm, cofounder, coo), the design-specialist handoff (§14.3).
