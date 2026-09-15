import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, realpath, writeFile } from "node:fs/promises";
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

export function activeTasksPreview(tasks: string, maxLines = 8, maxChars = 900): string {
	const heading = /^##\s+In Progress\s*$/m.exec(tasks);
	if (!heading || heading.index === undefined) return "_No active In Progress task recorded._";
	const rest = tasks.slice(heading.index + heading[0].length);
	const nextHeading = /^##\s+/m.exec(rest);
	const section = rest.slice(0, nextHeading?.index ?? rest.length);
	const active = previewText(section, maxLines, maxChars);
	return active || "_No active In Progress task recorded._";
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
	try {
		if (typeof sessionManager?.buildContextEntries === "function") return sessionManager.buildContextEntries();
		if (typeof sessionManager?.getEntries === "function") return sessionManager.getEntries();
	} catch {}
	return [];
}

export type PlanPointerResolution =
	| { status: "none" }
	| { status: "valid"; pointer: PlanPointer }
	| { status: "ambiguous"; pointers: PlanPointer[] }
	| { status: "invalid"; pointer: PlanPointer; reason: string }
	| { status: "session-mismatch"; pointer: PlanPointer }
	| { status: "worktree-mismatch"; pointer: PlanPointer };

/**
 * Resolve the latest active-plan pointer from session entries against the expected
 * session/worktree identity. Pure: no filesystem or process access.
 */
export function resolvePlanPointer(entries: unknown, expected: { sessionId: string; worktree: string; cwd: string }): PlanPointerResolution {
	const list = Array.isArray(entries) ? entries : [];
	const pointers: PlanPointer[] = [];
	for (let i = list.length - 1; i >= 0; i--) {
		const entry = list[i] as { type?: string; customType?: string; data?: unknown } | undefined;
		if (entry?.type !== "custom" || entry?.customType !== PLAN_POINTER_TYPE) continue;
		const pointer = parsePlanPointer(entry.data);
		if (pointer) pointers.push(pointer);
	}
	if (!pointers.length) return { status: "none" };
	const latest = pointers[0];
	if (new Set(pointers.map((pointer) => pointer.planPath)).size > 1) return { status: "ambiguous", pointers };
	if (!isPlanPathContained(latest.planPath, expected.cwd)) {
		return { status: "invalid", pointer: latest, reason: `plan path "${latest.planPath}" escapes .ai/plan/` };
	}
	const sessionMatch = latest.sessionId === expected.sessionId || legacySessionId(latest.sessionId) === legacySessionId(expected.sessionId);
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
	if (planSessionId && legacySessionId(planSessionId) !== legacySessionId(expected.sessionId)) {
		return `Plan metadata belongs to a different session (${planSessionId}); expected ${expected.sessionId}`;
	}
	const planWorktree = planMetadata(content, "Worktree");
	if (planWorktree && normalizeWorktreePath(planWorktree) !== normalizeWorktreePath(expected.worktree)) {
		return `Plan metadata belongs to a different worktree (${planWorktree}); expected ${expected.worktree}`;
	}
	return undefined;
}

/** Extract one bounded `## <heading>` section body from a plan body. */
export function planSection(content: string, heading: string, maxChars = 1200): string {
	const normalized = content.replace(/\r\n/g, "\n");
	const escaped = heading.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
	const match = new RegExp(`^##\\s+${escaped}\\s*$`, "m").exec(normalized);
	if (!match) return "";
	const rest = normalized.slice(match.index + match[0].length);
	const nextHeading = /^##\s+/m.exec(rest);
	const section = rest.slice(0, nextHeading?.index ?? rest.length).trim();
	return section.length > maxChars ? `${section.slice(0, maxChars)}\n[truncated]` : section;
}

/** Count plan checklist tasks by status. */
export function planTaskCounts(content: string): { total: number; open: number; done: number } {
	const open = countOpenTasks(content);
	const done = content.split("\n").filter((line) => /^- \[[xX]\] /.test(line.trim())).length;
	return { total: open + done, open, done };
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

/** First open `- [ ]` checklist task in the plan body, bounded to one line. */
export function planActiveTask(content: string, maxChars = PLAN_SNAPSHOT_LINE_CHARS): string {
	for (const line of content.split("\n")) {
		const trimmed = line.trim();
		if (/^- \[ \] /.test(trimmed)) return truncateLine(trimmed, maxChars);
	}
	return "";
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
	status: string;
	tldr: string;
	currentStep: string;
	tasks: { total: number; open: number; done: number };
	activeTask: string;
	warning: string;
}

/** Derive the bounded recovery view (status/TL;DR/step/counts/active task/warning) from a plan body. */
export function planSnapshot(content: string, planPath: string): PlanSnapshot {
	return {
		planPath,
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
		if (gitRoot.code === 0 && gitRoot.stdout.trim()) return normalizeWorktreePath(gitRoot.stdout.trim());
	} catch {}
	try {
		return normalizeWorktreePath(await realpath(cwd));
	} catch {
		return normalizeWorktreePath(cwd);
	}
}

/** Legacy exact current-session plan filenames (full or short session ID prefix, today's date). */
async function findSessionPlanFiles(cwd: string, sessionId: string): Promise<string[]> {
	const paths = projectPaths(cwd);
	const prefixes = [...new Set([sessionId, legacySessionId(sessionId)])].map((id) => `${localDate()}-${id}-`);
	try {
		return (await readdir(paths.planDir))
			.filter((file) => file.endsWith(".md") && prefixes.some((prefix) => file.startsWith(prefix)))
			.sort()
			.map((file) => `.ai/plan/${file}`);
	} catch {
		return [];
	}
}

function planSlugFromFilename(planPath: string, sessionId: string): string {
	const file = path.basename(planPath).replace(/\.md$/, "");
	for (const id of [sessionId, legacySessionId(sessionId)]) {
		const prefix = `${localDate()}-${id}-`;
		if (file.startsWith(prefix)) return file.slice(prefix.length) || "session-plan";
	}
	return file || "session-plan";
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
 * fallback only for an exact current-session filename. Never selects by mtime;
 * ambiguity and mismatch are reported as actionable blockers.
 */
async function resolveActivePlan(cwd: string, ctx: any): Promise<ActivePlanResolution> {
	const sessionId = sessionIdOf(ctx);
	const currentSessionPath = `.ai/plan/${localDate()}-${sessionId}-<slug>.md`;
	const worktree = await worktreeIdentity(cwd);
	const entries = activeBranchEntries(ctx.sessionManager);

	if (entries.length) {
		const resolution = resolvePlanPointer(entries, { sessionId, worktree, cwd });
		if (resolution.status === "ambiguous") {
			return {
				source: "missing",
				blocked: `Ambiguous active plan pointers: ${resolution.pointers.map((pointer) => pointer.planPath).join(", ")}. Remove or rename the stale plan file so exactly one remains, then run create_session_plan.`,
				currentSessionPath,
			};
		}
		if (resolution.status === "invalid") {
			return {
				source: "missing",
				blocked: `Invalid active plan pointer: ${resolution.reason}. Run create_session_plan to establish a valid plan.`,
				currentSessionPath,
			};
		}
		if (resolution.status === "valid") {
			const fullPath = path.join(cwd, resolution.pointer.planPath);
			if (existsSync(fullPath)) {
				const mismatch = planIdentityMismatch(await readIfExists(fullPath), { sessionId, worktree });
				if (mismatch) return { source: "missing", blocked: mismatch, currentSessionPath: resolution.pointer.planPath };
				return { planPath: resolution.pointer.planPath, source: "active-pointer", pointer: resolution.pointer, currentSessionPath: resolution.pointer.planPath };
			}
			return {
				source: "missing",
				blocked: `Active plan pointer references a missing file: ${resolution.pointer.planPath}. Run create_session_plan to recreate it.`,
				currentSessionPath: resolution.pointer.planPath,
			};
		}
		if (resolution.status === "worktree-mismatch") {
			return {
				source: "missing",
				blocked: `Active plan pointer (${resolution.pointer.planPath}) was recorded for a different worktree (${resolution.pointer.worktree}). Run create_session_plan in this worktree.`,
				currentSessionPath,
			};
		}
		if (resolution.status === "session-mismatch") {
			return {
				source: "missing",
				blocked: `Active plan pointer (${resolution.pointer.planPath}) was recorded for a different session (${resolution.pointer.sessionId}). Run create_session_plan for this session.`,
				currentSessionPath,
			};
		}
	}

	const legacy = await findSessionPlanFiles(cwd, sessionId);
	if (legacy.length === 1) {
		const mismatch = planIdentityMismatch(await readIfExists(path.join(cwd, legacy[0])), { sessionId, worktree });
		if (mismatch) return { source: "missing", blocked: mismatch, currentSessionPath: legacy[0] };
		return { planPath: legacy[0], source: "current-session", currentSessionPath: legacy[0] };
	}
	if (legacy.length > 1) {
		return {
			source: "missing",
			blocked: `Multiple current-session plan candidates: ${legacy.join(", ")}. Rename or remove stale files so exactly one remains.`,
			currentSessionPath: legacy[0],
		};
	}
	return { source: "missing", currentSessionPath };
}

// --- Existing-UI progress (ctx.ui.setStatus/setWidget; TUI only, never throws) ---

const PLAN_STATUS_KEY = "session-plan";
const PLAN_WIDGET_KEY = "session-plan";

function planStatusText(snapshot: PlanSnapshot | undefined, blocked?: string): string | undefined {
	if (blocked) return truncateLine(`Plan blocked: ${blocked}`, 120);
	if (!snapshot) return undefined;
	const step = truncateLine(snapshot.currentStep, 48);
	const tasks = `${snapshot.tasks.open} open/${snapshot.tasks.done} done`;
	return truncateLine(`Plan ${snapshot.status} · ${tasks}${step ? ` · ${step}` : ""}`, 120);
}

function planWidgetLines(snapshot: PlanSnapshot | undefined, blocked?: string): string[] | undefined {
	if (!snapshot) return undefined;
	const lines = [`Plan: ${snapshot.planPath} (${snapshot.status})`];
	if (snapshot.tldr) lines.push(`TL;DR: ${truncateLine(snapshot.tldr, 90)}`);
	if (snapshot.currentStep) lines.push(`Step: ${truncateLine(snapshot.currentStep, 90)}`);
	lines.push(`Tasks: ${snapshot.tasks.open} open / ${snapshot.tasks.done} done (${snapshot.tasks.total} total)`);
	const warning = blocked ?? snapshot.warning;
	if (warning) lines.push(`Warning: ${truncateLine(warning, 90)}`);
	return lines;
}

/** Bounded injected plan view for the system prompt: identity/status/counts/step/active task/warning only. */
function planSnapshotBlock(snapshot: PlanSnapshot | undefined, blocked?: string): string {
	if (blocked) return `> Active plan unavailable: ${blocked}`;
	if (!snapshot) return "_No active session plan yet. Run `create_session_plan` at the start of non-trivial tasks._";
	const lines = [
		`**Plan**: \`${snapshot.planPath}\` — status: ${snapshot.status}`,
		`**Tasks**: ${snapshot.tasks.open} open / ${snapshot.tasks.done} done (${snapshot.tasks.total} total)`,
	];
	if (snapshot.tldr) lines.push(`**TL;DR**: ${snapshot.tldr}`);
	if (snapshot.currentStep) lines.push(`**Current Step**: ${snapshot.currentStep}`);
	if (snapshot.activeTask) lines.push(`**Active task**: ${snapshot.activeTask}`);
	if (snapshot.warning) lines.push(`**Warning**: ${snapshot.warning}`);
	return lines.join("\n");
}

/** Update the existing status/widget UI from a plan snapshot; no-op outside TUI and never throws. */
function updatePlanUI(ctx: any, snapshot?: PlanSnapshot, blocked?: string): void {
	try {
		const ui = ctx?.ui;
		if (!ui || typeof ui.setStatus !== "function" || typeof ui.setWidget !== "function") return;
		if (ctx?.mode !== undefined && ctx.mode !== "tui") return;
		ui.setStatus(PLAN_STATUS_KEY, planStatusText(snapshot, blocked));
		ui.setWidget(PLAN_WIDGET_KEY, planWidgetLines(snapshot, blocked), { placement: "aboveEditor" });
	} catch {}
}

/** Clear status/widget state before a session switch so no stale plan text lingers. */
function clearPlanUI(ctx: any): void {
	try {
		const ui = ctx?.ui;
		if (!ui || typeof ui.setStatus !== "function" || typeof ui.setWidget !== "function") return;
		if (ctx?.mode !== undefined && ctx.mode !== "tui") return;
		ui.setStatus(PLAN_STATUS_KEY, undefined);
		ui.setWidget(PLAN_WIDGET_KEY, undefined, { placement: "aboveEditor" });
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

function planPointerRecord(pointer: Omit<PlanPointer, "v" | "updatedAt">): PlanPointer {
	return { v: 1, ...pointer, updatedAt: new Date().toISOString() };
}

function persistPlanPointer(pi: ExtensionAPI, pointer: PlanPointer): boolean {
	try {
		pi.appendEntry(PLAN_POINTER_TYPE, pointer);
		return true;
	} catch {
		return false;
	}
}

export default function (pi: ExtensionAPI) {
	// --- Tools ---

	pi.registerTool({
		name: "create_session_plan",
		label: "Create session plan",
		description: "Creates or retrieves the session plan file. Use this at the start of any non-trivial task.",
		parameters: Type.Object({
			slug: Type.String({ description: "Short descriptive slug for the plan (e.g. 'fix-auth-bug')." }),
		}),
		async execute(_id, params, _signal, _update, ctx) {
			const cwd = ctx.cwd;
			if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(params.slug) || params.slug.length > 80) throw new Error("Plan slug must be lowercase alphanumeric words separated by hyphens (max 80 characters)");
			await ensureProjectFiles(cwd);
			const sessionId = sessionIdOf(ctx);
			const worktree = await worktreeIdentity(cwd);
			const entries = activeBranchEntries(ctx.sessionManager);
			const resolution = entries.length ? resolvePlanPointer(entries, { sessionId, worktree, cwd }) : { status: "none" as const };

			if (resolution.status === "valid" || resolution.status === "worktree-mismatch") {
				const pointer = resolution.pointer;
				const contained = isPlanPathContained(pointer.planPath, cwd);
				if (contained && existsSync(path.join(cwd, pointer.planPath))) {
					if (resolution.status === "worktree-mismatch") {
						const rebound = planPointerRecord({ planPath: pointer.planPath, sessionId: pointer.sessionId, worktree, slug: pointer.slug });
						const persisted = persistPlanPointer(pi, rebound);
						await refreshPlanUI(ctx);
						return {
							content: [{ type: "text", text: `Session plan already exists at: ${pointer.planPath} (rebound to worktree ${worktree}${persisted ? "" : "; pointer not persisted"})` }],
							details: { path: pointer.planPath, created: false, rebound: true, pointerPersisted: persisted },
						};
					}
					await refreshPlanUI(ctx);
					return {
						content: [{ type: "text", text: `Session plan already exists at: ${pointer.planPath}` }],
						details: { path: pointer.planPath, created: false, pointerPersisted: true },
					};
				}
				// Pointer references a missing file: recreate at the same path instead of a second plan.
				const slug = pointer.slug || params.slug;
				await writeFile(path.join(cwd, pointer.planPath), PLAN_TEMPLATE(slug, sessionId, worktree), "utf8");
				const persisted = persistPlanPointer(pi, planPointerRecord({ planPath: pointer.planPath, sessionId, worktree, slug }));
				await refreshPlanUI(ctx);
				return {
					content: [{ type: "text", text: `Recreated missing session plan at: ${pointer.planPath}${persisted ? "" : " (warning: session pointer could not be persisted)"}` }],
					details: { path: pointer.planPath, created: true, pointerPersisted: persisted },
				};
			}

			if (resolution.status === "ambiguous") {
				throw new Error(`Ambiguous active plan pointers: ${resolution.pointers.map((pointer) => pointer.planPath).join(", ")}. Remove or rename the stale plan file so exactly one remains, then retry.`);
			}
			if (resolution.status === "invalid") {
				throw new Error(`Invalid active plan pointer: ${resolution.reason}. Remove or fix the stale pointer, then retry.`);
			}

			// No usable pointer (none, or one belonging to another session): adopt an exact
			// current-session legacy plan instead of creating a second plan.
			const legacy = await findSessionPlanFiles(cwd, sessionId);
			if (legacy.length > 1) throw new Error(`Multiple current-session plan candidates: ${legacy.join(", ")}. Rename or remove stale files so exactly one remains, then retry.`);
			if (legacy.length === 1) {
				const pointer = planPointerRecord({ planPath: legacy[0], sessionId, worktree, slug: planSlugFromFilename(legacy[0], sessionId) });
				const persisted = persistPlanPointer(pi, pointer);
				await refreshPlanUI(ctx);
				return {
					content: [{ type: "text", text: `Adopted existing session plan at: ${legacy[0]}${persisted ? "" : " (warning: session pointer could not be persisted)"}` }],
					details: { path: legacy[0], created: false, pointerPersisted: persisted },
				};
			}

			const finalPath = `.ai/plan/${localDate()}-${sessionId}-${params.slug}.md`;
			const fullPath = path.join(cwd, finalPath);
			await writeFile(fullPath, PLAN_TEMPLATE(params.slug, sessionId, worktree), "utf8");
			const persisted = persistPlanPointer(pi, planPointerRecord({ planPath: finalPath, sessionId, worktree, slug: params.slug }));
			await refreshPlanUI(ctx);
			return {
				content: [{ type: "text", text: `Created session plan at: ${finalPath}${persisted ? "" : " (warning: session pointer could not be persisted)"}` }],
				details: { path: finalPath, created: true, pointerPersisted: persisted },
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
					snapshot?.currentStep ? `Current Step: ${truncateLine(snapshot.currentStep, 200)}` : undefined,
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
				if (snapshot.currentStep) lines.push(`Current step: ${truncateLine(snapshot.currentStep, 120)}`);
				if (snapshot.activeTask) lines.push(`Active task: ${snapshot.activeTask}`);
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

	pi.on("before_agent_start", async (event, ctx) => {
		const cwd = event.systemPromptOptions?.cwd ?? ctx.cwd;
		const paths = await ensureProjectFiles(cwd);

		const resolved = await resolveActivePlan(cwd, ctx);
		const planPath = resolved.planPath ?? resolved.currentSessionPath;
		const planNote = resolved.planPath
			? ""
			: resolved.blocked
				? ` (blocked: ${resolved.blocked})`
				: " (no active plan yet — run `create_session_plan`)";
		const tasks = await readFile(paths.tasksFile, "utf8");
		const activeTasks = activeTasksPreview(tasks, 4, 600);
		const planContent = resolved.planPath ? await readIfExists(path.join(cwd, resolved.planPath)) : "";
		const snapshot = planContent ? planSnapshot(planContent, resolved.planPath!) : undefined;
		updatePlanUI(ctx, snapshot, resolved.blocked);
		const snapshotBlock = planSnapshotBlock(snapshot, resolved.blocked);
		const changelogPolicy = existsSync(path.join(cwd, "CHANGELOG.md"))
			? `\n### Changelog Policy\n- This project has a \`CHANGELOG.md\`. Every job producing user-visible changes MUST add or update a SemVer-aligned Keep a Changelog entry before finalizing.\n- If the changelog is missing or stale for the current job, do not report \`ready to ship\`.`
			: "";

		const workflowContext = `## Project Workflow

The current project uses local task and plan files:
- \`.ai/TASKS.md\` — pending project work.
- \`.ai/plan/\` — task-specific implementation plans.

Current session plan: \`${planPath}\`${planNote}

${snapshotBlock}

### Workflow Policy
- **Planning**: Use \`create_session_plan\` at the start of non-trivial tasks. Update the plan file directly.
- **Inspect**: Use \`get_current_plan\` for the active plan and \`summarize_worktree\` for a compact repo snapshot.
- **Tasks**: Use \`.ai/TASKS.md\` for work that survives sessions. Use wiki-links \`[[.ai/plan/file.md]]\` for complex tasks.
- **Reference discipline**: When a route, component, file, or decision is already recorded, refer to the existing section or item instead of restating the whole list.
- **Inventory discipline**: For route/component reports, keep one canonical list and append only new or changed entries.
- **Delta focus**: In iterative frontend, CSS, or JS work, answer with the smallest useful delta rather than reprinting prior inventories.
${changelogPolicy}

### Task Context (bounded; full ledger: .ai/TASKS.md):
Active In Progress item(s):
\`\`\`md
${activeTasks}
\`\`\``;

		return {
			systemPrompt: `${event.systemPrompt}\n\n${workflowContext}`,
		};
	});

	// Refresh the existing status/widget UI on safe session boundaries: refresh from
	// the canonical file on start/tree changes, clear stale text before a switch.
	pi.on("session_start", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});

	pi.on("session_before_switch", (_event, ctx) => {
		clearPlanUI(ctx);
	});

	pi.on("session_tree", async (_event, ctx) => {
		await refreshPlanUI(ctx);
	});
}
