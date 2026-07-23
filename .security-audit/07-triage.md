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
