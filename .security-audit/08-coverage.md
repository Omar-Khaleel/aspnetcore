# Coverage and blind spots

## Achieved in this invocation

- Repository scope locked to current checkout with product baseline separated from audit-skill installation.
- Inventory generated across 16,606 files.
- Security policy read and disclosure route recorded.
- Major ASP.NET Core component families mapped at a security-boundary level.
- Threat model with five prioritized, falsifiable hypotheses created.
- Targeted read-only source searches performed for high-risk APIs and comments.
- Static assets/file-provider candidate traced far enough to reject as non-reportable under the evidence gates.

## Not completed / blind spots

- No full product build or test suite execution: too large for this audit turn and would execute broad project scripts.
- No live or external service testing: MSRC/bounty eligibility, CI workflow behavior, IdP callback flows, and cloud/service integrations remain externally unverified.
- No two-principal/tenant validation environment was available for cross-user or cross-tenant claims.
- No Kestrel/SignalR/Razor parser fuzzing was executed.
- No CodeQL/Semgrep/Joern/dependency/secret scanner run was completed; searches were manual `rg`-based lead generation only.
- MVC, Razor, Components, DataProtection, Identity, and native server stacks need deeper component-specific follow-up.

## Resume recommendation

Another `$repo-audit` invocation should resume at deeper systematic hunt/dynamic validation for authentication handlers, SignalR protocol handling, Kestrel parsers, and CI/release workflow boundaries.

## Additional resumed-audit coverage on 2026-07-23

- Authentication callback state/correlation/nonce handling was source-traced for OAuth and OpenID Connect.
- The OAuth path was checked for protected `state` use, correlation validation, and challenge-time correlation generation.
- The shared remote authentication path was checked for correlation cookie generation, marker validation, deletion, and rejection behavior.
- The OpenID Connect path was checked for missing/invalid state rejection, correlation validation, nonce cookie lookup/deletion, and nonce propagation to protocol validators.
- Candidate `CAND-003` was rejected because no path was shown to create a principal without those binding checks; dynamic TestServer execution remains blocked by missing `dotnet`.

## 2026-07-23 Kestrel HTTP/1 TE/CL coverage update

Reviewed `Http1MessageBody`, `HttpRequestHeaders`, and existing Kestrel tests for the specific request-smuggling hypothesis where `Transfer-Encoding` and `Content-Length` ambiguity could alter application-visible request boundaries. Source and test evidence support rejection of that concrete hypothesis: Kestrel rejects non-final chunked transfer coding, suppresses conflicting content length when chunked is selected, and rejects differing duplicate content lengths. Dynamic fuzzing and proxy differential tests remain blocked until repository SDK bootstrap succeeds.

## 2026-07-23 SignalR MessagePack protocol coverage update

Reviewed the default SignalR MessagePack protocol worker and option paths for a concrete binder-bypass/unsafe-deserialization hypothesis. Source review found default `MessagePackSecurity.UntrustedData` settings, binder-provided method parameter metadata, exact argument-count enforcement, binding-failure handling, and existing tests for malformed fields, argument mismatches, partial frames, and deeply nested skipped results. Candidate `CAND-005` was rejected for this concrete hypothesis. Dynamic SignalR fuzzing remains blocked until repository SDK bootstrap can download dependencies.
