import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, stat, writeFile, appendFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";
import { Type } from "typebox";

const MEMORY_TEMPLATE = `# Project Memory

Durable project knowledge, decisions, preferences, and recurring lessons.

## Stable Preferences

- Prefer simple, direct implementations.
- Prefer framework-native and project-native solutions.
- Avoid unnecessary abstractions.
- Do not duplicate framework guarantees.

## Project Decisions

<!-- Durable technical or product decisions. -->

## Known Pitfalls

<!-- Recurring problems, fragile flows, or common agent mistakes. -->

## Agent Lessons

<!-- Lessons that help future agents work better in this project. -->
`;

const TASKS_TEMPLATE = `# Project Tasks

Pending project work that should survive across sessions.

## Inbox

- [ ] Add pending tasks here. Keep one-line tasks inline; link complex work with wiki links like [[.ai/plan/<file>.md]].

## In Progress

## Done
`;

const PLAN_TEMPLATE = (slug: string, sessionId: string) => `# Plan: ${slug}
- Status: in-progress
- Created: ${new Date().toISOString().split("T")[0]}
- Session ID: ${sessionId}

## Goal

## Current Step

## Spec / Contract

## Tasks
- [ ] Task 1: ...

## Stop Rules

## Validation Policy

## Validation
`;

function projectMemoryPaths(cwd: string) {
	const aiDir = path.join(cwd, ".ai");
	return {
		aiDir,
		planDir: path.join(aiDir, "plan"),
		dailyDir: path.join(aiDir, "daily"),
		memoryFile: path.join(aiDir, "MEMORY.md"),
		tasksFile: path.join(aiDir, "TASKS.md"),
	};
}

async function ensureProjectMemory(cwd: string) {
	const paths = projectMemoryPaths(cwd);
	await mkdir(paths.planDir, { recursive: true });
	await mkdir(paths.dailyDir, { recursive: true });

	if (!existsSync(paths.memoryFile)) {
		await writeFile(paths.memoryFile, MEMORY_TEMPLATE, "utf8");
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

function yesterdayDate(): string {
	const date = new Date();
	date.setDate(date.getDate() - 1);
	return localDate(date);
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

async function latestPlanPath(cwd: string): Promise<string | undefined> {
	const paths = projectMemoryPaths(cwd);
	try {
		const entries = (await readdir(paths.planDir)).filter((file) => file.endsWith(".md"));
		const files = await Promise.all(entries.map(async (file) => ({
			file,
			mtimeMs: (await stat(path.join(paths.planDir, file))).mtimeMs,
		})));
		files.sort((a, b) => b.mtimeMs - a.mtimeMs || a.file.localeCompare(b.file));
		return files[0] ? `.ai/plan/${files[0].file}` : undefined;
	} catch {
		return undefined;
	}
}

function countOpenTasks(tasks: string): number {
	return tasks.split("\n").filter((line) => /^- \[ \] /.test(line.trim())).length;
}

async function ensureDailyFile(cwd: string) {
	const paths = await ensureProjectMemory(cwd);
	const file = path.join(paths.dailyDir, `${localDate()}.md`);
	if (!existsSync(file)) {
		await writeFile(file, `# ${localDate()}\n`, "utf8");
	}
}

function shortSessionId(ctx: any): string {
	const id = ctx.sessionManager?.sessionId || ctx.sessionId;
	if (id) return id.slice(0, 8);
	return "session";
}

async function sessionPlanPath(cwd: string, sessionId: string): Promise<{ path: string; exists: boolean }> {
	const paths = projectMemoryPaths(cwd);
	const prefix = `${localDate()}-${sessionId}-`;

	try {
		const existing = (await readdir(paths.planDir))
			.filter((file) => file.startsWith(prefix) && file.endsWith(".md"))
			.sort();

		if (existing[0]) return { path: `.ai/plan/${existing[0]}`, exists: true };
	} catch {}

	return { path: `.ai/plan/${prefix}<short-slug>.md`, exists: false };
}

export default function (pi: ExtensionAPI) {
	// --- Tools ---

	pi.registerTool({
		name: "create_session_plan",
		description: "Creates or retrieves the session plan file. Use this at the start of any non-trivial task.",
		parameters: Type.Object({
			slug: Type.String({ description: "Short descriptive slug for the plan (e.g. 'fix-auth-bug')." }),
		}),
		async execute(_id, params, _signal, _update, ctx) {
			const cwd = ctx.cwd;
			const sessionId = shortSessionId(ctx);
			const { path: planPath, exists } = await sessionPlanPath(cwd, sessionId);

			if (exists) {
				return { content: [{ type: "text", text: `Session plan already exists at: ${planPath}` }] };
			}

			const finalPath = planPath.replace("<short-slug>", params.slug);
			const fullPath = path.join(cwd, finalPath);
			await writeFile(fullPath, PLAN_TEMPLATE(params.slug, sessionId), "utf8");

			return { content: [{ type: "text", text: `Created session plan at: ${finalPath}` }] };
		},
	});

	pi.registerTool({
		name: "add_daily_note",
		description: "Adds a concise note to today's daily log.",
		parameters: Type.Object({
			note: Type.String({ description: "The note to add (summary of work, risks, or decisions)." }),
		}),
		async execute(_id, params, _signal, _update, ctx) {
			const cwd = ctx.cwd;
			await ensureDailyFile(cwd);
			const dailyFile = path.join(cwd, ".ai", "daily", `${localDate()}.md`);
			const timestamp = new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
			const entry = `\n- **${timestamp}**: ${params.note}\n`;
			await appendFile(dailyFile, entry, "utf8");

			return { content: [{ type: "text", text: "Note added to daily log." }] };
		},
	});

	pi.registerTool({
		name: "get_current_plan",
		description: "Reads the active session plan, or the latest plan if no current session plan exists.",
		parameters: Type.Object({}),
		async execute(_id, _params, _signal, _update, ctx) {
			const cwd = ctx.cwd;
			await ensureProjectMemory(cwd);
			const sessionId = shortSessionId(ctx);
			const current = await sessionPlanPath(cwd, sessionId);
			const fallbackPath = current.exists ? current.path : await latestPlanPath(cwd);
			const planPath = fallbackPath || current.path;
			const fullPath = path.join(cwd, planPath);
			const content = await readIfExists(fullPath);
			const source = current.exists ? "current-session" : fallbackPath ? "latest" : "missing";
			const preview = content ? previewText(content, 16, 2000) : "";
			const text = content
				? `Plan source: ${source}\nPath: ${planPath}\n\n${preview}`
				: `Plan source: ${source}\nPath: ${planPath}\n\nNo plan file found.`;

			return {
				content: [{ type: "text", text }],
				details: {
					path: planPath,
					source,
					exists: Boolean(content),
					currentSessionPath: current.path,
				},
			};
		},
	});

	pi.registerTool({
		name: "summarize_worktree",
		description: "Returns a compact snapshot of the current repo state, current plan, and open tasks.",
		parameters: Type.Object({}),
		async execute(_id, _params, _signal, _update, ctx) {
			const cwd = ctx.cwd;
			const paths = await ensureProjectMemory(cwd);
			const status = await runCommand(cwd, "git", ["status", "--short", "--branch", "--untracked-files=normal"]);
			if (status.code !== 0) {
				const message = status.stderr.trim() || "git status failed";
				return { content: [{ type: "text", text: message }], details: { error: message } };
			}

			const log = await runCommand(cwd, "git", ["log", "-1", "--oneline", "--decorate=short"]);
			const tasks = await readIfExists(paths.tasksFile);
			const openTasks = countOpenTasks(tasks);
			const sessionId = shortSessionId(ctx);
			const current = await sessionPlanPath(cwd, sessionId);
			const fallbackPath = current.exists ? current.path : await latestPlanPath(cwd);
			const planPath = fallbackPath || current.path;
			const planContent = await readIfExists(path.join(cwd, planPath));
			const planPreview = planContent ? previewText(planContent, 8, 900) : "";
			const statusLines = status.stdout.trim().split("\n").filter(Boolean);
			const branchLine = statusLines[0]?.replace(/^##\s*/, "") || "unknown";
			const dirtyFiles = statusLines.slice(1).map((line) => line.replace(/^[ MADRCU?!]+/, "").trim()).filter(Boolean);
			const lastCommit = log.stdout.trim() || "unavailable";
			const lines = [
				`Branch: ${branchLine}`,
				dirtyFiles.length ? `Dirty: ${dirtyFiles.length} file(s)` : "Dirty: clean",
				`Last commit: ${lastCommit}`,
				`Current plan: ${planPath}${current.exists ? "" : fallbackPath ? " (latest)" : " (missing)"}`,
				`Open tasks: ${openTasks}`,
			];

			if (dirtyFiles.length) {
				lines.push("", "Changed files:", ...dirtyFiles.slice(0, 8).map((file) => `- ${file}`));
				if (dirtyFiles.length > 8) lines.push(`- … +${dirtyFiles.length - 8} more`);
			}

			if (planPreview) {
				lines.push("", "Plan preview:", planPreview);
			}

			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: {
					branch: branchLine,
					dirtyCount: dirtyFiles.length,
					dirtyFiles,
					lastCommit,
					planPath,
					planSource: current.exists ? "current-session" : fallbackPath ? "latest" : "missing",
					openTasks,
				},
			};
		},
	});

	// --- Lifecycle Hooks ---

	pi.on("before_agent_start", async (event, ctx) => {
		const cwd = event.systemPromptOptions?.cwd ?? ctx.cwd;
		const paths = await ensureProjectMemory(cwd);
		await ensureDailyFile(cwd);

		const sessionId = shortSessionId(ctx);
		const { path: planPath } = await sessionPlanPath(cwd, sessionId);
		const memory = await readFile(paths.memoryFile, "utf8");
		const tasks = await readFile(paths.tasksFile, "utf8");
		const today = localDate();
		const yesterday = yesterdayDate();
		const todayDaily = await readIfExists(path.join(paths.dailyDir, `${today}.md`));
		const yesterdayDaily = await readIfExists(path.join(paths.dailyDir, `${yesterday}.md`));
		const todayDailyPreview = previewText(todayDaily, 80, 6000);
		const yesterdayDailyPreview = previewText(yesterdayDaily, 40, 3000);
		const dailySections = [
			todayDailyPreview.trim() ? `## Daily log: ${today} (today)\n\n\`\`\`md\n${todayDailyPreview.trim()}\n\`\`\`` : "",
			yesterdayDailyPreview.trim() ? `## Daily log: ${yesterday} (yesterday)\n\n\`\`\`md\n${yesterdayDailyPreview.trim()}\n\`\`\`` : "",
		].filter(Boolean).join("\n\n");

		const memoryContext = `## Project Memory

The current project uses local AI memory files:
- \`.ai/MEMORY.md\` — durable context and decisions.
- \`.ai/TASKS.md\` — pending project work.
- \`.ai/plan/\` — task-specific implementation plans.
- \`.ai/daily/\` — concise daily notes.

Current session plan: \`${planPath}\`

### Memory Policy
- **Planning**: Use \`create_session_plan\` at the start of non-trivial tasks. Update the plan file directly.
- **Inspect**: Use \`get_current_plan\` for the active plan and \`summarize_worktree\` for a compact repo snapshot.
- **Tasks**: Use \`.ai/TASKS.md\` for work that survives sessions. Use wiki-links \`[[.ai/plan/file.md]]\` for complex tasks.
- **Daily**: Use \`add_daily_note\` after meaningful work. Do not write to daily files manually.
- **Durable**: Update \`.ai/MEMORY.md\` only for long-term project decisions or stable preferences.

Current \`.ai/MEMORY.md\` contents:
\`\`\`md
${memory.trim() || "# Project Memory\n\n_No durable project memory recorded yet._"}
\`\`\`

Current \`.ai/TASKS.md\` contents:
\`\`\`md
${tasks.trim() || "# Project Tasks\n\n_No pending project tasks recorded yet._"}
\`\`\`

${dailySections ? `Recent daily context:\n\n${dailySections}` : "No recent daily context yet."}`;

		return {
			systemPrompt: `${event.systemPrompt}\n\n${memoryContext}`,
		};
	});

	pi.on("agent_end", async (_event, ctx) => {
		await ensureDailyFile(ctx.cwd);
	});
}
