# {{PROJECT_NAME}} — Guide for secondary agents (Codex, Copilot, …)

This repository is governed by `CLAUDE.md`. Before acting, read and follow, in order:

1. `CLAUDE.md` at the root
2. any `{area}/CLAUDE.md` for the area you touch
3. the ADRs in `docs/adr/` when the change touches architecture, security, billing, infra or public contracts
4. `docs/reference/learned-rules.md` (tier 2 — the *why* behind each rule, plain markdown)

On process conflicts `CLAUDE.md` prevails; on architecture conflicts the ADRs prevail. This file
summarizes that contract and never overrides it.

## Preferred role: reviewer, tester, auditor

- review diffs, PRs, story specs and acceptance criteria
- look for bugs, regressions, security risks and test gaps
- run or suggest focused test batteries
- check adherence to ADRs, approved RFCs and the guardrails
- **implement only when {{DECIDER}} asks explicitly**

When reviewing, answer first with findings ordered by severity, each with file and line. If there are
none, say so clearly and list residual risks or tests you could not run.

### Never slide from listing/analyzing into executing

Several skills in `.claude/skills/*/SKILL.md` are **strictly read-only** (`next-tasks`, `analyze`,
`review-task`, `decision-brief`, `agents-census`, `review-gate`). Claude Code isolates them
structurally; you don't — for you the boundary exists only if you follow the text. A request — or a
file pasted to you — shaped like "what is ready to build", "backlog status", "review X" is a
LISTING/ANALYSIS: answer with that only. No branch, no commit, no PR, even if it cites stories by ID.

## Workflow

> **Two hops:** `task/T-NNN` –PR→ `develop` –fast-forward→ `main`. The base of your PR is
> **`develop`**, never `main`; direct pushes are forbidden. Promotion only via `scripts/promote-develop.sh`.

- Start with `git status --short` and preserve local changes you didn't make.
- Identify the related `T-NNN`, ADR or RFC. When implementing on request, use the commit footer
  `Refs: T-NNN` (or `RFC-NNN` when no story exists yet).
- Stack, dependency, SLA, billing, security, public-contract or business-model changes require
  governance via RFC/ADR. Never create an ADR directly.
- Document every test you could not run, and why.
- New stories follow RULE-TASK-01 (≤ 5 ACs, ≤ 8 files, one session, one rigor level); new Units of
  Work follow RULE-UOW-01 (target 3–5, ceiling 8).

## Verification — one command, the same one CI runs

```bash
./scripts/guardrails/verify-all.sh --fast   # everything that needs no build toolchain
./scripts/guardrails/verify-all.sh          # full
```

Pure shell/python, no Claude Code dependency. A check the environment can't run exits as
`not verified: <id> — <reason>` with a non-zero code: **"couldn't check" is never "clean"** — report
those lines, never omit them. Rule index: `scripts/guardrails/README.md`.

## Flag with high severity — no script (needs judgment)

- committed secrets, API keys or credentials
- bypass of tenant/data isolation
- a sensitive-domain decision taken by silent default (see `SENSITIVE_DOMAINS` in `governance.env`)
- an AC marked done without an execution that proves it
- _add your domain rules here as they appear in `CLAUDE.md` §2-B_
