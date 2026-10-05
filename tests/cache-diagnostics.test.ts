import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import extension, { createRecorder } from "../pi/.pi/agent/extensions/cache-diagnostics.ts";

function fixture(t: any) {
	const dir = mkdtempSync(join(tmpdir(), "cache-diagnostics-"));
	t.after(() => rmSync(dir, { recursive: true, force: true }));
	return join(dir, "requests.jsonl");
}
const model = { provider: "test", id: "test-model", api: "test-api", baseUrl: "https://secret-endpoint" };
const records = (file: string) => readFileSync(file, "utf8").trim().split("\n").map(line => JSON.parse(line));

test("records comparable keyed fingerprints without content, credentials or payload mutation", t => {
	const file = fixture(t);
	const recorder = createRecorder(file);
	const payload = { model: "test-model", instructions: "private instructions", input: [{ text: "private conversation" }], tools: [{ description: "private tool" }], prompt_cache_key: "private session", authorization: "private credential" };
	const before = structuredClone(payload);
	recorder.request(payload, "private session", model);
	recorder.request(payload, "private session", model);
	recorder.request({ ...payload, instructions: "changed", input: [{ text: "changed" }] }, "private session", model);
	assert.deepEqual(payload, before);
	const [a, b, c] = records(file);
	assert.equal(a.payload, b.payload);
	assert.equal(a.fields.tools, c.fields.tools);
	assert.notEqual(a.fields.instructions, c.fields.instructions);
	assert.notEqual(a.chunks[0], c.chunks[0]);
	assert.equal(a.session, b.session);
	assert.equal(b.request, 2);
	const text = readFileSync(file, "utf8");
	for (const secret of ["private", "secret-endpoint", "authorization"]) assert.ok(!text.includes(secret));
	assert.equal(statSync(file).mode & 0o777, 0o600);
	const other = fixture(t);
	createRecorder(other).request(payload, "private session", model);
	assert.notEqual(a.payload, records(other)[0].payload);
});

test("keeps stable input chunks across appends and bounds fingerprint count", t => {
	const file = fixture(t);
	const recorder = createRecorder(file);
	recorder.request({ input: "a".repeat(20000) }, "session", model);
	recorder.request({ input: "a".repeat(20000) + "b" }, "session", model);
	recorder.request({ input: "a".repeat(3 * 1024 * 1024) }, "session", model);
	const [a, b, c] = records(file);
	assert.deepEqual(a.chunks.slice(0, 2), b.chunks.slice(0, 2));
	assert.equal(c.chunks.length, 256);
	assert.equal(c.truncated, true);
});

test("records only response allowlist and numeric usage, including zero cache hits", t => {
	const file = fixture(t);
	const recorder = createRecorder(file);
	recorder.request({}, "session", model);
	recorder.response(200, { "x-request-id": "req-123", authorization: "secret", "set-cookie": "secret" });
	recorder.usage({ input: 120493, output: 64, cacheRead: 0, cacheWrite: 0 }, "toolUse");
	const [, response, usage] = records(file);
	assert.equal(response.requestId, "req-123");
	assert.equal(usage.request, response.request);
	assert.equal(usage.cacheRead, 0);
	assert.ok(!readFileSync(file, "utf8").includes("secret"));
});

test("rotates to one previous file and storage failures do not throw", t => {
	const file = fixture(t);
	const recorder = createRecorder(file, 4096);
	for (let i = 0; i < 20; i++) recorder.request({ input: "hello" }, "session", model);
	assert.ok(statSync(file).size <= 4096);
	assert.ok(statSync(file + ".1").size <= 4096);
	const blocked = fixture(t);
	writeFileSync(blocked, "not a directory");
	const broken = createRecorder(join(blocked, "requests.jsonl"));
	assert.doesNotThrow(() => broken.request({}, "session", model));
	assert.doesNotThrow(() => broken.usage({ input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }, "error"));
});

test("extension registers only observational handlers and returns no replacement payload", t => {
	const file = fixture(t);
	const previous = process.env.PI_CODING_AGENT_DIR;
	process.env.PI_CODING_AGENT_DIR = join(file, "..");
	const handlers = new Map<string, Function>();
	try { extension({ on: (name: string, handler: Function) => handlers.set(name, handler) } as any); }
	finally {
		if (previous === undefined) delete process.env.PI_CODING_AGENT_DIR;
		else process.env.PI_CODING_AGENT_DIR = previous;
	}
	assert.deepEqual([...handlers.keys()], ["before_provider_request", "after_provider_response", "message_end"]);
	const payload = Object.freeze({ input: Object.freeze(["hello"]) });
	assert.equal(handlers.get("before_provider_request")!({ payload }, { sessionManager: { getSessionId: () => "session" }, model }), undefined);
	assert.equal(handlers.get("after_provider_response")!({ status: 200, headers: {} }), undefined);
	assert.equal(handlers.get("message_end")!({ message: { role: "assistant", usage: { input: 10, output: 1, cacheRead: 0, cacheWrite: 0 }, stopReason: "stop" } }), undefined);
	assert.equal(records(join(file, "..", "cache-diagnostics", "requests.jsonl")).length, 3);
});
