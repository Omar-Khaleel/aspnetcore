# Attack surface and prioritized review notes

| Surface | Attacker-controlled source | Boundary | Sinks/assets | Coverage status |
| --- | --- | --- | --- | --- |
| HTTP routing/endpoints | URL path, method, host, metadata conventions | unauthenticated/authenticated client -> endpoint authority | endpoint dispatch, metadata, auth policies | Manually sampled with source searches; no reportable candidate. |
| Static assets/file providers | request path; developer/build manifest | web client -> file provider/content root | file reads, response headers, compressed variants | Manually reviewed manifest path and provider lookup; candidate rejected. |
| Authentication/authorization packages | cookies, bearer tokens, OIDC/OAuth callbacks, certs | external identity provider/client -> ASP.NET Core principal | authentication ticket, claims, challenges | Mapped as high priority; not dynamically validated due missing IdP/principals. |
| Kestrel/HttpSys/IIS servers | network frames, headers, TLS state, native server features | remote client/native host -> managed request features | parser state, request body, TLS cert, availability | Mapped; dynamic parser/fuzz testing deferred. |
| SignalR | WebSocket/SSE/LongPolling frames, hub payloads | remote client -> hub method dispatch | method invocation, connection/user state | Mapped; dynamic hub validation deferred. |
| MVC/Razor/Components | forms, JSON, route data, component params, browser events | client/browser -> model/render/server circuit | model binding, rendering, antiforgery, circuit state | Mapped; broad surface not exhaustively reviewed. |
| DataProtection/caching | key store config, protected payloads, cache keys | app/user/tenant -> keys/cache records | crypto keys, protected data, cache isolation | Mapped; no local key-store environment tested. |
| CI/build/tooling | PR code, scripts, archives, package metadata | contributor -> build/release authority | secrets, artifacts, signing, package publish | Lead searches only; protected CI proof unavailable. |

## Commands and searches performed

- Inventory generation with `repo_inventory.py`.
- Read `SECURITY.md` and representative README/build metadata.
- Targeted search for dangerous APIs and security-relevant terms: process execution, dynamic assembly loading, archive extraction, file providers, path joins, authorization metadata, dangerous options, TODO/security markers.
- Manual source reads for static asset manifest resolution and manifest-backed file provider behavior.

## Resumed authentication-handler review

| Surface | Attacker-controlled source | Boundary | Sinks/assets | Coverage status |
| --- | --- | --- | --- | --- |
| OAuth callback state/correlation | callback `state`, `code`, `error` query parameters | unauthenticated callback request -> application sign-in authority | `AuthenticationTicket`, claims principal, saved tokens | Source-traced; CAND-003 rejected because protected state and correlation cookie validation occur before ticket creation. |
| OpenID Connect callback state/nonce | callback query/form parameters, authorization code, ID token nonce | unauthenticated callback/token response -> application sign-in authority | validated token, principal, auth properties | Source-traced; CAND-003 rejected because missing/invalid state fails before correlation validation and nonce is passed to protocol validation. |
