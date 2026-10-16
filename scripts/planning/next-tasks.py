#!/usr/bin/env python3
"""next-tasks.py — backlog stories READY to build, with leverage, rigor, model and parallel batches.

Source of truth = story specs (front matter + "Expected files"), never the board (RULE-PM-01).

Usage:
    python3 scripts/planning/next-tasks.py              # ready stories + parallel batches
    python3 scripts/planning/next-tasks.py --blocked    # also blocked stories and what they miss
    python3 scripts/planning/next-tasks.py --self-check # CI: duplicate IDs, dangling deps, cycles

Ready = status todo|in-progress, no superseded_by, and EVERY depends_on is done.
Columns:
    RIGOR  N0 (no code in expected files) · N1 (code) · N2 (an expected file matches SENSITIVE_PATHS)
    MODEL  advisory model tier: N2 → strongest · N1 → standard · N0 → fast. Sensitive never goes down.
    PAR    ok = has checkable expected files · rev = none → manual review before parallelizing.
           Missing data is NEVER treated as safe.
    UNBLK  stories that list this one in depends_on · +READY stories that become ready if it closes.
Batches group ready stories whose expected files don't collide — ADVISORY: confirm before dispatching.
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(os.environ.get("GOV_ROOT") or Path(__file__).resolve().parents[2])
BACKLOG = ROOT / "docs" / "backlog"
EST = {"S": 0, "M": 1, "L": 2}
CODE_EXT = re.compile(r"\.(py|ts|tsx|js|jsx|java|kt|go|rs|rb|cs|php|swift|sql|proto)$")
PATH_RE = re.compile(r"`([^`]+)`")


def config(key, default=""):
    env = ROOT / "governance.env"
    if env.is_file():
        for line in env.read_text(encoding="utf-8").splitlines():
            m = re.match(rf'^{key}="?(.*?)"?\s*$', line)
            if m:
                return m.group(1)
    return default


SENSITIVE_PATHS = re.compile(config("SENSITIVE_PATHS", r"(migrations?/|/auth|/security|/billing)"))


def front(text):
    lines = text.splitlines()
    fm = {}
    if not lines or lines[0].strip() != "---":
        return None
    for ln in lines[1:]:
        if ln.strip() == "---":
            return fm
        m = re.match(r"^([A-Za-z_]+):\s*(.*?)\s*(#.*)?$", ln)
        if m:
            v = m.group(2).strip()
            fm[m.group(1)] = [x.strip() for x in v.strip("[]").split(",") if x.strip()] if v.startswith("[") else v
    return None


def expected_files(text):
    out, on = [], False
    for ln in text.splitlines():
        if re.match(r"^#{2,3} (Expected files|Arquivos esperados)", ln):
            on = True
            continue
        if on and re.match(r"^#{2,3} ", ln):
            break
        if on and ln.startswith("- "):
            m = PATH_RE.search(ln)
            if m:
                out.append(m.group(1))
    return out


def load():
    stories = {}
    dupes = []
    for f in sorted(BACKLOG.glob("*/T-*.md")):
        text = f.read_text(encoding="utf-8")
        fm = front(text)
        if fm is None or "id" not in fm:
            continue  # supporting document, not a story
        sid = fm["id"]
        if sid in stories:
            dupes.append(f"{sid}: {stories[sid]['file']} and {f.relative_to(ROOT)}")
        files = expected_files(text)
        code = [p for p in files if CODE_EXT.search(p)]
        rigor = "N2" if any(SENSITIVE_PATHS.search(p) for p in files) else ("N1" if code else "N0")
        stories[sid] = {
            "id": sid, "file": str(f.relative_to(ROOT)), "title": fm.get("title", ""),
            "status": fm.get("status", "todo"), "est": fm.get("estimate", "M"),
            "uow": fm.get("uow", "?"), "deps": fm.get("depends_on", []) or [],
            "superseded": fm.get("superseded_by"), "files": set(files), "rigor": rigor,
        }
    return stories, dupes


def is_ready(s, stories):
    return (s["status"] in ("todo", "in-progress") and not s["superseded"]
            and all(stories.get(d, {}).get("status") == "done" for d in s["deps"]))


def self_check(stories, dupes):
    errs = [f"duplicate story id — {d}" for d in dupes]
    for s in stories.values():
        for d in s["deps"]:
            if d not in stories:
                errs.append(f"{s['id']} depends on {d}, which does not exist")
    state = {}

    def visit(n, path):
        if state.get(n) == 1:
            errs.append("dependency cycle: " + " → ".join(path + [n]))
            return
        if state.get(n) == 2 or n not in stories:
            return
        state[n] = 1
        for d in stories[n]["deps"]:
            visit(d, path + [n])
        state[n] = 2

    for n in stories:
        visit(n, [])
    for e in errs:
        print(f"FAIL [next-tasks]: {e}")
    if not errs:
        print(f"OK [next-tasks]: {len(stories)} stories, no duplicates, dangling deps or cycles.")
    return 1 if errs else 0


def main():
    stories, dupes = load()
    if "--self-check" in sys.argv:
        sys.exit(self_check(stories, dupes))
    done = {k for k, s in stories.items() if s["status"] == "done"}
    ready = [s for s in stories.values() if is_ready(s, stories)]
    for s in stories.values():
        s["unblk"] = sum(1 for o in stories.values() if s["id"] in o["deps"])
        s["plus"] = sum(1 for o in stories.values()
                        if o["status"] in ("todo", "blocked") and s["id"] in o["deps"]
                        and all(d in done or d == s["id"] for d in o["deps"]))
    ready.sort(key=lambda s: (-s["plus"], -s["unblk"], s["status"] != "in-progress", EST.get(s["est"], 1), s["id"]))
    model = {"N2": "strongest", "N1": "standard", "N0": "fast"}
    print(f"DONE: {len(done)} | TOTAL: {len(stories)} | READY: {len(ready)}\n")
    if ready:
        print(f"{'STORY':<8} {'EST':<3} {'STATUS':<12} {'UOW':<5} {'RIGOR':<5} {'MODEL':<9} {'PAR':<3} {'UNBLK':>5} {'+READY':>6}  TITLE")
        for s in ready:
            par = "ok" if s["files"] else "rev"
            print(f"{s['id']:<8} {s['est']:<3} {s['status']:<12} {s['uow']:<5} {s['rigor']:<5} "
                  f"{model[s['rigor']]:<9} {par:<3} {s['unblk']:>5} {s['plus']:>6}  {s['title'][:70]}")
    # parallel batches: greedy grouping of ready stories with disjoint expected files
    safe = [s for s in ready if s["files"]]
    batches, collisions = [], []
    for s in safe:
        for b in batches:
            clash = [o for o in b if o["files"] & s["files"]]
            if not clash:
                b.append(s)
                break
            collisions.extend(f"{s['id']} × {o['id']}: {', '.join(sorted(o['files'] & s['files']))}" for o in clash)
        else:
            batches.append([s])
    multi = [b for b in batches if len(b) > 1]
    if multi:
        print("\nPARALLEL BATCHES (advisory — confirm file collisions before dispatching):")
        for i, b in enumerate(multi, 1):
            print(f"  batch {i}: " + ", ".join(f"{s['id']} ({model[s['rigor']]})" for s in b))
    review = [s["id"] for s in ready if not s["files"]]
    if review:
        print(f"\nMANUAL REVIEW (no expected files — never parallel-safe by omission): {', '.join(review)}")
    if collisions:
        print("\nCOLLISIONS:")
        for c in sorted(set(collisions)):
            print(f"  {c}")
    if "--blocked" in sys.argv:
        blocked = [s for s in stories.values() if s["status"] in ("todo", "blocked") and not is_ready(s, stories)]
        if blocked:
            print("\nBLOCKED:")
            for s in sorted(blocked, key=lambda s: s["id"]):
                miss = [d for d in s["deps"] if stories.get(d, {}).get("status") != "done"]
                print(f"  {s['id']:<8} waits on {', '.join(miss) or '(status: blocked)'} — {s['title'][:60]}")


if __name__ == "__main__":
    main()
