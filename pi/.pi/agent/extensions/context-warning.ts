import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const THRESHOLD = 65;

export default function (pi: ExtensionAPI) {
	pi.on("agent_end", async (_event, ctx) => {
		if (!ctx.hasUI) return;

		const usage = ctx.getContextUsage();
		if (usage?.percent == null || usage.percent <= THRESHOLD) return;

		ctx.ui.notify(`Contexto al ${Math.round(usage.percent)}%`, "error");
	});
}
