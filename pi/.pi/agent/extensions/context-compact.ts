import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { Model } from "@earendil-works/pi-ai";
import type { ThinkingLevel } from "@earendil-works/pi-agent-core";

/**
 * Automatic long-session compaction.
 *
 * The soft threshold is intentionally only documented for now. Pi does not
 * expose a reliable, cheap notion of a natural checkpoint, so the first
 * version only acts at the hard threshold.
 */
export const CONFIG = {
	softThreshold: 96_000,
	hardThreshold: 128_000,
	compactionModel: {
		provider: "openai-codex",
		id: "gpt-5.6-luna",
	},
	compactionThinking: "high" as const,
};

const COMPACTION_INSTRUCTIONS = `Produce a compact coding-agent working state, not a narrative recap.

Keep Pi's standard structured summary format. Preserve every still-relevant user
requirement, restriction, preference, technical decision and its rationale. In
## Critical Context, include concise subsections or bullets for these when they
exist: Repository State, Discoveries, Tests and Validation, Rejected Approaches,
Remaining Work, and Immediate Next Action.

For Repository State, record only important created, modified, deleted, or
relevant files and what matters about each; do not copy file contents. For Tests
and Validation, record checks and pass/fail status without full output. Keep only
rejected approaches that must not be retried, with a brief reason. Remove tool
noise, long command output, duplicate explanations, intermediate reasoning, and
stale details. Do not copy system prompts, AGENTS.md, skills, or other permanent
harness rules: Pi reloads those through its normal mechanism after compaction.
Preserve exact paths, names, commands, and unresolved errors where they matter.
Aim for a concise summary so the retained recent context plus this checkpoint
stays small, while losing no information needed to continue the task.`;

type ActiveCompaction = {
	originalModel: Model<any>;
	originalThinking: ThinkingLevel;
};

type NotifyContext = Pick<ExtensionContext, "hasUI" | "ui">;

function modelLabel(model: { provider: string; id: string }): string {
	return `${model.provider}/${model.id}`;
}

function formatTokens(tokens: number | undefined): string {
	return tokens == null ? "unknown" : String(Math.round(tokens));
}

function notify(ctx: NotifyContext, message: string, type: "info" | "warning" | "error" = "info"): void {
	if (ctx.hasUI) ctx.ui.notify(message, type);
}

export default function (pi: ExtensionAPI) {
	let activeCompaction: ActiveCompaction | undefined;
	let compactedThisRun = false;

	async function restoreOriginal(ctx: NotifyContext): Promise<void> {
		const pending = activeCompaction;
		// Clear before awaiting so a duplicate lifecycle/callback cannot restore
		// twice or mistake this completed operation for a new one.
		activeCompaction = undefined;
		if (!pending) return;

		try {
			const restored = await pi.setModel(pending.originalModel);
			if (!restored) {
				throw new Error(`model authentication unavailable for ${modelLabel(pending.originalModel)}`);
			}
			pi.setThinkingLevel(pending.originalThinking);
			if (pi.getThinkingLevel() !== pending.originalThinking) {
				throw new Error(`reasoning level could not be restored to ${pending.originalThinking}`);
			}
			notify(ctx, `[context-compact] restored ${modelLabel(pending.originalModel)}/${pending.originalThinking}`);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			notify(ctx, `[context-compact] restore failed: ${message}`, "error");
		}
	}

	async function compactAtThreshold(ctx: NotifyContext & {
		model: Model<any> | undefined;
		modelRegistry: { find(provider: string, modelId: string): Model<any> | undefined };
		compact(options?: {
			customInstructions?: string;
			onComplete?: (result: { tokensBefore: number; estimatedTokensAfter?: number }) => void;
			onError?: (error: Error) => void;
		}): void;
	}, thresholdTokens: number): Promise<void> {
		const originalModel = ctx.model;
		if (!originalModel) return;

		const compactionModel = ctx.modelRegistry.find(
			CONFIG.compactionModel.provider,
			CONFIG.compactionModel.id,
		);
		if (!compactionModel) {
			notify(ctx, `[context-compact] model unavailable: ${modelLabel(CONFIG.compactionModel)}`, "warning");
			return;
		}

		activeCompaction = {
			originalModel,
			originalThinking: pi.getThinkingLevel(),
		};
		compactedThisRun = true;
		notify(ctx, `[context-compact] threshold reached: ${formatTokens(thresholdTokens)} tokens`);

		try {
			const selected = await pi.setModel(compactionModel);
			if (!selected) throw new Error(`model authentication unavailable for ${modelLabel(compactionModel)}`);

			pi.setThinkingLevel(CONFIG.compactionThinking);
			if (pi.getThinkingLevel() !== CONFIG.compactionThinking) {
				throw new Error(`${modelLabel(compactionModel)} does not support ${CONFIG.compactionThinking} reasoning`);
			}

			notify(ctx, `[context-compact] compacting with ${modelLabel(compactionModel)}/${CONFIG.compactionThinking}`);
			await new Promise<void>((resolve, reject) => {
				try {
					ctx.compact({
						customInstructions: COMPACTION_INSTRUCTIONS,
						onComplete: (result) => {
							notify(
								ctx,
								`[context-compact] ${formatTokens(result.tokensBefore)} -> ${formatTokens(result.estimatedTokensAfter)} tokens`,
							);
							resolve();
						},
						onError: reject,
					});
				} catch (error) {
					reject(error);
				}
			});
		} catch (error) {
			await restoreOriginal(ctx);
			const message = error instanceof Error ? error.message : String(error);
			notify(ctx, `[context-compact] compaction failed: ${message}`, "error");
		}
	}

	pi.on("agent_start", () => {
		// A new agent run is the safe point at which another threshold check is
		// allowed. This also prevents duplicate/late settled events from causing
		// an immediate second compaction.
		compactedThisRun = false;
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (compactedThisRun || activeCompaction) return;

		const usage = ctx.getContextUsage();
		if (usage?.tokens == null || usage.tokens < CONFIG.hardThreshold) return;

		await compactAtThreshold(ctx, usage.tokens);
	});

	// Pi emits these only after it has atomically persisted/rebuilt the
	// compaction, or after it has rejected it. Restore the original session
	// settings on both paths; the error path leaves the original messages intact.
	pi.on("session_compact", async (_event, ctx) => {
		await restoreOriginal(ctx);
	});

	pi.on("session_compact_failed", async (_event, ctx) => {
		await restoreOriginal(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		await restoreOriginal(ctx);
	});
}
