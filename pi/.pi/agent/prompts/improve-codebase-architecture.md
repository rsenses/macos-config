---
description: Analyze how to improve the codebase architecture for AI agents and humans
argument-hint: "[optional focus area]"
---

Analyze the codebase architecture and suggest improvements that would make it easier to understand, maintain, and work with.

Focus area, if provided:
$ARGUMENTS

Goal:
Identify architectural or structural friction that makes development harder for humans and AI agents.

Rules:

- Do not modify code.
- Do not create files.
- Do not perform broad refactors.
- Prefer codebase inspection over assumptions.
- Use scout/fff if available to locate relevant areas efficiently.
- For framework-specific recommendations, consult official documentation or MCP tools when relevant.
- Keep recommendations practical and incremental.
- Do not suggest large rewrites unless there is a clear, strong reason.
- Prefer improvements that reduce ambiguity, coupling, hidden behavior, or repeated discovery cost.

Look for:

- unclear boundaries between modules/domains
- files/classes doing too many things
- duplicated patterns
- inconsistent naming or structure
- hard-to-test areas
- hidden side effects
- confusing service/action/model responsibilities
- missing conventions
- places where agents repeatedly need excessive context
- opportunities to improve docs, naming, file layout, or small abstractions

Output:

## Summary

<Brief diagnosis>

## Main Friction Points

- ...

## Recommended Improvements

For each recommendation include:

- problem
- proposed change
- expected benefit
- risk
- estimated effort: small | medium | large

## Quick Wins

- ...

## Bigger Refactors

- ...

## What Not To Change

<Areas that are fine or not worth touching now>

## Suggested Next Step

<One practical next action>
