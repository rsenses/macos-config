# Plan: update Pi prompts for memory extension

- Review all prompt templates under `pi/.pi/agent/prompts/`.
- Identify prompts that involve planning, implementation, review, finalization, or decisions.
- Add concise memory-skill instructions only where they improve behavior and avoid duplicating the extension's always-injected policy too much.
- Keep lightweight prompts that are purely conversational or one-off mostly unchanged unless finalization/continuity matters.
- Record changes in today's daily log.
