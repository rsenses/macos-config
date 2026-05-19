# rtk extension debug

- Status: in-progress
- Updated: 2026-05-15 09:35
- Scope: medium

## Goal

Investigate why the installed rtk extension appears not to work in Pi.

## Spec / Contract

- Objective: determine whether the extension is installed, loaded, and invoked as expected.
- Expected behavior: the extension should be visible in Pi config/session startup and expose its intended tools/behavior.
- Success criteria: identify the failure mode and the smallest next fix or confirm it is working.
- Out of scope: unrelated Pi config cleanup.
- Open questions: is the issue installation, loading, tool registration, or runtime behavior?

## Current Plan

1. Find the rtk extension files and registration points.
2. Inspect Pi config and logs for whether the extension is loaded.
3. Check recent sessions for any extension/tool activity or errors.
4. Narrow down the failure mode and report next action.

Current findings:
- `pi/.pi/agent/settings.json` and `~/.pi/agent/settings.json` both include `npm:@sherif-fanous/pi-rtk`.
- `rtk` is installed locally (`/opt/homebrew/bin/rtk`, version `0.39.0`).
- The package code rewrites only Pi shell paths (`bash` tool calls and `!<cmd>`), and it intentionally ignores `!!<cmd>`.
- I found no session-log evidence of a load failure yet.
- Live validation: a simple shell command appeared rewritten on execution (`ls /tmp` produced `ls -l`-style output), which is consistent with pi-rtk working.

## TODO

- [x] Locate rtk extension files and config references.
- [x] Check Pi startup/session logs for extension load errors.
- [x] Verify whether the extension registers any tools or prompts.
- [ ] Summarize findings and propose fix.

## Decisions and Constraints

- Use local project evidence first.
- Keep the investigation focused on Pi/rtk, not broader repo cleanup.

## Validation

- Live check suggests command rewriting is active.
- One more confirmation via a `!<cmd>` path or `/rtk status` would make it more certain.

## Remaining / Next

- Inspect the extension implementation and config hooks.
