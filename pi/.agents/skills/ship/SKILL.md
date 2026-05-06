---
description: Use when the user asks to commit, ship, finalize changes, prepare a commit, create a PR-ready commit, review staged changes, or generate a changelog/conventional commit message.
---

# Ship

Use this skill when the user asks to commit, ship, finalize, prepare changes, review staged changes, create a commit, or create a PR-ready commit.

## Agent routing

Use the `reviewer` subagent as the default agent for this skill.

Use the `worker` subagent only for concrete repository changes, such as:

- staging relevant files
- editing `CHANGELOG.md`
- creating the commit

Do not use the `debugger` subagent by default.

Use the `debugger` subagent only if:

- the diff indicates a likely CI/CD or deployment risk
- merge conflict markers are found
- the change appears technically unsafe
- tests were explicitly requested and fail

## Goal

Help the user avoid forgetting:

- changelog updates
- well-scoped commits
- conventional commit messages
- obvious pre-commit risks

## Rules

- Do not push unless explicitly requested.
- Do not create a PR unless explicitly requested.
- Do not run tests unless explicitly requested.
- Do not run destructive commands.
- Never commit secrets, `.env`, credentials, tokens, private keys, database files, or deployment secrets.
- Do not modify code unless explicitly requested.
- Only modify `CHANGELOG.md` when a changelog entry is needed.
- Stop if the diff mixes unrelated changes that should be split into separate commits.
- Do not post `/oc` or other bot-review comments unless explicitly requested.

## Workflow

### 1. Inspect Git state

```bash
git status --short
git branch --show-current
git diff --stat
git diff --staged --stat
git log --oneline -5
```

### 2. Inspect staged changes

```bash
git diff --staged
```

If nothing is staged, inspect unstaged changes:

```bash
git diff
```

Then decide what should be staged. Stage only relevant files.

### 3. Review commit scope

Check:

- Is this one coherent change?
- Are unrelated changes mixed in?
- Are generated/cache/temp files included?
- Are sensitive files included?

### 4. Changelog

- Check whether `CHANGELOG.md` exists.
- Decide if the change needs a changelog entry.
- A changelog is usually needed for user-visible behavior, bug fixes, features, API changes, config changes, migrations, breaking changes, or release-relevant internal changes.
- A changelog is usually not needed for tiny refactors, tests-only changes, formatting, comments, or internal cleanup with no user-visible effect.
- If needed, add a concise entry to `CHANGELOG.md` in the project’s existing style.
- Stage `CHANGELOG.md`.

### 5. Generate a Conventional Commit message

Use one of:

- `feat:` for new behavior
- `fix:` for bug fixes
- `refactor:` for behavior-preserving code changes
- `test:` for tests only
- `docs:` for documentation only
- `chore:` for maintenance
- `perf:` for performance
- `build:` for build/dependency/tooling changes
- `ci:` for CI changes

Use a scope when obvious:

```text
fix(auth): prevent expired token reuse
feat(exports): add CSV export filters
refactor(users): simplify profile update flow
```

Use `!` only for breaking changes:

```text
feat(api)!: remove legacy export endpoint
```

### 6. Commit

Use the `worker` subagent for the actual commit operation.

Before committing, show the proposed message and included files. If everything is coherent, create the commit:

```bash
git commit -m "<message>"
```

### 7. Optional PR creation

Only create a PR when the user explicitly asks for it.

If the user asks to create a PR:

1. Check branch and remote:

```bash
git branch --show-current
git remote -v
git status --short
```

2. Push the current branch if needed:

```bash
git push -u origin HEAD
```

3. Create a PR with `gh`:

```bash
gh pr create --fill
```

If `--fill` produces a weak title/body, create the PR with explicit title/body instead:

```bash
gh pr create --title "<title>" --body "<body>"
```

The PR body should include:

- summary
- changelog status
- tests/checks run
- risks/follow-ups

## Final response

Return:

- commit hash
- commit message
- files committed
- changelog status
- PR URL, if created
- risks or follow-ups

## Stop conditions

Stop and ask the user before committing if:

- the diff mixes unrelated changes
- sensitive files are staged
- the changelog change is unclear
- the commit would be too large
- there are merge conflict markers
- the change appears to require tests but none are present
- SemVer impact appears to be `major`
