import assert from "node:assert/strict";
import { once } from "node:events";
import { spawn } from "node:child_process";
import { test } from "node:test";
import {
  AbortableSemaphore,
  classifyLifecycleStatus,
  consumeChildEvent,
  createChildEventState,
  createDeadline,
  isAbortError,
  JsonLineParser,
  terminateProcessTree,
  truncateUtf8Head,
  UsageAccumulator,
} from "./helpers.ts";

test("only a non-empty terminal answer completes a child", () => {
  for (const stopReason of ["length", "deferred", "toolUse", "error", "aborted"]) {
    const state = createChildEventState();
    consumeChildEvent(state, { type: "message_end", message: { role: "assistant", stopReason: "stop", content: [{ type: "text", text: "old" }] } });
    consumeChildEvent(state, { type: "message_end", message: { role: "assistant", stopReason, content: [{ type: "text", text: "partial" }] } });
    assert.equal(state.hasFinalResponse, false, stopReason);
    assert.equal(state.finalOutput, "");
    assert.equal(state.partialOutput, "partial");
  }
  const state = createChildEventState();
  consumeChildEvent(state, { type: "message_end", message: { role: "assistant", stopReason: "stop", content: [] } });
  assert.equal(state.hasFinalResponse, false);
  consumeChildEvent(state, { type: "message_end", message: { role: "assistant", stopReason: "stop", content: [{ type: "text", text: "working", textSignature: '{"phase":"commentary"}' }] } });
  assert.equal(state.hasFinalResponse, false);
});

test("usage aggregates assistant, nested tool, and compaction exactly once", () => {
  const usage = new UsageAccumulator();
  const sample = {
    input: 10,
    output: 4,
    cacheRead: 2,
    cacheWrite: 1,
    totalTokens: 17,
    cost: { input: 1, output: 2, cacheRead: 3, cacheWrite: 4, total: 10 },
  };
  assert.equal(usage.addAssistant(sample, "assistant:1"), true);
  assert.equal(usage.addAssistant(sample, "assistant:1"), false);
  assert.equal(usage.add(sample, "tool:child"), true);
  assert.equal(usage.add(sample, "compaction:1"), true);
  assert.deepEqual(usage.toUsage(), {
    input: 30,
    output: 12,
    cacheRead: 6,
    cacheWrite: 3,
    totalTokens: 51,
    cost: { input: 3, output: 6, cacheRead: 9, cacheWrite: 12, total: 30 },
  });
  assert.equal(usage.totals.turns, 1);
});

test("concurrency rejects zero and non-integers", () => {
  assert.throws(() => new AbortableSemaphore(0), /positive integer/);
  assert.throws(() => new AbortableSemaphore(1.5), /positive integer/);
});

test("lifecycle distinguishes final, partial, and error with partial evidence", () => {
  assert.equal(classifyLifecycleStatus({ exitCode: 0, hasFinalResponse: true }), "complete");
  assert.equal(classifyLifecycleStatus({ exitCode: 0, hasFinalResponse: false }), "partial");
  assert.equal(classifyLifecycleStatus({ exitCode: 1, hasFinalResponse: false, error: "provider" }), "failed");
  assert.equal(
    classifyLifecycleStatus({ exitCode: 1, hasFinalResponse: false, error: "provider", termination: "timed_out" }),
    "timed_out",
  );
});

test("waiters retain FIFO reservations when a slot is released", async () => {
  const semaphore = new AbortableSemaphore(1);
  let releaseFirst!: () => void;
  const first = semaphore.run(
    () => new Promise<void>((resolve) => {
      releaseFirst = resolve;
    }),
  );
  const order: string[] = [];
  const second = semaphore.run(async () => {
    order.push("second-start");
  });
  const third = semaphore.run(async () => {
    order.push("third-start");
  });

  releaseFirst();
  await Promise.all([first, second, third]);
  assert.deepEqual(order, ["second-start", "third-start"]);
  assert.equal(semaphore.active, 0);
  assert.equal(semaphore.queued, 0);
});

test("abort after waiter resolution releases its reservation and wakes the next waiter", async () => {
  const semaphore = new AbortableSemaphore(1);
  let releaseFirst!: () => void;
  const first = semaphore.run(() => new Promise<void>((resolve) => {
    releaseFirst = resolve;
  }));
  let reads = 0;
  const signal = {
    get aborted() {
      // Initial check and enqueue check pass; the post-resolution check aborts.
      return ++reads >= 3;
    },
    addEventListener() {},
    removeEventListener() {},
  } as unknown as AbortSignal;
  let secondStarted = false;
  const second = semaphore.run(async () => {
    secondStarted = true;
  }, signal);
  let thirdStarted = false;
  const third = semaphore.run(async () => {
    thirdStarted = true;
  });
  releaseFirst();
  await assert.rejects(second, (error: unknown) => isAbortError(error));
  await third;
  await first;
  assert.equal(secondStarted, false);
  assert.equal(thirdStarted, true);
  assert.equal(semaphore.active, 0);
  assert.equal(semaphore.queued, 0);
});

test("queue aborts without starting a task", async () => {
  const semaphore = new AbortableSemaphore(1);
  let releaseFirst!: () => void;
  const release = new Promise<void>((resolve) => {
    releaseFirst = resolve;
  });
  const first = semaphore.run(() => release);
  const controller = new AbortController();
  let started = false;
  const queued = semaphore.run(async () => {
    started = true;
  }, controller.signal);
  controller.abort();
  await assert.rejects(queued, (error: unknown) => isAbortError(error));
  assert.equal(started, false);
  assert.equal(semaphore.queued, 0);
  releaseFirst();
  await first;
});

test("deadline is abortable and reports timeout", async () => {
  const deadline = createDeadline(20);
  await once(deadline.signal, "abort");
  assert.equal(deadline.signal.aborted, true);
  assert.equal((deadline.signal.reason as Error).name, "TimeoutError");
  deadline.cancel();
});

test("truncation respects UTF-8 bytes and line limits without replacement characters", () => {
  const result = truncateUtf8Head("😀😀\nsecond\nthird", 6, 2);
  assert.equal(result.truncated, true);
  assert.ok(result.outputBytes <= 6);
  assert.ok(result.outputLines <= 2);
  assert.equal(Buffer.byteLength(result.content), result.outputBytes);

  for (let maxBytes = 1; maxBytes < 4; maxBytes++) {
    const boundary = truncateUtf8Head("😀ok", maxBytes, 1);
    assert.equal(boundary.content, "");
    assert.equal(boundary.outputBytes, 0);
    assert.ok(!boundary.content.includes("�"));
  }
  const exact = truncateUtf8Head("😀ok", 4, 1);
  assert.equal(exact.content, "😀");
});

test("JSONL fixture preserves large events and distinguishes intermediate recovery", async () => {
  const fixture = [
    { type: "message_end", message: { role: "assistant", stopReason: "error", errorMessage: "transient", responseId: "bad", content: [], usage: usage(1) } },
    { type: "message_end", message: { role: "assistant", stopReason: "toolUse", responseId: "tool", content: [{ type: "text", text: "working" }], usage: usage(2) } },
    { type: "tool_execution_end", toolCallId: "read-1", result: { toolCallId: "read-1", content: [{ type: "text", text: "r".repeat(300_000) }], usage: usage(3) } },
    // The same tool usage is present again on the persisted toolResult message;
    // SDK totals count that message once, not both lifecycle notifications.
    { type: "message_end", message: { role: "toolResult", toolCallId: "read-1", usage: usage(3) } },
    // This is not an SDK JSON event and must not double-count tool usage.
    { type: "tool_result_end", toolCallId: "read-1", result: { usage: usage(99) } },
    { type: "compaction_end", result: { firstKeptEntryId: "compact-1", usage: usage(4) } },
    { type: "message_end", message: { role: "assistant", stopReason: "stop", responseId: "good", provider: "fixture", model: "model", content: [{ type: "text", text: "😀done" }], usage: usage(5) } },
  ];
  const state = createChildEventState();
  const parser = new JsonLineParser((line) => consumeChildEvent(state, JSON.parse(line)));
  const prefix = [...fixture.slice(0, 4), fixture[5]].map(JSON.stringify);
  const finalMessage = JSON.stringify(fixture[6]);
  const childScript = `const lines = ${JSON.stringify(prefix)}; lines.push(${JSON.stringify(finalMessage)}); process.stdout.write(lines.join(String.fromCharCode(10)) + String.fromCharCode(10));`;
  const child = spawn(process.execPath, ["-e", childScript], { stdio: ["ignore", "pipe", "ignore"] });
  for await (const chunk of child.stdout!) parser.push(chunk);
  parser.end();
  await once(child, "close");

  assert.equal(state.error, undefined);
  assert.equal(state.hasFinalResponse, true);
  assert.equal(state.finalOutput, "😀done");
  assert.equal(state.model, "fixture/model");
  assert.equal(state.usage.totals.input, 1 + 2 + 3 + 4 + 5);
  assert.equal(state.usage.totals.output, 2 * (1 + 2 + 3 + 4 + 5));
});

function usage(seed: number) {
  return {
    input: seed,
    output: seed * 2,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: seed * 3,
    cost: { input: seed, output: seed, cacheRead: 0, cacheWrite: 0, total: seed },
  };
}

test("process tree receives SIGKILL after ignored SIGTERM", async () => {
  if (process.platform === "win32") return;
  const child = spawn(
    process.execPath,
    ["-e", "process.on('SIGTERM',()=>{}); setInterval(()=>{},1000); process.stdout.write('ready')"],
    { detached: true, stdio: ["ignore", "pipe", "ignore"] },
  );
  await once(child.stdout!, "data"); // Handler is installed, not merely spawned.
  const started = Date.now();
  await terminateProcessTree(child, 50);
  assert.ok(Date.now() - started >= 45, "SIGTERM was ignored; escalation must run");
  assert.ok(Date.now() - started < 2000);
  assert.throws(() => process.kill(-child.pid!, 0), { code: "ESRCH" });
});

test("process-tree termination waits for a descendant after the parent exits", async () => {
  if (process.platform === "win32") return;
  const child = spawn(
    process.execPath,
    [
      "-e",
      "const {spawn}=require('node:child_process'); process.on('SIGTERM',()=>process.exit(0)); const d=spawn(process.execPath,['-e',\"process.on('SIGTERM',()=>{});setInterval(()=>{},1000);process.stdout.write('ready')\"],{stdio:['ignore','pipe','ignore']}); d.stdout.once('data',()=>process.stdout.write(String(d.pid))); setInterval(()=>{},1000)",
    ],
    { detached: true, stdio: ["ignore", "pipe", "ignore"] },
  );
  await new Promise<void>((resolve) => child.once("spawn", resolve));
  const [data] = await once(child.stdout!, "data") as [Buffer];
  const descendantPid = Number(data.toString());
  assert.ok(descendantPid > 0);
  await terminateProcessTree(child, 25);
  assert.throws(() => process.kill(descendantPid, 0), { code: "ESRCH" });
});
