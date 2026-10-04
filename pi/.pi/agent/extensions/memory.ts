import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, realpath, stat, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";
import { Type } from "typebox";

const TASKS_TEMPLATE = `# Project Tasks

Pending project work that should survive across sessions.

## Inbox

- [ ] Add pending tasks here. Keep one-line tasks inline; link complex work with wiki links like [[.ai/plan/<file>.md]].

## In Progress

## Done
`;

const PLAN_TEMPLATE = (slug: string, sessionId: string, worktree: string) => `# Plan: ${slug}
- Status: pending
- Created: ${localDate()}
- Session ID: ${sessionId}
- Worktree: ${worktree}

## TL;DR

## Current Step
- Current: T1
- Next: none
- Blockers: none

## Goal

## Spec / Contract

## Tasks
- [ ] T1: ...

## Risks / Stop Rules

## Validation Policy

## Validation

## Unresolved
`;

function projectPaths(cwd: string) {
	const aiDir = path.join(cwd, ".ai");
	return {
		planDir: path.join(aiDir, "plan"),
		tasksFile: path.join(aiDir, "TASKS.md"),
	};
}

async function ensureProjectFiles(cwd: string) {
	const paths = projectPaths(cwd);
	await mkdir(paths.planDir, { recursive: true });
	const realCwd = await realpath(cwd);
	const realPlanDir = await realpath(paths.planDir);
	if (!realPlanDir.startsWith(realCwd + path.sep)) {
		throw new Error(`Plan directory resolves outside the worktree: ${realPlanDir}`);
	}

	if (!existsSync(paths.tasksFile)) {
		await writeFile(paths.tasksFile, TASKS_TEMPLATE, "utf8");
	}

	return paths;
}

function localDate(date = new Date()): string {
	return new Intl.DateTimeFormat("en-CA", {
		year: "numeric",
		month: "2-digit",
		day: "2-digit",
	}).format(date);
}

async function readIfExists(file: string): Promise<string> {
	if (!existsSync(file)) return "";
	return readFile(file, "utf8");
}

function previewText(text: string, maxLines = 12, maxChars = 1200): string {
	const normalized = text.replace(/\r\n/g, "\n").trim();
	if (!normalized) return "";
	const lines = normalized.split("\n");
	const clippedLines = lines.slice(0, maxLines);
	let preview = clippedLines.join("\n");
	if (preview.length > maxChars) {
		preview = `${preview.slice(0, maxChars)}\n\n[truncated]`;
	}
	if (lines.length > maxLines) {
		preview += "\n\n[truncated]";
	}
	return preview;
}

function tailPreview(text: string, maxLines = 12, maxChars = 1200): string {
	const normalized = text.replace(/\r\n/g, "\n").trim();
	if (!normalized) return "";
	const lines = normalized.split("\n");
	const clippedLines = lines.slice(Math.max(0, lines.length - maxLines));
	let preview = clippedLines.join("\n");
	if (preview.length > maxChars) {
		preview = `...[truncated]\n${preview.slice(-maxChars)}`;
	}
	if (lines.length > maxLines) {
		preview = `[truncated ${lines.length - maxLines} earlier line(s)]\n\n${preview}`;
	}
	return preview;
}

async function runCommand(cwd: string, command: string, args: string[]): Promise<{ code: number; stdout: string; stderr: string }> {
	return await new Promise((resolve) => {
		const child = spawn(command, args, { cwd, stdio: ["ignore", "pipe", "pipe"] });
		let stdout = "";
		let stderr = "";
		child.stdout.on("data", (chunk: Buffer) => {
			stdout += chunk.toString();
		});
		child.stderr.on("data", (chunk: Buffer) => {
			stderr += chunk.toString();
		});
		child.on("close", (code) => {
			resolve({ code: code ?? 1, stdout, stderr });
		});
		child.on("error", (error) => {
			resolve({ code: 1, stdout, stderr: error instanceof Error ? error.message : String(error) });
		});
	});
}

/** Pure task-ledger helpers kept separate so extraction can be regression-tested. */
export function countOpenTasks(tasks: string): number {
	return tasks.split("\n").filter((line) => /^- \[ \] /.test(line.trim())).length;
}

// --- Plan identity and pointer resolution (pure helpers; no filesystem access) ---

/** Custom session entry type for the versioned active-plan pointer record. */
export const PLAN_POINTER_TYPE = "memory.active-plan";

export interface PlanPointer {
	v: number;
	planPath: string;
	sessionId: string;
	worktree: string;
	slug: string;
	updatedAt: string;
}

/** Normalize a worktree identity: canonical Git root or real path, no trailing separators. */
export function normalizeWorktreePath(input: string): string {
	if (typeof input !== "string") return "";
	return input.replace(/[\\/]+$/, "");
}

/** Full session ID when persisted contexts provide one; stable fallback for non-persisted test contexts. */
function sessionIdOf(ctx: any): string {
	return ctx.sessionManager?.getSessionId?.() || ctx.sessionId || "session";
}

/** Legacy plans used the first 8 characters of the session ID in filenames. */
function legacySessionId(sessionId: string): string {
	return sessionId.length > 8 ? sessionId.slice(0, 8) : sessionId;
}

/** True when planPath is a relative path contained under <cwd>/.ai/plan/. */
export function isPlanPathContained(planPath: string, cwd: string): boolean {
	if (typeof planPath !== "string" || !planPath || path.isAbsolute(planPath)) return false;
	const planDir = path.resolve(cwd, ".ai", "plan");
	const resolved = path.resolve(cwd, planPath);
	return resolved === planDir || resolved.startsWith(planDir + path.sep);
}

/** Parse and shape-validate a raw pointer record; returns undefined for foreign or malformed data. */
export function parsePlanPointer(data: unknown): PlanPointer | undefined {
	if (!data || typeof data !== "object") return undefined;
	const record = data as Record<string, unknown>;
	if (typeof record.planPath !== "string" || !record.planPath) return undefined;
	if (typeof record.sessionId !== "string" || !record.sessionId) return undefined;
	if (typeof record.worktree !== "string" || !record.worktree) return undefined;
	return {
		v: typeof record.v === "number" ? record.v : 1,
		planPath: record.planPath,
		sessionId: record.sessionId,
		worktree: normalizeWorktreePath(record.worktree),
		slug: typeof record.slug === "string" ? record.slug : "",
		updatedAt: typeof record.updatedAt === "string" ? record.updatedAt : "",
	};
}

/** Custom (type: "custom") entries from the active session branch, latest-first capable. */
export function activeBranchEntries(sessionManager: any): unknown[] {
	if (!sessionManager) return [];
	// getBranch is the full active path, unlike compacted buildContextEntries.
	// Never substitute global getEntries or hide a state-read failure.
	const entries = sessionManager.getBranch();
	if (!Array.isArray(entries)) throw new Error("Cannot read active plan state: invalid branch entries");
	return entries;
}

/** Other branches only tell us whether legacy filename recovery is still allowed. */
function sessionUsesPlanPointers(sessionManager: any): boolean {
	if (!sessionManager) return false;
	const entries = sessionManager.getEntries();
	if (!Array.isArray(entries)) throw new Error("Cannot read active plan state: invalid session entries");
	return entries.some((entry: any) => entry?.type === "custom" && entry.customType === PLAN_POINTER_TYPE);
}

const NO_BRANCH_SELECTION = "This branch has no active plan selection; the session has selection records outside this branch. Explicitly select an existing plan or start another with newPlan=true; filename recovery is disabled.";

export type PlanPointerResolution =
	| { status: "none" }
	| { status: "valid"; pointer: PlanPointer }
	| { status: "invalid"; pointer?: PlanPointer; reason: string }
	| { status: "session-mismatch"; pointer: PlanPointer }
	| { status: "worktree-mismatch"; pointer: PlanPointer };

/**
 * Resolve the latest active-plan pointer from session entries against the expected
 * session/worktree identity. Pure: no filesystem or process access.
 */
export function resolvePlanPointer(entries: unknown, expected: { sessionId: string; worktree: string; cwd: string }): PlanPointerResolution {
	const list = Array.isArray(entries) ? entries : [];
	let latestEntry: { data?: unknown } | undefined;
	for (let i = list.length - 1; i >= 0; i--) {
		const entry = list[i] as { type?: string; customType?: string; data?: unknown } | undefined;
		if (entry?.type === "custom" && entry.customType === PLAN_POINTER_TYPE) {
			latestEntry = entry;
			break;
		}
	}
	if (!latestEntry) return { status: "none" };
	const latest = parsePlanPointer(latestEntry.data);
	if (!latest) return { status: "invalid", reason: "latest active-plan pointer is malformed" };
	if (!isPlanPathContained(latest.planPath, expected.cwd)) {
		return { status: "invalid", pointer: latest, reason: `plan path "${latest.planPath}" escapes .ai/plan/` };
	}
	const sessionMatch = latest.sessionId === expected.sessionId ||
		(latest.sessionId.length <= 8 && latest.sessionId === legacySessionId(expected.sessionId));
	const worktreeMatch = latest.worktree === normalizeWorktreePath(expected.worktree);
	if (!sessionMatch) {
		return worktreeMatch
			? { status: "session-mismatch", pointer: latest }
			: { status: "invalid", pointer: latest, reason: `pointer belongs to another session (${latest.sessionId}) and worktree (${latest.worktree})` };
	}
	if (!worktreeMatch) return { status: "worktree-mismatch", pointer: latest };
	return { status: "valid", pointer: latest };
}

// --- Plan metadata/status helpers (pure) ---

/** Extract the `Status:` metadata line value from a plan body. */
export function planStatus(content: string): string | undefined {
	const match = /^-\s*Status:\s*(.+)$/m.exec(content);
	return match ? match[1].trim() : undefined;
}

function planMetadata(content: string, key: string): string | undefined {
	const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
	const match = new RegExp(`^-\\s*${escaped}:\\s*(.+)$`, "m").exec(content);
	return match ? match[1].trim() : undefined;
}

/** Return an actionable identity mismatch for metadata present in the plan body. */
function planIdentityMismatch(content: string, expected: { sessionId: string; worktree: string }): string | undefined {
	const planSessionId = planMetadata(content, "Session ID");
	if (planSessionId && planSessionId !== expected.sessionId &&
		!(planSessionId.length <= 8 && planSessionId === legacySessionId(expected.sessionId))) {
		return `Plan metadata belongs to a different session (${planSessionId}); expected ${expected.sessionId}`;
	}
	const planWorktree = planMetadata(content, "Worktree");
	if (planWorktree && normalizeWorktreePath(planWorktree) !== normalizeWorktreePath(expected.worktree)) {
		return `Plan metadata belongs to a different worktree (${planWorktree}); expected ${expected.worktree}`;
	}
	return undefined;
}

/** Return lines for one top-level `## <heading>` section, ignoring fenced examples. */
function sectionLines(content: string, heading: string): string[] {
	const lines = content.replace(/\r\n/g, "\n").split("\n");
	const wanted = heading.trim().toLowerCase();
	let inSection = false;
	let fenced = false;
	const result: string[] = [];
	for (const line of lines) {
		const trimmed = line.trim();
		if (/^(```|~~~)/.test(trimmed)) {
			if (inSection) result.push(line);
			fenced = !fenced;
			continue;
		}
		if (!fenced && /^##\s+/.test(line)) {
			const current = line.replace(/^##\s+/, "").trim().toLowerCase();
			if (inSection) break;
			if (current === wanted) {
				inSection = true;
				continue;
			}
		}
		if (inSection) result.push(line);
	}
	return result;
}

/** Extract one bounded `## <heading>` section body from a plan body. */
export function planSection(content: string, heading: string, maxChars = 1200): string {
	const section = sectionLines(content, heading).join("\n").trim();
	return section.length > maxChars ? `${section.slice(0, maxChars)}\n[truncated]` : section;
}

/** Extract only real top-level Tn checklist tasks, shared by counts and selection. */
function planTasks(content: string): { id: string; done: boolean; line: string }[] {
	const lines = sectionLines(content, "Tasks");
	const tasks: { id: string; done: boolean; line: string }[] = [];
	let fenced = false;
	for (const line of lines) {
		const trimmed = line.trim();
		if (/^(```|~~~)/.test(trimmed)) {
			fenced = !fenced;
			continue;
		}
		if (fenced) continue;
		const match = /^- \[([ xX])\]\s+(T[0-9]+)\b/.exec(line);
		if (!match) continue;
		tasks.push({ id: match[2], done: match[1].toLowerCase() === "x", line });
	}
	return tasks;
}

export function planTaskCounts(content: string): { total: number; open: number; done: number } {
	const tasks = planTasks(content);
	const done = tasks.filter((task) => task.done).length;
	return { total: tasks.length, open: tasks.length - done, done };
}

// --- Bounded plan snapshot (pure; no filesystem access) ---

const PLAN_SNAPSHOT_SECTION_CHARS = 400;
const PLAN_SNAPSHOT_LINE_CHARS = 300;

/** Collapse a (possibly multi-line) bounded string to one short line for status/widget surfaces. */
function truncateLine(text: string, maxChars = PLAN_SNAPSHOT_LINE_CHARS): string {
	const one = text.replace(/\s+/g, " ").trim();
	if (!one) return "";
	return one.length > maxChars ? `${one.slice(0, maxChars - 1)}…` : one;
}

function humanTaskName(task: { id: string; line: string }): string {
	const match = /^- \[[ xX]\]\s+T[0-9]+\b\s*:?\s*(.*)$/.exec(task.line);
	const name = (match?.[1] ?? "").replace(/\s*(?:[—–;|\-]\s*)?acceptance:\s*.*$/i, "").trim();
	return !name || /^\.{3,}$/.test(name) ? "" : name;
}

/** Current task selected by `Current Step`, falling back to the first open main task. */
export function planActiveTask(content: string, maxChars = PLAN_SNAPSHOT_LINE_CHARS): string {
	const tasks = planTasks(content);
	const currentStep = sectionLines(content, "Current Step").join("\n");
	// New plans distinguish Current/Next/Blockers; keep old free-form steps readable.
	const currentLine = /^- Current:[ \t]*(.*)$/mi.exec(currentStep);
	const structured = /^- (Current|Next|Blockers):/mi.test(currentStep);
	const currentId = /\b(T[0-9]+)\b/i.exec(structured ? currentLine?.[1] ?? "" : currentStep)?.[1]?.toUpperCase();
	if (currentId) {
		const current = tasks.find((task) => task.id === currentId);
		return truncateLine(current?.line ?? `Inconsistent Current Step: ${currentId} not found in Tasks`, maxChars);
	}
	const firstOpen = tasks.find((task) => !task.done);
	return firstOpen ? truncateLine(firstOpen.line, maxChars) : "";
}

export function planHumanActiveTask(content: string): string {
	const active = planActiveTask(content);
	if (!active || active.startsWith("Inconsistent Current Step:")) return active;
	return humanTaskName({ id: "", line: active });
}

/** Render structured step IDs as task names without changing the stored snapshot fields. */
export function planHumanCurrentStep(content: string): string {
	const lines = sectionLines(content, "Current Step");
	const tasks = planTasks(content);
	const structured = lines.some((line) => /^- (Current|Next|Blockers):/i.test(line));
	if (!structured) return truncateLine(lines.join(" "));
	const rendered = lines.flatMap((line) => {
		const match = /^- (Current|Next|Blockers):[ \t]*(.*)$/i.exec(line);
		if (!match) return [];
		const label = match[1][0].toUpperCase() + match[1].slice(1).toLowerCase();
		const value = match[2].trim();
		if (label === "Blockers") return value && value.toLowerCase() !== "none" ? [`${label}: ${value}`] : [];
		const id = /\b(T[0-9]+)\b/i.exec(value)?.[1]?.toUpperCase();
		if (!id) return value && value.toLowerCase() !== "none" ? [`${label}: ${value}`] : [];
		const task = tasks.find((candidate) => candidate.id === id);
		if (!task) return [`${label}: Inconsistent — ${id} not found in Tasks`];
		const name = humanTaskName(task);
		return name ? [`${label}: ${name} (${id})`] : [`${label}: ${id} task description unavailable`];
	});
	return rendered.map((line) => truncateLine(line)).join(" · ");
}

/** Short latest warning: first Unresolved line, else last Validation line, else "". */
export function planWarning(content: string, maxChars = PLAN_SNAPSHOT_LINE_CHARS): string {
	const unresolved = planSection(content, "Unresolved", maxChars);
	const firstUnresolved = unresolved.split("\n").map((line) => line.trim()).find(Boolean);
	if (firstUnresolved) return truncateLine(firstUnresolved, maxChars);
	const validation = planSection(content, "Validation", maxChars);
	const lastValidation = validation.split("\n").map((line) => line.trim()).filter(Boolean).pop();
	return lastValidation ? truncateLine(lastValidation, maxChars) : "";
}

export interface PlanSnapshot {
	planPath: string;
	title: string;
	status: string;
	tldr: string;
	currentStep: string;
	tasks: { total: number; open: number; done: number };
	activeTask: string;
	warning: string;
}

/** Extract the short display title from the plan heading without exposing the full summary. */
export function planTitle(content: string): string {
	const planHeading = /^#\s+Plan:\s*(.+)$/m.exec(content);
	if (planHeading?.[1]) return truncateLine(planHeading[1], 120);
	const heading = /^#\s+(.+)$/m.exec(content);
	return heading?.[1] ? truncateLine(heading[1], 120) : "untitled";
}

/** Derive the bounded recovery view (status/TL;DR/step/counts/active task/warning) from a plan body. */
export function planSnapshot(content: string, planPath: string): PlanSnapshot {
	return {
		planPath,
		title: planTitle(content),
		status: planStatus(content) ?? "unknown",
		tldr: planSection(content, "TL;DR", PLAN_SNAPSHOT_SECTION_CHARS),
		currentStep: planSection(content, "Current Step", PLAN_SNAPSHOT_SECTION_CHARS),
		tasks: planTaskCounts(content),
		activeTask: planActiveTask(content),
		warning: planWarning(content),
	};
}

// --- Filesystem-backed identity and resolution ---

/** Canonical Git root when available, otherwise the real path of cwd, normalized. */
async function worktreeIdentity(cwd: string): Promise<string> {
	try {
		const gitRoot = await runCommand(cwd, "git", ["rev-parse", "--show-toplevel"]);
		if (gitRoot.code === 0 && gitRoot.stdout.trim()) return normalizeWorktreePath(await realpath(gitRoot.stdout.trim()));
	} catch {}
	try {
		return normalizeWorktreePath(await realpath(cwd));
	} catch {
		return normalizeWorktreePath(cwd);
	}
}

function escapedRegex(value: string): string {
	return value.replace(/[.*+?^${}()|[\\]\\]/g, "\\$&");
}

/** Legacy recovery accepts any date, but only the current full ID or old short-ID format. */
async function findSessionPlanFiles(cwd: string, sessionId: string): Promise<string[]> {
	const paths = projectPaths(cwd);
	const fullId = escapedRegex(sessionId);
	const shortId = escapedRegex(legacySessionId(sessionId));
	const fullPattern = new RegExp(`^\\d{4}-\\d{2}-\\d{2}-${fullId}-.+\\.md$`);
	const shortPattern = new RegExp(`^\\d{4}-\\d{2}-\\d{2}-${shortId}-.+\\.md$`);
	try {
		const files = (await readdir(paths.planDir)).filter((file) => file.endsWith(".md"));
		const fullMatches = files.filter((file) => fullPattern.test(file)).sort();
		const matches = fullMatches.length ? fullMatches : files.filter((file) => shortPattern.test(file)).sort();
		return matches.map((file) => `.ai/plan/${file}`);
	} catch {
		return [];
	}
}

function planSlugFromFilename(planPath: string, sessionId: string): string {
	const file = path.basename(planPath).replace(/\.md$/, "");
	for (const id of [sessionId, legacySessionId(sessionId)]) {
		const match = new RegExp(`^\\d{4}-\\d{2}-\\d{2}-${escapedRegex(id)}-(.+)$`).exec(file);
		if (match) return match[1] || "session-plan";
	}
	return file || "session-plan";
}

async function isContainedRegularPlanFile(cwd: string, planPath: string): Promise<boolean> {
	if (!isPlanPathContained(planPath, cwd)) return false;
	try {
		const [realCwd, realPlanDir, realFile, info] = await Promise.all([
			realpath(cwd),
			realpath(projectPaths(cwd).planDir),
			realpath(path.join(cwd, planPath)),
			stat(path.join(cwd, planPath)),
		]);
		return realPlanDir.startsWith(realCwd + path.sep) && info.isFile() && realFile.startsWith(realPlanDir + path.sep);
	} catch {
		return false;
	}
}

export interface ActivePlanResolution {
	planPath?: string;
	source: "active-pointer" | "current-session" | "missing";
	pointer?: PlanPointer;
	blocked?: string;
	currentSessionPath: string;
}

/**
 * Resolve the active plan for the current session/worktree. Pointer first; legacy
 * fallback is only for an unambiguous current-session filename. Never selects by
 * date or mtime, and never recreates a selected file.
 */
async function resolveActivePlan(cwd: string, ctx: any): Promise<ActivePlanResolution> {
	const sessionId = sessionIdOf(ctx);
	const currentSessionPath = `.ai/plan/<any-date>-${sessionId}-<slug>.md`;
	const worktree = await worktreeIdentity(cwd);
	const entries = activeBranchEntries(ctx.sessionManager);
	const resolution = resolvePlanPointer(entries, { sessionId, worktree, cwd });

	if (resolution.status === "invalid") {
		return {
			source: "missing",
			blocked: `Invalid active plan pointer: ${resolution.reason}. Restore it, explicitly select another existing plan, or start a new plan; the pointer will not be ignored.`,
			currentSessionPath,
		};
	}
	if (resolution.status === "valid") {
		const planPath = resolution.pointer.planPath;
		if (!(await isContainedRegularPlanFile(cwd, planPath))) {
			return {
				source: "missing",
				blocked: `Active plan pointer references a missing, non-file, or out-of-scope plan: ${planPath}. Restore it, explicitly select another existing plan, or start a new plan; it will not be recreated.`,
				currentSessionPath: planPath,
			};
		}
		return { planPath, source: "active-pointer", pointer: resolution.pointer, currentSessionPath: planPath };
	}
	if (resolution.status === "worktree-mismatch") {
		return {
			source: "missing",
			blocked: `Active plan pointer (${resolution.pointer.planPath}) was recorded for a different worktree (${resolution.pointer.worktree}). Explicitly select an existing plan in this worktree or start a new plan.`,
			currentSessionPath,
		};
	}
	if (resolution.status === "session-mismatch") {
		return {
			source: "missing",
			blocked: `Active plan pointer (${resolution.pointer.planPath}) was recorded for a different session (${resolution.pointer.sessionId}). Explicitly select an existing plan or start a new plan; another session will not be adopted automatically.`,
			currentSessionPath,
		};
	}

	if (sessionUsesPlanPointers(ctx.sessionManager)) {
		return { source: "missing", blocked: NO_BRANCH_SELECTION, currentSessionPath };
	}
	const legacy = await findSessionPlanFiles(cwd, sessionId);
	const validLegacy: string[] = [];
	for (const candidate of legacy) {
		if (await isContainedRegularPlanFile(cwd, candidate)) validLegacy.push(candidate);
	}
	if (legacy.length !== validLegacy.length) {
		return {
			source: "missing",
			blocked: `A current-session plan candidate is missing, non-file, or out of scope: ${legacy.filter((candidate) => !validLegacy.includes(candidate)).join(", ")}. Explicitly select a valid plan or start a new one.`,
			currentSessionPath: legacy[0] ?? currentSessionPath,
		};
	}
	if (validLegacy.length === 1) {
		const mismatch = planIdentityMismatch(await readIfExists(path.join(cwd, validLegacy[0])), { sessionId, worktree });
		if (mismatch) return { source: "missing", blocked: mismatch, currentSessionPath: validLegacy[0] };
		return { planPath: validLegacy[0], source: "current-session", currentSessionPath: validLegacy[0] };
	}
	if (validLegacy.length > 1) {
		return {
			source: "missing",
			blocked: `Multiple current-session plan candidates: ${validLegacy.join(", ")}. Explicitly select one existing plan or start a new plan; do not choose by date or mtime.`,
			currentSessionPath: validLegacy[0],
		};
	}
	return { source: "missing", currentSessionPath };
}

// --- Existing-UI status line (ctx.ui.setStatus; TUI only, never throws) ---

const PLAN_STATUS_KEY = "session-plan";

function planStatusText(snapshot: PlanSnapshot | undefined, blocked?: string): string | undefined {
	if (blocked) return truncateLine(`Plan blocked: ${blocked}`, 120);
	if (!snapshot) return undefined;
	const tasks = `${snapshot.tasks.open} open/${snapshot.tasks.done} done`;
	return truncateLine(`Plan ${snapshot.status} · ${tasks}${snapshot.activeTask ? ` · ${snapshot.activeTask.startsWith("Inconsistent Current Step:") ? snapshot.activeTask : humanTaskName({ id: "", line: snapshot.activeTask })}` : ""}`, 120);
}

/**
 * Plan state communicated to the model: which file is active, its status and the
 * current step. Task counts, TL;DR, the active task and the ledger's In Progress list
 * are deliberately omitted; they are derivable with `get_current_plan`,
 * `summarize_worktree` or `read`, and the agent is normally editing those files anyway.
 *
 * `previouslyCommunicated` makes the loss of a plan explicit instead of leaving an
 * earlier message describing it as valid. It is only consulted when there is no plan
 * to describe, so a session that never had one stays silent.
 */
export function planStateBlock(
	snapshot: PlanSnapshot | undefined,
	blocked?: string,
	humanStep?: string,
	previouslyCommunicated = false,
): string {
	if (blocked) return `> Active plan unavailable: ${blocked}`;
	if (!snapshot) {
		return previouslyCommunicated
			? "**Active plan**: none. The plan named earlier in this conversation is no longer available and will not be recreated."
			: "";
	}
	const lines = [`**Plan**: \`${snapshot.planPath}\` — status: ${snapshot.status}`];
	if (humanStep) lines.push(`**Current Step**: ${humanStep}`);
	if (snapshot.warning) lines.push(`**Warning**: ${snapshot.warning}`);
	return lines.join("\n");
}

/**
 * Custom type of the persisted plan-state message. It is a real session entry, so it
 * stays where it was sent instead of being regenerated at the end of every request.
 */
const PLAN_STATE_TYPE = "memory.plan-state";

/**
 * Last plan-state block present in the messages the model actually receives, or
 * undefined when it has never been communicated in the applicable context.
 */
function lastCommunicatedPlanState(messages: unknown): { content?: string } | undefined {
	if (!Array.isArray(messages)) return undefined;
	return messages.findLast((message: any) => message?.customType === PLAN_STATE_TYPE) as
		| { content?: string }
		| undefined;
}

/**
 * Messages the model is about to receive, used by `before_agent_start` where the
 * boundary preview does not exist. The session projection is branch-aware and
 * reflects the compaction that Pi runs before this hook, so it is the applicable
 * context rather than the whole session.
 */
function effectiveContextMessages(ctx: any): unknown {
	try {
		return ctx?.sessionManager?.buildSessionProjection?.().messages;
	} catch {
		return undefined;
	}
}

/**
 * Plan state that still has to be communicated, or undefined when the model already
 * receives exactly this block.
 *
 * The comparison is with the last communicated value, not with anything ever seen:
 * A → B → A communicates both changes, while a branch or compaction that dropped the
 * entry re-communicates it instead of staying silent.
 *
 * Returning undefined means no second copy is added; it says nothing about cost, and a
 * persisted entry is not an entry the model has already processed.
 */
async function pendingPlanState(cwd: string, ctx: any, applicableMessages: unknown): Promise<string | undefined> {
	const resolved = await resolveActivePlan(cwd, ctx);
	const content = resolved.planPath ? await readIfExists(path.join(cwd, resolved.planPath)) : "";
	const snapshot = content ? planSnapshot(content, resolved.planPath!) : undefined;
	const humanStep = content ? planHumanCurrentStep(content) : undefined;
	const communicated = lastCommunicatedPlanState(applicableMessages);
	const block = planStateBlock(snapshot, resolved.blocked, humanStep, communicated !== undefined);
	if (!block || block === communicated?.content) return undefined;
	return block;
}

/** Update the status line from a plan snapshot; no-op outside TUI and never throws. */
function updatePlanUI(ctx: any, snapshot?: PlanSnapshot, blocked?: string): void {
	try {
		const ui = ctx?.ui;
		if (!ui || typeof ui.setStatus !== "function") return;
		if (ctx?.mode !== undefined && ctx.mode !== "tui") return;
		ui.setStatus(PLAN_STATUS_KEY, planStatusText(snapshot, blocked));
	} catch {}
}

/** Clear the status line before a session switch so no stale plan text lingers. */
function clearPlanUI(ctx: any): void {
	try {
		const ui = ctx?.ui;
		if (!ui || typeof ui.setStatus !== "function") return;
		if (ctx?.mode !== undefined && ctx.mode !== "tui") return;
		ui.setStatus(PLAN_STATUS_KEY, undefined);
	} catch {}
}

/** Refresh the existing UI from the canonical plan (or a precomputed bounded snapshot). */
async function refreshPlanUI(ctx: any, precomputed?: { snapshot?: PlanSnapshot; blocked?: string }): Promise<void> {
	try {
		if (precomputed) {
			updatePlanUI(ctx, precomputed.snapshot, precomputed.blocked);
			return;
		}
		const cwd: string | undefined = ctx?.cwd;
		if (!cwd) {
			clearPlanUI(ctx);
			return;
		}
		const resolved = await resolveActivePlan(cwd, ctx);
		if (resolved.blocked) {
			updatePlanUI(ctx, undefined, resolved.blocked);
			return;
		}
		const content = resolved.planPath ? await readIfExists(path.join(cwd, resolved.planPath)) : "";
		updatePlanUI(ctx, content ? planSnapshot(content, resolved.planPath!) : undefined);
	} catch {}
}

function shellQuote(value: string): string {
	return `'${value.replace(/'/g, `'\\''`)}'`;
}

function planPointerRecord(pointer: Omit<PlanPointer, "v" | "updatedAt">): PlanPointer {
	return { v: 1, ...pointer, updatedAt: new Date().toISOString() };
}

function persistPlanPointer(pi: ExtensionAPI, pointer: PlanPointer, ctx: any): boolean {
	try {
		if (typeof ctx.sessionManager?.isPersisted === "function" && !ctx.sessionManager.isPersisted()) return false;
		pi.appendEntry(PLAN_POINTER_TYPE, pointer);
		const sessionId = sessionIdOf(ctx);
		const worktree = normalizeWorktreePath(pointer.worktree);
		const resolution = resolvePlanPointer(activeBranchEntries(ctx.sessionManager), {
			sessionId,
			worktree,
			cwd: ctx.cwd,
		});
		return resolution.status === "valid" &&
			resolution.pointer.planPath === pointer.planPath &&
			resolution.pointer.sessionId === pointer.sessionId &&
			resolution.pointer.worktree === pointer.worktree;
	} catch {
		return false;
	}
}

function cancelledPlanSelection() {
	return {
		content: [{ type: "text" as const, text: "Plan selection cancelled; previous selection and documents unchanged. Stop this attempt." }],
		details: { status: "cancelled", selected: false, created: false },
		terminate: true,
	};
}

async function confirmPlanSelection(ctx: any, operation: string, signal?: AbortSignal): Promise<boolean> {
	if (signal?.aborted) return false;
	if (!ctx.hasUI || typeof ctx.ui?.confirm !== "function") {
		throw new Error("Plan selection requires interactive confirmation; no UI is available. Nothing was changed.");
	}
	const confirmed = await ctx.ui.confirm("Change active plan?", `${operation}\nThis does not authorize implementation.`, { signal });
	return confirmed && !signal?.aborted;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("open-plan", {
		description: "Open the active session plan in Neovim in a new Herdr pane",
		handler: async (_args, ctx) => {
			const resolved = await resolveActivePlan(ctx.cwd, ctx);
			if (resolved.blocked) {
				ctx.ui.notify(`Cannot open active plan: ${resolved.blocked}`, "error");
				return;
			}
			if (!resolved.planPath || !(await isContainedRegularPlanFile(ctx.cwd, resolved.planPath))) {
				ctx.ui.notify("No active plan is selected for this session and worktree.", "warning");
				return;
			}
			if (ctx.mode !== "tui" || process.env.HERDR_ENV !== "1") {
				ctx.ui.notify("/open-plan requires running Pi inside a Herdr pane.", "warning");
				return;
			}

			const sourcePaneId = process.env.HERDR_PANE_ID || process.env.HERDR_ACTIVE_PANE_ID;
			if (!sourcePaneId) {
				ctx.ui.notify("Herdr did not provide the current pane id.", "error");
				return;
			}

			const herdr = process.env.HERDR_BIN_PATH || "herdr";
			const split = await runCommand(ctx.cwd, herdr, [
				"pane",
				"split",
				sourcePaneId,
				"--direction",
				"right",
				"--cwd",
				ctx.cwd,
				"--focus",
			]);
			if (split.code !== 0) {
				ctx.ui.notify(`Could not create Herdr pane: ${split.stderr.trim() || split.stdout.trim() || "unknown error"}`, "error");
				return;
			}

			let paneId: string | undefined;
			try {
				const response = JSON.parse(split.stdout);
				const candidate = response?.result?.pane?.pane_id;
				if (typeof candidate === "string" && candidate) paneId = candidate;
			} catch {}
			if (!paneId) {
				ctx.ui.notify("Herdr created a pane but did not return its id.", "error");
				return;
			}

			const planPath = path.resolve(ctx.cwd, resolved.planPath);
			const nvimCommand = `exec zsh -lc ${shellQuote(`exec nvim -- ${shellQuote(planPath)}`)}`;
			const opened = await runCommand(ctx.cwd, herdr, ["pane", "run", paneId, nvimCommand]);
			if (opened.code !== 0) {
				await runCommand(ctx.cwd, herdr, ["pane", "close", paneId]);
				ctx.ui.notify(`Could not open Neovim in Herdr: ${opened.stderr.trim() || opened.stdout.trim() || "unknown error"}`, "error");
				return;
			}
			ctx.ui.notify(`Opened ${resolved.planPath} in a new Herdr pane.`, "info");
		},
	});

	// --- Tools ---

	pi.registerTool({
		name: "create_session_plan",
		label: "Create session plan",
		description: "Creates a new session plan, or retrieves the active one. newPlan=true starts another plan only after user confirmation in the tool UI; cancellation preserves the current selection.",
		parameters: Type.Object({
			slug: Type.String({ description: "Short descriptive slug for the plan (e.g. 'fix-auth-bug')." }),
			newPlan: Type.Optional(Type.Boolean({ description: "Explicitly start a new plan instead of reusing or recovering the active selection." })),
		}),
		async execute(_id, params, signal, _update, ctx) {
			const cwd = ctx.cwd;
			if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(params.slug) || params.slug.length > 80) throw new Error("Plan slug must be lowercase alphanumeric words separated by hyphens (max 80 characters)");
			if (signal?.aborted) return cancelledPlanSelection();
			if (params.newPlan && !(await confirmPlanSelection(ctx, `Start another plan under .ai/plan/ with slug "${params.slug}"; preserve the previous file.`, signal))) return cancelledPlanSelection();
			const sessionId = sessionIdOf(ctx);
			const worktree = await worktreeIdentity(cwd);
			const resolution = resolvePlanPointer(activeBranchEntries(ctx.sessionManager), { sessionId, worktree, cwd });

			if (!params.newPlan) {
				if (resolution.status === "valid") {
					if (!(await isContainedRegularPlanFile(cwd, resolution.pointer.planPath))) {
						throw new Error(`Active plan pointer references a missing, non-file, or out-of-scope plan: ${resolution.pointer.planPath}. It will not be recreated; explicitly select another plan or call create_session_plan with newPlan=true.`);
					}
					await refreshPlanUI(ctx);
					return {
						content: [{ type: "text", text: `Session plan already exists at: ${resolution.pointer.planPath}` }],
						details: { path: resolution.pointer.planPath, created: false, pointerPersisted: true },
					};
				}
				if (resolution.status === "invalid" || resolution.status === "session-mismatch" || resolution.status === "worktree-mismatch") {
					const reason = resolution.status === "invalid" ? resolution.reason :
						resolution.status === "session-mismatch" ? `different session ${resolution.pointer.sessionId}` :
						resolution.status === "worktree-mismatch" ? `different worktree ${resolution.pointer.worktree}` : "invalid selection";
					throw new Error(`Active plan selection is blocked (${reason}). Restore it, use select_session_plan for an explicit existing file, or call create_session_plan with newPlan=true; no fallback was applied.`);
				}

				if (sessionUsesPlanPointers(ctx.sessionManager)) throw new Error(NO_BRANCH_SELECTION);
				const legacy = await findSessionPlanFiles(cwd, sessionId);
				const validLegacy = (await Promise.all(legacy.map(async (candidate) => (await isContainedRegularPlanFile(cwd, candidate)) ? candidate : undefined))).filter((candidate): candidate is string => Boolean(candidate));
				if (legacy.length !== validLegacy.length) throw new Error(`A current-session plan candidate is missing, non-file, or out of scope. Explicitly select a valid plan or call create_session_plan with newPlan=true.`);
				if (validLegacy.length > 1) throw new Error(`Multiple current-session plan candidates: ${validLegacy.join(", ")}. Explicitly select one with select_session_plan or call create_session_plan with newPlan=true.`);
				if (validLegacy.length === 1) {
					const mismatch = planIdentityMismatch(await readIfExists(path.join(cwd, validLegacy[0])), { sessionId, worktree });
					if (mismatch) throw new Error(`${mismatch}. Explicitly select this plan to adopt it or call create_session_plan with newPlan=true.`);
					if (signal?.aborted) return cancelledPlanSelection();
					const pointer = planPointerRecord({ planPath: validLegacy[0], sessionId, worktree, slug: planSlugFromFilename(validLegacy[0], sessionId) });
					const persisted = persistPlanPointer(pi, pointer, ctx);
					await refreshPlanUI(ctx);
					return {
						content: [{ type: "text", text: `Adopted existing session plan at: ${validLegacy[0]}${persisted ? "" : " (selection could not be verified as persisted; do not treat it as durable)"}` }],
						details: { path: validLegacy[0], created: false, pointerPersisted: persisted },
					};
				}
			}

			if (signal?.aborted) return cancelledPlanSelection();
			await ensureProjectFiles(cwd);
			const planDir = projectPaths(cwd).planDir;
			const baseName = `${localDate()}-${sessionId}-${params.slug}`;
			let suffix = "";
			let fullPath = path.join(planDir, `${baseName}.md`);
			while (existsSync(fullPath)) {
				suffix = suffix ? `-${Number(suffix.slice(1)) + 1}` : "-2";
				fullPath = path.join(planDir, `${baseName}${suffix}.md`);
			}
			const finalPath = `.ai/plan/${path.basename(fullPath)}`;
			if (signal?.aborted) return cancelledPlanSelection();
			await writeFile(fullPath, PLAN_TEMPLATE(params.slug, sessionId, worktree), "utf8");
			const pointer = planPointerRecord({ planPath: finalPath, sessionId, worktree, slug: params.slug });
			const persisted = persistPlanPointer(pi, pointer, ctx);
			await refreshPlanUI(ctx);
			const prefix = params.newPlan ? "Started new session plan" : "Created session plan";
			return {
				content: [{ type: "text", text: `${prefix} at: ${finalPath}${persisted ? "" : " (selection could not be verified as persisted; do not treat it as durable)"}` }],
				details: { path: finalPath, created: true, pointerPersisted: persisted, newPlan: Boolean(params.newPlan) },
			};
		},
	});

	pi.registerTool({
		name: "select_session_plan",
		label: "Select session plan",
		description: "Adopt or switch to an existing Markdown plan under .ai/plan after user confirmation in the tool UI. Cancellation preserves the selection; choosing a plan does not authorize implementation.",
		parameters: Type.Object({
			path: Type.String({ description: "Existing relative path such as .ai/plan/2026-09-15-session-fix.md." }),
		}),
		async execute(_id, params, signal, _update, ctx) {
			const cwd = ctx.cwd;
			if (!(await confirmPlanSelection(ctx, `Select existing plan: ${params.path}`, signal))) return cancelledPlanSelection();
			if (!(await isContainedRegularPlanFile(cwd, params.path))) {
				throw new Error(`Cannot select plan "${params.path}": it must be an existing regular file within .ai/plan in this worktree.`);
			}
			const sessionId = sessionIdOf(ctx);
			const worktree = await worktreeIdentity(cwd);
			if (signal?.aborted) return cancelledPlanSelection();
			const pointer = planPointerRecord({
				planPath: params.path,
				sessionId,
				worktree,
				slug: planSlugFromFilename(params.path, sessionId),
			});
			const persisted = persistPlanPointer(pi, pointer, ctx);
			await refreshPlanUI(ctx);
			if (!persisted) {
				return {
					content: [{ type: "text", text: `Plan exists at ${params.path}, but selection could not be verified as persisted. It was not reported as durably selected; retry or choose another plan.` }],
					details: { path: params.path, selected: false, pointerPersisted: false },
				};
			}
			return {
				content: [{ type: "text", text: `Selected existing session plan: ${params.path}` }],
				details: { path: params.path, selected: true, pointerPersisted: true },
			};
		},
	});

	pi.registerTool({
		name: "get_current_plan",
		label: "Current plan",
		description: "Reads the active session plan for this session and worktree. Fails closed on ambiguity or identity mismatch instead of guessing.",
		parameters: Type.Object({}),
		async execute(_id, _params, _signal, _update, ctx) {
			let uiState: { snapshot?: PlanSnapshot; blocked?: string } = {};
			try {
				const cwd = ctx.cwd;
				await ensureProjectFiles(cwd);
				const resolved = await resolveActivePlan(cwd, ctx);
				if (resolved.blocked) {
					uiState = { blocked: resolved.blocked };
					throw new Error(resolved.blocked);
				}
				const planPath = resolved.planPath ?? resolved.currentSessionPath;
				const fullPath = path.join(cwd, planPath);
				const content = await readIfExists(fullPath);
				const source = resolved.source;
				const snapshot = content ? planSnapshot(content, planPath) : undefined;
				if (snapshot) uiState = { snapshot };
				const preview = content ? previewText(content, 16, 2000) : "";
				const header = [
					`Plan source: ${source}`,
					`Path: ${planPath}`,
					snapshot ? `Status: ${snapshot.status}` : undefined,
					snapshot ? `Tasks: ${snapshot.tasks.open} open / ${snapshot.tasks.done} done (${snapshot.tasks.total} total)` : undefined,
					snapshot?.tldr ? `TL;DR: ${truncateLine(snapshot.tldr, 200)}` : undefined,
					snapshot?.currentStep ? `Current Step: ${planHumanCurrentStep(content)}` : undefined,
					snapshot?.activeTask ? `Active task: ${truncateLine(planHumanActiveTask(content), 200)}` : undefined,
					snapshot?.warning ? `Warning: ${snapshot.warning}` : undefined,
				].filter(Boolean);
				const text = content
					? `${header.join("\n")}\n\n${preview}`
					: `${header.join("\n")}\n\nNo plan file found.`;

				return {
					content: [{ type: "text", text }],
					details: {
						path: planPath,
						source,
						exists: Boolean(content),
						currentSessionPath: resolved.currentSessionPath,
						...(snapshot ? {
							planStatus: snapshot.status,
							planTldr: snapshot.tldr,
							planTasks: snapshot.tasks,
							planCurrentStep: snapshot.currentStep,
							planActiveTask: snapshot.activeTask,
							planWarning: snapshot.warning,
						} : {}),
					},
				};
			} finally {
				await refreshPlanUI(ctx, uiState);
			}
		},
	});

	pi.registerTool({
		name: "summarize_worktree",
		label: "Worktree summary",
		description: "Returns a compact snapshot of the current repo state, current plan, and open tasks.",
		parameters: Type.Object({}),
		async execute(_id, _params, _signal, _update, ctx) {
			const cwd = ctx.cwd;
			const paths = await ensureProjectFiles(cwd);
			const [status, log, resolved] = await Promise.all([
				runCommand(cwd, "git", ["status", "--short", "--branch", "--untracked-files=normal"]),
				runCommand(cwd, "git", ["log", "-1", "--oneline", "--decorate=short"]),
				resolveActivePlan(cwd, ctx),
			]);
			if (status.code !== 0) {
				const message = status.stderr.trim() || "git status failed";
				return { content: [{ type: "text", text: message }], details: { error: message } };
			}

			const tasks = await readIfExists(paths.tasksFile);
			const openTasks = countOpenTasks(tasks);
			const planPath = resolved.planPath ?? resolved.currentSessionPath;
			const planContent = resolved.planPath ? await readIfExists(path.join(cwd, resolved.planPath)) : "";
			const snapshot = planContent ? planSnapshot(planContent, planPath) : undefined;
			const statusLines = status.stdout.trim().split("\n").filter(Boolean);
			const branchLine = statusLines[0]?.replace(/^##\s*/, "") || "unknown";
			const dirtyFiles = statusLines.slice(1).map((line) => line.replace(/^[ MADRCU?!]+/, "").trim()).filter(Boolean);
			const lastCommit = log.stdout.trim() || "unavailable";
			const planNote = resolved.blocked ? " (blocked)" : ` (${resolved.source})`;
			const lines = [
				`Branch: ${branchLine}`,
				dirtyFiles.length ? `Dirty: ${dirtyFiles.length} file(s)` : "Dirty: clean",
				`Last commit: ${lastCommit}`,
				`Current plan: ${planPath}${resolved.planPath ? planNote : " (missing)"}`,
				`Open tasks: ${openTasks}`,
			];

			if (resolved.blocked) lines.push(`Plan warning: ${resolved.blocked}`);
			if (snapshot) {
				lines.push(`Plan status: ${snapshot.status}`);
				if (snapshot.currentStep) lines.push(`Current step: ${planHumanCurrentStep(planContent)}`);
				if (snapshot.activeTask) lines.push(`Active task: ${planHumanActiveTask(planContent)}`);
				lines.push(`Plan tasks: ${snapshot.tasks.open} open / ${snapshot.tasks.done} done (${snapshot.tasks.total} total)`);
				if (snapshot.warning) lines.push(`Plan warning: ${snapshot.warning}`);
			}

			if (dirtyFiles.length) {
				lines.push("", "Changed files:", ...dirtyFiles.slice(0, 8).map((file) => `- ${file}`));
				if (dirtyFiles.length > 8) lines.push(`- … +${dirtyFiles.length - 8} more`);
			}

			updatePlanUI(ctx, snapshot, resolved.blocked);

			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: {
					branch: branchLine,
					dirtyCount: dirtyFiles.length,
					dirtyFiles,
					lastCommit,
					planPath,
					planSource: resolved.source,
					openTasks,
					...(snapshot ? {
						planStatus: snapshot.status,
						planTldr: snapshot.tldr,
						planCurrentStep: snapshot.currentStep,
						planActiveTask: snapshot.activeTask,
						planTasks: snapshot.tasks,
						planWarning: snapshot.warning,
					} : {}),
					...(resolved.blocked ? { planBlocked: resolved.blocked } : {}),
				},
			};
		},
	});

	// --- Lifecycle Hooks ---

	// Deliberately returns no `systemPrompt`. Returning one sets Pi's
	// `forceSystemPrompt`, and its projection then rebuilds the request head on every
	// turn and restates the entire tool set there, discarding the incremental tool
	// declarations. A changing head invalidates whatever the provider had cached of the
	// prefix, which is the mechanism behind the observed `cacheRead` freeze. That link
	// is an inference from local request traces, not a provider-confirmed cause, and no
	// saving is claimed here. The workflow policy
	// therefore lives in APPEND_SYSTEM.md, and the plan reaches the model through the
	// persisted messages below.
	//
	// `context` is deliberately not used either: a request-time projection is rebuilt
	// on every call, and returning a changed conversation from a `context` handler
	// makes Pi restore the prompt through `restoreSystemMessages`, which rebuilds the
	// head and can move system and tool declarations to the front.
	pi.on("before_agent_start", async (event, ctx) => {
		await ensureProjectFiles(event.systemPromptOptions?.cwd ?? ctx.cwd);
		await refreshPlanUI(ctx);
		try {
			// `BeforeAgentStartEventResult.message` is the native field for this. It is
			// not `systemPrompt`, so nothing about the request head changes, and unlike
			// a `context` projection the entry is appended to the conversation and
			// persisted, so the first request of the turn carries it.
			//
			// This runs once per agent loop, not once per provider call, so an automatic
			// compaction *between two calls of the same run* does not reach it. `turn_end`
			// covers the ordinary progress within a run, and `session_compact` covers the
			// compaction that happens after it, because all three compare against the
			// context the model actually receives.
			const block = await pendingPlanState(ctx.cwd, ctx, effectiveContextMessages(ctx));
			if (!block) return;
			return { message: { customType: PLAN_STATE_TYPE, content: block, display: false } };
		} catch {
			return;
		}
	});

	// Communicate ordinary progress as a real session entry appended at the end of the
	// turn. It is not re-derived per request, so it keeps the position it was sent at
	// and earlier messages are never rewritten, moved or dropped to show it.
	pi.on("turn_end", async (event, ctx) => {
		try {
			const block = await pendingPlanState(ctx.cwd, ctx, event.context.contextMessages);
			if (!block) return;

			// `emitBoundary` replaces the accumulated array with whatever a handler
			// returns, so entries proposed by earlier handlers are carried over in
			// order. `continue` is deliberately untouched: publishing state is not a
			// reason to ask for another turn.
			return {
				entries: [
					...(event.entries ?? []),
					{ type: "custom_message", customType: PLAN_STATE_TYPE, content: block, display: false },
				],
			};
		} catch {
			return;
		}
	});

	// Refresh the existing status/widget UI on startup, branch/compaction changes,
	// tool-driven Markdown edits, and settled turns. There is no polling and no
	// full-plan copy in these handlers.
	pi.on("session_start", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});

	pi.on("session_before_switch", (_event, ctx) => {
		clearPlanUI(ctx);
	});

	pi.on("session_tree", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});

	pi.on("session_compact", async (_event, ctx) => {
		await refreshPlanUI(ctx);
		// A compaction that keeps a recent slice can drop the state entry. Pi runs it
		// from `prepareNextTurnWithContext`, that is after `finishTurn` has already
		// dispatched `turn_end` for this turn and before the next request is rebuilt
		// from the compacted projection, and `before_agent_start` belongs to `prompt()`,
		// so neither of the other two hooks can refill that gap.
		//
		// The comparison is against the projection *after* the compaction, so this is
		// also the deduplication: a state message that survived is still the last one
		// communicated and nothing is sent. `sendMessage` is the native action and, with
		// no `deliverAs`, it appends the message as a real session entry while Pi is
		// between provider calls — which is exactly the state it is in while compacting
		// mid-run — so the projection rebuilt afterwards already contains it. The
		// regression checks the persisted entry in the branch and in the next request
		// rather than trusting that internal branch. It is a session message, not a
		// per-request projection, and it costs no extra model call.
		//
		// A failed or cancelled compaction emits `session_compact_failed` instead and
		// never reaches this handler, so nothing is re-sent for a compaction that did not
		// happen.
		try {
			const block = await pendingPlanState(ctx.cwd, ctx, effectiveContextMessages(ctx));
			if (!block) return;
			pi.sendMessage({ customType: PLAN_STATE_TYPE, content: block, display: false });
		} catch {
			return;
		}
	});

	pi.on("tool_execution_end", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});

	pi.on("agent_end", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});

	pi.on("agent_settled", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});
}
