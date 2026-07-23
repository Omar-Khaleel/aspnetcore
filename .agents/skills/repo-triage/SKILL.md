---
name: repo-triage
description: Automatically adversarially triage every reproduced or impact-proven candidate in the current authorized repository with no extra prompt. Acts as a hostile bounty maintainer, builds the strongest rejection, checks scope, attacker control, downstream defenses, intended behavior, clean reproduction, impact and CVSS, sends resolvable gaps back to validation, repeats up to four evidence rounds, and classifies reportability.
---

# Autonomous Adversarial Security Triage

When invoked as `$repo-triage` with no additional text, start immediately and triage every candidate eligible for review. If validation evidence is missing, execute the validation workflow first. Do not ask the user to repeat the triage checklist.

Assume every candidate is wrong until evidence survives all applicable objections.

## Three-role review

Use separate reasoning roles, preferably independent subagents when supported:

- **Prover:** presents only observed source and dynamic evidence.
- **Breaker:** argues the strongest possible maintainer/bounty rejection and alternative explanation.
- **Adjudicator:** identifies the failed gate or the smallest decisive experiment.

The same agent may perform the roles sequentially when subagents are unavailable, but must keep the arguments distinct.

## Rejection matrix

For every candidate, answer with evidence:

1. Is the exact component/version/class in disclosure and bounty scope?
2. Is external scope verification current, or merely inferred from repository ownership?
3. Does the attacker genuinely control the trigger under realistic privileges?
4. Is the path reachable in supported/default or credibly deployed behavior?
5. Is there a real lower-trust → higher-trust boundary and a named protected asset?
6. Does authoritative downstream validation, authorization, signature checking, canonicalization, or sandboxing neutralize the input?
7. Is the effect only self-attack, same privilege, local configuration, user-controlled output, malicious admin/contributor with equivalent authority, or intended plugin/customization behavior?
8. Does the PoC demonstrate the claimed impact rather than a precursor?
9. Are actor, victim, owner, tenant, token, path, process, and authority states unambiguous?
10. Are negative controls and clean reproduction convincing?
11. Is the suspected root cause causal, or could stale state, fixture error, inherited permissions, test instrumentation, or unsupported setup explain the result?
12. Is the issue documented, known, duplicate, already fixed, excluded, debug/example-only, or not shipped?
13. Does severity rely on chained assumptions not demonstrated?
14. Would a regression test fail before the fix and pass after it?
15. Are title, CWE, and CVSS calibrated to the proven path only?

## Mandatory strongest rejection

Write the best rejection a senior triager could make, not a straw man. Common fatal weaknesses include:

- fake token accepted by one layer but rejected by the authoritative service;
- lexical path anomaly without protected data access or modification;
- only attacker-owned files/process/session affected;
- malicious code contributor already has equivalent authority;
- debug/test/example code is not shipped or reachable;
- optional unsafe configuration is documented and explicitly trusted;
- crash requires local input and has no meaningful boundary;
- cross-account claim uses one account;
- race lacks realistic reliability or attacker control;
- scanner output lacks source-to-sink proof;
- claimed RCE/EoP/escape is only a primitive or hypothetical chain.

## Evidence repair loop

Repeat up to four rounds per candidate:

1. Build the strongest rejection from current evidence.
2. Identify every material unresolved objection.
3. For each safely resolvable objection, define the smallest local experiment.
4. Return to `repo-validate`, run only those experiments, and preserve evidence.
5. Rerun the entire rejection matrix from scratch.
6. Stop when the verdict is stable.

Do not loop to improve rhetoric. Loop only to obtain missing evidence. If an objection needs unauthorized infrastructure, real victims, production exploitation, or speculative chaining, classify it instead of testing it.

## Final classification

Choose exactly one:

- `REPORTABLE`: all applicable evidence gates pass and no material objection remains;
- `VALIDATED_NON_REPORTABLE`: behavior is real but accepted boundary, impact, or program eligibility is absent;
- `NEEDS_ENVIRONMENT`: decisive proof requires an unavailable authorized environment;
- `REJECTED`: hypothesis is disproven or fails a fatal gate.

For `REPORTABLE`, record:

- every passed gate;
- strongest remaining limitation;
- likely triage challenge and evidence answering it;
- accurate CWE;
- conservative CVSS vector with metric reasoning;
- report prerequisites that must not be hidden.

Never estimate bounty as evidence of severity and never inflate a finding to avoid rejection.

## Outputs

Update:

- `.security-audit/07-triage.md`
- candidate records and triage-round history;
- `.security-audit/state.json`

Only a candidate classified `REPORTABLE` may proceed to the reporting workflow.
