import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";
import { livePlanBlock, planActiveTask, planHumanActiveTask, planHumanCurrentStep, planSnapshot } from "../pi/.pi/agent/extensions/memory.ts";

const plan = (current: string, tasks: string) => `## Current Step\n${current}\n\n## Tasks\n${tasks}\n`;

test("human plan status resolves current and next task IDs to task names", () => {
	const content = plan(
		"- Current: T1\n- Next: T2\n- Blockers: awaiting review",
		"- [ ] T1: Implement plan display — acceptance: all status surfaces are readable\n- [ ] T2: Add regression coverage",
	);
	assert.equal(planHumanActiveTask(content), "Implement plan display");
	assert.match(planActiveTask(content), /T1: Implement plan display/);
	assert.equal(
		planHumanCurrentStep(content),
		"Current: Implement plan display (T1) · Next: Add regression coverage (T2) · Blockers: awaiting review",
	);
});

test("explicit missing task IDs stay visible as inconsistencies, not substituted tasks", () => {
	const content = plan("- Current: T9\n- Next: none\n- Blockers: none", "- [ ] T1: Existing work");
	assert.equal(planActiveTask(content), "Inconsistent Current Step: T9 not found in Tasks");
	assert.equal(planHumanCurrentStep(content), "Current: Inconsistent — T9 not found in Tasks");
});

test("blocker explanations mentioning task IDs retain the cause and next action", () => {
	const content = plan("- Current: none\n- Next: none\n- Blockers: T1 needs a dependency; install it before validating", "- [ ] T1: Validate changes");
	assert.equal(planHumanCurrentStep(content), "Blockers: T1 needs a dependency; install it before validating");
});

test("placeholder task descriptions are omitted rather than presented as work", () => {
	const content = plan("- Current: T1\n- Next: none\n- Blockers: none", "- [ ] T1: ...");
	assert.equal(planHumanActiveTask(content), "");
	assert.equal(planHumanCurrentStep(content), "Current: T1 task description unavailable");
});

// The system prompt is the head of every request. Pi rebuilds that head and restates
// the whole tool set whenever an extension returns a `systemPrompt`, so any state
// written there truncates the cached prompt prefix and re-bills the whole
// conversation. The workflow policy therefore lives in a static file, and only live
// plan state is injected, as a trailing context message.

test("workflow policy lives in APPEND_SYSTEM.md so no extension rebuilds the prompt head", () => {
	const append = readFileSync(new URL("../pi/.pi/agent/APPEND_SYSTEM.md", import.meta.url), "utf8");
	for (const marker of ["## Project Plans and Tasks", "`create_session_plan` at the start of non-trivial tasks", "`.ai/TASKS.md`", "`.ai/plan/`"]) {
		assert.ok(append.includes(marker), `APPEND_SYSTEM.md must carry ${marker}`);
	}
	assert.ok(!/\*\*Current Step\*\*/.test(append), "APPEND_SYSTEM.md must not carry live plan state");
});

test("no extension returns a systemPrompt, which is what sets Pi's forceSystemPrompt", () => {
	const source = readFileSync(new URL("../pi/.pi/agent/extensions/memory.ts", import.meta.url), "utf8");
	const start = source.indexOf('pi.on("before_agent_start"');
	assert.ok(start >= 0, "before_agent_start hook must exist");
	const body = source.slice(start, source.indexOf('\n\tpi.on(', start + 1)).replace(/\/\/[^\n]*/g, "");
	assert.ok(!/\bsystemPrompt\s*:/.test(body), "before_agent_start must not return a systemPrompt");
});

test("live plan block carries path, status and current step, and omits derivable detail", () => {
	const content = plan(
		"- Current: T1\n- Next: T2\n- Blockers: none",
		"- [ ] T1: Trim the injected context — acceptance: prompt cache survives plan edits\n- [ ] T2: Document it",
	);
	const block = livePlanBlock(planSnapshot(content, ".ai/plan/p.md"), undefined, planHumanCurrentStep(content));
	assert.match(block, /\*\*Plan\*\*: `\.ai\/plan\/p\.md` — status:/);
	assert.match(block, /\*\*Current Step\*\*: Current: Trim the injected context \(T1\)/);
	for (const omitted of ["**Tasks**", "**TL;DR**", "**Active task**", "Active In Progress"]) {
		assert.ok(!block.includes(omitted), `appended block must not carry ${omitted}`);
	}
});

test("a blocked plan selection reports the blocker instead of a stale pointer", () => {
	assert.match(livePlanBlock(undefined, "no active plan selection", undefined), /no active plan selection/);
	assert.equal(livePlanBlock(undefined, undefined, undefined), "");
});
