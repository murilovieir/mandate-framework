---
name: agents-census
description: Virtual-org census — lists every agent in .claude/agents/ with model, number and date of the last opinion in docs/office/, local executions, total tokens and average per execution (local transcripts). Use on "/agents-census", "agent census", "my agents", "when did each agent last act", "how many tokens is each agent using". READ-ONLY — doesn't create, edit or delete agents.
---

# `/agents-census` — virtual-org census

> ⛔ **READ-ONLY.** Lists and reports; creating/editing/deleting an agent is the decider's call.

Answers "who are my agents, when did they last act and what do they cost?" by crossing three sources
of different durability. **Don't trust conversation memory — run the script.**

```bash
python3 .claude/skills/agents-census/census.py          # readable table
python3 .claude/skills/agents-census/census.py --json   # for processing
```

| Source | Gives | Durability |
|---|---|---|
| `.claude/agents/*.md` | roster + model + tools | versioned (git) |
| `docs/office/<agent>/` | number of opinions + date of the last (`YYYY-MM-DD` prefix) | **versioned — the reliable history** |
| `~/.claude/projects/**/*.jsonl` | executions, tokens (cumulative max per task), last invocation | **local and ephemeral** — this machine only |

## Present
1. Paste the script's table whole (reading notes included).
2. Highlight in 2–4 bullets: biggest token consumer, idle agents (0 execs AND old opinion), and any
   roster×usage divergence (invoked agent missing from the roster; orphan `office/` folder).
3. Trend questions → only `docs/office/` survives across sandboxes; tokens are a snapshot of this machine.

## Known limits
- Tokens of nested sub-agents show up aggregated in the parent.
- Remote sandboxes are ephemeral: execs/tokens reset with each new environment.
- Keep the script's numbers — don't recompute by hand.
