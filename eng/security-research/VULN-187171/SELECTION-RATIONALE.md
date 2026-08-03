# Why VULN-187171 was selected for strengthening

The goal was to select one previously submitted Microsoft report that:

- requires no Azure subscription, paid cloud service, Business Central tenant, Copilot subscription, or external managed identity;
- has a direct security impact rather than only local file placement;
- has an objection that can be closed with new technical evidence;
- maps to an accessible repository owned by the researcher;
- has not already received a final architectural rejection that new evidence cannot change.

## Candidate comparison

| Report | Strength | Blocking objection | No-cloud proof | Reassessment value |
|---|---|---|---:|---:|
| APM remote Git symlink (`VULN-188514`) | Microsoft assessed Moderate and planned a fix | Read file remains on victim; direct attacker delivery still requires an extra publication/exfiltration step | Yes | Medium-low: already assessed and the missing exfiltration primitive remains |
| Purview GitHub Action symlink | Workspace escape is technically clear | Attacker needs repository write access, treated as CI code-execution-equivalent | Yes | Low: attacker model objection is architectural |
| NuGet global-packages symlink (`VULN-185692`) | Reproducible cross-directory writes | Microsoft treats a shared writable package cache across trust domains as operator responsibility | Yes | Very low: final trust-domain rejection |
| VSTest output-local `testhost.exe` (`VULN-190639`) | Code executes during test discovery without explicit test run | VSTest source and unit tests intentionally prefer output-local testhost binaries | Yes | Low: strong by-design evidence exists in upstream source |
| ASP.NET Core OutputCache (`VULN-187171`) | Direct cross-user network disclosure; protected response replay | Expected objection was middleware ordering/configuration | Yes | **High**: Microsoft later changed the framework for the exact reported scenario |

## Decisive evidence for OutputCache

The original report was submitted on 2026-05-10 against ASP.NET Core 9.0.15.

On 2026-06-09 Microsoft merged commit:

`1a638c9050d54510c9e48fea351636d736956196`

The commit states that if authentication runs after OutputCache and non-Authorization-header authentication is used, a page intended for one user can be cached and served to anonymous or other users.

That description matches the original report's cookie-authenticated Alice-to-Bob/anonymous replay.

The vulnerable code remains in 9.0.16, and the fix appears in 9.0.17. This creates a clean, locally reproducible vulnerable-versus-fixed comparison and materially addresses the expected “configuration only” objection.

## Decision

`VULN-187171` is the strongest report to update now.

The correct action is not to open a duplicate report. The correct action is to attach the version-differential evidence and fix correlation to the existing submission and request reassessment and bounty correlation.
