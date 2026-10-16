#!/usr/bin/env python3
"""Virtual-org census — roster, last activity and token spend per role agent.

Sources (by durability):
  1. Roster:              .claude/agents/*.md (front matter: name, model, tools)
  2. Last opinion:        docs/office/<agent>/ (dated YYYY-MM-DD-*.md files — DURABLE, versioned in
                          git, survives any machine/session)
  3. Invocations+tokens:  ~/.claude/projects/**/*.jsonl (LOCAL transcripts of this machine —
                          ephemeral in remote sandboxes; cover only sessions that ran here)

Token correlation: each Agent tool launch is a tool_use with `subagent_type`; the matching
tool_result carries the `agentId`; <task-notification>s carry `<task-id>` (== agentId) and CUMULATIVE
`<subagent_tokens>` (a resumed agent re-notifies its running total). So tokens per execution = MAX of
subagent_tokens per task-id, never the sum of notifications.

Usage:  python3 census.py [--json]
"""

import json
import os
import re
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
AGENTS_DIR = REPO / ".claude" / "agents"
OFFICE_DIR = REPO / "docs" / "office"
PROJECTS_DIR = Path.home() / ".claude" / "projects"

RE_AGENT_ID = re.compile(r"agentId:\s*([a-z0-9]+)")
RE_TASK_ID = re.compile(r"<task-id>([a-z0-9]+)</task-id>")
RE_TOKENS = re.compile(r"<subagent_tokens>(\d+)</subagent_tokens>")
RE_DATED_FILE = re.compile(r"^(\d{4}-\d{2}-\d{2})")


def parse_frontmatter(path: Path) -> dict:
    """Simple keys (name/model/tools) from YAML front matter, without pyyaml."""
    fm = {}
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        return fm
    for line in lines[1:]:
        if line.strip() == "---":
            break
        m = re.match(r"^(name|model|tools):\s*(.+)$", line)
        if m:
            fm[m.group(1)] = m.group(2).strip()
    return fm


def load_roster() -> dict:
    roster = {}
    if AGENTS_DIR.is_dir():
        for f in sorted(AGENTS_DIR.glob("*.md")):
            fm = parse_frontmatter(f)
            name = fm.get("name", f.stem)
            roster[name] = {"model": fm.get("model", "inherit"), "tools": fm.get("tools", "*")}
    return roster


def office_last_activity() -> dict:
    """Most recent opinion date per agent, from the YYYY-MM-DD prefix of files in office/."""
    last = {}
    if OFFICE_DIR.is_dir():
        for d in OFFICE_DIR.iterdir():
            if not d.is_dir():
                continue
            dates = [m.group(1) for f in d.glob("*.md") if (m := RE_DATED_FILE.match(f.name))]
            count = sum(1 for _ in d.glob("*.md"))
            if dates:
                last[d.name] = {"last": max(dates), "count": count}
            elif count:
                last[d.name] = {"last": "?", "count": count}
    return last


def iter_transcript_lines():
    if not PROJECTS_DIR.is_dir():
        return
    for jsonl in PROJECTS_DIR.glob("*/*.jsonl"):
        with open(jsonl, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                try:
                    yield json.loads(line)
                except (json.JSONDecodeError, ValueError):
                    continue


def scan_transcripts():
    """One pass over transcripts: launches, agentId→type map, tokens per task-id."""
    launches = {}          # tool_use_id -> {type, desc, ts, sidechain}
    agent_of_tooluse = {}  # agentId -> tool_use_id
    notif = {}             # task-id -> {tokens: max, last_ts}
    n_files = len(list(PROJECTS_DIR.glob("*/*.jsonl"))) if PROJECTS_DIR.is_dir() else 0

    for obj in iter_transcript_lines():
        ts = obj.get("timestamp", "")
        content = (obj.get("message") or {}).get("content")

        if isinstance(content, str):
            if "<task-notification>" in content:
                for tid, tok in zip(RE_TASK_ID.findall(content), RE_TOKENS.findall(content) or []):
                    cur = notif.setdefault(tid, {"tokens": 0, "last_ts": ""})
                    cur["tokens"] = max(cur["tokens"], int(tok))
                    cur["last_ts"] = max(cur["last_ts"], ts)
                # a notification without a usage block (e.g. partial) still updates last_ts
                for tid in RE_TASK_ID.findall(content):
                    cur = notif.setdefault(tid, {"tokens": 0, "last_ts": ""})
                    cur["last_ts"] = max(cur["last_ts"], ts)
            continue

        if not isinstance(content, list):
            continue
        for item in content:
            if not isinstance(item, dict):
                continue
            if item.get("type") == "tool_use" and item.get("name") in ("Agent", "Task"):
                inp = item.get("input") or {}
                launches[item["id"]] = {
                    "type": inp.get("subagent_type") or "general-purpose",
                    "desc": inp.get("description", ""),
                    "ts": ts,
                    "sidechain": bool(obj.get("isSidechain")),
                }
            elif item.get("type") == "tool_result":
                c = item.get("content")
                text = c if isinstance(c, str) else (
                    " ".join(x.get("text", "") for x in c if isinstance(x, dict)) if isinstance(c, list) else "")
                m = RE_AGENT_ID.search(text)
                if m and item.get("tool_use_id") in launches:
                    agent_of_tooluse[m.group(1)] = item["tool_use_id"]

    return launches, agent_of_tooluse, notif, n_files


def aggregate():
    roster = load_roster()
    office = office_last_activity()
    launches, agent_map, notif, n_files = scan_transcripts()

    stats = defaultdict(lambda: {"execs": 0, "execs_side": 0, "tokens": 0,
                                 "tokens_execs": 0, "last_invoke": ""})
    for tuid, info in launches.items():
        s = stats[info["type"]]
        s["execs"] += 1
        if info["sidechain"]:
            s["execs_side"] += 1
        s["last_invoke"] = max(s["last_invoke"], info["ts"])

    for agent_id, tuid in agent_map.items():
        info = launches.get(tuid)
        if not info:
            continue
        n = notif.get(agent_id)
        if n:
            s = stats[info["type"]]
            s["tokens"] += n["tokens"]
            if n["tokens"]:
                s["tokens_execs"] += 1
            s["last_invoke"] = max(s["last_invoke"], n["last_ts"])

    return roster, office, stats, n_files


def fmt_date(iso: str) -> str:
    if not iso:
        return "—"
    try:
        return datetime.fromisoformat(iso.replace("Z", "+00:00")).astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M")
    except ValueError:
        return iso[:16]


def fmt_tokens(n: int) -> str:
    return f"{n/1000:.1f}k" if n else "—"


def main():
    roster, office, stats, n_files = aggregate()

    if "--json" in sys.argv:
        out = {name: {
            "model": meta["model"],
            "office_opinions": office.get(name, {}).get("count", 0),
            "last_opinion": office.get(name, {}).get("last"),
            "local_execs": stats.get(name, {}).get("execs", 0),
            "local_tokens_total": stats.get(name, {}).get("tokens", 0),
            "last_local_invocation": stats.get(name, {}).get("last_invoke") or None,
        } for name, meta in roster.items()}
        print(json.dumps(out, ensure_ascii=False, indent=2))
        return

    all_names = list(roster)
    extras = sorted(set(stats) - set(roster))  # types invoked outside the roster (general-purpose, Explore…)

    def sort_key(name):
        return -(stats.get(name, {}).get("tokens", 0)), name
    all_names.sort(key=sort_key)

    print(f"VIRTUAL ORG CENSUS — {len(roster)} agents in roster · "
          f"{n_files} local transcript(s) scanned\n")
    header = (f"{'AGENT':<16} {'MODEL':<8} {'OPINIONS':>9} {'LAST OPINION':>12} "
              f"{'EXECS':>5} {'TOKENS':>9} {'AVG/EXEC':>10} {'LAST INVOKE (local)':>22}")
    print(header)
    print("-" * len(header))
    for name in all_names:
        meta = roster[name]
        off = office.get(name, {})
        st = stats.get(name, {})
        execs = st.get("execs", 0)
        tokens = st.get("tokens", 0)
        tex = st.get("tokens_execs", 0)
        avg = fmt_tokens(tokens // tex) if tex else "—"
        side = f" ({st['execs_side']}†)" if st.get("execs_side") else ""
        print(f"{name:<16} {meta['model']:<8} {off.get('count', 0):>9} "
              f"{off.get('last', '—'):>12} {str(execs) + side:>5} {fmt_tokens(tokens):>9} "
              f"{avg:>10} {fmt_date(st.get('last_invoke', '')):>22}")

    if extras:
        print("\nInvoked outside the roster (generic/harness types):")
        for name in extras:
            st = stats[name]
            tex = st.get("tokens_execs", 0)
            avg = fmt_tokens(st["tokens"] // tex) if tex else "—"
            print(f"  {name:<20} execs={st['execs']:<3} tokens={fmt_tokens(st['tokens']):<8} "
                  f"avg={avg:<8} last={fmt_date(st['last_invoke'])}")

    print("""
Reading notes:
  · OPINIONS/LAST OPINION = durable trail in docs/office/<agent>/ (git) — the best historical source.
  · EXECS/TOKENS = local transcripts (~/.claude/projects) — only sessions on THIS machine; ephemeral in
    remote sandboxes. † = execs launched by another agent (sidechain), whose tokens show up aggregated
    in the PARENT agent when the child emits no notification of its own.
  · TOKENS per exec = cumulative max per task (a resumed agent re-notifies its running total).
  · AVG/EXEC counts only execs with recorded usage.""")


if __name__ == "__main__":
    main()
