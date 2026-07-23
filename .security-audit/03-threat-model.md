# Repository-specific threat model

## Assets

- Confidentiality/integrity of users' HTTP requests, responses, headers, cookies, authentication tickets, tokens, and claims.
- Authorization boundaries between anonymous, authenticated, role/claim-restricted, user-owned, tenant-owned, and app-owned resources.
- Filesystem boundaries for static files, content roots, temporary files, uploads, archives, and generated assets.
- Parser and protocol availability/integrity for HTTP/1, HTTP/2, HTTP/3, WebSockets, SignalR JSON/MessagePack, form parsing, and routing.
- Cryptographic key material and protected payloads in Data Protection and authentication.
- CI/release/package authority, signing state, build artifacts, and installer outputs.

## Realistic attackers

- Unauthenticated remote client sending HTTP requests or protocol frames to an ASP.NET Core app.
- Authenticated low-privilege user attempting object/function authorization bypass in framework-mediated flows.
- Malicious tenant or application contributor influencing configuration, manifests, static assets, routes, component parameters, or build inputs.
- Malicious package/repository contributor attempting CI or build/release authority escalation.
- Local low-integrity user interacting with dev tools, temp files, installers, or local hosted services.

## Testable invariants

1. An endpoint marked as requiring authorization must not be reachable through a sibling route or metadata path that loses the authorization requirement.
2. A path accepted as inside a web/content root must resolve to the intended file provider root at the time it is opened or served.
3. Build/development manifests must not let untrusted web input select arbitrary local files; manifest and content roots are developer/build authority.
4. Authentication handlers must bind issuer, audience, nonce/correlation, callback path, scheme, and claims to the intended workflow before issuing an identity.
5. SignalR and component browser-origin inputs must not invoke higher-authority server behavior without connection/session/user binding.
6. CI workflows must not run untrusted fork code with secrets, signing, release, or protected write authority.

## Ranked hypotheses reviewed in this run

| ID | Hypothesis | Priority | Strongest rejection |
| --- | --- | ---: | --- |
| H1 | Static asset manifest path/content root confusion could expose files outside intended web root. | 72 | Manifest selection is application/developer controlled, build-time trusted, and `IFileProvider` enforces root semantics; no lower-trust web input controls manifest path in default serving. |
| H2 | Route/endpoint authorization metadata may be lost through static asset or routing conventions. | 64 | Static asset endpoints are application-registered assets, not object-owned resources; no concrete bypass path found without app-specific misconfiguration. |
| H3 | Remote authentication handlers could accept mismatched state/nonce/scheme in callback flows. | 60 | Requires per-handler deep validation and controlled IdP/callback environment; no local proof gathered in this run. |
| H4 | SignalR protocol/parser input could cause denial of service or method authorization confusion. | 56 | Needs targeted dynamic tests/fuzzing and controlled hub app; no candidate survived evidence gates here. |
| H5 | CI scripts that extract archives or execute tools could permit supply-chain authority escalation. | 52 | Requires controlled CI/fork/runner proof and review of protected workflow permissions; environment unavailable. |

No hypothesis was promoted to reportable vulnerability in this run.

## Resumed hypothesis result

| ID | Hypothesis | Result | Strongest rejection |
| --- | --- | --- | --- |
| H3 / CAND-003 | Remote authentication callback state/nonce confusion could allow forged or replayed login callbacks. | Rejected in source-trace validation. | OAuth and OIDC callback paths unprotect state, require correlation validation, and OIDC propagates nonce to protocol validators before accepting the sign-in path; no forged/replayed callback impact was reproduced. |
