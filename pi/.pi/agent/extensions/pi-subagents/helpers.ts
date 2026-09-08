import { spawnSync, type ChildProcess } from "node:child_process";
import { StringDecoder } from "node:string_decoder";
import * as fs from "node:fs/promises";
import * as os from "node:os";
import * as path from "node:path";

export interface UsageShape {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cacheWrite1h?: number;
  reasoning?: number;
  totalTokens: number;
  cost: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
    total: number;
  };
}

export interface UsageTotals extends UsageShape {
  turns: number;
}

export function emptyUsage(): UsageTotals {
  return {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    totalTokens: 0,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
    turns: 0,
  };
}

/**
 * Adds each usage-bearing event once. The key is deliberately supplied by the
 * event parser: assistant messages, tool results, and compaction results have
 * different identities. This prevents a child's aggregate tool usage from
 * being added again when its own detail tree is displayed.
 */
export class UsageAccumulator {
  readonly totals = emptyUsage();
  private readonly seen = new Set<string>();

  add(usage: Partial<UsageShape> | undefined, key: string): boolean {
    if (!usage || this.seen.has(key)) return false;
    this.seen.add(key);
    const n = (value: unknown): number =>
      typeof value === "number" && Number.isFinite(value) ? value : 0;
    this.totals.input += n(usage.input);
    this.totals.output += n(usage.output);
    this.totals.cacheRead += n(usage.cacheRead);
    this.totals.cacheWrite += n(usage.cacheWrite);
    this.totals.totalTokens += n(usage.totalTokens);
    this.totals.cost.input += n(usage.cost?.input);
    this.totals.cost.output += n(usage.cost?.output);
    this.totals.cost.cacheRead += n(usage.cost?.cacheRead);
    this.totals.cost.cacheWrite += n(usage.cost?.cacheWrite);
    this.totals.cost.total += n(usage.cost?.total);
    if (typeof usage.cacheWrite1h === "number") {
      this.totals.cacheWrite1h = (this.totals.cacheWrite1h ?? 0) + n(usage.cacheWrite1h);
    }
    if (typeof usage.reasoning === "number") {
      this.totals.reasoning = (this.totals.reasoning ?? 0) + n(usage.reasoning);
    }
    return true;
  }

  addAssistant(usage: Partial<UsageShape> | undefined, key: string): boolean {
    const added = this.add(usage, key);
    if (added) this.totals.turns++;
    return added;
  }

  toUsage(): UsageShape {
    const { turns: _turns, ...usage } = this.totals;
    return usage;
  }
}

export function isAbortError(error: unknown): boolean {
  return error instanceof Error && error.name === "AbortError";
}

export function throwIfAborted(signal?: AbortSignal): void {
  if (!signal?.aborted) return;
  const error = new Error("The operation was aborted");
  error.name = "AbortError";
  throw error;
}

/** A FIFO semaphore whose wait can be cancelled before work starts. */
export class AbortableSemaphore {
  readonly max: number;
  private inFlight = 0;
  private readonly waiters: Array<{
    signal?: AbortSignal;
    resolve: () => void;
    reject: (error: Error) => void;
    onAbort?: () => void;
  }> = [];

  constructor(max: number) {
    this.max = max;
    if (!Number.isInteger(max) || max < 1) {
      throw new Error(`maxConcurrency must be a positive integer (got ${max})`);
    }
  }

  get active(): number {
    return this.inFlight;
  }

  get queued(): number {
    return this.waiters.length;
  }

  async run<T>(fn: () => Promise<T>, signal?: AbortSignal): Promise<T> {
    throwIfAborted(signal);
    let acquired = false;
    try {
      if (this.inFlight < this.max) {
        // Reserve synchronously. A waiter must never be allowed to lose this
        // slot to a newcomer between releaseNext() and its continuation.
        this.inFlight++;
        acquired = true;
      } else {
        await this.waitForSlot(signal);
        // releaseNext() reserved the slot before resolving this waiter. Mark
        // it acquired before checking abort: an abort in this tiny window must
        // return the reservation and continue the FIFO chain.
        acquired = true;
        throwIfAborted(signal);
      }
      return await fn();
    } finally {
      if (acquired) {
        this.inFlight--;
        this.releaseNext();
      }
    }
  }

  private waitForSlot(signal?: AbortSignal): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const waiter = { signal, resolve, reject } as (typeof this.waiters)[number];
      const onAbort = () => {
        const index = this.waiters.indexOf(waiter);
        if (index >= 0) this.waiters.splice(index, 1);
        rejectAbort(reject);
      };
      waiter.onAbort = onAbort;
      this.waiters.push(waiter);
      signal?.addEventListener("abort", onAbort, { once: true });
      if (signal?.aborted) onAbort();
    });
  }

  private releaseNext(): void {
    const next = this.waiters.shift();
    if (!next) return;
    // Reserve before resolving. Promise continuations run later, and a new
    // caller can otherwise observe a free slot and steal it first.
    this.inFlight++;
    next.signal?.removeEventListener("abort", next.onAbort!);
    next.resolve();
  }
}

function rejectAbort(reject: (error: Error) => void): void {
  const error = new Error("The operation was aborted");
  error.name = "AbortError";
  reject(error);
}

export interface Deadline {
  signal: AbortSignal;
  cancel(): void;
}

export function createDeadline(ms: number): Deadline {
  if (!Number.isFinite(ms) || ms < 1) {
    throw new Error(`timeoutMs must be a positive number (got ${ms})`);
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(new DOMException("Timeout", "TimeoutError")), ms);
  timer.unref?.();
  return {
    signal: controller.signal,
    cancel: () => clearTimeout(timer),
  };
}

export function combineSignals(signals: Array<AbortSignal | undefined>): AbortSignal | undefined {
  const present = signals.filter((signal): signal is AbortSignal => Boolean(signal));
  if (present.length === 0) return undefined;
  if (present.length === 1) return present[0];
  return AbortSignal.any(present);
}

export function isTimeoutSignal(signal: AbortSignal | undefined): boolean {
  const reason = signal?.reason as { name?: string } | undefined;
  return reason?.name === "TimeoutError";
}

export type LifecycleStatus = "complete" | "partial" | "failed" | "cancelled" | "timed_out";

export function classifyLifecycleStatus(input: {
  exitCode: number;
  error?: string;
  hasFinalResponse: boolean;
  termination?: "cancelled" | "timed_out";
}): LifecycleStatus {
  if (input.termination) return input.termination;
  if (input.error || input.exitCode !== 0) return "failed";
  return input.hasFinalResponse ? "complete" : "partial";
}

export interface TruncationResult {
  content: string;
  truncated: boolean;
  outputBytes: number;
  totalBytes: number;
  outputLines: number;
  totalLines: number;
}

/**
 * Line framing for Pi's JSONL protocol. The old 256 KiB guard rejected valid
 * tool results; complete lines are delivered regardless of size. Only a
 * broken unterminated line is bounded to avoid retaining an accidental stream
 * forever.
 */
export class JsonLineParser {
  private readonly decoder = new StringDecoder("utf8");
  private buffer = "";

  private readonly onLine: (line: string) => void;
  private readonly onOverflow?: (message: string) => void;
  private readonly maxUnterminatedBytes: number;

  constructor(
    onLine: (line: string) => void,
    onOverflow?: (message: string) => void,
    maxUnterminatedBytes = 16 * 1024 * 1024,
  ) {
    this.onLine = onLine;
    this.onOverflow = onOverflow;
    this.maxUnterminatedBytes = maxUnterminatedBytes;
  }

  push(chunk: Uint8Array): void {
    this.buffer += this.decoder.write(chunk);
    this.drain();
    if (Buffer.byteLength(this.buffer, "utf8") > this.maxUnterminatedBytes) {
      this.buffer = "";
      this.onOverflow?.("Child stdout exceeded the unterminated event limit");
    }
  }

  end(): void {
    this.buffer += this.decoder.end();
    this.drain();
    if (this.buffer.trim()) this.onLine(this.buffer);
    this.buffer = "";
  }

  private drain(): void {
    let newline;
    while ((newline = this.buffer.indexOf("\n")) !== -1) {
      this.onLine(this.buffer.slice(0, newline).replace(/\r$/, ""));
      this.buffer = this.buffer.slice(newline + 1);
    }
  }
}

export interface ChildEventState {
  readonly usage: UsageAccumulator;
  partialOutput: string;
  finalOutput: string;
  hasFinalResponse: boolean;
  error?: string;
  model?: string;
  tokens: number;
  /** Used only when an event has no durable identity of its own. */
  eventSequence: number;
}

export function createChildEventState(): ChildEventState {
  return {
    usage: new UsageAccumulator(),
    partialOutput: "",
    finalOutput: "",
    hasFinalResponse: false,
    tokens: 0,
    eventSequence: 0,
  };
}

/**
 * Consume the durable JSON event shapes emitted by Pi's JSON mode. In
 * particular, tool usage lives on tool_execution_end.result and compaction
 * usage on compaction_end.result; there is no tool_result_end event in the
 * installed SDK JSON contract.
 */
export function consumeChildEvent(state: ChildEventState, evt: any): void {
  const sequence = ++state.eventSequence;
  if (evt?.type === "tool_execution_end") {
    const toolResult = evt.result;
    state.usage.add(
      toolResult?.usage,
      `tool:${evt.toolCallId || toolResult?.toolCallId || sequence}`,
    );
    return;
  }
  if (evt?.type === "compaction_end") {
    const result = evt.result;
    // CompactionResult has no durable result-entry id in the JSON contract;
    // sequence keeps two legitimate compactions with the same cut point from
    // collapsing into one usage row.
    state.usage.add(result?.usage, `compaction:${sequence}`);
    return;
  }
  if (evt?.type !== "message_end" || evt.message?.role !== "assistant") return;

  const message = evt.message;
  const key = `assistant:${message.responseId || message.timestamp || sequence}`;
  state.usage.addAssistant(message.usage, key);
  const usage = message.usage;
  if (usage) {
    state.tokens =
      usage.totalTokens ||
      (usage.input || 0) +
        (usage.output || 0) +
        (usage.cacheRead || 0) +
        (usage.cacheWrite || 0);
  }
  if (message.provider && (message.responseModel || message.model)) {
    state.model = `${message.provider}/${message.responseModel || message.model}`;
  } else if (message.model) {
    state.model = message.model;
  }

  const text = extractAssistantText(message.content);
  // Only the latest terminal, non-empty answer can establish completion.
  // Length/deferred are unfinished, even when they contain useful prose.
  state.hasFinalResponse = false;
  state.finalOutput = "";
  if (text) state.partialOutput = text;
  const commentary = Array.isArray(message.content) && message.content.some((part: any) => {
    if (part?.type !== "text" || typeof part.textSignature !== "string") return false;
    try { return JSON.parse(part.textSignature).phase === "commentary"; } catch { return false; }
  });
  const failed =
    message.stopReason === "error" ||
    message.stopReason === "aborted" ||
    Boolean(message.errorMessage);
  if (failed) {
    state.error = message.errorMessage || `Child stopped with ${message.stopReason}`;
    return;
  }

  // A later successful response supersedes a transient provider error. A
  // toolUse response is an intermediate turn, not the final child answer.
  state.error = undefined;
  if (message.stopReason === "stop" && text.trim() && !commentary) {
    state.hasFinalResponse = true;
    state.finalOutput = text;
  }
}

function extractAssistantText(content: unknown): string {
  if (!content) return "";
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter((part: any) => part?.type === "text")
    .map((part: any) => part.text)
    .join("\n");
}

/** UTF-8 and line aware head truncation. Never splits a code point. */
export function truncateUtf8Head(
  text: string,
  maxBytes: number,
  maxLines: number,
): TruncationResult {
  const totalBytes = Buffer.byteLength(text, "utf8");
  const lines = text.split("\n");
  const totalLines = lines.length;
  let selected = lines.slice(0, Math.max(1, maxLines)).join("\n");
  let outputBytes = Buffer.byteLength(selected, "utf8");
  if (outputBytes > maxBytes) {
    // Iterate Unicode code points instead of decoding a cut Buffer. The latter
    // turns an incomplete trailing sequence into U+FFFD, which is observable
    // and can fit inside the requested byte budget at some boundaries.
    let kept = "";
    let keptBytes = 0;
    for (const codePoint of selected) {
      const size = Buffer.byteLength(codePoint, "utf8");
      if (keptBytes + size > maxBytes) break;
      kept += codePoint;
      keptBytes += size;
    }
    selected = kept;
    outputBytes = keptBytes;
  }
  const outputLines = selected ? selected.split("\n").length : 0;
  return {
    content: selected,
    truncated: outputBytes < totalBytes || outputLines < totalLines,
    outputBytes,
    totalBytes,
    outputLines,
    totalLines,
  };
}

export async function writeRecoverableArtifact(
  text: string,
  prefix = "pi-subagent-output-",
): Promise<string> {
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), prefix));
  const file = path.join(dir, "output.txt");
  await fs.writeFile(file, text, { encoding: "utf8", mode: 0o600 });
  return file;
}

/** Send a signal to the whole detached process group, not just the pi child. */
export function signalProcessTree(proc: ChildProcess, signal: NodeJS.Signals): boolean {
  if (!proc.pid) return false;
  try {
    if (process.platform !== "win32") process.kill(-proc.pid, signal);
    else if (signal === "SIGKILL") {
      // Windows has no process groups compatible with negative kill; taskkill
      // is the built-in equivalent that includes descendants (/t).
      spawnSync("taskkill", ["/pid", String(proc.pid), "/t", "/f"], { stdio: "ignore" });
    } else process.kill(proc.pid, signal);
    return true;
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "ESRCH") return false;
    try {
      return proc.kill(signal);
    } catch {
      return false;
    }
  }
}

function processGroupExists(pid: number): boolean {
  if (process.platform === "win32") return false;
  try {
    process.kill(-pid, 0);
    return true;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code !== "ESRCH";
  }
}

function waitForProcessAndGroup(
  proc: ChildProcess,
  pid: number,
  timeoutMs = 2000,
): Promise<boolean> {
  return new Promise((resolve) => {
    let done = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    let poll: ReturnType<typeof setInterval> | undefined;
    const finish = (value: boolean) => {
      if (done) return;
      done = true;
      if (timer) clearTimeout(timer);
      if (poll) clearInterval(poll);
      proc.removeListener("close", check);
      proc.removeListener("exit", check);
      resolve(value);
    };
    const check = () => {
      if ((proc.exitCode !== null || proc.signalCode !== null) && !processGroupExists(pid)) {
        finish(true);
      }
    };
    proc.on("close", check);
    proc.on("exit", check);
    // Descendant exit does not emit events on the already-closed parent.
    // Poll the group, with a finite ceiling even for unreaped zombies.
    timer = setTimeout(() => finish(false), timeoutMs);
    poll = setInterval(check, Math.min(20, timeoutMs));
    check();
  });
}

/**
 * Terminate the process group and wait for the group, not merely the parent
 * ChildProcess, to disappear. A parent can exit after SIGTERM while a
 * descendant ignores it; SIGKILL is sent to the group after the grace period.
 */
export async function terminateProcessTree(
  proc: ChildProcess,
  graceMs = 1000,
): Promise<void> {
  let pid = proc.pid;
  if (!pid && proc.exitCode === null && proc.signalCode === null) {
    // spawn() assigns pid asynchronously. Waiting for spawn closes the race
    // where an abort arrives immediately after creating the ChildProcess.
    await new Promise<void>((resolve) => {
      const cleanup = () => {
        proc.removeListener("spawn", onSpawn);
        proc.removeListener("close", onClose);
        proc.removeListener("error", onError);
      };
      const onSpawn = () => {
        cleanup();
        void terminateProcessTree(proc, graceMs).then(resolve, resolve);
      };
      const onClose = () => {
        cleanup();
        resolve();
      };
      const onError = () => {
        cleanup();
        resolve();
      };
      proc.once("spawn", onSpawn);
      proc.once("close", onClose);
      proc.once("error", onError);
    });
    return;
  }
  if (!pid) return;
  if (process.platform === "win32") {
    if (proc.exitCode === null && proc.signalCode === null) signalProcessTree(proc, "SIGTERM");
    await waitForProcessAndGroup(proc, pid, graceMs);
    if (proc.exitCode === null && proc.signalCode === null) signalProcessTree(proc, "SIGKILL");
    // taskkill /t /f is synchronous on Windows; still wait for the parent
    // close event so callers never race the pipe cleanup.
    if (!await waitForProcessAndGroup(proc, pid)) throw new Error("Timed out waiting for child termination");
    return;
  }

  if (!processGroupExists(pid) && proc.exitCode !== null) return;
  signalProcessTree(proc, "SIGTERM");
  const endedGracefully = await waitForProcessAndGroup(proc, pid, graceMs);
  if (!endedGracefully || processGroupExists(pid)) signalProcessTree(proc, "SIGKILL");
  if (!await waitForProcessAndGroup(proc, pid)) throw new Error("Timed out waiting for child process group termination");
}
