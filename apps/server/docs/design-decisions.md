# Server Design Decisions

> App-specific decisions for `apps/server`.
> Cross-cutting decisions (affecting **both** server and client) live in [`/docs/design-decisions.md`](../../../docs/design-decisions.md).

---

| Date       | What                                          | Why                                                                                                                              | Rejected                              |
| ---------- | --------------------------------------------- |----------------------------------------------------------------------------------------------------------------------------------|---------------------------------------|
| 2026-06-17 | Read-only `.rfw` endpoint, no user-data API   | Sub-RQ 3 measures render overhead; network in the hot-path would distort it                                                      | submit/current endpoints             |
| 2026-06-17 | `shelf` as HTTP framework                     | Standard Dart server lib, well documented; enough for the endpoint, just need a simple server that serves the rfw file over http | `dart_frog`, etc.                     |
| 2026-06-20 | Explicit `content-type: application/octet-stream` on `.rfw` responses | RFW-Binary is no text; tells clients and caches it's a generic binary blob (MDN MIME-Types: "application/octet-stream … denotes a generic binary file") | shelf default `text/plain; charset=utf-8` — clients would try to render binary as text → garbled output |
| 2026-06-20 (rev. 2026-06-21) | Fetch-once architecture: full workflow library loaded on workflow entry, all step transitions stay client-side | Demo order-workflow is data-collection (no per-step backend logic), so per-step server-driven adds no value here. A is a valid SDUI slice (UI delivered from server at runtime). Deployment time still holds (deployment-time = `.rfwtxt` edit). | The practice partner's hybrid pattern (cached library plus a per-step activity id fetched over GraphQL) — adds value only when a workflow carries real per-step backend logic; the demo workflow does not. Treated as future work. |
| 2026-06-21 | Re-parse + re-encode + re-hash per request (no in-memory cache) | Sub-RQ 2 demo requires `.rfwtxt` edits to take effect without server restart; in-memory cache would either show stale layouts or require file-watcher invalidation. Low request volume (Bachelor demo) makes the CPU overhead irrelevant. | In-memory cache with file-watcher invalidation — production-grade optimization, out of Bachelor scope; would risk Sub-RQ 2 demo correctness if invalidation has bugs |