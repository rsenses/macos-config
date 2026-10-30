---
name: writing-for-agents
description: "Use when creating, editing, or reviewing skills, Pi prompts, system guidance, AGENTS.md, or other agent-facing instructions, including their descriptions, trigger conditions, structure, and invocation behavior."
---

# Writing for Agents

For skills, prompts, `APPEND_SYSTEM.md`, `AGENTS.md` and agent-referenced documents, aim for predictable behavior with minimal useful context.

## 1. Identify the contract

Before editing, inspect the harness contract and the current document:

- How is this file discovered and invoked?
- Is it user-invoked or model-invoked?
- Which tools, arguments, files, and project conventions does it actually have?
- Which existing document is the source of truth for the behavior being described?

User-invoked documents need a human-facing description and explicit entry point; model-invoked documents need concrete triggers. Do not silently change invocation mode.

## 2. Put information at the right level

Keep the main workflow in the document and disclose branch-specific reference material behind a clear pointer. Every step needs a checkable completion condition. Prefer the smallest document that changes behavior:

- **Context load** is always-paid text in system guidance or descriptions.
- **Cognitive load** is the human's cost of remembering which document to use.
- **Progressive disclosure** keeps branch-specific detail out of the common path.

Do not repeat reliably exposed facts such as scripts or directory listings. Keep a short cache only for conventions, rationale or failure modes expensive to rediscover.

## 3. Prune and sharpen

Keep sentences that change behavior, distinguish a branch or protect a guardrail. Remove no-ops, duplicate rules, stale commands and conflicting fallbacks. Prefer positive instructions; retain prohibitions protecting hard invariants and pair them with safe actions.

Use precise leading words such as **tight loop**, **public seam**, **vertical slice**, and **single source of truth** when they replace repeated explanations. Keep one meaning in one authoritative place and point to it from other documents.

## 4. Final checks

Before finishing:

- Re-read the complete changed document.
- Confirm frontmatter, arguments, tool names, paths, and invocation behavior match the harness.
- Check that every referenced file or command exists, or mark it as an intentional external dependency.
- Preserve security, data-integrity, changelog, and manual-only constraints.
- Check the diff for unrelated edits and report the validation actually run.
