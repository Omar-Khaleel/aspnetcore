# Final audit summary

- Product baseline: `d144ac55`.
- Worktree commit: `b8f104d6f6763c043224bd47de69c5ae35e1496b`.
- Scope verification: local source review authorized; MSRC/.NET bounty route identified from `SECURITY.md`; external eligibility not verified.
- Coverage achieved: inventory, architecture map, threat model, attack surface coverage notes, targeted dangerous-API/security searches, static asset source trace, authentication callback state/correlation/nonce source trace, candidate evidence manifests, and adversarial triage.
- Blind spots: no full build/test/fuzzing because `dotnet` is unavailable in this container, no external IdP or multi-tenant/principal lab, no authorized CI runner/fork validation, and no exhaustive component-specific review across the full ASP.NET Core surface.

## Candidate classifications

- `REPORTABLE`: 0
- `IMPACT_PROVEN`: 0
- `REPRODUCED`: 0
- `VALIDATED_NON_REPORTABLE`: 0
- `NEEDS_ENVIRONMENT`: 1 (`CAND-002`)
- `REJECTED`: 2 (`CAND-001`, `CAND-003`)

## Reportable findings

None. No candidate survived the required evidence gates and adversarial triage as reportable.

## Strongest rejected or blocked candidate

- Strongest rejected: `CAND-001`, static asset manifest/content-root confusion. Missing proof: lower-trust remote attacker control over manifest path/content roots and observed unauthorized file disclosure.
- Newly rejected auth lead: `CAND-003`, remote authentication callback state/nonce confusion. Missing proof: a callback path that creates an authentication ticket without valid protected state, matching correlation cookie, and required nonce validation.
- Strongest environment-blocked: `CAND-002`, CI/release supply-chain authority. Missing proof: authorized controlled CI/fork/runner with protected workflow permissions and dummy secrets/artifacts.

## Reproduction commands for PoCs

No reportable PoC exists. Source-trace commands are recorded in:

- `.security-audit/06-evidence/CAND-001/commands.log`
- `.security-audit/06-evidence/CAND-003/commands.log`

## Resume status

The audit should be resumed with another `$repo-audit` for deeper component-specific dynamic validation. Recommended next phase: SignalR protocol/hub authorization validation, Kestrel parser fuzzing, MVC/Razor/Components boundary review, DataProtection/caching review, and CI/release workflow proof in an authorized lab.
