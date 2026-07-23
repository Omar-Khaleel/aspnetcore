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
