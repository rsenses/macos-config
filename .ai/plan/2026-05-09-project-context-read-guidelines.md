# Plan: tighten project context read guidelines

- Strengthen project-context prompt guidelines so models prefer `read` after `project_search` instead of full-file reads.
- Add generic guidance for test verification to restrict searches to tests when appropriate.
- Keep changes limited to guidelines; no new tools.
- Validate syntax with `node --check`.
