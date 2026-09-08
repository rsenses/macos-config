# web_fetch

Local Pi extension for bounded HTML/PDF/text retrieval. Install dependencies with `npm ci --ignore-scripts` in this directory.

```json
{"url":"https://example.org/docs","limit":6000}
```

- `offset`: zero-based Unicode code-point offset, default 0.
- `limit` / `maxChars`: returned characters (default 12,000; maximum 40,000).
- `maxLines`: returned lines (default 200; maximum 1,000).
- `artifact`: a previously returned artifact for the same URL and extension instance; recovers content without a network call.
- `refresh`: bypass cache/artifact and fetch again.

Truncated results include the next offset and full artifact path. Use both for recovery. Artifacts are immutable files in a private per-instance temporary directory; they survive for recovery until system/user cleanup. They are not a shared cross-project cache.

Actual streamed bodies are limited to 5 MiB (HTML/text/Jina) or 20 MiB (PDF). Network/extraction operations have a 30-second cooperative timeout. A synchronous CPU-bound parser cannot be preempted by a JavaScript timer. PDF extraction is limited to 100 pages.

A small in-process public-URL cache uses a 5-minute TTL, at most six entries and a total character budget. Query strings, credentials, private/local hosts, sensitive paths, redirected responses, Set-Cookie and private/no-cache/no-store responses are not cached. This conservative URL policy is not an SSRF sandbox or a guarantee that any arbitrary URL contains no sensitive data.

Readability 0.6.0 fixes the regex denial-of-service advisory affecting the prior version. HTML, RSC and PDF extraction remain supported. Jina fallback is an external relay, used only for URLs passing a conservative public-URL gate; its results are not URL-cached. Do not provide confidential URLs expecting an isolated browser.

Tests without network:

```sh
node --experimental-strip-types --test helpers.test.ts
```

The sibling subagents integration test also exercises actual loading, HTML extraction, bounded text, cache/refresh and immutable artifact recovery using a stubbed fetch.
