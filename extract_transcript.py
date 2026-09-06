"""Extract a readable markdown transcript from the prior session JSONL.

Strategy:
  1. Load every event with a uuid and parentUuid.
  2. Build a uuid index, ignoring any that fail to parse.
  3. Find the root (the event whose parentUuid is not in the index).
  4. Walk children in timestamp order.
  5. For each event, emit:
     - USER: only when the message is a real user prompt (string content)
     - ASSISTANT: text content of an assistant message
     - TOOL_CALL: short one-liner per tool_use block
     - TOOL_RESULT: short one-liner per tool_result block
  6. Skip: thinking blocks, attachment events, mode/permission events.
"""
import json
from pathlib import Path

src = Path(r"C:\Users\user\.claude\projects\D--projects-coderank-test\31d2d155-8417-4d3f-b44f-79942a773ece.jsonl")
out = Path(r"D:\projects\coderank_test\TRANSCRIPT.md")

# Pass 1: load every event with a uuid
events = []
with src.open("r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        if e.get("uuid"):
            events.append(e)

uuid_to_event = {e["uuid"]: e for e in events}
print(f"Total events with uuid: {len(events)}")

# Find root: event whose parentUuid is not in the index
roots = [e for e in events if not e.get("parentUuid") or e["parentUuid"] not in uuid_to_event]
print(f"Roots: {len(roots)}")
# Pick the earliest root by timestamp
roots.sort(key=lambda x: x.get("timestamp", ""))
root = roots[0] if roots else None
print(f"Earliest root uuid: {root['uuid'] if root else None}, type={root.get('type') if root else None}, ts={root.get('timestamp') if root else None}")

# Build children map
children = {}
for e in events:
    p = e.get("parentUuid")
    if p and p in uuid_to_event:
        children.setdefault(p, []).append(e)
for v in children.values():
    v.sort(key=lambda x: x.get("timestamp", ""))

# Counters
emitted = {"user": 0, "assistant": 0, "tool_call": 0, "tool_result": 0, "skipped": 0}

def emit_tool_use(name, inp, out_lines):
    if name == "Bash":
        desc = inp.get("description", "")
        cmd = inp.get("command", "")
        out_lines.append(f"\n<TOOL_CALL: Bash — {desc}>\n```\n{cmd}\n```\n")
    elif name == "Read":
        p = inp.get("file_path", "")
        off = inp.get("offset")
        lim = inp.get("limit")
        rng = f" (offset={off}, limit={lim})" if off or lim else ""
        out_lines.append(f"\n<TOOL_CALL: Read `{p}`{rng}>\n")
    elif name == "Write":
        p = inp.get("file_path", "")
        out_lines.append(f"\n<TOOL_CALL: Write `{p}`>\n")
    elif name == "Edit":
        p = inp.get("file_path", "")
        out_lines.append(f"\n<TOOL_CALL: Edit `{p}`>\n")
    elif name == "Grep":
        pat = inp.get("pattern", "")
        glob_ = inp.get("glob", "")
        out_lines.append(f"\n<TOOL_CALL: Grep `{pat}`{(' glob=' + glob_) if glob_ else ''}>\n")
    elif name == "Glob":
        pat = inp.get("pattern", "")
        out_lines.append(f"\n<TOOL_CALL: Glob `{pat}`>\n")
    elif name == "Agent":
        desc = inp.get("description", "")
        out_lines.append(f"\n<TOOL_CALL: Agent — {desc}>\n")
    elif name in ("TaskCreate", "TaskUpdate", "TaskGet", "TaskList",
                  "CronCreate", "CronDelete", "CronList",
                  "EnterPlanMode", "ExitPlanMode",
                  "EnterWorktree", "ExitWorktree",
                  "ListAgents", "SendMessage", "ScheduleWakeup",
                  "TaskOutput", "TaskStop", "Workflow", "Skill",
                  "AskUserQuestion", "NotebookEdit", "ReportFindings"):
        out_lines.append(f"\n<TOOL_CALL: {name}>\n")
    elif name == "WebFetch":
        url = inp.get("url", "")
        out_lines.append(f"\n<TOOL_CALL: WebFetch `{url}`>\n")
    elif name == "WebSearch":
        q = inp.get("query", "")
        out_lines.append(f"\n<TOOL_CALL: WebSearch `{q}`>\n")
    else:
        out_lines.append(f"\n<TOOL_CALL: {name}>\n")

def emit(e, out_lines):
    ts = e.get("timestamp", "").split(".")[0].replace("T", " ")
    t = e.get("type")
    if t == "attachment":
        emitted["skipped"] += 1
        return
    if t not in ("user", "assistant"):
        emitted["skipped"] += 1
        return
    msg = e.get("message", {})
    content = msg.get("content", [])

    if t == "user":
        # String content = real user prompt
        if isinstance(content, str) and content.strip():
            out_lines.append(f"\n### USER ({ts})\n\n{content.strip()}\n")
            emitted["user"] += 1
            return
        # List content = tool_result wrappers
        if isinstance(content, list):
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_result":
                    inner = block.get("content", "")
                    if isinstance(inner, list):
                        inner = "".join(
                            b.get("text", "") if isinstance(b, dict) else str(b)
                            for b in inner
                        )
                    inner = str(inner)
                    is_err = block.get("is_error", False)
                    snippet = inner[:400]
                    if not snippet.strip():
                        continue
                    tag = "TOOL_RESULT (ERROR)" if is_err else "TOOL_RESULT"
                    out_lines.append(f"\n<{tag}>\n```\n{snippet}\n```\n")
                    emitted["tool_result"] += 1
        return

    if t == "assistant":
        if isinstance(content, str):
            if content.strip():
                out_lines.append(f"\n### ASSISTANT ({ts})\n\n{content.strip()}\n")
                emitted["assistant"] += 1
            return
        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get("type", "")
            if btype == "text":
                text = block.get("text", "").strip()
                if text:
                    out_lines.append(f"\n### ASSISTANT ({ts})\n\n{text}\n")
                    emitted["assistant"] += 1
            elif btype == "tool_use":
                emit_tool_use(block.get("name", "?"), block.get("input", {}), out_lines)
                emitted["tool_call"] += 1
            # Skip thinking

def walk(e, out_lines):
    emit(e, out_lines)
    for child in children.get(e["uuid"], []):
        walk(child, out_lines)

out_lines = [
    "# Prior session transcript",
    "",
    "_Reconstructed from the JSONL log. Real user prompts, assistant replies, and tool calls only — long file contents and internal thinking elided._",
    ""
]

if root:
    walk(root, out_lines)
else:
    out_lines.append("No root found.")

out.write_text("\n".join(out_lines), encoding="utf-8")
print(f"Wrote {out} ({out.stat().st_size:,} bytes, {out.stat().st_size / 1024:.1f} KB)")
print(f"Emitted: {emitted}")
