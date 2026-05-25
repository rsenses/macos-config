import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const LANGUAGES = [
	"c",
	"cpp",
	"csharp",
	"css",
	"dart",
	"elixir",
	"go",
	"haskell",
	"html",
	"java",
	"javascript",
	"json",
	"kotlin",
	"lua",
	"php",
	"python",
	"ruby",
	"rust",
	"scala",
	"sql",
	"swift",
	"tsx",
	"typescript",
	"yaml",
] as const;

const MODES = ["pattern", "rule", "inspect", "replace"] as const;
const INSPECT_FORMATS = ["ast", "cst", "pattern", "sexp"] as const;

type Mode = (typeof MODES)[number];
type InspectFormat = (typeof INSPECT_FORMATS)[number];

interface AstGrepParams {
	mode: Mode;
	pattern?: string;
	rule?: string;
	rewrite?: string;
	apply?: boolean;
	lang: string;
	paths?: string[];
	globs?: string[];
	context?: boolean;
	limit?: number;
	inspect_format?: InspectFormat;
}

interface AstGrepMatch {
	file?: string;
	range?: { start?: { line?: number; column?: number }; end?: { line?: number; column?: number } };
	text?: string;
	lines?: string;
	replacement?: string;
	ruleId?: string;
	message?: string;
	severity?: string;
}

interface CommandResult {
	stdout: string;
	stderr: string;
	code: number | null;
	killed?: boolean;
}

function textResult(text: string, details: Record<string, unknown> = {}) {
	return { content: [{ type: "text" as const, text }], details };
}

function requireParam(value: string | undefined, name: string, mode: Mode): string {
	if (!value || value.trim().length === 0) {
		throw new Error(`ast_grep mode '${mode}' requires '${name}'.`);
	}
	return value;
}

function addCommonArgs(args: string[], params: AstGrepParams, options: { includeJson?: boolean; includeMaxResults?: boolean } = {}): void {
	const includeJson = options.includeJson ?? true;
	if (includeJson) args.push("--json=compact");
	for (const glob of params.globs ?? []) {
		args.push("--globs", glob);
	}
	if (params.context) args.push("--context", "2");
	if (options.includeMaxResults && params.limit && Number.isFinite(params.limit) && params.limit > 0) {
		args.push("--max-results", String(Math.floor(params.limit)));
	}
	args.push(...normalizePaths(params.paths));
}

function normalizePaths(paths: string[] | undefined): string[] {
	const normalized = (paths ?? [])
		.map((path) => path.trim())
		.filter((path) => path.length > 0)
		.map((path) => (path.startsWith("@") ? path.slice(1) : path));
	return normalized.length > 0 ? normalized : ["."];
}

function parseJsonMatches(stdout: string): AstGrepMatch[] {
	if (!stdout.trim()) return [];
	const parsed = JSON.parse(stdout) as unknown;
	if (Array.isArray(parsed)) return parsed as AstGrepMatch[];
	return [parsed as AstGrepMatch];
}

function lineNumber(line: number | undefined): number {
	return typeof line === "number" ? line + 1 : 1;
}

function columnNumber(column: number | undefined): number {
	return typeof column === "number" ? column + 1 : 1;
}

function truncateOneLine(text: string, max = 160): string {
	const oneLine = text.replace(/\s+/g, " ").trim();
	return oneLine.length > max ? `${oneLine.slice(0, max)}...` : oneLine;
}

function formatMatches(matches: AstGrepMatch[], options: { dryRunReplace?: boolean; applied?: boolean; limit?: number } = {}): string {
	if (matches.length === 0) return "No matches found";

	const limit = options.limit && options.limit > 0 ? options.limit : 100;
	const shown = matches.slice(0, limit);
	const lines: string[] = [];

	if (matches.length > shown.length) {
		lines.push(`Found ${matches.length} matches (showing first ${shown.length}):`);
	}

	for (const match of shown) {
		const loc = `${match.file ?? "<unknown>"}:${lineNumber(match.range?.start?.line)}:${columnNumber(match.range?.start?.column)}`;
		const label = match.ruleId ? ` [${match.ruleId}${match.severity ? `/${match.severity}` : ""}]` : "";
		const message = match.message ? ` ${match.message}` : "";
		const text = truncateOneLine(match.text ?? match.lines ?? "");

		if ((options.dryRunReplace || options.applied) && match.replacement !== undefined) {
			lines.push(`${loc}${label}${message}\n  - ${text}\n  + ${truncateOneLine(match.replacement)}`);
		} else {
			lines.push(`${loc}${label}${message}: ${text}`);
		}
	}

	if (options.dryRunReplace) {
		lines.push("", "Dry run only. Pass apply=true to modify files.");
	}

	if (options.applied) {
		lines.unshift(`Applied ${matches.length} replacement${matches.length === 1 ? "" : "s"}:`);
	}

	return lines.join("\n");
}

function indentYamlBody(body: string): string {
	return body
		.replace(/\r\n/g, "\n")
		.split("\n")
		.map((line) => (line.trim().length === 0 ? "" : `  ${line}`))
		.join("\n");
}

async function runSg(pi: ExtensionAPI, args: string[], signal?: AbortSignal): Promise<CommandResult> {
	try {
		return await pi.exec("sg", args, { signal, timeout: 60_000 });
	} catch (error) {
		const message = error instanceof Error ? error.message : String(error);
		if (message.includes("ENOENT") || message.includes("not found")) {
			throw new Error("ast-grep CLI not found. Install it with: npm i -g @ast-grep/cli");
		}
		throw error;
	}
}

function assertSuccess(result: CommandResult): void {
	if (result.code !== 0 && !result.stdout.trim()) {
		const stderr = result.stderr.trim();
		throw new Error(stderr || `sg exited with code ${result.code}`);
	}
}

async function runPattern(pi: ExtensionAPI, params: AstGrepParams, signal?: AbortSignal) {
	const pattern = requireParam(params.pattern, "pattern", params.mode);
	const args = ["run", "--pattern", pattern, "--lang", params.lang];
	addCommonArgs(args, params);
	const result = await runSg(pi, args, signal);
	assertSuccess(result);
	const matches = parseJsonMatches(result.stdout);
	return textResult(formatMatches(matches, { limit: params.limit }), { mode: params.mode, matchCount: matches.length });
}

async function runReplace(pi: ExtensionAPI, params: AstGrepParams, signal?: AbortSignal) {
	const pattern = requireParam(params.pattern, "pattern", params.mode);
	const rewrite = requireParam(params.rewrite, "rewrite", params.mode);
	const args = ["run", "--pattern", pattern, "--rewrite", rewrite, "--lang", params.lang, "--json=compact"];
	for (const glob of params.globs ?? []) args.push("--globs", glob);
	if (params.context) args.push("--context", "2");
	if (params.apply) args.push("--update-all");
	args.push(...normalizePaths(params.paths));

	const result = await runSg(pi, args, signal);
	assertSuccess(result);
	const matches = parseJsonMatches(result.stdout);
	return textResult(formatMatches(matches, { dryRunReplace: !params.apply, applied: params.apply, limit: params.limit }), {
		mode: params.mode,
		matchCount: matches.length,
		applied: Boolean(params.apply),
	});
}

async function runRule(pi: ExtensionAPI, params: AstGrepParams, signal?: AbortSignal) {
	const rule = requireParam(params.rule, "rule", params.mode);
	const dir = await mkdtemp(join(tmpdir(), "pi-ast-grep-"));
	const rulePath = join(dir, "rule.yml");
	const ruleFile = `id: pi-ast-grep-rule\nlanguage: ${params.lang}\nmessage: ast-grep rule matched\nseverity: info\nrule:\n${indentYamlBody(rule)}\n`;

	try {
		await writeFile(rulePath, ruleFile, "utf8");
		const args = ["scan", "--rule", rulePath];
		addCommonArgs(args, params, { includeMaxResults: true });
		const result = await runSg(pi, args, signal);
		assertSuccess(result);
		const matches = parseJsonMatches(result.stdout);
		return textResult(formatMatches(matches, { limit: params.limit }), { mode: params.mode, matchCount: matches.length });
	} finally {
		await rm(dir, { recursive: true, force: true });
	}
}

async function runInspect(pi: ExtensionAPI, params: AstGrepParams, signal?: AbortSignal) {
	const pattern = requireParam(params.pattern, "pattern", params.mode);
	const format = params.inspect_format ?? "ast";
	const args = ["run", "--pattern", pattern, "--lang", params.lang, `--debug-query=${format}`];
	const result = await runSg(pi, args, signal);
	assertSuccess(result);
	const output = [result.stdout.trim(), result.stderr.trim()].filter(Boolean).join("\n");
	return textResult(output || "No inspect output", { mode: params.mode, inspectFormat: format });
}

export default function astGrepExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "ast_grep",
		label: "ast_grep",
		description:
			"Search, inspect, and replace code using ast-grep. Modes: pattern (simple AST pattern search), rule (YAML rule body wrapped by this tool), inspect (debug AST/CST/pattern structure), replace (AST-aware rewrite; dry-run by default, apply=true modifies files). Requires the sg CLI.",
		promptSnippet: "Search, inspect, or rewrite code with ast-grep AST patterns and YAML rules.",
		promptGuidelines: [
			"Use ast_grep mode='pattern' for quick syntax-aware searches such as console.log($MSG) or async function $NAME($$$) { $$$ }.",
			"Use ast_grep mode='rule' for relational/composite searches; pass only the YAML body under rule, not a full rule file wrapper.",
			"Use ast_grep mode='inspect' to debug node kinds and pattern parsing before writing complex rules.",
			"Use ast_grep mode='replace' for AST-aware rewrites; it is a dry run unless apply=true is explicitly set.",
			"For ast_grep YAML rules with has or inside, include stopBy: end when searching the full subtree.",
		],
		parameters: Type.Object({
			mode: Type.Union(MODES.map((mode) => Type.Literal(mode)), {
				description: "Search mode: pattern, rule, inspect, or replace.",
			}),
			pattern: Type.Optional(
				Type.String({
					description: "AST pattern to search/inspect/replace. Use $VAR for one node and $$$VAR for multiple nodes.",
				}),
			),
			rule: Type.Optional(
				Type.String({
					description: "YAML rule body for mode='rule'. Pass only what goes under rule:, e.g. 'kind: function_declaration\nhas:\n  pattern: await $EXPR\n  stopBy: end'.",
				}),
			),
			rewrite: Type.Optional(
				Type.String({
					description: "Replacement pattern for mode='replace', e.g. logger.info($MSG).",
				}),
			),
			apply: Type.Optional(
				Type.Boolean({
					description: "Apply replacements for mode='replace'. Default false means dry-run only.",
				}),
			),
			lang: Type.Union(LANGUAGES.map((lang) => Type.Literal(lang)), {
				description: "Target language. Required by sg for reliable pattern parsing.",
			}),
			paths: Type.Optional(Type.Array(Type.String(), { description: "Files or directories to search. Defaults to ['.']." })),
			globs: Type.Optional(
				Type.Array(Type.String(), {
					description: "Include/exclude globs passed to sg --globs. Prefix with ! to exclude.",
				}),
			),
			context: Type.Optional(Type.Boolean({ description: "Show two context lines around matches when sg supports it." })),
			limit: Type.Optional(Type.Number({ description: "Maximum results to request/show." })),
			inspect_format: Type.Optional(
				Type.Union(INSPECT_FORMATS.map((format) => Type.Literal(format)), {
					description: "Inspect output format for mode='inspect': ast, cst, pattern, or sexp.",
				}),
			),
		}),
		async execute(_toolCallId, params, signal) {
			const input = params as AstGrepParams;
			switch (input.mode) {
				case "pattern":
					return runPattern(pi, input, signal);
				case "replace":
					return runReplace(pi, input, signal);
				case "rule":
					return runRule(pi, input, signal);
				case "inspect":
					return runInspect(pi, input, signal);
				default:
					throw new Error(`Unknown ast_grep mode: ${(input as { mode?: string }).mode}`);
			}
		},
	});
}
