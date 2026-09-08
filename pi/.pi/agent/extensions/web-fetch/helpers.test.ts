import test from "node:test";
import assert from "node:assert/strict";
import {
  BodyLimitError,
  FetchAbortError,
  FetchTimeoutError,
  SessionCache,
  isJinaSafeUrl,
  publicCacheKey,
  readResponseBody,
  responseCacheKey,
  sliceOutput,
  withTimeout,
} from "./helpers.ts";

test("readResponseBody enforces the streamed byte limit", async () => {
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(new TextEncoder().encode("1234"));
      controller.enqueue(new TextEncoder().encode("5678"));
      controller.close();
    },
  });

  await assert.rejects(
    readResponseBody(body, 6),
    (error: unknown) => error instanceof BodyLimitError && error.bytes === 8,
  );
});

test("sliceOutput is Unicode-safe and bounded by characters and lines", () => {
  const result = sliceOutput("😀a\nβc\nlast", {
    offset: 0,
    maxChars: 20,
    maxLines: 2,
  });

  assert.equal(result.text, "😀a\nβc");
  assert.equal(result.chars, 5);
  assert.equal(result.totalChars, 10);
  assert.equal(result.nextOffset, 5);

  const middle = sliceOutput("😀abc", { offset: 1, maxChars: 2, maxLines: 10 });
  assert.equal(middle.text, "ab");
  assert.equal([...middle.text].length, 2);
});

test("sliceOutput advances when a line-limited window starts at a newline", () => {
  const first = sliceOutput("one\ntwo", { offset: 3, maxChars: 20, maxLines: 1 });
  assert.equal(first.text, "\n");
  assert.equal(first.nextOffset, 4);

  const second = sliceOutput("one\ntwo", { offset: first.nextOffset, maxChars: 20, maxLines: 1 });
  assert.equal(second.text, "two");
  assert.equal(second.nextOffset, undefined);
});

test("readResponseBody cancels a pending reader.read on caller abort", async () => {
  const controller = new AbortController();
  let cancelled = false;
  const body = new ReadableStream<Uint8Array>({
    pull() {
      return new Promise<void>(() => {});
    },
    cancel() {
      cancelled = true;
    },
  });
  const pending = readResponseBody(body, 100, controller.signal);
  controller.abort();
  await assert.rejects(
    Promise.race([
      pending,
      new Promise<never>((_, reject) => setTimeout(() => reject(new Error("still pending")), 100)),
    ]),
    (error: unknown) => error instanceof FetchAbortError,
  );
  assert.equal(cancelled, true);
});

test("withTimeout settles even when extraction ignores cooperative abort", async () => {
  const result = withTimeout(1, undefined, async () => new Promise<string>(() => {}));
  await assert.rejects(result, (error: unknown) => error instanceof FetchTimeoutError);
});

test("cache policy omits ambiguous or credential-bearing URLs", () => {
  assert.equal(publicCacheKey("https://example.test/docs"), "https://example.test/docs");
  assert.equal(publicCacheKey("https://example.test/docs?token=secret"), null);
  assert.equal(publicCacheKey("https://user:pass@example.test/docs"), null);
  assert.equal(publicCacheKey("http://127.0.0.1/private"), null);
});

test("response cache policy rejects redirects, private directives, cookies, and final private URLs", () => {
  const base = { url: "https://example.test/docs", redirected: false };
  const headers = (values: Record<string, string>) => new Headers(values);
  assert.equal(responseCacheKey("https://example.test/docs", { ...base, headers: headers({}) }), "https://example.test/docs");
  assert.equal(responseCacheKey("https://example.test/docs", { ...base, headers: headers({ "cache-control": "no-store" }) }), null);
  assert.equal(responseCacheKey("https://example.test/docs", { ...base, headers: headers({ "cache-control": "private" }) }), null);
  assert.equal(responseCacheKey("https://example.test/docs", { ...base, headers: headers({ "set-cookie": "sid=secret" }) }), null);
  assert.equal(responseCacheKey("https://example.test/docs", { ...base, url: "https://other.test/docs", headers: headers({}) }), null);
  assert.equal(responseCacheKey("https://example.test/docs", { ...base, redirected: true, headers: headers({}) }), null);
});

test("Jina fallback only accepts clearly public URLs", () => {
  assert.equal(isJinaSafeUrl("https://example.test/docs"), true);
  assert.equal(isJinaSafeUrl("https://example.test/docs?token=secret"), false);
  assert.equal(isJinaSafeUrl("http://127.0.0.1/docs"), false);
  assert.equal(isJinaSafeUrl("https://internal.example.com/docs"), false);
});

test("SessionCache expires entries and remains small", () => {
  const now = Date.now();
  const cache = new SessionCache<string>({
    ttlMs: 100,
    maxEntries: 2,
    maxSize: 5,
    sizeOf: (value) => value.length,
  });

  assert.equal(cache.set("a", "123", now), true);
  assert.equal(cache.get("a", now + 99), "123");
  assert.equal(cache.get("a", now + 101), undefined);
  cache.set("b", "12", now);
  cache.set("c", "34", now);
  cache.set("d", "56", now);
  assert.equal(cache.size, 2);
  assert.equal(cache.set("too-big", "123456", now), false);
});
