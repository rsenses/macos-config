/**
 * Minimal subagents extension.
 *
 * Registers a single `subagent` tool with five agents: scout, researcher, planner, worker, and manual-only plan-reviewer.
 * Supports single and parallel execution. Output is verbal only (no file handoff).
 */
import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { Usage } from "@earendil-works/pi-ai";
import { getSupportedThinkingLevels } from "@earendil-works/pi-ai/compat";
import {
  AbortableSemaphore,
  classifyLifecycleStatus,
  combineSignals,
  createChildEventState,
  consumeChildEvent,
  createDeadline,
  emptyUsage,
  isAbortError,
  isTimeoutSignal,
  JsonLineParser,
  terminateProcessTree,
  throwIfAborted,
  truncateUtf8Head,
  writeRecoverableArtifact,
} from "./helpers.ts";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import {
  getMarkdownTheme,
  parseFrontmatter,
  withFileMutationQueue,
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
} from "@mariozechner/pi-coding-agent";
import {
  Container,
  Markdown,
  Spacer,
  Text,
  visibleWidth,
} from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

// ── Types ──────────────────────────────────────────────────────────────

export interface AgentConfig {
  name: string;
  description: string;
  tools: string[];
  model: string;
  thinking: string;
  systemPrompt: string;
  filePath: string;
  /**
   * If this agent has the `subagent` tool, restrict which agents it may spawn.
   * Passed to the child pi process via `PI_SUBAGENT_ALLOWED` so the child's
   * subagents extension filters its own registry before exposing it to the LLM.
   * `undefined` means no restriction (child sees every registered agent).
   */
  subagentAgents?: string[];
}

interface ToolEvent {
  tool: string;
  args: string;
  /** Matches the producing tool_execution_start/update/end event. */
  toolCallId?: string;
  /**
   * "running" while between tool_execution_start and tool_execution_end; flipped
   * to "done" on end. We store every in-flight call in recentTools (keyed by
   * toolCallId) rather than a single current-tool slot, because pi-agent-core
   * dispatches a turn's tool calls in parallel via Promise.all — a single slot
   * would let the second start overwrite the first.
   */
  status: "running" | "done";
  /**
   * Live progress of subagents spawned by this tool call. Populated only for
   * `subagent` tool calls, from the `partialResult.details.results` payload of
   * `tool_execution_update` events (and refreshed once more from the end
   * event's final results). Recursive: each child's own progress may carry
   * further children via its `recentTools[i].children`.
   */
  children?: AgentResult[];
}

type AgentStatus =
  | "pending"
  | "running"
  | "complete"
  | "partial"
  | "failed"
  | "cancelled"
  | "timed_out"
  | "blocked";

interface AgentProgress {
  agent: string;
  status: AgentStatus;
  task: string;
  /**
   * Chronological log of tool calls — running and done interleaved. The
   * renderer prefixes running entries with `▸` and done ones with `  `.
   */
  recentTools: ToolEvent[];
  toolCount: number;
  tokens: number;
  durationMs: number;
  lastMessage: string;
  error?: string;
}

interface AgentResult {
  agent: string;
  task: string;
  status: AgentStatus;
  output: string;
  exitCode: number;
  progress: AgentProgress;
  /** Requested model, retained for diagnosing selection/fallback. */
  requestedModel?: string;
  thinking?: string;
  totalDurationMs?: number;
  queueDurationMs?: number;
  /** Effective provider/model reported by the child response. */
  model?: string;
  contextWindow?: number;
  artifact?: string;
  usage: {
    input: number;
    output: number;
    cacheRead: number;
    cacheWrite: number;
    cacheWrite1h?: number;
    reasoning?: number;
    totalTokens: number;
    cost: Usage["cost"];
    turns: number;
  };
}

interface Details {
  status: AgentStatus;
  results: AgentResult[];
  /** Complete nested usage, including tool-result and compaction usage. */
  usage?: Usage;
  artifact?: string;
}

// ── Config ─────────────────────────────────────────────────────────────

interface ExtensionConfig {
  maxConcurrency?: number;
  timeoutMs?: number;
  maxOutputBytes?: number;
  maxOutputLines?: number;
}

const EXT_DIR = path.dirname(new URL(import.meta.url).pathname);
const AGENTS_DIR = path.join(EXT_DIR, "agents");
const TOOLS_DIR = path.join(EXT_DIR, "tools");
const CONFIG_PATH = path.join(EXT_DIR, "config.json");
const DEFAULT_MAX_CONCURRENCY = 2;
const DEFAULT_TIMEOUT_MS = 10 * 60 * 1000;
const DEFAULT_OUTPUT_BYTES = Math.min(DEFAULT_MAX_BYTES, 16 * 1024);
const DEFAULT_OUTPUT_LINES = Math.min(DEFAULT_MAX_LINES, 200);
// Complete JSON events may legitimately exceed 256 KiB (for example a read
// result). Only an unterminated/broken line is bounded; valid complete lines
// are parsed regardless of size.
const MAX_UNTERMINATED_EVENT_BYTES = 16 * 1024 * 1024;
const MAX_STDERR_BYTES = 64 * 1024;
const MAX_CAPTURED_OUTPUT_BYTES = 1024 * 1024;
const MAX_RECENT_TOOLS = 100;

function loadConfig(): ExtensionConfig {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      return JSON.parse(fs.readFileSync(CONFIG_PATH, "utf-8")) as ExtensionConfig;
    }
  } catch (error) {
    throw new Error(`Cannot load pi-subagents config: ${String(error)}`);
  }
  return {};
}

function validateConfig(config: ExtensionConfig): Required<ExtensionConfig> {
  const maxConcurrency = config.maxConcurrency ?? DEFAULT_MAX_CONCURRENCY;
  const timeoutMs = config.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const maxOutputBytes = config.maxOutputBytes ?? DEFAULT_OUTPUT_BYTES;
  const maxOutputLines = config.maxOutputLines ?? DEFAULT_OUTPUT_LINES;
  if (!Number.isInteger(maxConcurrency) || maxConcurrency < 1) {
    throw new Error(`Invalid pi-subagents maxConcurrency: ${maxConcurrency}`);
  }
  if (!Number.isFinite(timeoutMs) || timeoutMs < 1) {
    throw new Error(`Invalid pi-subagents timeoutMs: ${timeoutMs}`);
  }
  if (!Number.isInteger(maxOutputBytes) || maxOutputBytes < 1) {
    throw new Error(`Invalid pi-subagents maxOutputBytes: ${maxOutputBytes}`);
  }
  if (!Number.isInteger(maxOutputLines) || maxOutputLines < 1) {
    throw new Error(`Invalid pi-subagents maxOutputLines: ${maxOutputLines}`);
  }
  return { maxConcurrency, timeoutMs, maxOutputBytes, maxOutputLines };
}

// Built-in tools that pi provides natively (no extension needed)
const BUILTIN_TOOLS = new Set([
  "read",
  "write",
  "edit",
  "bash",
  "grep",
  "find",
  "ls",
]);

// Custom tools that require loading an extension into the subagent process
const EXT_BASE = path.dirname(EXT_DIR);
const SEARCH_EXTENSION = path.join(os.homedir(), ".pi", "agent", "npm", "node_modules", "pi-gpt-search", "src", "index.ts");
const CUSTOM_TOOL_EXTENSIONS: Record<string, string> = {
  web_fetch: path.join(EXT_BASE, "web-fetch", "index.ts"),
  safe_bash: path.join(TOOLS_DIR, "safe-bash.ts"),
  ast_grep: path.join(EXT_BASE, "ast-grep.ts"),
  "codex-research": SEARCH_EXTENSION,
  "codex-search": SEARCH_EXTENSION,
  // `subagent` is the tool this very extension registers. Listing it here lets
  // a parent agent grant it to a child agent — the child pi process loads this
  // same index.ts via `--extension`, sees its own subagent tool, and (if
  // PI_SUBAGENT_ALLOWED is set) only registers the allowlisted agents.
  subagent: path.join(EXT_DIR, "index.ts"),
};

// ── Agent Discovery & Registration ────────────────────────────────────

let agents: AgentConfig[] = [];

// Read once at module load. If we're a child subagent process whose parent
// pinned an allowlist, we silently ignore any agent (built-in OR registered
// later by a third-party extension) that isn't in the list.
const SUBAGENT_ALLOWLIST: string[] | undefined = (() => {
  const raw = process.env.PI_SUBAGENT_ALLOWED;
  if (!raw) return undefined;
  const list = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  return list.length > 0 ? list : undefined;
})();

export function registerAgent(config: AgentConfig): void {
  if (SUBAGENT_ALLOWLIST && !SUBAGENT_ALLOWLIST.includes(config.name)) return;
  if (agents.find((a) => a.name === config.name)) {
    throw new Error(`Agent already registered: ${config.name}`);
  }
  agents.push(config);
}

export function unregisterAgent(name: string): void {
  agents = agents.filter((a) => a.name !== name);
}

// Expose registration functions globally so other extensions loaded via jiti
// (which creates separate module instances) can access the shared agents array.
(globalThis as any).__pi_subagents = { registerAgent, unregisterAgent };

function loadAgents(): AgentConfig[] {
  const agents: AgentConfig[] = [];
  if (!fs.existsSync(AGENTS_DIR)) return agents;
  for (const entry of fs.readdirSync(AGENTS_DIR)) {
    if (!entry.endsWith(".md")) continue;
    const filePath = path.join(AGENTS_DIR, entry);
    const content = fs.readFileSync(filePath, "utf-8");
    const { frontmatter, body } =
      parseFrontmatter<Record<string, string>>(content);
    if (!frontmatter.name) continue;
    const tools = (frontmatter.tools || "")
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);
    const rawSubagentAgents = (frontmatter as Record<string, string>)
      .subagent_agents;
    const subagentAgents = rawSubagentAgents
      ? rawSubagentAgents
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean)
      : undefined;
    agents.push({
      name: frontmatter.name,
      description: frontmatter.description || "",
      tools,
      model: frontmatter.model || "",
      thinking: frontmatter.thinking || "medium",
      systemPrompt: body,
      filePath,
      subagentAgents,
    });
  }
  return agents;
}

// ── Pi Binary Resolution ──────────────────────────────────────────────

function resolvePiBinary(): { command: string; baseArgs: string[] } {
  // Resolve the pi entry point from process.argv[1]
  const entry = process.argv[1];
  if (entry) {
    try {
      const realEntry = fs.realpathSync(entry);
      if (/[\\/]pi-coding-agent[\\/].*[\\/]cli\.js$/i.test(realEntry)) {
        return { command: process.execPath, baseArgs: [realEntry] };
      }
    } catch {}
  }
  return { command: "pi", baseArgs: [] };
}

// ── Formatting Utilities ──────────────────────────────────────────────

function formatTokens(n: number): string {
  return n < 1000
    ? String(n)
    : n < 10000
      ? `${(n / 1000).toFixed(1)}k`
      : `${Math.round(n / 1000)}k`;
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60000) return `${(ms / 1000).toFixed(1)}s`;
  return `${Math.floor(ms / 60000)}m${Math.floor((ms % 60000) / 1000)}s`;
}

function formatContextUsage(
  tokens: number,
  contextWindow: number | undefined,
): string {
  if (!contextWindow) return `${formatTokens(tokens)} ctx`;
  const pct = (tokens / contextWindow) * 100;
  const maxStr =
    contextWindow >= 1_000_000
      ? `${(contextWindow / 1_000_000).toFixed(1)}M`
      : `${Math.round(contextWindow / 1000)}k`;
  return `${pct.toFixed(1)}%/${maxStr}`;
}

function formatToolPreview(
  name: string,
  args: Record<string, unknown>,
): string {
  switch (name) {
    case "bash":
    case "safe_bash":
      return `$ ${((args.command as string) || "").slice(0, 80)}`;
    case "read":
      return `read ${(args.path as string) || ""}`;
    case "write":
      return `write ${(args.path as string) || ""}`;
    case "edit":
      return `edit ${(args.path as string) || ""}`;
    case "grep":
      return `grep ${(args.pattern as string) || ""}`;
    case "find":
      return `find ${(args.pattern as string) || ""}`;
    case "ls":
      return `ls ${(args.path as string) || "."}`;
    case "web_fetch":
      return `fetch ${(args.url as string) || ""}`;
    default: {
      const s = JSON.stringify(args);
      return `${name} ${s.slice(0, 60)}`;
    }
  }
}

function truncLine(text: string, maxWidth: number): string {
  // Collapse embedded newlines first so we render exactly one visible line.
  // We can't strip them inside `text` directly (would also touch ANSI escapes
  // like "\x1b[0m"), so we only target literal \r and \n outside of escapes.
  if (text.includes("\n") || text.includes("\r")) {
    text = text.replace(/\r?\n/g, "↵ ");
  }
  if (visibleWidth(text) <= maxWidth) return text;
  // Simple truncation - strip to fit
  let result = "";
  let width = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    // Skip ANSI escape sequences
    if (ch === "\x1b") {
      const match = text.slice(i).match(/^\x1b\[[0-9;]*m/);
      if (match) {
        result += match[0];
        i += match[0].length - 1;
        continue;
      }
    }
    if (width >= maxWidth - 1) {
      return result + "…";
    }
    result += ch;
    width++;
  }
  return result;
}

// ── Subagent Execution ────────────────────────────────────────────────

async function buildPiArgs(
  agent: AgentConfig,
  task: string,
  cwd: string,
): Promise<{
  args: string[];
  tempDir: string;
  childEnv: NodeJS.ProcessEnv;
}> {
  const modelSeparator = agent.model?.indexOf("/") ?? -1;
  if (!agent.model || modelSeparator <= 0 || modelSeparator === agent.model.length - 1) {
    throw new Error(`Agent ${agent.name} has no explicit provider/model selection`);
  }
  // Fail before allocating temporary resources, never silently drop tools.
  if (!/^[a-zA-Z0-9_-]+$/.test(agent.name)) throw new Error(`Invalid agent name: ${agent.name}`);
  for (const tool of agent.tools) {
    if (tool === "subagent") throw new Error("Nested delegation is disabled; ask the principal to coordinate");
    if (BUILTIN_TOOLS.has(tool)) continue;
    const extension = CUSTOM_TOOL_EXTENSIONS[tool];
    if (!extension || !fs.existsSync(extension)) throw new Error(`Unavailable tool ${tool} for ${agent.name}${extension ? `: ${extension}` : ""}`);
  }
  const piBin = resolvePiBinary();
  const tempDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-sub-"));

  try {
  // Write system prompt to temp file
  const promptPath = path.join(tempDir, `${agent.name}.md`);
  await withFileMutationQueue(promptPath, async () => {
    await fs.promises.writeFile(promptPath, agent.systemPrompt, {
      encoding: "utf-8",
      mode: 0o600,
    });
  });

  const args = [
    ...piBin.baseArgs,
    "--mode",
    "json",
    "-p",
    "--no-session",
    "--no-skills",
  ];

  // Separate builtin tools from custom tools. Both kinds share the same
  // --tools allowlist in pi; --no-tools would disable extension tools too.
  const allowlist: string[] = [];
  const extensionPaths = new Set<string>();

  for (const tool of agent.tools) {
    // Nested delegation is intentionally disabled at this boundary. It creates
    // an unbounded per-process tree and makes the configured concurrency cap
    // misleading; a worker reports `blocked` and the parent can decide.
    if (tool === "subagent") continue;
    if (BUILTIN_TOOLS.has(tool)) {
      allowlist.push(tool);
    } else if (CUSTOM_TOOL_EXTENSIONS[tool]) {
      allowlist.push(tool);
      extensionPaths.add(CUSTOM_TOOL_EXTENSIONS[tool]);
    }
  }

  // Use --no-extensions then add only what we need
  args.push("--no-extensions");

  if (allowlist.length > 0) {
    // --tools is a unified allowlist that applies to built-in, extension, and custom tools.
    args.push("--tools", allowlist.join(","));
  } else {
    // Agent declared no tools — disable everything.
    args.push("--no-tools");
  }

  for (const extPath of extensionPaths) {
    args.push("--extension", extPath);
  }

  // Explicit selection; the parent verifies the exact provider/model first.
  args.push("--model", agent.model);
  args.push("--thinking", agent.thinking);
  args.push("--no-prompt-templates", "--no-themes");
  // Replace only Pi's generic default, never an explicitly configured SYSTEM.md.
  // Pi still appends AGENTS.md/CLAUDE.md context files to this lean prompt.
  const hasCustomSystem = [path.join(cwd, ".pi", "SYSTEM.md"), path.join(os.homedir(), ".pi", "agent", "SYSTEM.md")].some(file => fs.existsSync(file));
  if (!hasCustomSystem) args.push("--system-prompt", path.join(EXT_DIR, "SYSTEM.md"));
  args.push("--append-system-prompt", promptPath);

  // Handle long tasks by writing to file
  const TASK_LIMIT = 8000;
  if (task.length > TASK_LIMIT) {
    const taskPath = path.join(tempDir, "task.md");
    await withFileMutationQueue(taskPath, async () => {
      await fs.promises.writeFile(taskPath, `Task: ${task}`, {
        encoding: "utf-8",
        mode: 0o600,
      });
    });
    args.push(`@${taskPath}`);
  } else {
    args.push(`Task: ${task}`);
  }

  // Keep the environment explicit so a child cannot inherit a stale nested
  // delegation allowlist from a grandparent process. Nested delegation is
  // disabled in the tool allowlist above, regardless of agent frontmatter.
  const childEnv: NodeJS.ProcessEnv = { ...process.env };
  delete childEnv.PI_SUBAGENT_ALLOWED;

  return { args: [piBin.command, ...args], tempDir, childEnv };
  } catch (error) {
    await fs.promises.rm(tempDir, { recursive: true, force: true });
    throw error;
  }
}

function extractTextFromContent(content: unknown): string {
  if (!content) return "";
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter((c: any) => c.type === "text")
      .map((c: any) => c.text)
      .join("\n");
  }
  return "";
}

/** Collapse any whitespace run (incl. newlines) into a single space. Used to
 *  keep tool-arg previews to one renderable line in collapsed view. */
function flatten(s: string): string {
  return s.replace(/\s+/g, " ").trim();
}

function toPiUsage(usage: AgentResult["usage"]): Usage {
  const { turns: _turns, ...result } = usage;
  return result as Usage;
}

function renderCompactResult(result: AgentResult): string {
  const output = result.output || "(no output)";
  const error = result.progress.error ? `\nError: ${result.progress.error}` : "";
  return `[execution=${result.status}]${error}\n${output}`;
}

// Per-event hard cap on stored arg previews. Even in expanded view we don't
// want a 50KB bash heredoc sitting in memory per tool call across last-20
// `recentTools` slots per agent across N agents. A few KB covers any realistic
// command; anything longer is almost certainly a generated payload the user
// doesn't need to read inline anyway.
const MAX_ARG_PREVIEW = 4000;

function extractToolArgsPreview(args: Record<string, unknown>): string {
  const cap = (s: string) =>
    s.length > MAX_ARG_PREVIEW ? s.slice(0, MAX_ARG_PREVIEW) + "…" : s;
  if (args.command) return cap(flatten(String(args.command)));
  if (args.path) return cap(flatten(String(args.path)));
  if (args.query) return `"${cap(flatten(String(args.query)))}"`;
  if (args.url) return cap(flatten(String(args.url)));
  if (args.pattern) return cap(flatten(String(args.pattern)));
  // `subagent` tool args: show which agent(s) it's calling, not the full task body.
  if (args.agent) return flatten(String(args.agent));
  if (Array.isArray(args.tasks)) {
    const names = (args.tasks as Array<{ agent?: string }>)
      .map((t) => t?.agent || "?")
      .join(", ");
    return `parallel(${names})`;
  }
  return cap(flatten(JSON.stringify(args)));
}

async function runSubagent(
  agent: AgentConfig,
  task: string,
  cwd: string,
  signal: AbortSignal | undefined,
  onUpdate?: (progress: AgentProgress, usage: AgentResult["usage"]) => void,
  outputLimits: { maxBytes: number; maxLines: number } = {
    maxBytes: DEFAULT_OUTPUT_BYTES,
    maxLines: DEFAULT_OUTPUT_LINES,
  },
): Promise<AgentResult> {
  throwIfAborted(signal);
  const { args, tempDir, childEnv } = await buildPiArgs(agent, task, cwd);
  const command = args[0];
  const spawnArgs = args.slice(1);

  const eventState = createChildEventState();
  const usage = eventState.usage;
  let termination: "cancelled" | "timed_out" | undefined;
  const result: AgentResult = {
    agent: agent.name,
    task,
    status: "running",
    output: "",
    exitCode: 0,
    requestedModel: agent.model,
    model: agent.model,
    usage: usage.totals,
    progress: {
      agent: agent.name,
      status: "running",
      task,
      recentTools: [],
      toolCount: 0,
      tokens: 0,
      durationMs: 0,
      lastMessage: "",
    },
  };

  const startTime = Date.now();
  const progress = result.progress;

  const fireUpdate = throttle(() => {
    progress.durationMs = Date.now() - startTime;
    onUpdate?.(progress, result.usage);
  }, 150);

  let exitCode: number;
  try {
  exitCode = await new Promise<number>((resolve) => {
    const proc = spawn(command, spawnArgs, {
      cwd,
      stdio: ["ignore", "pipe", "pipe"],
      detached: process.platform !== "win32",
      env: childEnv,
    });

    let stderrBuf = "";
    let protocolError: string | undefined;
    let abortHandler: (() => void) | undefined;
    let terminationPromise: Promise<void> | undefined;
    let settled = false;

    const processLine = (line: string) => {
      if (!line.trim()) return;
      try {
        const evt = JSON.parse(line) as any;
        progress.durationMs = Date.now() - startTime;

        if (evt.type === "tool_execution_start") {
          progress.toolCount++;
          progress.recentTools.push({
            tool: evt.toolName,
            args: extractToolArgsPreview(
              (evt.args || {}) as Record<string, unknown>,
            ),
            toolCallId: evt.toolCallId,
            status: "running",
          });
          if (progress.recentTools.length > MAX_RECENT_TOOLS) {
            progress.recentTools.splice(0, progress.recentTools.length - MAX_RECENT_TOOLS);
          }
          fireUpdate();
        }

        // Subagents emit `tool_execution_update` while their own subagent tool
        // runs — the partial result carries the live nested AgentResult[]. We
        // surface that as `children` on the in-flight ToolEvent so the renderer
        // can inline grandchild activity beneath the parent's tool row.
        if (evt.type === "tool_execution_update") {
          const partial = evt.partialResult as
            | { details?: { results?: unknown } }
            | undefined;
          const nested = partial?.details?.results;
          if (
            evt.toolName === "subagent" &&
            Array.isArray(nested) &&
            evt.toolCallId
          ) {
            const hit = progress.recentTools.find(
              (t) => t.toolCallId === evt.toolCallId,
            );
            if (hit) {
              hit.children = nested as AgentResult[];
              fireUpdate();
            }
          }
        }

        if (evt.type === "tool_execution_end") {
          const hit = evt.toolCallId
            ? progress.recentTools.find((t) => t.toolCallId === evt.toolCallId)
            : undefined;
          if (hit) {
            hit.status = "done";
            // Prefer the end event's final results over the last throttled
            // update — throttling can drop the trailing update, leaving stale
            // children visible on a tool that has actually completed.
            const finalResult = evt.result as
              | { details?: { results?: unknown } }
              | undefined;
            const finalChildren = finalResult?.details?.results;
            if (evt.toolName === "subagent" && Array.isArray(finalChildren)) {
              hit.children = finalChildren as AgentResult[];
            }
          }
          consumeChildEvent(eventState, evt);
          fireUpdate();
        }

        if (evt.type === "message_end" && evt.message) {
          if (evt.message.role === "assistant") {
            consumeChildEvent(eventState, evt);
            progress.error = eventState.error || protocolError;
            progress.tokens = eventState.tokens;
            result.model = eventState.model;
            const text = extractTextFromContent(evt.message.content);
            if (text) {
              // Extract just the prose "thinking" text — skip code blocks.
              const proseLines: string[] = [];
              let inCodeBlock = false;
              for (const line of text.split("\n")) {
                if (line.trimStart().startsWith("```")) {
                  inCodeBlock = !inCodeBlock;
                  continue;
                }
                if (!inCodeBlock && line.trim()) proseLines.push(line.trim());
              }
              if (proseLines.length > 0) progress.lastMessage = proseLines.slice(0, 3).join(" ").slice(0, 1000);
            }
          }
          fireUpdate();
        }

        // Pi's JSON stream has no tool_result_end event. Tool-result usage is
        // carried by tool_execution_end.result and is accounted above.
        if (evt.type === "compaction_end") {
          consumeChildEvent(eventState, evt);
          fireUpdate();
        }
      } catch {
        // Non-JSON lines are expected
      }
    };

    const lineParser = new JsonLineParser(
      processLine,
      (message) => {
        protocolError ||= message;
        progress.error ||= message;
      },
      MAX_UNTERMINATED_EVENT_BYTES,
    );
    proc.stdout.on("data", (d: Buffer) => lineParser.push(d));

    proc.stderr.on("data", (d: Buffer) => {
      const next = `${stderrBuf}${d.toString("utf8")}`;
      const bytes = Buffer.from(next, "utf8");
      stderrBuf = bytes.length > MAX_STDERR_BYTES
        ? bytes.subarray(bytes.length - MAX_STDERR_BYTES).toString("utf8")
        : next;
    });

    proc.on("close", (code) => {
      if (settled) return;
      settled = true;
      void (async () => {
        // The parent pipe can close before descendants in its process group.
        // Do not resolve runSubagent until terminateProcessTree has completed.
        await terminationPromise;
        if (abortHandler && signal) signal.removeEventListener("abort", abortHandler);
        lineParser.end();
        if (code !== 0 && stderrBuf.trim() && !progress.error) {
          progress.error = stderrBuf.trim();
        }
        resolve(code ?? 1);
      })();
    });

    proc.on("error", (error) => {
      // ChildProcess emits close after error. Let that single path settle the
      // promise so an in-flight process-tree termination is still awaited.
      progress.error ||= error.message;
    });

    if (signal) {
      const kill = () => {
        termination = isTimeoutSignal(signal) ? "timed_out" : "cancelled";
        terminationPromise ??= terminateProcessTree(proc, 3000).catch(error => {
          progress.error = `Process cleanup failed: ${String(error)}`;
        });
      };
      abortHandler = kill;
      if (signal.aborted) kill();
      else signal.addEventListener("abort", kill, { once: true });
    }
  });

  } finally {
    fireUpdate.cancel();
    try { fs.rmSync(tempDir, { recursive: true, force: true }); } catch {}
  }

  result.exitCode = exitCode;
  result.output = eventState.finalOutput || eventState.partialOutput;
  result.status = classifyLifecycleStatus({
    exitCode,
    error: progress.error,
    hasFinalResponse: eventState.hasFinalResponse,
    termination,
  });
  progress.status = result.status;
  progress.durationMs = Date.now() - startTime;
  if (progress.error && !result.output) result.output = `Error: ${progress.error}`;

  // Preserve the captured output before clipping it for the model/UI. The
  // artifact intentionally survives temp-dir cleanup and is mode 0600.
  const captured = result.output;
  const trunc = truncateUtf8Head(
    captured,
    Math.min(outputLimits.maxBytes, MAX_CAPTURED_OUTPUT_BYTES),
    outputLimits.maxLines,
  );
  if (trunc.truncated) {
    try {
      result.artifact = await writeRecoverableArtifact(captured);
    } catch (error) {
      progress.error ||= `Could not write output artifact: ${String(error)}`;
    }
    const artifactNote = result.artifact ? ` Full output: ${result.artifact}` : "";
    result.output = `${trunc.content}\n\n[Output truncated: ${trunc.outputBytes}/${trunc.totalBytes} bytes, ${trunc.outputLines}/${trunc.totalLines} lines.]${artifactNote}`;
  } else {
    result.output = trunc.content;
  }

  return result;
}

// ── Throttle ──────────────────────────────────────────────────────────

function throttle<T extends (...args: any[]) => void>(fn: T, ms: number): T & { cancel(): void } {
  let lastCall = 0;
  let timer: ReturnType<typeof setTimeout> | undefined;
  const throttled = ((...args: any[]) => {
    const now = Date.now();
    const remaining = ms - (now - lastCall);
    if (remaining <= 0) {
      lastCall = now;
      if (timer) {
        clearTimeout(timer);
        timer = undefined;
      }
      fn(...args);
    } else if (!timer) {
      timer = setTimeout(() => {
        lastCall = Date.now();
        timer = undefined;
        fn(...args);
      }, remaining);
    }
  }) as T;
  return Object.assign(throttled, { cancel() { if (timer) clearTimeout(timer); timer = undefined; } });
}

// ── Parallel Execution with Concurrency Limit ─────────────────────────

// AbortableSemaphore is shared with deterministic tests in helpers.ts. The
// default is intentionally two direct children; nested delegation is disabled.
// ── Rendering ─────────────────────────────────────────────────────────

type Theme = ExtensionContext["ui"]["theme"];
type Component =
  ReturnType<typeof Text.prototype.render> extends string[] ? Text : any;

function getTermWidth(): number {
  return process.stdout.columns || 120;
}

function renderAgentProgress(
  r: AgentResult,
  theme: Theme,
  expanded: boolean,
  w: number,
  depth: number = 0,
): Container {
  const c = new Container();
  const prog = r.progress;
  const isRunning = prog.status === "running";
  const isPending = prog.status === "pending";
  const nested = depth > 0;

  // Indent prefix for nested levels. ANSI escapes are zero-width so this works
  // with colored content. Children are visually offset by 2 spaces per depth.
  const indent = nested ? "  ".repeat(depth) : "";
  // Available width shrinks with indent so truncLine still fits one line.
  const innerW = Math.max(20, w - indent.length);

  // `line(content)`: emit one indented, optionally-truncated row.
  // In expanded mode we still indent but don't truncate — the Text component
  // wraps and we want every wrapped line to share the same left margin, so we
  // keep the indent as a hard prefix on the first line only (pi-tui Text
  // doesn't expose a per-line gutter). Wrapping at depth is rare anyway since
  // the lines that wrap (lastMessage, full output) only render at depth 0.
  const addLine = (content: string) => {
    if (expanded) {
      c.addChild(new Text(indent + content, 0, 0));
    } else {
      c.addChild(new Text(indent + truncLine(content, innerW), 0, 0));
    }
  };

  // Header: icon + agent + stats (always one line)
  const icon = isRunning
    ? theme.fg("warning", "⟳")
    : isPending
      ? theme.fg("dim", "○")
      : prog.status === "complete"
        ? theme.fg("success", "✓")
        : prog.status === "partial"
          ? theme.fg("warning", "◐")
          : theme.fg("error", "✗");
  const stats = `${prog.toolCount} tools · ${formatDuration(prog.durationMs)}`;
  const modelStr = r.model ? theme.fg("dim", ` (${r.model})`) : "";
  addLine(
    `${icon} ${theme.fg("toolTitle", theme.bold(r.agent))}${modelStr} — ${theme.fg("dim", stats)}`,
  );

  // NOTE: the task body used to be rendered here at depth 0 (truncated when
  // collapsed, full when expanded). It's now owned by `renderCall` above this
  // block in the same tool shell — the call header shows the truncated
  // preview when collapsed and the full streaming prompt when expanded — so
  // repeating it here would duplicate the prompt on screen. Nested children
  // never rendered Task in the first place; the parent's recentTools row
  // above each child already conveys the dispatch.

  // Helper for rendering one tool row + recursively rendering its children.
  const renderToolRow = (
    toolName: string,
    args: string,
    children: AgentResult[] | undefined,
    isCurrent: boolean,
  ) => {
    const body = args ? `${toolName}: ${args}` : toolName;
    if (isCurrent) {
      addLine(theme.fg("warning", `▸ ${body}`));
    } else {
      addLine(theme.fg("muted", `  ${body}`));
    }
    if (children && children.length > 0) {
      for (const child of children) {
        c.addChild(renderAgentProgress(child, theme, expanded, w, depth + 1));
      }
    }
  };

  // Tool log — running and done interleaved in chronological order. Running
  // entries get the `▸` marker; done ones get a muted `  ` prefix. Children
  // (live subagent activity) render inline beneath each row.
  for (const t of prog.recentTools) {
    renderToolRow(t.tool, t.args, t.children, t.status === "running");
  }

  // Latest assistant message (prose "thinking"). Rendered at every depth so a
  // nested subagent's current thought sits at the bottom of its own indented
  // block, mirroring how the master box shows it under all tool rows. At depth
  // 0 we precede it with a blank line for visual separation from the tool log;
  // at depth>=1 we skip the spacer so the row stays grouped with the child's
  // tool list above and doesn't break the visual run between sibling children.
  if (prog.lastMessage) {
    if (!nested) c.addChild(new Spacer(1));
    addLine(theme.fg("text", prog.lastMessage));
  }

  // Expanded final output — only at depth 0. Nested levels are summarized via
  // their own tool list; the master-level result block is enough context.
  if (!nested && !isRunning && r.output && expanded) {
    c.addChild(new Spacer(1));
    const mdTheme = getMarkdownTheme();
    c.addChild(new Markdown(r.output, 0, 0, mdTheme));
  }

  // Usage line. Includes the context %/max gauge at every depth — each
  // subagent carries its own model/contextWindow and its own token count, so
  // the gauge is meaningful per-row even for nested children.
  if (!nested) c.addChild(new Spacer(1));
  const usageParts: string[] = [];
  if (r.usage.input)
    usageParts.push(theme.fg("dim", `↑${formatTokens(r.usage.input)}`));
  if (r.usage.output)
    usageParts.push(theme.fg("dim", `↓${formatTokens(r.usage.output)}`));
  if (r.usage.cacheRead)
    usageParts.push(theme.fg("dim", `R${formatTokens(r.usage.cacheRead)}`));
  if (r.usage.cacheWrite)
    usageParts.push(theme.fg("dim", `W${formatTokens(r.usage.cacheWrite)}`));
  if (r.usage.cost.total)
    usageParts.push(theme.fg("dim", `$${r.usage.cost.total.toFixed(3)}`));
  if (prog.tokens > 0) {
    const ctxStr = formatContextUsage(prog.tokens, r.contextWindow);
    const pct = r.contextWindow ? (prog.tokens / r.contextWindow) * 100 : 0;
    const coloredCtx =
      pct > 90
        ? theme.fg("error", ctxStr)
        : pct > 70
          ? theme.fg("warning", ctxStr)
          : theme.fg("dim", ctxStr);
    usageParts.push(coloredCtx);
  }
  if (usageParts.length) {
    addLine(usageParts.join(" "));
  }

  // Error
  if (prog.error) {
    addLine(theme.fg("error", `Error: ${prog.error}`));
  }

  return c;
}

// ── Extension ─────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  const config = validateConfig(loadConfig());
  const semaphore = new AbortableSemaphore(config.maxConcurrency);
  agents = loadAgents();

  // If spawned as a child by a parent subagent process, PI_SUBAGENT_ALLOWED
  // pins which agents we're allowed to expose. Filter the registry now, before
  // any tool description sees the agent list — the child LLM should not even
  // know that other agents exist.
  if (SUBAGENT_ALLOWLIST) {
    agents = agents.filter((a) => SUBAGENT_ALLOWLIST.includes(a.name));
  }

  // execute() returns evidence and usage normally; this hook is the host-level
  // error signal required by Pi 0.85.1. Returning isError from execute() is not
  // interpreted by the executor.
  pi.on("tool_result", (event) => {
    if (event.toolName !== "subagent") return;
    const details = event.details as Details | undefined;
    if (["failed", "cancelled", "timed_out", "blocked"].includes(details?.status || "")) {
      return { isError: true };
    }
  });

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      `Delegate bounded work; no conversation is inherited. Available: ${agents.map(a => `${a.name} (${a.description})`).join("; ")}. Include goal, known evidence, constraints, acceptance, checks and stop condition.`,
    promptSnippet: "Run subagents for delegated tasks",
    promptGuidelines: [
      "Parallel tool calls are your primary parallelism mechanism — put multiple independent read/fetch calls in one function_calls block. Don't use subagents to parallelize simple I/O.",
      "Delegate only when isolation or independent work outweighs handoff and verification. Normally 0–1 subagents, up to 2 disjoint tasks. Planner is optional. Never rediscover known evidence.",
      "For multiple independent subagent tasks, emit multiple `subagent` tool calls in the same turn — they run in parallel automatically.",
      "Subagents have NO context from the current conversation — include ALL necessary context in the task description",
    ],
    parameters: Type.Object({
      agent: Type.String({ description: "Name of the agent to invoke" }),
      task: Type.String({ description: "Goal, known evidence, constraints, acceptance, checks, stop condition; do not paste the whole conversation" }),
      thinking: Type.Optional(Type.Union([Type.Literal("low"), Type.Literal("medium"), Type.Literal("high"), Type.Literal("max")], { description: "Override this invocation only; use high for difficult/risky work, not routine lookups" })),
      cwd: Type.Optional(
        Type.String({ description: "Working directory for the agent process" }),
      ),
    }),

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const cwd = ctx.cwd;

      if (!params.agent || !params.task) {
        throw new Error(
          "`subagent` requires both `agent` and `task`. To fan out work, emit multiple `subagent` tool calls in the same turn — they run in parallel.",
        );
      }

      const configuredAgent = agents.find((a) => a.name === params.agent);
      if (!configuredAgent) {
        const available = agents.map((a) => a.name).join(", ") || "none";
        throw new Error(
          `Unknown agent: ${params.agent}. Available agents: ${available}`,
        );
      }

      const invocationStart = Date.now();
      const agent = { ...configuredAgent, thinking: params.thinking ?? configuredAgent.thinking };
      const modelSeparator = agent.model.indexOf("/");
      const provider = agent.model.slice(0, modelSeparator);
      const modelId = agent.model.slice(modelSeparator + 1);
      const selectedModel = ctx.modelRegistry.find(provider, modelId);
      if (!selectedModel) throw new Error(`Configured model unavailable: ${agent.model}; no implicit fallback`);
      const supported = getSupportedThinkingLevels(selectedModel);
      if (!supported.includes(agent.thinking as any)) throw new Error(`Unsupported thinking ${agent.thinking} for ${agent.model}; supported: ${supported.join(", ")}`);
      const contextWindow = selectedModel.contextWindow;
      let queueDurationMs = 0;
      const liveResult: AgentResult = {
        agent: params.agent,
        task: params.task,
        status: "running",
        output: "",
        exitCode: -1,
        requestedModel: agent.model,
        model: agent.model,
        contextWindow,
        usage: emptyUsage(),
        progress: {
          agent: params.agent,
          status: "running" as const,
          task: params.task,
          recentTools: [],
          toolCount: 0,
          tokens: 0,
          durationMs: 0,
          lastMessage: "",
        },
      };

      const deadline = createDeadline(config.timeoutMs);
      const childSignal = combineSignals([signal, deadline.signal]);
      let result: AgentResult;
      try {
        result = await semaphore.run(
          () => {
            queueDurationMs = Date.now() - invocationStart;
            return runSubagent(
              agent,
              params.task!,
              params.cwd ?? cwd,
              childSignal,
              (progress, usage) => {
                liveResult.progress = progress;
                liveResult.usage = { ...usage, cost: { ...usage.cost } };
                onUpdate?.({
                  content: [{ type: "text", text: "(running...)" }],
                  details: { status: "running", results: [liveResult] },
                  usage: toPiUsage(liveResult.usage),
                });
              },
              { maxBytes: config.maxOutputBytes, maxLines: config.maxOutputLines },
            );
          },
          childSignal,
        );
      } catch (error) {
        if (!isAbortError(error)) throw error;
        const timedOut = isTimeoutSignal(childSignal);
        result = {
          ...liveResult,
          status: timedOut ? "timed_out" : "cancelled",
          exitCode: -1,
          progress: { ...liveResult.progress, status: timedOut ? "timed_out" : "cancelled" },
          output: timedOut ? "Subagent timed out before it could start" : "Subagent cancelled before it could start",
        };
      } finally {
        deadline.cancel();
      }

      result.contextWindow = contextWindow;
      result.thinking = agent.thinking;
      result.totalDurationMs = Date.now() - invocationStart;
      result.queueDurationMs = queueDurationMs;
      const aggregate = toPiUsage(result.usage);
      const details: Details = {
        status: result.status,
        results: [result],
        usage: aggregate,
        artifact: result.artifact,
      };
      return {
        content: [{ type: "text", text: renderCompactResult(result) }],
        details,
        usage: aggregate,
      };
    },

    // ── Render: tool call header ──
    //
    // Two views, toggled by ctrl+o (pi flips `context.expanded` and re-invokes
    // this on every flip). pi-agent-core also re-invokes this on every streamed
    // args delta, so in the expanded branch the full task text grows token by
    // token while the master LLM is still writing the prompt — mirroring how
    // `write`/`edit` reveal their `content` field live.
    renderCall(args, theme, context) {
      // Collapsed view (default): single-line header + 60-char task preview.
      if (!context.expanded) {
        if (!args.agent) {
          return new Text(theme.fg("toolTitle", theme.bold("subagent")), 0, 0);
        }
        const taskPreview = args.task
          ? (args.task.length > 60
              ? args.task.slice(0, 60) + "…"
              : args.task
            ).replace(/\n/g, " ")
          : "";
        return new Text(
          `${theme.fg("toolTitle", theme.bold("subagent"))} ${theme.fg("accent", args.agent)} ${theme.fg("dim", taskPreview)}`,
          0,
          0,
        );
      }

      // Expanded view: header + full streaming task body. Reuse the previous
      // Container so we don't allocate on every streamed token (same pattern
      // the built-in write/edit tools use via context.lastComponent).
      const c =
        context.lastComponent instanceof Container
          ? (context.lastComponent.clear(), context.lastComponent)
          : new Container();
      const agentLabel = args.agent ? ` ${theme.fg("accent", args.agent)}` : "";
      const cwdLabel = args.cwd ? theme.fg("dim", ` (cwd: ${args.cwd})`) : "";
      c.addChild(
        new Text(
          `${theme.fg("toolTitle", theme.bold("subagent"))}${agentLabel}${cwdLabel}`,
          0,
          0,
        ),
      );
      if (args.task) {
        c.addChild(new Spacer(1));
        // Plain Text wraps to terminal width. Markdown would also work but
        // the task prompt is the master's raw instruction text, not authored
        // markdown, and parsing partial markdown mid-stream looks jittery.
        c.addChild(new Text(theme.fg("text", args.task), 0, 0));
      }
      return c;
    },

    // ── Render: result ──
    renderResult(result, options, theme, context) {
      const details = result.details as Details | undefined;
      if (!details?.results?.length) {
        const t = result.content[0];
        const text = t?.type === "text" ? t.text : "(no output)";
        return new Text(text.slice(0, 200), 0, 0);
      }

      const w = getTermWidth() - 4;
      const expanded = options.expanded;
      const c = new Container();
      c.addChild(renderAgentProgress(details.results[0], theme, expanded, w));
      return c;
    },
  });
}
