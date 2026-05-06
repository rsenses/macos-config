---
description: Analyze how to improve the codebase architecture for AI agents and humans
argument-hint: "[optional focus area]"
---

Use the `orchestrator` skill for this task.

Analyze the codebase architecture and suggest improvements that would make it easier to understand, maintain, and work with.

Focus area, if provided:
$ARGUMENTS

Goal:
Identify architectural, structural, or convention-level friction that makes development harder for humans and AI agents.

This command is for analysis and learning. It should help improve the codebase gradually over time, not trigger broad rewrites.

Rules:

- Do not modify code.
- Do not create files.
- Do not perform refactors.
- Do not propose abstract architecture advice without evidence from the codebase.
- Prefer codebase inspection over assumptions.
- Use `scout` when codebase discovery is needed.
- Use `researcher` only when framework/library/package guidance matters.
- Use `oracle` only for genuinely high-impact architectural tradeoffs.
- Follow AGENTS.md and project-specific architecture/testing rules.
- For framework-specific recommendations, consult official documentation or MCP tools when relevant.
- Keep recommendations practical, incremental, and reversible.
- Do not suggest large rewrites unless there is a clear, strong reason.
- Prefer improvements that reduce ambiguity, coupling, hidden behavior, repeated discovery cost, or unnecessary complexity.
- Prefer framework-native and project-native patterns over new abstractions.
- Distinguish between:
  - real architectural friction,
  - harmless style differences,
  - code that is fine and should not be touched.

Look for:

- unclear boundaries between modules/domains
- files/classes doing too many things
- duplicated patterns
- inconsistent naming or structure
- hard-to-test areas
- hidden side effects
- confusing service/action/model/controller/component responsibilities
- missing or inconsistent conventions
- places where agents repeatedly need excessive context
- places where Laravel/framework-native features could replace custom code
- unnecessary abstractions, shallow layers, or over-engineered structures
- opportunities to improve docs, naming, file layout, or small abstractions
- opportunities to make future AI-assisted changes safer and cheaper

Output:

## Summary

<Brief diagnosis. Mention the focus area if one was provided.>

## Evidence Inspected

<List the main files, directories, patterns, or flows inspected. Keep concise.>

## Main Friction Points

For each friction point include:

- evidence
- why it matters
- who it affects: humans, agents, tests, CI/CD, maintenance

## Recommended Improvements

For each recommendation include:

- problem
- proposed change
- expected benefit
- risk
- estimated effort: small | medium | large
- confidence: low | medium | high
- suggested timing: now | later | only if touched again

## Quick Wins

<Small improvements with low risk and clear payoff.>

## Bigger Refactors

<Only include if genuinely justified. Explain why they should not be done casually.>

## What Not To Change

<Areas that are fine, stable, or not worth touching now.>

## Lessons / Project Rules To Consider

<Optional: durable lessons that could become future AGENTS.md rules or project conventions. Do not add them automatically.>

## Suggested Next Step

<One practical next action. Prefer the smallest useful step.>
