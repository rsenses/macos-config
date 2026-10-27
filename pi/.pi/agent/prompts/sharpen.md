---
description: Clarify a vague request into a usable brief without planning or implementation
argument-hint: "<request>"
---

Reformulate this request, without executing it: $ARGUMENTS

Load `ops` for its section 3 brief and section 6 clarification contract. This is a manual preparation command, not authorization to implement.

1. Identify the desired outcome and underlying problem, constraints, behavior to preserve, and non-goals. Distinguish the user's decisions, verified facts, and assumptions. Make the task deeper, not broader: separate unrequested improvements as optional rather than adding them to acceptance.
2. Use the supplied context first. Consult minimal local evidence only to resolve a concrete uncertainty; do not survey the repository. Identify relevant primary sources, methods/tools, and observable checks that could establish the result independently of the agent's explanation. Mark proposed sources and checks as not yet consulted or run.
3. If a missing decision materially changes behavior, ask one focused question using the question tool, or leave that decision explicitly open. Do not choose an implementation to fill the gap. If no request was supplied or recoverable from context, ask for it instead of inventing one.
4. Return a copyable reformulated brief using the existing **Goal**, **Known**, **Evidence**, **Acceptance**, **Checks**, and **Stop** headings. Keep it proportionate to the request; express outcomes and constraints, not an implementation plan.

Do not edit files, save a document by default, launch subagents or other models, design an implementation plan, change plan selection, or invoke `/grill-me` or `/plan` automatically. The user decides whether and how to hand off the brief; direct requests remain valid without this command.
