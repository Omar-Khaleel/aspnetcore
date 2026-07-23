# Adversarial triage

## CAND-001 — Static asset manifest/content-root confusion

- Prover: Static asset serving reaches `IFileProvider.GetFileInfo` through manifest descriptors and therefore file serving is a sensitive filesystem-read sink.
- Breaker: The security boundary is not crossed because the remote web client was not shown to control the manifest path or content roots. Application/developer configuration and build output are trusted relative to a remote requester.
- Adjudicator: Reject. Gates G1, G3, and G4 fail: attacker control, boundary violation, and observable impact are missing.
- Final classification: `REJECTED`.

## CAND-002 — CI archive extraction/script execution

- Prover: Engineering scripts contain archive extraction and process execution operations that are supply-chain sensitive.
- Breaker: No authorized controlled CI environment, protected workflow permission model, dummy secret, or fork/event proof was available. The reviewed script operations alone are not a vulnerability.
- Adjudicator: Needs environment. Gates G0, G2, G4, and G6 are unresolved.
- Final classification: `NEEDS_ENVIRONMENT`.

No candidate reached `IMPACT_PROVEN` or `REPORTABLE`; therefore no vendor-ready vulnerability report was produced.

## CAND-003 — Remote authentication callback state/nonce confusion

- Prover: OAuth and OIDC callback inputs are high-impact because a successful bypass would create an application principal from lower-trust callback data.
- Breaker: The reviewed source shows the expected state/correlation/nonce order: OAuth unprotects `state` and rejects null properties before `ValidateCorrelationId`; challenge generation calls `GenerateCorrelationId`; the shared remote handler validates the protected correlation value against a matching cookie marker and deletes it; OIDC rejects missing/invalid state before correlation validation and passes nonce into protocol validation.
- Adjudicator: Reject this concrete hypothesis. The source trace does not show a callback path that creates a ticket without protected state/correlation/nonce binding, and `dotnet` plus a controlled IdP/token lab were unavailable for dynamic tests.
- Final classification: `REJECTED`.

## CAND-004 adversarial triage — Kestrel HTTP/1 TE/CL parser differential

**Verdict:** `REJECTED` for the reviewed hypothesis.

**Prover evidence:** the attacker controls HTTP/1 request headers; source review found `Http1MessageBody` checks final transfer coding, rejects non-final/non-chunked transfer coding, moves `Content-Length` to `X-Content-Length`, and clears parsed content length before selecting a chunked message body. `HttpRequestHeaders` rejects differing duplicate content lengths. Existing Kestrel tests cover transfer-coding parsing and chunked+content-length header normalization.

**Strongest breaker rejection:** this is a high-value request-smuggling surface, but no parser differential or hidden request was reproduced. The reviewed code appears to enforce the expected invariant for the concrete TE/CL ambiguity. Without a dynamic proxy/Kestrel differential harness, the claim cannot show observable security impact.

**Adjudication:** reject this candidate rather than report it. Preserve it as coverage and resume future Kestrel fuzzing/differential validation when the repository SDK bootstrap is available.

## CAND-005 adversarial triage — SignalR MessagePack binder/deserialization bypass

**Verdict:** `REJECTED` for the reviewed concrete hypothesis.

**Prover evidence:** a remote SignalR client controls MessagePack hub protocol frames before server-side hub dispatch, and successful parser/binder bypass could affect hub invocation authority. Source review found the default protocol options use MessagePack `UntrustedData` security, invocation parsing asks `IInvocationBinder` for target parameter types, `BindArguments` requires exact argument count, and binding/deserialization exceptions are represented as binding-failure messages. Existing tests cover malformed primitive fields, missing/empty target and invocation IDs, argument count/type mismatches, partial-frame non-consumption, and a deeply nested skipped-result case.

**Strongest breaker rejection:** no unauthorized hub invocation, type-confusion effect, or resource-exhaustion impact was reproduced. Custom application-supplied serializer options are explicitly developer-controlled configuration, not remote attacker control. The reviewed code and tests support the expected invariant for the concrete default MessagePack binder-bypass/unsafe-default claim.

**Adjudication:** reject this candidate rather than report it. Preserve SignalR protocol fuzzing as a future dynamic coverage item once SDK bootstrap is available.
