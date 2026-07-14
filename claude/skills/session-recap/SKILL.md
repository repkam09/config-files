---
name: session-recap
description: Record a structured session recap after a debugging, planning, or implementation session with Claude. Use when the user says "wrap up", "record what we did", "session summary", "save our progress", "document this session", "write up what happened", "capture the outcomes", "end of session recap", or similar. Generates a human-readable Markdown file in .repka-ignore/sessions/ scoped to the current repo, and distills key facts into /memories/repo/ for future agent sessions.
metadata:
  version: 0.2.0
---

# Skill: session-recap

## Purpose

Track collaborative sessions (debugging, planning, implementation) so that:

1. **Mark** can return to the work later and know exactly where things stand without re-reading the conversation.
2. **Future agent sessions** can pick up context quickly via `/memories/repo/` instead of starting from zero.

The skill operates in two phases: **session-start** (proactive tracking from the first message) and **session-end** (finalizing the permanent record).

---

## Phase 1 — Session Start (proactive, automatic)

**Trigger:** Mark's very first message describes a problem, error, goal, or task — e.g. "help me debug this", "why is X failing", "I need to implement Y", "can you help me figure out Z". No special phrasing required. If the opening message is clearly initiating a work session rather than asking a quick one-off factual question, Phase 1 fires immediately as part of formulating your first response.

**Heuristic — session vs. one-off:**
- One-off (no tracking): "What does this Terraform variable do?", "What's the syntax for X?"
- Session (track it): anything involving debugging an error, investigating a system, planning or implementing a change, or work that will likely take multiple back-and-forth turns.

**Do this as part of your very first response, without being asked:**

1. Derive a `<topic-slug>` (2–5 lowercase hyphenated words) from the stated goal.
2. Create the stub session file at `.repka-ignore/sessions/YYYY-MM-DD-<topic-slug>.md` (see structure below). Populate only the sections you can fill from the opening message: Goals, Context & Background. Leave the rest with placeholder comments.
3. Create (or overwrite) `/memories/session/session-recap-wip.md` — a compact running log used internally throughout the session (see WIP log format below).
4. Include a single line at the end of your response, e.g.: *"Session tracked → `.repka-ignore/sessions/2026-07-10-eks-node-oom.md`"*

If `.repka-ignore/sessions/` does not exist in the repo, create the directory.

### WIP log format (`/memories/session/session-recap-wip.md`)

```markdown
# WIP: <topic-slug>
**Session file:** .repka-ignore/sessions/YYYY-MM-DD-<topic-slug>.md

## Goals
- <bullet from initial ask>

## Log
<!-- Append entries here as work progresses. Newest at bottom. -->
- [HH:MM] <brief fact, finding, command, or state change>
```

**Update the WIP log** at natural checkpoints during the session:
- After confirming or ruling out a hypothesis
- After a significant command is run and its output is meaningful
- After a config or code change is made
- When a blocker is hit or unblocked
- When scope changes

Keep entries terse (one line each). This log feeds Phase 2.

---

## Phase 2 — Session End (finalize)

**Trigger:** Mark says "wrap up", "record what we did", "session summary", "save our progress", "document this session", "write up what happened", "capture the outcomes", "end of session recap", or similar.

**Workflow:**

1. Read `/memories/session/session-recap-wip.md` to reconstruct the full session arc.
2. Briefly summarize the session back to Mark (2–5 bullets) and confirm accuracy — unless he says to just write it.
3. Write (or overwrite) the full `.repka-ignore/sessions/` file using the structure below.
4. Update `/memories/repo/` with distilled key facts (see below).
5. Report both file paths.

---

## Session file structure

```markdown
# Session Recap: <Human-Readable Topic Title>
**Date:** YYYY-MM-DD  
**Repo / Context:** <repo name or folder>  
**Status:** In Progress | Resolved | Abandoned | Handed Off

## Goals
<!-- What were we trying to accomplish? Bullet list. -->

## Context & Background
<!-- Relevant system state, prior decisions, constraints that shaped the session. -->

## What Was Tried
<!-- Ordered log of significant approaches, commands, changes, and why each was attempted. -->
<!-- Include commands or config snippets where useful. -->

## Outcomes
<!-- What actually worked. What did not. What is in an uncertain/partial state. -->

## Current State
<!-- Where does the work stand RIGHT NOW? What is deployed/changed/broken/waiting? -->
<!-- This is the section Mark will re-read when picking back up. Be precise. -->

## Open Questions / Blockers
<!-- Things that are unanswered or need external input. -->

## Next Steps
<!-- Concrete, ordered list of what to do next. -->

## Key Commands / Snippets
<!-- Any commands, config fragments, or code worth preserving for quick reference. -->
```

### File naming

```
.repka-ignore/sessions/YYYY-MM-DD-<topic-slug>.md
```

- Use today's date (the session date, not the finalization date if different).
- If a file with the same date + slug already exists, append `-2`, `-3` rather than overwriting (unless you created it in Phase 1, in which case overwrite it).

---

## /memories/repo/ update

After writing the session file, check whether a relevant `/memories/repo/` file exists (look for files matching the topic area). Then:

- **If an existing file covers the topic:** append new facts as bullet points. Remove or mark stale any facts that are now outdated.
- **If no relevant file exists:** create one with only the facts genuinely useful in a future session: key commands with args, non-obvious gotchas, current infra state, credential patterns. Keep it terse bullets, not prose.

Do NOT copy the full narrative into memory. Only distill facts that would otherwise require rediscovering.

---

## Tone and style

- Precise and factual, not conversational.
- Bullet lists over prose paragraphs.
- Commands and config in fenced code blocks with language tags.
- State what is known; flag uncertainty explicitly under "Open Questions" rather than hedging inline.
