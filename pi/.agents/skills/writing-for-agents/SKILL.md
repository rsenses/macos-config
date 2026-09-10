---
name: writing-for-agents
description: Write and maintain skills, Pi prompts, system guidance, and other documents consumed by agents. Use when creating or editing agent-facing instructions or reviewing their structure and triggering behavior.
---

# Writing for Agents

Use this skill when changing a skill, prompt template, `APPEND_SYSTEM.md`, `AGENTS.md`, or another document an agent reaches through a pointer. The goal is predictable behavior with the smallest useful context load.

## 1. Identify the contract

Before editing, inspect the harness contract and the current document:

- How is this file discovered and invoked?
- Is it user-invoked or model-invoked?
- Which tools, arguments, files, and project conventions does it actually have?
- Which existing document is the source of truth for the behavior being described?

A user-invoked document should have a human-facing description and an explicit entry point. A model-invoked document should state concrete trigger conditions. Do not silently change invocation mode.

## 2. Put information at the right level

Keep the main workflow in the document and disclose branch-specific reference material behind a clear pointer. Every step needs a checkable completion condition. Prefer the smallest document that changes behavior:

- **Context load** is always-paid text in system guidance or descriptions.
- **Cognitive load** is the human's cost of remembering which document to use.
- **Progressive disclosure** keeps branch-specific detail out of the common path.

Do not repeat facts the environment already exposes reliably, such as a package script or directory listing. Preserve a short cache only for conventions, rationale, or failure modes that are otherwise expensive to rediscover.

## 3. Prune and sharpen

Review each sentence for a behavior change, a real branch, or a necessary guardrail. Delete no-ops, duplicated rules, stale commands, and conflicting fallbacks. Prefer positive instructions that name the desired behavior; keep a prohibition only when it protects a hard invariant and pair it with the safe action.

Use precise leading words such as **tight loop**, **public seam**, **vertical slice**, and **single source of truth** when they replace repeated explanations. Keep one meaning in one authoritative place and point to it from other documents.

## 4. Final checks

Before finishing:

- Re-read the complete changed document.
- Confirm frontmatter, arguments, tool names, paths, and invocation behavior match the harness.
- Check that every referenced file or command exists, or mark it as an intentional external dependency.
- Preserve security, data-integrity, changelog, and manual-only constraints.
- Check the diff for unrelated edits and report the validation actually run.
