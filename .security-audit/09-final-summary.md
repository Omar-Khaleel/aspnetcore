# Final audit summary

- Product baseline: `d144ac55` (resumed audit baseline; upstream verification remains limited).
- Worktree commit: `e61e22a14c0ce545fbe53b223ecd764a996e4328`.
- Scope verification: local source review and isolated testing are authorized for this checked-out repository. MSRC/.NET disclosure route is identified from repository policy, but external bounty eligibility and duplicate checks were not verified.
- Coverage achieved: inventory, architecture map, threat model, attack surface coverage notes, targeted dangerous-API/security searches, static asset source trace, authentication callback state/correlation/nonce source trace, Kestrel HTTP/1 TE/CL request-smuggling source/test trace, candidate evidence manifests, and adversarial triage.
- Bootstrap status: `./.dotnet/dotnet` was absent; `./restore.sh` was attempted as required, but dependency download from `builds.dotnet.microsoft.com` repeatedly failed via proxy HTTP 403 and was preserved in `.security-audit/restore-20260723.log`.
- Blind spots: no Kestrel unit tests/fuzzing or parser-differential harness executed because repository SDK bootstrap was blocked by proxy restrictions; no external IdP or multi-tenant/principal lab; no authorized CI runner/fork validation; no exhaustive component-specific dynamic review across the full ASP.NET Core surface.

## Candidate classifications

- `REPORTABLE`: 0
- `IMPACT_PROVEN`: 0
- `REPRODUCED`: 0
- `VALIDATED_NON_REPORTABLE`: 0
- `NEEDS_ENVIRONMENT`: 1 (`CAND-002`)
- `REJECTED`: 3 (`CAND-001`, `CAND-003`, `CAND-004`)

## Reportable findings

None. No candidate survived the required evidence gates and adversarial triage as reportable.

## Strongest rejected or blocked candidate

- Strongest rejected local-parser candidate: `CAND-004`, Kestrel HTTP/1 TE/CL request-smuggling parser differential. Missing proof: a dynamic Kestrel/proxy differential or smuggled request; source/test evidence instead shows final-transfer-coding enforcement and content-length suppression when chunked framing is selected.
- Other rejected candidates: `CAND-001`, static asset manifest/content-root confusion; `CAND-003`, remote authentication callback state/nonce confusion.
- Strongest environment-blocked: `CAND-002`, CI/release supply-chain authority. Missing proof: authorized controlled CI/fork/runner with protected workflow permissions and dummy secrets/artifacts.

## Reproduction commands for PoCs

No reportable PoC exists. Source-trace commands are recorded in:

- `.security-audit/06-evidence/CAND-001/commands.log`
- `.security-audit/06-evidence/CAND-003/commands.log`
- `.security-audit/06-evidence/CAND-004/commands.log`

## Resume status

The audit is not complete. Another `$repo-audit` invocation should resume with Kestrel parser fuzzing/differential tests once SDK bootstrap can reach dependencies, then continue SignalR protocol/hub authorization validation, MVC/Razor/Components boundary review, DataProtection/caching review, and CI/release workflow proof in an authorized lab.
