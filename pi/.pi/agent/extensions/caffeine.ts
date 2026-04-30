import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn, type ChildProcess } from "node:child_process";

export default function (pi: ExtensionAPI) {
	if (process.platform !== "darwin") {
		console.warn("Caffeinate disabled: macOS only");
		return;
	}

	let caffeinate: ChildProcess | undefined;

	const stop = () => {
		const child = caffeinate;
		caffeinate = undefined;
		if (child) child.kill("SIGTERM");
	};

	const start = () => {
		if (caffeinate) return;
		caffeinate = spawn("caffeinate", ["-dimsu"], {
			detached: true,
			stdio: "ignore",
		});
		caffeinate.unref();
	};

	pi.on("agent_start", start);
	pi.on("tool_execution_start", start);
	pi.on("agent_end", stop);
	pi.on("session_shutdown", stop);

	process.on("exit", stop);
	process.on("SIGINT", () => {
		stop();
		process.exit(130);
	});
	process.on("SIGTERM", () => {
		stop();
		process.exit(143);
	});
}
