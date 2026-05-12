import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { readFile } from "node:fs/promises";
import path from "node:path";

const DEFAULT_EXCLUDES = [
	".git",
	".ai",
	"node_modules",
	"vendor",
	"dist",
	"build",
	"coverage",
	"storage",
	".next",
	".nuxt",
	".turbo",
	".cache",
	"tmp",
	".worktrees",
];

const KIND_GLOBS: Record<string, string[]> = {
	any: [],
	php: ["*.php"],
	test: ["*Test.php", "*.test.*", "*.spec.*", "tests/**"],
	config: ["*.json", "*.yaml", "*.yml", "*.toml", "*.ini", "*.neon", "config/**"],
	doc: ["*.md", "*.mdx", "docs/**"],
	js: ["*.js", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.svelte"],
};

function clamp(value: number | undefined, fallback: number, min: number, max: number): number {
	if (!Number.isFinite(value)) return fallback;
	return Math.max(min, Math.min(max, Math.floor(value!)));
}

function excludeArgsForFd(): string[] {
	return DEFAULT_EXCLUDES.flatMap((pattern) => ["--exclude", pattern]);
}

function excludeArgsForRg(): string[] {
	return DEFAULT_EXCLUDES.flatMap((pattern) => ["--glob", `!${pattern}/**`]);
}

function globArgs(globs: string[] | undefined): string[] {
	return (globs ?? []).flatMap((glob) => ["--glob", glob]);
}

function kindGlobs(kind: string | undefined): string[] {
	return KIND_GLOBS[kind ?? "any"] ?? [];
}

function normalizeLines(text: string): string[] {
	return text.split("\n").map((line) => line.trimEnd()).filter(Boolean);
}

function formatCommand(command: string, args: string[]): string {
	return [command, ...args.map((arg) => JSON.stringify(arg))].join(" ");
}

function resolveProjectPath(cwd: string, filePath: string): string | undefined {
	const resolved = path.resolve(cwd, filePath.replace(/^@/, ""));
	const relative = path.relative(cwd, resolved);
	if (relative.startsWith("..") || path.isAbsolute(relative)) return undefined;
	return resolved;
}

function compactLine(line: string, maxLength = 220): string {
	const trimmed = line.trim();
	return trimmed.length > maxLength ? `${trimmed.slice(0, maxLength - 1)}…` : trimmed;
}

function normalizeFileQuery(query: string): string {
	return query.trim().replace(/^\*+/, "").replace(/\*+$/, "");
}

function rgPatternArgs(query: string): string[] {
	try {
		// Preserve regex support when the query is valid, but fall back to a literal
		// search for text snippets that would otherwise fail regex parsing.
		// This keeps queries like "->mount(" working without requiring escaping.
		void new RegExp(query);
		return ["-e", query];
	} catch {
		return ["-F", "-e", query];
	}
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "project_files",
		label: "Project Files",
		description: "Find project file paths with conservative limits. Uses fd when available. Returns paths only, not file contents.",
		promptSnippet: "Find relevant project file paths without reading contents",
		promptGuidelines: [
			"Prefer project_files over raw fd/find/ls for codebase discovery by filename or path unless the user explicitly asks for a raw shell command.",
			"Use project_files before broad file reads when you need to locate likely relevant files by path/name.",
			"Prefer small project_files limits and then read only the most relevant files or snippets.",
			"Do not use project_files as proof of behavior; follow with project_search or read_window to verify actual definitions, call sites, triggers, and conditions.",
		],
		parameters: Type.Object({
			query: Type.Optional(Type.String({ description: "Filename/path query. Omit or pass empty string to list files by kind." })),
			kind: Type.Optional(Type.String({ description: "Optional kind: any, php, test, config, doc, js. Default: any." })),
			limit: Type.Optional(Type.Number({ description: "Maximum paths to return. Default: 30, max: 100." })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const limit = clamp(params.limit, 30, 1, 100);
			const query = normalizeFileQuery(params.query ?? "");
			const args = [
				"--type", "f",
				"--fixed-strings",
				"--hidden",
				"--follow",
				"--color", "never",
				...excludeArgsForFd(),
				...kindGlobs(params.kind).flatMap((glob) => ["--glob", glob]),
			];

			if (query) args.push(query);
			args.push(".");

			const result = await pi.exec("fd", args, { cwd: ctx.cwd, signal, timeout: 10_000 });
			if (result.code !== 0) {
				return {
					content: [{ type: "text", text: `project_files failed. Is fd installed?\n\nCommand: ${formatCommand("fd", args)}\n\n${result.stderr || result.stdout}` }],
					details: { command: "fd", args, code: result.code },
				};
			}

			const paths = normalizeLines(result.stdout).slice(0, limit);
			const totalLines = normalizeLines(result.stdout).length;
			const truncated = totalLines > paths.length;
			const text = paths.length
				? [`Found ${paths.length}${truncated ? ` of ${totalLines}` : ""} matching file(s).`, "", ...paths.map((file) => `- ${file}`), truncated ? "\nRefine query/kind or raise limit for more paths." : ""].filter(Boolean).join("\n")
				: "No matching files found.";

			return { content: [{ type: "text", text }], details: { count: paths.length, total: totalLines, truncated } };
		},
	});

	pi.registerTool({
		name: "project_search",
		label: "Project Search",
		description: "Search project contents with rg and return grouped, capped matches. Designed as a compact alternative to broad raw rg output.",
		promptSnippet: "Search project contents with grouped, capped results",
		promptGuidelines: [
			"Prefer project_search over raw rg/grep for broad codebase discovery unless the user explicitly asks for a raw shell command or project_search cannot express the query.",
			"Use project_search to shortlist relevant files and line numbers before reading file contents.",
			"After project_search, the default next step is read_window on the most relevant hits; do not use full-file read unless the file is short or broad context is clearly necessary.",
			"If a read_window snippet is too small, increase before/after or make another targeted read_window call before reading the whole file.",
			"When investigating behavior, search for both definitions and actual usage: call sites, triggers, registration, configuration, conditions, and channels.",
			"Do not infer runtime behavior from builder/helper methods alone; verify the activation path or dispatch path with project_search/read_window.",
			"When checking test coverage or examples, restrict project_search with kind='test' or test-specific globs instead of repeating broad searches.",
			"If project_search returns too much, refine query, kind, or globs instead of dumping raw rg output.",
		],
		parameters: Type.Object({
			query: Type.String({ description: "Regex/text query to search for." }),
			kind: Type.Optional(Type.String({ description: "Optional kind: any, php, test, config, doc, js. Default: any." })),
			globs: Type.Optional(Type.Array(Type.String(), { description: "Additional rg globs, e.g. ['app/**', '*.php']." })),
			maxFiles: Type.Optional(Type.Number({ description: "Maximum files to show. Default: 8, max: 30." })),
			maxMatchesPerFile: Type.Optional(Type.Number({ description: "Maximum matches per file. Default: 3, max: 10." })),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const maxFiles = clamp(params.maxFiles, 8, 1, 30);
			const maxMatchesPerFile = clamp(params.maxMatchesPerFile, 3, 1, 10);
			const args = [
				"--line-number",
				"--column",
				"--hidden",
				"--color", "never",
				"--max-count", String(maxMatchesPerFile),
				...excludeArgsForRg(),
				...globArgs(kindGlobs(params.kind)),
				...globArgs(params.globs),
				...rgPatternArgs(params.query),
				".",
			];

			const result = await pi.exec("rg", args, { cwd: ctx.cwd, signal, timeout: 10_000 });
			if (result.code === 1) {
				return { content: [{ type: "text", text: `No matches for ${JSON.stringify(params.query)}.` }], details: { count: 0 } };
			}
			if (result.code !== 0) {
				return {
					content: [{ type: "text", text: `project_search failed.\n\nCommand: ${formatCommand("rg", args)}\n\n${result.stderr || result.stdout}` }],
					details: { command: "rg", args, code: result.code },
				};
			}

			const grouped = new Map<string, string[]>();
			const firstLines = new Map<string, number>();
			for (const line of normalizeLines(result.stdout)) {
				const match = line.match(/^(.+?):(\d+):(\d+):(.*)$/);
				if (!match) continue;
				const [, file, lineNumber, column, content] = match;
				if (!grouped.has(file) && grouped.size >= maxFiles) continue;
				const entries = grouped.get(file) ?? [];
				if (entries.length >= maxMatchesPerFile) continue;
				const numericLine = Number(lineNumber);
				if (!firstLines.has(file)) firstLines.set(file, numericLine);
				entries.push(`L${lineNumber}:C${column}: ${compactLine(content)}`);
				grouped.set(file, entries);
			}

			if (grouped.size === 0) {
				return { content: [{ type: "text", text: `No parseable matches for ${JSON.stringify(params.query)}.` }], details: { count: 0 } };
			}

			const sections = [`Found matches in ${grouped.size} file(s). Showing up to ${maxMatchesPerFile} match(es) per file.`, ""];
			for (const [file, matches] of grouped) {
				sections.push(`## ${file}`);
				sections.push(...matches.map((match) => `- ${match}`));
				sections.push("");
			}
			sections.push("## Suggested reads");
			for (const [file, line] of [...firstLines.entries()].slice(0, Math.min(5, maxFiles))) {
				sections.push(`- read_window path=${JSON.stringify(file)} line=${line} before=20 after=40`);
			}
			sections.push("");
			sections.push("Next step: use read_window for the most relevant hits, or refine query/globs for a smaller result set.");

			return {
				content: [{ type: "text", text: sections.join("\n") }],
				details: { files: grouped.size, maxFiles, maxMatchesPerFile, suggestedReads: firstLines.size },
			};
		},
	});

	pi.registerTool({
		name: "read_window",
		label: "Read Window",
		description: "Read a compact snippet from a project file around a line number or the first pattern match. Use after project_search instead of reading whole files.",
		promptSnippet: "Read a compact file snippet around a line or pattern",
		promptGuidelines: [
			"Use read_window after project_search to inspect only the relevant part of a file.",
			"Prefer read_window over full-file reads unless the file is short or the entire file is clearly needed.",
			"If the snippet is insufficient, increase before/after or make another targeted read_window call before falling back to full-file read.",
			"Use multiple small read_window calls to connect related definitions and call sites before reading whole files.",
			"When verifying behavior, inspect the nearby conditions, return values, registrations, and dispatch/trigger lines around each match.",
		],
		parameters: Type.Object({
			path: Type.String({ description: "Project-relative file path." }),
			line: Type.Optional(Type.Number({ description: "1-based line number to center the snippet around." })),
			pattern: Type.Optional(Type.String({ description: "Text or regex pattern. If provided without line, reads around the first matching line." })),
			before: Type.Optional(Type.Number({ description: "Lines before the target. Default: 20, max: 80." })),
			after: Type.Optional(Type.Number({ description: "Lines after the target. Default: 40, max: 120." })),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const resolved = resolveProjectPath(ctx.cwd, params.path);
			if (!resolved) {
				return { content: [{ type: "text", text: `Invalid project path: ${params.path}` }], details: { path: params.path, isError: true } };
			}

			let text: string;
			try {
				text = await readFile(resolved, "utf8");
			} catch (error) {
				return { content: [{ type: "text", text: `Could not read ${params.path}: ${error instanceof Error ? error.message : String(error)}` }], details: { path: params.path, isError: true } };
			}

			const lines = text.split("\n");
			let targetLine = params.line ? clamp(params.line, 1, 1, lines.length) : undefined;
			let matchedPattern = false;

			if (!targetLine && params.pattern) {
				let regex: RegExp | undefined;
				try {
					regex = new RegExp(params.pattern);
				} catch {
					regex = undefined;
				}
				const index = lines.findIndex((line) => regex ? regex.test(line) : line.includes(params.pattern!));
				if (index >= 0) {
					targetLine = index + 1;
					matchedPattern = true;
				}
			}

			if (!targetLine) {
				return { content: [{ type: "text", text: params.pattern ? `No match for pattern ${JSON.stringify(params.pattern)} in ${params.path}.` : "Provide either line or pattern." }], details: { path: params.path, isError: true } };
			}

			const before = clamp(params.before, 20, 0, 80);
			const after = clamp(params.after, 40, 0, 120);
			const start = Math.max(1, targetLine - before);
			const end = Math.min(lines.length, targetLine + after);
			const width = String(end).length;
			const snippet = lines.slice(start - 1, end).map((line, index) => {
				const number = start + index;
				const marker = number === targetLine ? ">" : " ";
				return `${marker} ${String(number).padStart(width, " ")}: ${line}`;
			}).join("\n");

			const header = `Read ${params.path}:${start}-${end}${matchedPattern ? ` around pattern ${JSON.stringify(params.pattern)}` : ` around line ${targetLine}`}`;
			return {
				content: [{ type: "text", text: `${header}\n\n\`\`\`\n${snippet}\n\`\`\`` }],
				details: { path: params.path, start, end, targetLine, totalLines: lines.length },
			};
		},
	});
}
