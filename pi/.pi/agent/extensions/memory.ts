import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";

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

function shortSessionId(ctx: { sessionManager?: { sessionId?: string } }): string {
	const id = ctx.sessionManager?.sessionId;
	if (id) return id.slice(0, 8);

	return "session";
}

async function sessionPlanPath(cwd: string, sessionId: string): Promise<string> {
	const paths = projectMemoryPaths(cwd);
	const prefix = `${localDate()}-${sessionId}-`;

	try {
		const existing = (await readdir(paths.planDir))
			.filter((file) => file.startsWith(prefix) && file.endsWith(".md"))
			.sort();

		if (existing[0]) return `.ai/plan/${existing[0]}`;
	} catch {}

	return `.ai/plan/${prefix}<short-slug>.md`;
}

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		const cwd = event.systemPromptOptions?.cwd ?? ctx.cwd;
		const paths = await ensureProjectMemory(cwd);
		await ensureDailyFile(cwd);

		const sessionId = shortSessionId(ctx);
		const planPath = await sessionPlanPath(cwd, sessionId);
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

The current project uses local AI memory files under the current working directory:

- \`.ai/MEMORY.md\` — durable project context, decisions, preferences, and recurring lessons.
- \`.ai/TASKS.md\` — pending project work. One-line tasks live directly here; complex tasks link to a plan file with wiki links like \`[[.ai/plan/<file>.md]]\`.
- \`.ai/plan/\` — session/task plans for non-trivial implementation work.
- \`.ai/daily/\` — concise daily notes after meaningful work. Today and yesterday are injected for continuity when present.

Current session plan path: \`${planPath}\`

If the path contains \`<short-slug>\`, replace it with a short descriptive slug when creating the plan. Before creating a new plan, look for an existing file matching \`.ai/plan/${localDate()}-${sessionId}-*.md\` and update that existing file instead.

Memory is context, not authority. Current user instructions, AGENTS.md, and explicit project documentation override memory. Do not let memory broaden the current task scope.

## Memory Policy

- For non-trivial implementation, fixing, debugging, planning, or finalization work, use the \`memory\` skill when available.
- For non-trivial work in this session, create or update the single current session plan at \`${planPath}\`. Use a descriptive slug only when creating the file for the first time. Do not create a new plan file for every interaction.
- If the current task changes materially, update the same session plan with the new status, decisions, TODOs, and remaining work.
- Store pending work in \`.ai/TASKS.md\`: simple tasks as one-line checkboxes; complex tasks as checkboxes with wiki links to plans, e.g. \`[[.ai/plan/YYYY-MM-DD-topic.md]]\`.
- At the end of meaningful work, append a concise entry to \`.ai/daily/${localDate()}.md\`.
- Update \`.ai/MEMORY.md\` only for durable lessons, stable preferences, architecture decisions, recurring pitfalls, or important workflow decisions.
- Do not store secrets, full transcripts, long diffs, temporary logs, or irrelevant tool output.
- Keep daily notes short. Prefer outcomes, validation, remaining work, and risks for the next session.

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
		// MVP fallback: keep today's daily file available, but let the model write useful summaries.
		await ensureDailyFile(ctx.cwd);
	});
}
