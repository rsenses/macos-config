---
name: source-driven-development
description: Grounds framework and library decisions in authoritative documentation. Use when implementing with frameworks/packages where API correctness, current conventions, or version-specific behavior matters.
---

# Source-Driven Development

## Overview

Important framework-specific code decisions should be backed by authoritative documentation or project-provided MCP tools. Don't implement unfamiliar or version-sensitive APIs from memory — verify, cite when useful, and let the user see sources for non-obvious choices. Keep verification proportional: obvious syntax and established project patterns do not need ceremony. If the codebase already shows the pattern clearly, prefer the local pattern and skip deeper docs unless the version/API choice is actually unclear.

## When to Use

- The user wants code that follows current best practices for a given framework and the codebase does not already establish the pattern
- Building boilerplate, starter code, or patterns that will be copied across a project
- The user explicitly asks for documented, verified, or "correct" implementation
- Implementing features where the framework's recommended approach matters (forms, routing, data fetching, state management, auth)
- Reviewing or improving code that uses framework-specific patterns when the local pattern is ambiguous or missing
- Any time you are about to write unfamiliar or version-sensitive framework-specific code from memory

**When NOT to use:**

- Correctness does not depend on a specific version (renaming variables, fixing typos, moving files)
- Pure logic that works the same across all versions (loops, conditionals, data structures)
- The codebase already demonstrates the same pattern clearly
- The user explicitly wants speed over verification ("just do it quickly")

## The Process

```
DETECT ──→ FETCH ──→ IMPLEMENT ──→ CITE
  │          │           │            │
  ▼          ▼           ▼            ▼
 What       Get the    Follow the   Show your
 stack?     relevant   documented   sources
            docs       patterns
```

### Step 1: Detect Stack and Versions

Read the project's dependency file to identify exact versions:

```
composer.json   → PHP/Symfony/Laravel
package.json    → Node/React/Vue/Angular/Svelte
requirements.txt / pyproject.toml → Python/Django/Flask
go.mod          → Go
Cargo.toml      → Rust
Gemfile         → Ruby/Rails
<other manifest> → Project-specific stack
```

State what you found explicitly:

```
STACK DETECTED:
- Laravel 12.x (from composer.json)
- PHP 8.4
- Inertia/Vue/etc. if present
→ Fetching authoritative docs or MCP guidance for the relevant patterns.
```

If versions are missing or ambiguous, **ask the user**. Don't guess — the version determines which patterns are correct.

### Step 2: Fetch Official Documentation

Fetch the specific documentation page for the feature you're implementing. Not the homepage, not the full docs — the relevant page.

Prefer project-provided MCP documentation tools when available (for example Laravel Boost in Laravel projects). If MCP docs are unavailable or insufficient, use official online documentation.

**Source hierarchy (in order of authority):**

| Priority | Source | Example |
|----------|--------|---------|
| 1 | Official documentation | react.dev, docs.djangoproject.com, symfony.com/doc |
| 2 | Official blog / changelog | react.dev/blog, nextjs.org/blog |
| 3 | Web standards references | MDN, web.dev, html.spec.whatwg.org |
| 4 | Browser/runtime compatibility | caniuse.com, node.green |

**Not authoritative — never cite as primary sources:**

- Stack Overflow answers
- Blog posts or tutorials (even popular ones)
- AI-generated documentation or summaries
- Your own training data (that is the whole point — verify it)

**Be precise with what you fetch:**

```
BAD:  Fetch a framework homepage
GOOD: Fetch the specific official page for the API/pattern being used

BAD:  Search "django authentication best practices"
GOOD: Fetch docs.djangoproject.com/en/6.0/topics/auth/
```

After fetching, extract the key patterns and note any deprecation warnings or migration guidance.

If the repo already contains a clear example, verify that example first and stop unless the docs conflict with it or the version matters.

When official sources conflict with each other (e.g. a migration guide contradicts the API reference), surface the discrepancy to the user and verify which pattern actually works against the detected version.

### Step 3: Implement Following Documented Patterns

Write code that matches what the documentation shows:

- Use the API signatures from the docs, not from memory
- If the docs show a new way to do something, use the new way
- If the docs deprecate a pattern, don't use the deprecated version
- If the docs don't cover something, flag it as unverified

**When docs conflict with existing project code:**

```
CONFLICT DETECTED:
The existing codebase uses an older framework pattern,
but current official docs recommend a newer pattern for this use case.
(Source: <specific official docs page>)

Options:
A) Use the documented modern pattern — consistent with current docs
B) Match existing code — consistent with codebase
→ Which approach do you prefer?
```

Surface the conflict. Don't silently pick one.

### Step 4: Cite Your Sources

Cite sources for non-obvious, unfamiliar, version-sensitive, or framework-specific decisions. The user must be able to verify important choices without citation noise for obvious project-local patterns.

**In code comments:**

```php
// Framework-native validation rule for this field.
// Source: <specific official docs URL>
$request->validate([
    'email' => ['required', 'email'],
]);
```

**In conversation:**

```
I'm using the framework-native validation rule instead of custom
parsing because the official docs define this as the supported API
for this version.

Source: <specific official docs URL>
"<short relevant quote>"
```

**Citation rules:**

- Full URLs, not shortened
- Prefer deep links with anchors where possible (e.g. `/useActionState#usage` over `/useActionState`) — anchors survive doc restructuring better than top-level pages
- Quote the relevant passage when it supports a non-obvious decision
- Include browser/runtime support data when recommending platform features
- If you cannot find documentation for a pattern, say so explicitly:

```
UNVERIFIED: I could not find official documentation for this
pattern. This is based on training data and may be outdated.
Verify before using in production.
```

Honesty about what you couldn't verify is more valuable than false confidence.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'm confident about this API" | Confidence is not evidence. Training data contains outdated patterns that look correct but break against current versions. Verify. |
| "Fetching docs wastes tokens" | Hallucinating an API wastes more. The user debugs for an hour, then discovers the function signature changed. One fetch prevents hours of rework. |
| "The docs won't have what I need" | If the docs don't cover it, that's valuable information — the pattern may not be officially recommended. |
| "I'll just mention it might be outdated" | A disclaimer doesn't help. Either verify and cite, or clearly flag it as unverified. Hedging is the worst option. |
| "This is a simple task, no need to check" | Simple tasks with wrong patterns become templates. The user copies your deprecated form handler into ten components before discovering the modern approach exists. |

## Red Flags

- Writing framework-specific code without checking the docs for that version
- Using "I believe" or "I think" about an API instead of citing the source
- Implementing a pattern without knowing which version it applies to
- Citing Stack Overflow or blog posts instead of official documentation
- Using deprecated APIs because they appear in training data
- Not reading the relevant dependency manifest before implementing
- Delivering code without source citations for non-obvious framework-specific decisions
- Fetching an entire docs site when only one page is relevant

## Verification

After implementing with source-driven development:

- [ ] Framework and library versions were identified from the dependency file
- [ ] Official documentation was fetched for framework-specific patterns
- [ ] All sources are official documentation, not blog posts or training data
- [ ] Code follows the patterns shown in the current version's documentation
- [ ] Non-trivial decisions include source citations with full URLs
- [ ] No deprecated APIs are used (checked against migration guides)
- [ ] Conflicts between docs and existing code were surfaced to the user
- [ ] Anything that could not be verified is explicitly flagged as unverified
