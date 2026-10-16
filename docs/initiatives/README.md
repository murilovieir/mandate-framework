# Initiatives — optional business-outcome layer

An **Initiative** ties one **business outcome** (anchored in the business plan, `docs/versions/`) to
one or more Units of Work. It is the top of the delivery pyramid — the business *why* above the *what
to build*.

- **Create one** when several Units of Work serve the same outcome and you want to track it.
- **Don't** for cross-cutting infra/process Units of Work — they have no business thesis of their own.
- Absence of an Initiative never blocks execution.
- Optional scale-readiness gate **G1** (template §16): every new *product* Unit of Work is born with a
  parent Initiative. Adopt it when more than one team plans work.
- On the board: a theme label `initiative:INI-NNN` (not an issue, not a milestone).

## Template — `INI-NNN-slug.md`

```markdown
---
id: INI-NNN
date: YYYY-MM-DD
status: active | done | paused
uows: [01, 03]
plan: "<anchor / section in the business plan>"
---

# INI-NNN — {Business outcome}

## Business outcome
## Why now
## How we measure it
## Units of Work that deliver it
| Unit of Work | Role in this outcome |
|---|---|
## Out of scope
```
