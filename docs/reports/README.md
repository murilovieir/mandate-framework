# Reports

Output of **read-only housekeeping routines** and audits. These files are **outputs, not sources of
truth** — they cite the canonical files they audited (`DECISIONS.md`, `docs/rfc/`, `docs/backlog/`,
`docs/adr/`).

## Routines

| Routine | Cadence | File |
|---|---|---|
| Consistency gate (`/analyze`) | before closing a Unit of Work; monthly | `analyze-YYYY-MM-DD.md` |
| Decision-log health | biweekly once past ~50 PDs | `decisions-health-YYYY-MM-DD.md` |
| Audit trail (`backlog-executor` step 9) | every story closure | `process-metrics.jsonl` (exception — see below) |

## Conventions

- Filenames carry an ISO date suffix: `<type>-YYYY-MM-DD.md`.
- Every report states up front that it changed nothing ("read-only — no PD/ADR/story modified").
- A new run creates a new file; reports are reproducible and may be pruned.

## Exception — `process-metrics.jsonl`

Append-only, one JSON line per event, **not reproducible** — never edit or prune a line. Events:

```json
{"ts":"<UTC ISO-8601>","event":"story_closed","story":"T-NNN","rigor":"N0","model":"<id>","token_cost":null,"acs_failed_at_gate":0,"findings_by_agent":{}}
{"ts":"<UTC ISO-8601>","event":"rework_observed","story":"T-NNN","origin_story":"T-MMM","cause":"<short>","pr":null}
```

The rework rate is derived later by matching `rework_observed.origin_story` against
`story_closed.story` — never declared at closure.
