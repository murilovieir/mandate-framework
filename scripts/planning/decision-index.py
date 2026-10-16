#!/usr/bin/env python3
"""Regenerates the Decision Log index (DECISIONS.md) from the PD bodies, and audits it.

Source of truth = the `## PD-...` headings in DECISIONS.md (live) and DECISIONS_ARCHIVE.md (closed).
The index between the DECISION-INDEX:BEGIN/END markers is rewritten whole — never edit it by hand
(a hand-kept index drifts: the header count, the index rows and the actual bodies end up disagreeing).

Usage:
    python3 scripts/planning/decision-index.py            # regenerate + report
    python3 scripts/planning/decision-index.py --check    # CI: write nothing, exit 1 if stale/broken

Reports: duplicate IDs across files, closed PDs still in the live file, PDs with no Status, invalid
Scope, defaults awaiting ratification, and fired Reopen-triggers.

HARD GATE (both modes): a PD whose Sensitivity is in SENSITIVE_DOMAINS (governance.env), closed as
DEFAULT_APPLIED without an explicit ratification, fails the script. The escalation rule stops being
procedural and becomes mechanical. Ratification by a role (`owner:billing (...)`) counts — that is
what makes federating ratification configuration rather than migration.

Reopen-triggers are evaluated in BOTH modes — `--check` included. A trigger that the CI path never
evaluates is prose in a structured costume. Two machine-resolvable forms:
    - **Reopen-trigger:** T-123 done            → fires when that story's status is `done`
    - **Reopen-trigger:** cmd: <shell command>  → fires when the command exits 0 (a data query)
Anything else is listed as "watch" — honest about not being mechanical.
A fired trigger is an action item, not a broken state: it is printed (also in CI), never fails the run.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(os.environ.get("GOV_ROOT") or Path(__file__).resolve().parents[2])
LIVE = ROOT / "DECISIONS.md"
ARCHIVE = ROOT / "DECISIONS_ARCHIVE.md"
BEGIN, END = "<!-- DECISION-INDEX:BEGIN -->", "<!-- DECISION-INDEX:END -->"
CLOSED = {"RESOLVED", "DEFAULT_APPLIED", "BLOCKER_RESOLVED"}
SCOPES = {"local", "org"}

HEAD_RE = re.compile(r"^## (PD-[A-Za-z0-9_-]+)\s*(?:—|-)?\s*(.*)$")
FIELD_RE = re.compile(r"^\s*-\s*\*\*([A-Za-z-]+):\*\*\s*(.*)$")
TASK_RE = re.compile(r"\b(T-\d+[a-z]?)\b")


def config(key, default=""):
    env = ROOT / "governance.env"
    if env.is_file():
        for line in env.read_text(encoding="utf-8").splitlines():
            m = re.match(rf'^{key}="?(.*?)"?\s*$', line)
            if m:
                return m.group(1)
    return default


SENSITIVE = set(config("SENSITIVE_DOMAINS", "security billing privacy public-api schema").split())


def parse(path, origin):
    entries, cur, in_fence = [], None, False
    if not path.is_file():
        return entries
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("```"):
            in_fence = not in_fence      # the entry template inside a code fence is not a PD
            continue
        if in_fence:
            continue
        m = HEAD_RE.match(line)
        if m:
            cur = {"id": m.group(1), "title": m.group(2).strip(), "origin": origin}
            entries.append(cur)
            continue
        f = FIELD_RE.match(line)
        if cur is not None and f and f.group(1) not in cur:
            cur[f.group(1)] = f.group(2).strip()
    for e in entries:
        st = e.get("Status", "")
        sm = re.match(r"`?([A-Z_]+)`?", st)
        e["status"] = sm.group(1) if sm else None
        sv = re.match(r"`?([a-z-]+)`?", e.get("Sensitivity", ""))
        e["sensitivity"] = sv.group(1) if sv else None
        sc = re.match(r"`?([a-z-]+)`?", e.get("Scope", ""))
        e["scope"] = sc.group(1) if sc else None
        e["ratified"] = e.get("Ratified-by")
        e["trigger"] = e.get("Reopen-trigger")
    return entries


def unratified(e):
    r = (e["ratified"] or "").strip()
    return r == "" or r.startswith("—") or r == "-"


def story_status(sid):
    for f in (ROOT / "docs" / "backlog").glob(f"*/{sid}-*.md"):
        for line in f.read_text(encoding="utf-8").splitlines()[:15]:
            if line.startswith("status:"):
                return line.split(":", 1)[1].strip().split()[0]
    return None


def check_triggers(entries):
    fired, watch = [], []
    for e in entries:
        if e["status"] != "DEFERRED" or not e["trigger"]:
            continue
        t = e["trigger"]
        if t.startswith("cmd:"):
            cmd = t[4:].strip()
            try:
                ok = subprocess.run(cmd, shell=True, cwd=ROOT, timeout=30,
                                    capture_output=True).returncode == 0
            except subprocess.TimeoutExpired:
                watch.append(f"{e['id']} — trigger command timed out: {cmd[:70]}")
                continue
            (fired if ok else watch).append(
                f"{e['id']} — {'condition met' if ok else 'condition not met'}: `{cmd[:70]}`")
            continue
        done = [s for s in TASK_RE.findall(t) if story_status(s) == "done"]
        if done:
            fired.append(f"{e['id']} — {', '.join(done)} done: {t[:80]}")
        else:
            watch.append(f"{e['id']} — {t[:80]}{'' if TASK_RE.search(t) else '  (not machine-resolvable)'}")
    return fired, watch


def main():
    check = "--check" in sys.argv
    if not LIVE.is_file():
        print(f"FATAL: {LIVE} not found"); sys.exit(2)
    live, arch = parse(LIVE, "live"), parse(ARCHIVE, "archive")
    every = live + arch
    problems, seen = [], {}
    for e in every:
        if e["id"] in seen:
            problems.append(f"DUPLICATE: {e['id']} in '{seen[e['id']]}' and '{e['origin']}'")
        seen[e["id"]] = e["origin"]
        if e["status"] is None:
            problems.append(f"NO STATUS: {e['id']} ({e['origin']})")
        if e["scope"] is not None and e["scope"] not in SCOPES:
            problems.append(f"INVALID SCOPE: {e['id']} — '{e['scope']}' (allowed: local | org)")
    misplaced = [e["id"] for e in live if e["status"] in CLOSED]
    if misplaced:
        problems.append(f"CLOSED but still in DECISIONS.md (move to the archive): {', '.join(misplaced)}")

    violations = [f"{e['id']} (sensitivity={e['sensitivity']}, {e['origin']})" for e in every
                  if e["sensitivity"] in SENSITIVE and e["status"] == "DEFAULT_APPLIED" and unratified(e)]
    if violations:
        print("HARD GATE VIOLATED — sensitive PD closed as DEFAULT_APPLIED without ratification "
              "(escalation rule: a sensitive default NEVER closes silently):")
        for v in violations:
            print(f"  - {v}")
        print("Fix: reclassify as NEEDS_VALIDATION and escalate, or record the explicit ratification "
              "(Ratified-by: <decider|owner:area> (YYYY-MM-DD, ...)).")
        sys.exit(1)

    counts = {}
    for e in every:
        counts[e["status"] or "?"] = counts.get(e["status"] or "?", 0) + 1
    summary = " · ".join(f"{k}: {v}" for k, v in sorted(counts.items(), key=lambda kv: -kv[1]))
    rows = [f"| {e['id']} | `{e['status'] or '?'}` | {e['scope'] or '—'} | {e['origin']} |"
            for e in sorted(every, key=lambda e: e["id"])]
    table = "\n".join([f"**Total: {len(every)}** ({summary})", "",
                       "| PD | Status | Scope | Location |", "|---|---|---|---|"] + rows)
    text = LIVE.read_text(encoding="utf-8")
    if BEGIN not in text or END not in text:
        print("FATAL: index markers not found in DECISIONS.md"); sys.exit(2)
    i, j = text.index(BEGIN) + len(BEGIN), text.index(END)
    new = text[:i] + "\n" + table + "\n" + text[j:]

    fired, watch = check_triggers(live)
    for f in fired:
        print(f"⚠️  TRIGGER FIRED — re-evaluate: {f}")

    awaiting = [e["id"] for e in every if e["status"] == "DEFAULT_APPLIED" and unratified(e)]
    if check:
        if new != text or problems:
            print("Index stale or bookkeeping problems:" if new != text else "Bookkeeping problems:")
            for p in problems:
                print(f"  - {p}")
            if new != text:
                print("  - index out of date: run python3 scripts/planning/decision-index.py")
            sys.exit(1)
        print(f"Decision index OK ({len(every)} PDs).")
        return

    LIVE.write_text(new, encoding="utf-8")
    print(f"Index regenerated: {len(live)} live + {len(arch)} archive = {len(every)} PDs ({summary or 'empty'})")
    if awaiting:
        print(f"Awaiting ratification: {', '.join(awaiting)}")
    if watch:
        print(f"Deferred with pending trigger: {len(watch)}")
        for w in watch:
            print(f"    · {w}")
    for p in problems:
        print(f"WARNING: {p}")


if __name__ == "__main__":
    main()
