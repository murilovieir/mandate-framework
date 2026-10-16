# AI-DLC rosetta — this method ↔ AWS AI-DLC

> **Reference, not normative** — outside the instruction budget. For readers arriving with AI-DLC
> vocabulary (`awslabs/aidlc-workflows`). Edit in place. Full comparison — verdict, adoptions,
> rejections, gaps and PODs: [`mandate-vs-ai-dlc.md`](mandate-vs-ai-dlc.md).

| AI-DLC | Here | Status |
|---|---|---|
| Ideation / business intent | **Initiative** (`INI-NNN`, `docs/initiatives/`) | ✅ optional level |
| Inception | RFC → ADR + story spec | ✅ — decision axis stronger than AI-DLC's (it has no Decision Log) |
| Construction | Unit of Work + `backlog-executor` | ✅ |
| **Operation** | registered slot + observable trigger (`CLAUDE.md` §5) | 🔒 gated |
| Unit of Work | **Unit of Work** (`uow-NN`) | ✅ literal convergence |
| Stage (owner + approval gate, 33 total) | steps of the `backlog-executor` loop + 5 handoff gates (template §16) | ✅ functional equivalent |
| User Story | **Story `T-NNN`** | ✅ |
| Bolt (iteration, hours/days) | RULE-TASK-01 — a story sized to one session | ✅ sizing adopted, not a level |
| Depth levels (manual) | rigor ladder N0–N3, derived from touched paths | ✅ mechanical, not chosen |
| Logical architecture per Unit of Work | — | ⚪ non-adoption recorded |
| Method memory | `docs/office/` + `DECISIONS.md` | ✅ (with reversibility, sensitivity, ratification) |
| Audit trail | `docs/reports/process-metrics.jsonl` | ✅ |
| Two-tier knowledge | `CLAUDE.md` + `docs/reference/learned-rules.md` | ✅ |
| Domain experts + quality reviewers + composer | `.claude/agents/` (`qa-engineer`/`release-manager` = reviewers) | ✅ |
| Mob Elaboration (synchronous) | — | ⚪ not adopted — the virtual org covers it asynchronously; an Inception-only mob is planned with PODs (ROADMAP MF-041) |
| Team of humans + agents | **POD** — owns paths, backlog, decider and autonomy level | 🔜 planned (ROADMAP UoW-07) |

**Legend:** ✅ exists · 🔒 gated slot · ⚪ recorded non-adoption (a decision, not a gap).

## Hierarchy

```
Intent (AI-DLC top level)        ←→ Initiative (optional)
  └─ Unit of Work                ←→ Unit of Work
       └─ User Story             ←→ Story T-NNN
            └─ Acceptance Criteria
Bolt = the ITERATION that crosses these levels — not a level of its own.
```
