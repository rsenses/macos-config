import assert from "node:assert/strict";
import { test } from "node:test";
import { planActiveTask, planHumanActiveTask, planHumanCurrentStep, planSnapshot, planTaskCounts } from "../pi/.pi/agent/extensions/memory.ts";

const plan = (current: string, tasks: string, extra = "") => `# Plan: fixture\n- Status: in-progress\n\n## TL;DR\nA bounded plan summary.\n\n## Current Step\n${current}\n\n## Tasks\n${tasks}\n\n## Unresolved\n${extra}\n`;

test("plan snapshots resolve current and next task IDs to readable task names", () => {
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
	const content = plan(
		"- Current: none\n- Next: none\n- Blockers: T1 needs a dependency; install it before validating",
		"- [ ] T1: Validate changes",
	);
	assert.equal(planHumanCurrentStep(content), "Blockers: T1 needs a dependency; install it before validating");
});

test("task counts include only top-level checklist items in Tasks", () => {
	const content = plan(
		"- Current: T1\n- Next: T2\n- Blockers: none",
		"- [x] T1: Done\n  - [ ] subtask\n- [ ] T2: Open\n```markdown\n- [ ] T99: Example\n```\n- [ ] T3: Also open",
	);
	assert.deepEqual(planTaskCounts(content), { total: 3, open: 2, done: 1 });
});

test("plan snapshots provide a bounded document summary for explicit tools and the status line", () => {
	const content = plan(
		"- Current: T1\n- Next: T2\n- Blockers: none",
		"- [ ] T1: Read the selected plan\n- [ ] T2: Verify acceptance",
		"- Confirm the validation command",
	);
	const snapshot = planSnapshot(content, ".ai/plan/fixture.md");
	assert.equal(snapshot.planPath, ".ai/plan/fixture.md");
	assert.equal(snapshot.title, "fixture");
	assert.equal(snapshot.status, "in-progress");
	assert.equal(snapshot.tldr, "A bounded plan summary.");
	assert.deepEqual(snapshot.tasks, { total: 2, open: 2, done: 0 });
	assert.match(snapshot.currentStep, /Current: T1/);
	assert.match(snapshot.activeTask, /T1: Read the selected plan/);
	assert.equal(snapshot.warning, "- Confirm the validation command");
});
