---
description: Prepare a release locally from project evidence without publishing or deploying
argument-hint: "[scope or target version]"
---

Prepare a release for: ${@:-the current unreleased changes}

Load `ops`. Follow the project's release, versioning, and changelog policy plus APPEND_SYSTEM's Changelog Policy. A user-invoked `/prepare-release` authorizes local release-file preparation only; it does not authorize commits or publication.

1. Establish the source of truth. Read the relevant project release, versioning, changelog, compatibility, CI, and deployment documentation plus the files that declare the current version. Identify the published baseline and the exact files that record version, notes, and publication state. Verify publication state from project records; do not infer it from a merge, deployment, or an unreleased heading alone. If the policy sources conflict or the baseline is ambiguous, stop with the exact question.
2. Inspect the baseline diff: changed source, public interfaces, docs, migrations, configuration and dependencies. Classify user-visible additions, changes, fixes, removals, security fixes and breaking changes—not just commit messages or unreleased notes.
3. Under the project's compatibility contract, propose the version with rationale and exact, concise user-facing notes. Include upgrade/migration notes for breaking or risky changes. Verify supplied target versions against evidence.
4. Prepare authorized local files. Update the changelog source of truth and version files using project conventions. Preserve published history and chronology; do not rewrite or delete published entries unless the user explicitly requests a correction, and do not invent versions, dates, or links. Stop before editing when the policy, baseline, or intended version is unresolved.
5. Validate consistency. Re-read the complete changed documents and version sources. Check headings, links, duplicate or missing entries, agreement across version files, and that every note is supported by the diff. Run targeted project checks; follow `ops` section 4 for full validation, which runs only when the user requests it. Report checks actually run and any unverified remainder.

Preparation is not publication. A GitHub release, package publication, tag, commit, push, merge to a release branch, and deployment are separate actions; do not perform any of them or mutate any remote, tag, release, or deployment state without explicit authorization. Return the proposed version and notes, local changes, evidence, checks, and the publication decisions that remain.
