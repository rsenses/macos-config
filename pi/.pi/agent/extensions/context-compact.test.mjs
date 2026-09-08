import assert from "node:assert/strict";
import { test } from "node:test";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const { createJiti } = await import(
	pathToFileURL(join(here, "../npm/node_modules/jiti/lib/jiti.mjs")).href,
);
const extension = await createJiti(pathToFileURL(join(here, "context-compact.ts")).href).import(
	pathToFileURL(join(here, "context-compact.ts")).href,
);
const install = extension.default;

const originalModel = {
	provider: "openai-codex",
	id: "gpt-6-astra",
	reasoning: true,
};
const compactionModel = {
	provider: "openai-codex",
	id: "gpt-5.6-luna",
	reasoning: true,
};

function createHarness({ tokens = 20_000, fail = false } = {}) {
	const handlers = new Map();
	const state = {
		model: originalModel,
		thinking: "low",
		modelChanges: [],
		compactCalls: [],
		messages: ["original context"],
		notifications: [],
	};

	const pi = {
		on(event, handler) {
			handlers.set(event, handler);
		},
		getThinkingLevel() {
			return state.thinking;
		},
		async setModel(model) {
			state.model = model;
			state.modelChanges.push(`${model.provider}/${model.id}`);
			return true;
		},
		setThinkingLevel(level) {
			state.thinking = level;
		},
	};

	install(pi);

	const context = {
		hasUI: true,
		model: originalModel,
		ui: {
			notify(message, type) {
				state.notifications.push({ message, type });
			},
		},
		modelRegistry: {
			find(provider, id) {
				return provider === compactionModel.provider && id === compactionModel.id
					? compactionModel
					: undefined;
			},
		},
		getContextUsage() {
			return { tokens };
		},
		compact(options) {
			state.compactCalls.push({
				model: state.model,
				thinking: state.thinking,
				options,
			});
			queueMicrotask(async () => {
				if (fail) {
					await handlers.get("session_compact_failed")?.({}, context);
					options.onError?.(new Error("fixture compaction failure"));
					return;
				}

				await handlers.get("session_compact")?.({}, context);
				options.onComplete?.({
					tokensBefore: tokens,
					estimatedTokensAfter: 18_720,
				});
			});
		},
	};

	return { handlers, state, context };
}

test("does not compact below the hard threshold", async () => {
	const { handlers, state, context } = createHarness({ tokens: 127_999 });
	await handlers.get("agent_settled")({}, context);
	assert.equal(state.compactCalls.length, 0);
	assert.deepEqual(state.model, originalModel);
	assert.equal(state.thinking, "low");
});

test("compacts at the hard threshold with Luna/high and restores the session", async () => {
	const { handlers, state, context } = createHarness({ tokens: 128_432 });
	await handlers.get("agent_settled")({}, context);

	assert.equal(state.compactCalls.length, 1);
	assert.equal(state.compactCalls[0].model.id, "gpt-5.6-luna");
	assert.equal(state.compactCalls[0].thinking, "high");
	assert.match(state.compactCalls[0].options.customInstructions, /working state/i);
	assert.deepEqual(state.model, originalModel);
	assert.equal(state.thinking, "low");
	assert.deepEqual(state.modelChanges, ["openai-codex/gpt-5.6-luna", "openai-codex/gpt-6-astra"]);
	assert.ok(state.notifications.some(({ message }) => /128432 tokens/.test(message)));
});

test("preserves the original session when compaction fails", async () => {
	const { handlers, state, context } = createHarness({ tokens: 129_001, fail: true });
	await handlers.get("agent_settled")({}, context);

	assert.equal(state.compactCalls.length, 1);
	assert.deepEqual(state.model, originalModel);
	assert.equal(state.thinking, "low");
	assert.deepEqual(state.messages, ["original context"]);
	assert.ok(state.notifications.some(({ message, type }) => type === "error" && /compaction failed/.test(message)));
});

test("does not immediately compact twice in the same agent run", async () => {
	const { handlers, state, context } = createHarness({ tokens: 128_500 });
	await handlers.get("agent_settled")({}, context);
	await handlers.get("agent_settled")({}, context);
	assert.equal(state.compactCalls.length, 1);

	await handlers.get("agent_start")({}, context);
	await handlers.get("agent_settled")({}, context);
	assert.equal(state.compactCalls.length, 2);
});
