export class BodyLimitError extends Error {
	readonly limit: number;
	readonly bytes: number;

	constructor(limit: number, bytes: number) {
		super(`Response body exceeded ${limit} bytes`);
		this.name = "BodyLimitError";
		this.limit = limit;
		this.bytes = bytes;
	}
}

export class FetchAbortError extends Error {
	constructor() {
		super("Aborted");
		this.name = "FetchAbortError";
	}
}

export class FetchTimeoutError extends Error {
	readonly timeoutMs: number;

	constructor(timeoutMs: number) {
		super(`Timed out after ${timeoutMs}ms`);
		this.name = "FetchTimeoutError";
		this.timeoutMs = timeoutMs;
	}
}

/** Read a response body while enforcing a byte limit on the actual stream. */
function cancelReader(reader: ReadableStreamDefaultReader<Uint8Array>): void {
	try {
		// Do not await cancellation: a broken transport must not keep an aborted
		// extraction pending after reader.read() has been interrupted.
		void reader.cancel().catch(() => undefined);
	} catch {
		// The transport may already have cancelled the body.
	}
}

async function readWithSignal(
	reader: ReadableStreamDefaultReader<Uint8Array>,
	signal?: AbortSignal,
): Promise<ReadableStreamReadResult<Uint8Array>> {
	if (!signal) return reader.read();
	if (signal.aborted) throw new FetchAbortError();

	let rejectAbort!: (reason: FetchAbortError) => void;
	const aborted = new Promise<ReadableStreamReadResult<Uint8Array>>((_, reject) => {
		rejectAbort = reject;
	});
	const onAbort = () => {
		rejectAbort(new FetchAbortError());
		cancelReader(reader);
	};
	signal.addEventListener("abort", onAbort, { once: true });
	if (signal.aborted) onAbort();
	try {
		return await Promise.race([reader.read(), aborted]);
	} finally {
		signal.removeEventListener("abort", onAbort);
	}
}

export async function readResponseBody(
	body: ReadableStream<Uint8Array> | null,
	maxBytes: number,
	signal?: AbortSignal,
): Promise<Uint8Array> {
	if (maxBytes < 0 || !Number.isFinite(maxBytes)) {
		throw new RangeError("maxBytes must be a non-negative finite number");
	}
	if (!body) return new Uint8Array();

	const reader = body.getReader();
	const chunks: Uint8Array[] = [];
	let total = 0;
	let completed = false;
	try {
		while (true) {
			if (signal?.aborted) throw new FetchAbortError();
			const next = await readWithSignal(reader, signal);
			if (next.done) {
				completed = true;
				break;
			}
			const chunk = next.value;
			if (!chunk) continue;
			total += chunk.byteLength;
			if (total > maxBytes) throw new BodyLimitError(maxBytes, total);
			chunks.push(chunk);
		}
	} catch (error) {
		if (signal?.aborted && !(error instanceof BodyLimitError)) {
			throw new FetchAbortError();
		}
		throw error;
	} finally {
		if (!completed) cancelReader(reader);
		try {
			reader.releaseLock();
		} catch {
			// A cancelled stream can already have released its reader.
		}
	}

	const result = new Uint8Array(total);
	let offset = 0;
	for (const chunk of chunks) {
		result.set(chunk, offset);
		offset += chunk.byteLength;
	}
	return result;
}

/** Run one network/extraction operation with the same timeout and cancellation semantics. */
export async function withTimeout<T>(
	timeoutMs: number,
	parentSignal: AbortSignal | undefined,
	operation: (signal: AbortSignal) => Promise<T>,
): Promise<T> {
	if (parentSignal?.aborted) throw new FetchAbortError();

	const controller = new AbortController();
	let timedOut = false;
	let rejectTimeout!: (reason: FetchTimeoutError) => void;
	const timeout = new Promise<T>((_, reject) => {
		rejectTimeout = reject;
	});
	const timer = setTimeout(() => {
		timedOut = true;
		controller.abort();
		rejectTimeout(new FetchTimeoutError(timeoutMs));
	}, timeoutMs);

	let rejectParent!: (reason: FetchAbortError) => void;
	const parentAborted = new Promise<T>((_, reject) => {
		rejectParent = reject;
	});
	const onParentAbort = () => {
		controller.abort();
		rejectParent(new FetchAbortError());
	};
	parentSignal?.addEventListener("abort", onParentAbort, { once: true });
	if (parentSignal?.aborted) onParentAbort();

	// Promise.race observes the operation even when timeout/abort wins, so a
	// later rejection from a cooperative operation is not left unhandled.
	const pendingOperation = Promise.resolve().then(() => operation(controller.signal));
	try {
		return await Promise.race([pendingOperation, timeout, parentAborted]);
	} catch (error) {
		if (parentSignal?.aborted) throw new FetchAbortError();
		if (timedOut) throw new FetchTimeoutError(timeoutMs);
		throw error;
	} finally {
		clearTimeout(timer);
		parentSignal?.removeEventListener("abort", onParentAbort);
	}
}

export interface OutputWindowOptions {
	offset?: number;
	maxChars: number;
	maxLines: number;
}

export interface OutputWindow {
	text: string;
	offset: number;
	chars: number;
	totalChars: number;
	totalLines: number;
	truncated: boolean;
	nextOffset?: number;
}

/** Slice by Unicode code points, then cap lines, without splitting surrogate pairs. */
export function sliceOutput(text: string, options: OutputWindowOptions): OutputWindow {
	const codePoints = Array.from(text);
	const offset = Math.min(Math.max(0, Math.floor(options.offset ?? 0)), codePoints.length);
	const maxChars = Math.max(1, Math.floor(options.maxChars));
	const maxLines = Math.max(1, Math.floor(options.maxLines));
	let end = Math.min(codePoints.length, offset + maxChars);
	let output = codePoints.slice(offset, end).join("");
	const lines = output.split("\n");
	if (lines.length > maxLines) {
		output = lines.slice(0, maxLines).join("\n");
		end = offset + Array.from(output).length;
		// A window beginning at a newline otherwise yields an empty string and
		// repeats the same offset forever when callers request continuations.
		if (end === offset && offset < codePoints.length) {
			output = codePoints[offset];
			end = offset + 1;
		}
	}

	const totalLines = text.length === 0 ? 0 : text.split("\n").length;
	const truncated = end < codePoints.length;
	return {
		text: output,
		offset,
		chars: Array.from(output).length,
		totalChars: codePoints.length,
		totalLines,
		truncated,
		...(truncated ? { nextOffset: end } : {}),
	};
}

export interface CacheOptions<T> {
	ttlMs: number;
	maxEntries: number;
	maxSize: number;
	sizeOf?: (value: T) => number;
}

interface CacheEntry<T> {
	value: T;
	expiresAt: number;
	lastUsed: number;
	size: number;
}

/** Small in-memory session cache; callers decide which keys are safe to cache. */
export class SessionCache<T> {
	private readonly entries = new Map<string, CacheEntry<T>>();
	private readonly sizeOf: (value: T) => number;
	private readonly options: CacheOptions<T>;
	private totalSize = 0;

	constructor(options: CacheOptions<T>) {
		this.options = options;
		this.sizeOf = options.sizeOf ?? (() => 1);
	}

	get(key: string, now = Date.now()): T | undefined {
		const entry = this.entries.get(key);
		if (!entry) return undefined;
		if (entry.expiresAt <= now) {
			this.delete(key);
			return undefined;
		}
		entry.lastUsed = now;
		return entry.value;
	}

	set(key: string, value: T, now = Date.now()): boolean {
		const size = this.sizeOf(value);
		if (size > this.options.maxSize || this.options.maxEntries < 1) return false;
		this.delete(key);
		this.entries.set(key, {
			value,
			size,
			expiresAt: now + this.options.ttlMs,
			lastUsed: now,
		});
		this.totalSize += size;
		this.evict();
		return this.entries.has(key);
	}

	delete(key: string): void {
		const entry = this.entries.get(key);
		if (!entry) return;
		this.totalSize -= entry.size;
		this.entries.delete(key);
	}

	clear(): void {
		this.entries.clear();
		this.totalSize = 0;
	}

	get size(): number {
		return this.entries.size;
	}

	private evict(): void {
		for (const [key, entry] of this.entries) {
			if (entry.expiresAt <= Date.now()) this.delete(key);
		}
		while (this.entries.size > this.options.maxEntries || this.totalSize > this.options.maxSize) {
			const oldest = [...this.entries.entries()].sort((a, b) => a[1].lastUsed - b[1].lastUsed)[0];
			if (!oldest) break;
			this.delete(oldest[0]);
		}
	}
}

/** Conservative policy: only cache clearly public, query-free URLs. */
export function publicCacheKey(rawUrl: string): string | null {
	try {
		const url = new URL(rawUrl);
		if (url.protocol !== "http:" && url.protocol !== "https:") return null;
		if (url.username || url.password || url.search || url.port || url.hostname.includes(":")) return null;
		const host = url.hostname.toLowerCase();
		if (
			host === "localhost" ||
			host.endsWith(".local") ||
			/^(127\.|10\.|192\.168\.|169\.254\.)/.test(host) ||
			/^172\.(1[6-9]|2\d|3[01])\./.test(host) ||
			/\b(auth|login|account|session|token|secret|private)\b/i.test(url.pathname)
		) return null;
		url.hash = "";
		return url.toString();
	} catch {
		return null;
	}
}

/** Return a cache key only when the final response is safe to reuse. */
export function responseCacheKey(
	requestedUrl: string,
	response: {
		url?: string;
		redirected?: boolean;
		headers: Pick<Headers, "get" | "has">;
	},
): string | null {
	if (response.redirected) return null;
	try {
		const requested = new URL(requestedUrl);
		const final = new URL(response.url || requestedUrl);
		requested.hash = "";
		final.hash = "";
		if (requested.toString() !== final.toString()) return null;
	} catch {
		return null;
	}

	const directives = (response.headers.get("cache-control") || "")
		.toLowerCase()
		.split(",")
		.map((directive) => directive.trim().split("=", 1)[0]);
	if (directives.some((directive) => directive === "no-store" || directive === "private" || directive === "no-cache")) return null;
	if (response.headers.has("set-cookie")) return null;
	return publicCacheKey(response.url || requestedUrl);
}

/** Jina is an external relay; only send URLs that are clearly public. */
export function isJinaSafeUrl(rawUrl: string): boolean {
	const cacheKey = publicCacheKey(rawUrl);
	if (!cacheKey) return false;
	try {
		const url = new URL(rawUrl);
		const host = url.hostname.toLowerCase();
		if (url.hash || !host.includes(".") || /^\d+(?:\.\d+){3}$/.test(host) || host.includes(":")) return false;
		if (/(^|[.-])(localhost|local|internal|intranet|corp|lan|home|private|auth|login|account|session|token|secret)([.-]|$)/i.test(host)) return false;
		return true;
	} catch {
		return false;
	}
}
