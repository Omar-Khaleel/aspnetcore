# Evidence and report triage loops

## Candidate evidence loop

Maximum: four rounds.

Each round contains:

1. Prover evidence summary.
2. Strongest breaker rejection.
3. Adjudicator gate decision.
4. Smallest safe experiment for each material gap.
5. Evidence update.
6. Full re-triage from scratch.

A round is useful only when it adds decisive evidence. Do not spend rounds rewriting arguments.

## Report text loop

Maximum: three revisions.

Each revision contains:

1. Vendor-ready draft.
2. Hostile review of the exact draft.
3. Claim-to-evidence mapping.
4. Source/version/command/hash consistency check.
5. Removal or qualification of unsupported statements.
6. Full final triage.

## Material objection examples

- attacker control is not proven;
- actor, owner, tenant, token, path, or authority is ambiguous;
- the PoC demonstrates a precursor but not impact;
- a downstream authority rejects the action;
- the vulnerable path is unsupported or not shipped;
- same-privilege or self-attack explains the effect;
- clean reproduction fails;
- negative control does not isolate the security condition;
- root cause is correlated but not causal;
- scope or affected version is unverified;
- title, CWE, or CVSS exceeds the demonstrated path.

Any unresolved material objection blocks a final report.
