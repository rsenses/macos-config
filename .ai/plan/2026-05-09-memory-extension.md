# Plan: pi memory extension

- Read pi extension docs and the existing memory skill.
- Add a small global pi extension in dotfiles.
- On `before_agent_start`, ensure project-local `.ai` structure, read `.ai/MEMORY.md`, and inject memory policy/context into the system prompt.
- On `agent_end`, ensure today's daily file exists without attempting automatic summarization.
