# scripts/guardrails/

Deterministic rules. **A rule without a script is a wish** — every rule in `CLAUDE.md` that can be
checked mechanically has a script here, marked 🔒 in the constitution. The script is the authority;
the constitution is the index.

## The single command

```bash
./scripts/guardrails/verify-all.sh            # the definition of "green" — CI runs exactly this
./scripts/guardrails/verify-all.sh --fast     # skip anything needing a build toolchain
./scripts/guardrails/verify-all.sh --list     # what would run
./scripts/guardrails/verify-all.sh --only guardrails,planning
```

A check that can't run prints `not verified: <id> — <reason>` and fails the run. "Couldn't check" is
never "clean".

## Two consumers, one source

| Mode | Invoked by | Reads | Exit |
|---|---|---|---|
| `--hook` | `.claude/settings.json` PreToolUse (Edit\|Write) | only the content being written | always 0 (warn) |
| CI | `verify-all.sh` | tracked files, or what's new in the diff | 1 on violation (blocks merge) |

Commit-time rules use the native git hook instead (`git config core.hooksPath
scripts/guardrails/git-hooks`) — the agent's tool hook never sees `git commit`. Aggregate properties
(budget, cross-record consistency, gates) are CI-only.

## Index

| Script | Rule | Hook | CI |
|---|---|---|---|
| `commit-refs-footer.sh` | RULE-PM-02 — `Refs: T-NNN` or `RFC-NNN` | git `commit-msg` | `--ci-range` |
| `instruction-budget.sh` | instruction budget, descending ratchet | — | ✅ |
| `task-spec-shape.sh` | RULE-TASK-01 / RULE-UOW-01 (new only) | ✅ | `--ci-range` |
| `decision-status-consistency.sh` | ADR/RFC status coherence, fail-closed | — | ✅ |
| `uow-gate.sh` | executable Unit of Work exit gate (G5) | — | `--all` |
| `../planning/decision-index.py --check` | Decision Log index + sensitive hard gate | — | ✅ |

## Allowlists

`allowlists/<rule>.txt` — one exact violation line per entry, followed by `# reason`. An exception
without a reason is a defect.

## Writing a domain guardrail (~30 lines)

Your survival conditions are where most of the value is ("money is never a float", "no vendor SDK in
domain code", "cache namespace X only through service Y"). Template:

```bash
#!/usr/bin/env bash
# scripts/guardrails/no-float-money.sh — RULE-CODE-01: money is never a float.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT" || exit 2
RULE="no-float-money"
PATTERN='(double|float)\s+\w*(price|amount|total)'
if [ "${1:-}" = "--hook" ]; then
  json=$(cat)
  hits=$(gr_hook_new_content "$json" | grep -nE "$PATTERN" || true)
  gr_hook_report "$RULE" "$hits"
fi
hits=$(gr_tracked_files "java kt" | xargs -r grep -nE "$PATTERN" | cut -d: -f1,2 \
  | gr_apply_allowlist "scripts/guardrails/allowlists/${RULE}.txt")
gr_ci_report "$RULE" "$hits"
```

Then: add it to `GUARDRAILS` in `verify-all.sh`, to `.claude/settings.json` (hook), write
`tests/test-<rule>.sh` proving **one passing and one failing case** (a test that only exercises the
happy path stays green with the bug reintroduced), and mark the rule 🔒
in `CLAUDE.md`.

## Portability

Nothing here hardcodes a product path: project specifics come from `governance.env`, and `GOV_ROOT`
points any script at a fixture. Keep it that way — it's what keeps the governance layer extractable.
