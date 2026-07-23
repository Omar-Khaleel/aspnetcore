# Attack-surface catalog

Use this as a coverage checklist, not a claim generator.

## Identity and authorization

- authentication bypass, session binding, token audience/issuer/tenant confusion;
- object-level and function-level authorization;
- role/claim mapping, default identity selection, service-account fallback;
- confused deputy and ambient authority;
- cross-user, cross-tenant, cross-subscription, or cross-project actions;
- OAuth redirects, PKCE/state/nonce, device flows, webhook signatures.

## Input and execution

- command/shell/process execution;
- template, expression, query, or script injection;
- unsafe deserialization and parser differentials;
- SSRF, URL parsing, proxy bypass, DNS rebinding assumptions;
- path traversal, archive extraction, symlink/hardlink, canonicalization, TOCTOU;
- file overwrite, permission inheritance, temporary-file races.

## Memory and concurrency

- bounds errors, use-after-free, uninitialized reads, integer overflow;
- lifetime and ownership errors across FFI;
- races, double fetch, lock-order issues, check/use gaps;
- resource exhaustion with realistic remote or privilege boundary.

## Isolation boundaries

- sandbox/container/namespace escapes;
- plugin/add-in/extension trust boundaries;
- IPC/RPC peer authentication and message origin;
- browser origin, postMessage, CORS, CSP, WebView, deep links;
- local privileged service or daemon interfaces.

## Supply chain and build

- CI pull-request trust, workflow token permissions, artifact substitution;
- untrusted checkout/build scripts and path hijacking;
- dependency confusion, package-source precedence, lockfile bypass;
- release signing, provenance, update channels, rollback/downgrade;
- generated code, codegen plugins, compiler/linker flags;
- cache poisoning and cross-job/cross-tenant cache reuse.

## Data protection and crypto

- secret storage/logging/error disclosure;
- key selection, algorithm downgrade, nonce/IV reuse;
- signature verification confusion and canonicalization;
- encryption without authenticity, weak KDF parameters;
- sensitive data in telemetry, crash dumps, caches, or artifacts.

## State machines and business logic

- skipped or repeated workflow states;
- replay, idempotency, duplicate processing;
- stale authorization after rename/delete/recreate;
- partial failure and rollback inconsistency;
- quota, billing, balance, ownership, invitation, or approval bypass;
- cache/session invalidation and revocation gaps.

## Deployment and configuration

- insecure defaults and first-run behavior;
- debug/admin endpoints reachable in production;
- trust-on-first-use and bootstrap races;
- environment-variable or config precedence confusion;
- mixed-version or migration paths;
- platform-specific behavior on Windows/Linux/macOS.
