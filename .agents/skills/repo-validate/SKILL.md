---
name: repo-validate
description: Automatically validate queued vulnerability candidates in the current authorized repository with no extra prompt. Selects candidates by priority, creates isolated deterministic PoCs, establishes baselines, positive and negative controls, proves or disproves trust-boundary impact, reproduces cleanly, hashes evidence, and classifies every tested candidate without attacking live systems.
---

# Autonomous Safe Candidate Validation

When invoked as `$repo-validate` with no additional text, start immediately. If no candidate ID is supplied, validate queued candidates in descending priority until the queue is exhausted, an environment limitation blocks further work, or execution limits require a persisted checkpoint. Do not ask the user to select a candidate unless multiple candidates require mutually exclusive external environments.

Operate only locally or in a dedicated authorized environment. Never test a live third-party service, use real victim data, expose secrets, persist access, or perform destructive actions.

## Prerequisites

If mapping, threat modeling, or candidate hunting is missing, execute the missing workflow first. Read the candidate hypothesis, source references, scope, baseline, and strongest rejection argument.

## Mandatory evidence location

For each candidate, create:

```text
.security-audit/06-evidence/<candidate-id>/
├── environment.md
├── hypothesis.md
├── commands.log
├── outputs/
├── poc/
├── controls/
├── clean-run/
├── impact.md
├── limitations.md
└── evidence-manifest.json
```

Use `.security-audit/lab/` or a separate worktree/copy for instrumentation, PoCs, or patch experiments. Preserve the product baseline unchanged.

## Validation protocol

For each candidate:

1. Pin the exact product baseline and record tool/runtime versions.
2. State one decisive observation that would prove the claim and one that would disprove it.
3. Establish baseline secure/expected behavior.
4. Build the smallest realistic attacker-controlled input or action.
5. Trigger the exact reachable path with copy-pasteable commands.
6. Capture source trace, stdout/stderr, exit code, logs, timestamps, network/filesystem/account state, and relevant identities.
7. Demonstrate the named invariant violation and lower-trust → higher-trust boundary crossing.
8. Demonstrate concrete confidentiality, integrity, availability, identity, tenant, signing, release, sandbox, filesystem, or privilege impact.
9. Run at least one negative control differing only in the security-relevant condition.
10. Test authoritative downstream validation or mitigation that could neutralize the result.
11. Patch/disable the suspected root cause in the isolated lab when feasible and show the effect disappears; do not treat this as the product fix.
12. Reproduce from a clean clone/container/VM/worktree.
13. Measure reliability for timing-sensitive behavior.
14. Minimize the PoC and remove irrelevant steps.
15. Hash evidence and record cleanup.
16. Explicitly list plausible but unproven consequences.

## Class-specific requirements

### Authorization / cross-user / multi-tenant

Use at least two controlled principals or tenants where separation is claimed. Record actor identity, owner identity, token/claims, resource ownership, request, response, and final resource state. A 200 response without unauthorized effect is insufficient.

### Token / confused deputy

Prove issuer, audience, tenant, subject, resource, workflow/session mismatch, and show the higher-trust component performs an action the lower-trust context should not control. Downstream rejection defeats the impact claim.

### Path / symlink / archive

Record allowed root, lexical path, canonical path, symlink/hardlink target, ownership, permissions, before/after state, and exact open/read/write/extract operation. Include a non-link or correctly canonicalized control. Prove access to a protected object, not merely surprising path resolution.

### Memory safety

Use appropriate sanitizers and debug symbols, minimize input, establish external reachability, and determine meaningful confidentiality, integrity, or availability consequences. A local crash alone is not automatically reportable.

### Race / TOCTOU

Measure attempts, successes, timing window, hardware/filesystem conditions, and reproducibility. Prove the attacker can influence the checked and used state under realistic capability.

### CI / supply chain

Use a controlled fork/repository/runner and dummy secrets. Prove transition from untrusted contribution or artifact to protected repository, release, signing, environment, or secret authority.

## Status rules

Update the candidate to exactly one validation status:

- `REJECTED`: hypothesis disproven or a fatal gate fails;
- `VALIDATED_NON_REPORTABLE`: behavior is real but no accepted boundary/impact exists;
- `NEEDS_ENVIRONMENT`: required authorized environment is unavailable;
- `REPRODUCED`: behavior reproduced but impact remains unproven;
- `IMPACT_PROVEN`: concrete security impact observed with controls and clean evidence.

Never mark `REPORTABLE`; that is owned by adversarial triage.

## Completion

Continue through the priority queue and persist checkpoints. Report what was tested, disproven, blocked, and not demonstrated. Mark orchestrator state `VALIDATION_ACTIVE` or advance only when all queued candidates have a validation classification.
