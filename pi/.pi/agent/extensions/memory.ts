import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, writeFile, appendFile } from "node:fs/promises";
import { existsSync } from "node:fs";
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

- Validation:
- Remaining:
- Notes:
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

## Spec / Contract

## Tasks
- [ ] Task 1: ...

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
		const dailySections = [
			todayDaily.trim() ? `## Daily log: ${today} (today)\n\n\`\`\`md\n${todayDaily.trim()}\n\`\`\`` : "",
			yesterdayDaily.trim() ? `## Daily log: ${yesterday} (yesterday)\n\n\`\`\`md\n${yesterdayDaily.trim()}\n\`\`\`` : "",
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
