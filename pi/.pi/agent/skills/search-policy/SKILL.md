---
name: search-policy
description: Search policy for Pi code discovery. Use ffffind for fuzzy file/path discovery, prefer bash rg for content search, and avoid ffgrep unless explicitly requested or rg is unavailable.
---

# Search Policy

- Use `fffind` to discover files and paths.
- Use `bash rg` for content/text search.
- Do not use `ffgrep` by default.
- Use `ffgrep` only when the user explicitly asks for FFF search or when you already know FFF is the right tool for the job.
