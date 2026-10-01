import assert from "node:assert/strict";
import { test } from "node:test";
import { planActiveTask, planHumanActiveTask, planHumanCurrentStep } from "../pi/.pi/agent/extensions/memory.ts";

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
