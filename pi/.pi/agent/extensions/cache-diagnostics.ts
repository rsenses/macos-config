import { createHmac, randomBytes, randomUUID } from "node:crypto";
import { appendFileSync, mkdirSync, renameSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Observation only: no payload/header changes, tools, prompts, notices or model calls.
// Hooks run in extension order: these fingerprints are not proof of final wire bytes.
export function createRecorder(file: string, limit = 2 * 1024 * 1024) {
	const key = randomBytes(32); // Never persisted; prevents guessing content from hashes.
	const run = randomUUID();
	const hash = (value: unknown) => createHmac("sha256", key).update(JSON.stringify(value) ?? "undefined").digest("hex");
	let request = 0;
	let disabled = false;
	function write(type: string, data: Record<string, unknown>) {
		if (disabled) return;
		try {
			mkdirSync(dirname(file), { recursive: true, mode: 0o700 });
			const line = JSON.stringify({ time: new Date().toISOString(), run, request, type, ...data }) + "\n";
			let size = 0;
			try { size = statSync(file).size; } catch (error) {
				if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
			}
			if (size + Buffer.byteLength(line) > limit) renameSync(file, file + ".1");
			appendFileSync(file, line, { mode: 0o600 });
		} catch {
			// Diagnostics must never break inference; stop recording on storage failure.
			disabled = true;
		}
	}
	return {
		request(payload: unknown, session: string, model: { provider?: string; id?: string; api?: string; baseUrl?: string } | undefined) {
			request++;
			const body = payload as Record<string, unknown>;
			const fields: Record<string, string> = {};
			for (const name of ["model", "instructions", "system", "tools", "input", "messages", "prompt_cache_key", "reasoning", "previous_response_id"]) {
				fields[name] = hash(body?.[name]);
			}
			const input = Buffer.from(JSON.stringify(body?.input ?? body?.messages ?? null));
			const chunks: string[] = [];
			for (let offset = 0; offset < input.length && chunks.length < 256; offset += 8192) {
				chunks.push(createHmac("sha256", key).update(input.subarray(offset, offset + 8192)).digest("hex"));
			}
			write("request", {
				session: hash(session), provider: model?.provider, model: model?.id, api: model?.api,
				endpoint: hash(model?.baseUrl), payload: hash(payload), fields,
				options: hash(Object.fromEntries(Object.entries(body ?? {}).filter(([name]) => name !== "input" && name !== "messages"))),
				inputBytes: input.length, chunkBytes: 8192, chunks, truncated: input.length > 256 * 8192,
			});
		},
		response(status: number, headers: Record<string, string>) {
			const id = headers["x-request-id"];
			write("response", { status, requestId: id && /^[\w-]{1,128}$/.test(id) ? id : undefined });
		},
		usage(usage: { input: number; output: number; cacheRead: number; cacheWrite: number }, stopReason: string) {
			write("usage", { input: usage.input, output: usage.output, cacheRead: usage.cacheRead, cacheWrite: usage.cacheWrite, stopReason });
		},
	};
}

export default function (pi: ExtensionAPI) {
	const agentDir = process.env.PI_CODING_AGENT_DIR?.replace(/^~(?=\/|$)/, homedir()) ?? join(homedir(), ".pi", "agent");
	const recorder = createRecorder(join(agentDir, "cache-diagnostics", "requests.jsonl"));
	pi.on("before_provider_request", (event, ctx) => {
		try { recorder.request(event.payload, ctx.sessionManager.getSessionId(), ctx.model); } catch { /* observation only */ }
	});
	pi.on("after_provider_response", (event) => { recorder.response(event.status, event.headers); });
	pi.on("message_end", (event) => {
		if (event.message.role === "assistant") recorder.usage(event.message.usage, event.message.stopReason);
	});
}
