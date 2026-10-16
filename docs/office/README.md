# docs/office/ — institutional memory of the virtual org

Opinions, memos, briefings and reports produced by the **role agents** (`.claude/agents/`). Agents
have no memory between sessions — this directory is what survives: each agent reads its own history
when invoked and writes here anything worth keeping.

## Convention

```
docs/office/<role>/YYYY-MM-DD-subject.md
```

One subdirectory per role, created on first use: `architect/`, `product-owner/`, `qa-engineer/`,
`release-manager/`, `tpm/`, `chief-of-staff/` (and any optional role you add: `devops/`, `cfo/`,
`pmm/`, `cofounder/`, `coo/`…).

## What this directory is NOT

- **Not a source of decision.** Formal governance stays where it always was (RULE-PM-01): decisions
  → `docs/adr/`; proposals → `docs/rfc/`; emergent decisions → `DECISIONS.md`; scope/ACs →
  `docs/backlog/`. A memo here that contradicts an ADR is wrong by definition — the ADR prevails.
- **Not product documentation.** Approved material migrates to its canonical home in its own story;
  the draft/opinion that originated it stays here.

## Lifecycle

- Files are immutable after their date — a new opinion is a new file, not an edit.
- Never delete — the history is the value. When a role becomes a real hire, its subdirectory plus the
  agent file **is** that person's onboarding.
