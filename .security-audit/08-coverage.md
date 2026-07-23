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
