#!/usr/bin/env bash
# scripts/guardrails/lib.sh — helpers shared by every guardrail.
#
# One source, two consumers: each guardrail runs in CI (scans the repo, exit 1 blocks the merge) and
# as a Claude Code PreToolUse hook (`--hook`: checks only the content about to be written, ALWAYS
# exit 0 — warn mode, never blocks an edit). The mode is chosen explicitly by the `--hook` flag, which
# `.claude/settings.json` passes — never guessed from stdin.
#
# GOV_ROOT overrides the repository root so tests can point a guardrail at a fixture. Without it, a
# test would silently run against the real repo and pass without exercising anything.

set -uo pipefail

REPO_ROOT="${GOV_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Load project knobs (governance.env): KEY="value" lines. Never executes anything else.
gr_load_config() {
  local f="$REPO_ROOT/governance.env" line key val
  [ -f "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    key="${line%%=*}"; val="${line#*=}"
    val="${val%\"}"; val="${val#\"}"
    [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
    # environment wins over the file (tests and CI can override)
    [ -n "${!key:-}" ] || printf -v "$key" '%s' "$val"
    export "${key?}"
  done < "$f"
}
gr_load_config

# ── Hook mode: Claude Code sends the tool_input as JSON on stdin ─────────────

# Content about to be written: `content` (Write) or `new_string` (Edit).
gr_hook_new_content() {
  local json="$1" v
  v=$(jq -r '.tool_input.content // empty' <<<"$json" 2>/dev/null)
  [ -n "$v" ] && { printf '%s' "$v"; return 0; }
  jq -r '.tool_input.new_string // empty' <<<"$json" 2>/dev/null
}

gr_hook_file_path() {
  jq -r '.tool_input.file_path // empty' <<<"$1" 2>/dev/null
}

# Path relative to the repo root (Claude Code always sends absolute paths).
gr_relpath() {
  local p="$1"
  case "$p" in "$REPO_ROOT"/*) printf '%s' "${p#"$REPO_ROOT"/}" ;; *) printf '%s' "$p" ;; esac
}

# Hook verdict — ALWAYS exits 0. The authority that actually blocks is CI.
gr_hook_report() {
  local rule="$1" violations="$2"
  [ -z "$violations" ] && exit 0
  local msg
  msg=$(printf '⚠️  guardrail [%s]: %s' "$rule" "$violations" | head -c 900)
  jq -nc --arg msg "$msg" \
    '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow"}}'
  exit 0
}

# ── CI mode ──────────────────────────────────────────────────────────────────

# Tracked files with the given extensions (space-separated, no dot). Only what git tracks.
gr_tracked_files() {
  local exts="$1" pattern="" e
  for e in $exts; do pattern="${pattern:+$pattern|}\\.${e}\$"; done
  git -C "$REPO_ROOT" ls-files | grep -E "$pattern" || true
}

# Drop violations listed in the allowlist (one exact line per entry: "path[:line] # reason").
gr_apply_allowlist() {
  local allowlist="$1" entries line
  if [ ! -f "$allowlist" ]; then cat; return; fi
  entries=$(grep -vE '^\s*(#|$)' "$allowlist" | sed -E 's/\s*#.*$//; s/\s+$//')
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ -n "$entries" ] && grep -qxF "$line" <<<"$entries"; then continue; fi
    printf '%s\n' "$line"
  done
}

# CI verdict: exit 1 if any violation survived the allowlist.
gr_ci_report() {
  local rule="$1" violations="$2"
  if [ -z "$violations" ]; then
    echo "OK [$rule]: no violations."
    exit 0
  fi
  echo "FAIL [$rule]:"
  echo "$violations" | sed 's/^/  /'
  echo
  echo "Fix it, or add the exact line to scripts/guardrails/allowlists/${rule}.txt with a reason."
  exit 1
}
