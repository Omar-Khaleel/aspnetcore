---
name: repo-threat-model
description: Automatically create a repository-specific threat model for the current authorized repository with no extra prompt. Defines assets, realistic attackers, trust boundaries, authority owners, testable security invariants, abuse cases, rejected assumptions, and ranked attack paths. Runs repository mapping first when required.
---

# Autonomous Repository Threat Model

When invoked as `$repo-threat-model` with no additional text, start immediately. If the repository map is missing or stale, execute the `repo-map` workflow first; do not ask the user to invoke it separately.

## Inputs and defaults

Read:

- `.security-audit/00-scope.md`
- `.security-audit/01-inventory.json`
- `.security-audit/02-architecture.md`
- `.security-audit/04-attack-surface.md`
- product source, tests, docs, and security policy as needed.

Default to a deep, repository-specific model. Do not use a generic CWE list as the model.

## Mandatory deliverables

Produce or update:

- `.security-audit/03-threat-model.md`
- ranked hypotheses and coverage priorities in `.security-audit/04-attack-surface.md`
- `.security-audit/state.json`

## Build the model

For each major component and workflow, identify:

- protected assets: confidentiality, integrity, availability, identity, tenant isolation, signing/release authority, filesystem boundary, sandbox boundary, secrets, keys, privileged operations, billing/balance, or approval state;
- realistic attacker classes: unauthenticated remote, authenticated low privilege, malicious tenant, malicious repository contributor, local low-integrity user, untrusted plugin/content, adjacent process, compromised dependency, or malicious package author;
- exact prerequisites and capabilities the attacker does not have;
- victim role and any required user interaction;
- trust boundaries and the component that owns enforcement;
- authority sources: identity, token, tenant, subscription/project, role, filesystem owner/root, process privilege, signature, origin, branch/event, or workflow state;
- security invariants written as testable statements;
- abuse cases, expected mitigations, and authoritative downstream checks;
- lifecycle and stale-state risks after retry, revocation, rename, delete/recreate, migration, rollback, or partial failure.

## Invariant discipline

Write invariants specific enough to test, for example:

- A path accepted as inside workspace W must resolve inside canonical W at the time of use.
- Identity A cannot authorize an action on a resource exclusively owned by B.
- Untrusted pull-request code cannot execute with protected release authority.
- A token is accepted only for the intended issuer, audience, tenant, subject, resource, and workflow state.
- A lower-trust plugin/message origin cannot command a higher-trust host without origin and session binding.
- A parser cannot cause memory access or allocation outside validated bounds under an externally reachable input.

## Rank attack paths

Rank hypotheses using transparent reasoning across:

- realistic reachability;
- value of the crossed boundary;
- potential demonstrable impact;
- confidence from source evidence;
- historical weakness and novelty;
- validation cost and environment availability.

For each top hypothesis record:

- entry point and attacker-controlled value;
- authority context;
- expected invariant;
- suspected enforcement gap;
- sensitive sink;
- realistic prerequisite;
- strongest rejection argument;
- smallest positive experiment;
- meaningful negative control;
- downstream defense that could disprove the claim.

## Rejection discipline

Explicitly mark hypotheses likely to be non-reportable because they are self-attack, same privilege, documented customization, unsupported configuration, debug/example-only behavior, local-only without a security boundary, or neutralized by downstream authorization.

Do not claim a vulnerability during threat modeling.

## Final output

Return the top 5–15 falsifiable hypotheses and mark state as `THREAT_MODEL_READY` only when assets, attackers, boundaries, authority owners, invariants, rejected assumptions, and ranked paths are all documented.
