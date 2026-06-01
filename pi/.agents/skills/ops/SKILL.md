---
name: ops
description: Memory management (.ai/), context engineering, and subagent orchestration.
---

# Ops: System Control and Memory

## 1. Memory Management (.ai/)

Use project-relative paths. Do not write outside the `.ai/` directory.

### Tools:

- `create_session_plan(slug)`: Use this at the start of any non-trivial task. It handles Session ID and Date automatically.
- `add_daily_note(note)`: Use this after meaningful work. It appends to the correct daily file with a timestamp.

### Structure and Rules:

- `.ai/MEMORY.md`: Durable knowledge (decisions, preferences, pitfalls). Update only after stable lessons emerge.
- `.ai/TASKS.md`: Pending work. Use `[[wiki-links]]` for complex plans.
- **Session Plans**: Only ONE plan per session. Use the tool to find or create it.
- **Daily Notes**: Do not write manually to daily files; use the `add_daily_note` tool.

### Authority Order:

1. Current instruction > 2. Project rules (AGENTS.md) > 3. Session plan > 4. MEMORY.md > 5. TASKS.md.

## 2. Context Engineering

- **Hierarchy:** Project Rules > Specs/Architecture > Source Code > Error Output > History.
- **Selective Loading:** Read only relevant files. For `Simple` tasks, avoid over-investigating.
- **Confusion Management:** If Specs and Code conflict, or requirements are missing, **STOP and ask**. Do not guess.

## 3. Orchestration and Subagents

The main agent is the authority. Subagents are specific tools.

### Roles and Contracts:

- **scout**: Codebase discovery and mapping. No implementation.
- **researcher**: External documentation and framework behavior.
- **planner**: Concrete implementation plans from context and requirements. No code changes.
- **worker**: Surgical implementation. Requires an explicit validation policy.

The current subagent set includes scout, researcher, planner, and worker. Use the main agent for final decisions and for coordination between planning and implementation.

### Validation Policies (for worker):

- `no-tests`, `targeted-check` (specific command), `add-test`, `test-first` (bug repro), `defer-validation`.

### Golden Rules:

- Do not launch parallel writers on overlapping files.
- Prefer "fresh" context for scout/researcher and "forked" for worker.
- Provide short contracts: Goal, Context, Success Criteria, and Stop Rules.

## 4. Direct Questions

When the user asks a direct conceptual or explanatory question, answer directly first.
Do not inspect files, run commands, or use subagents unless repository-specific evidence is required.

## 5. Clarification Gate

Do not ask for confirmation by default.

Ask one focused clarification question only when:

- the request is ambiguous,
- multiple interpretations would lead to different code,
- the change touches critical config, data, security, or production behavior,
- or the requested outcome is unclear.

For clear surgical requests, execute directly.

## 6. Critical Configuration Safety

Before editing critical local/system configuration files, create a timestamped backup and explain the intended change.

Critical files include `.env`, SSH config, credentials/password-manager config, deployment config, production config, shell/profile files, and database/client configuration.

Do not edit these files unless the user explicitly approves the change.

## 7. Debugging Delegation

Keep nuanced debugging and diagnosis in the main agent when the user has already corrected an interpretation.

Use `scout` for locating evidence and `researcher` for documentation, but keep root-cause judgment in the main agent unless the task is isolated and mechanical.
