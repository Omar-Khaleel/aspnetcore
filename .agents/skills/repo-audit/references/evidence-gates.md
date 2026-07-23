# Evidence gates

A candidate is reportable only if every applicable gate passes.

## G0 — Scope and authorization

- Component and version are in scope.
- Testing is authorized and respects program rules.
- The tested commit and environment are recorded.

## G1 — Attacker control

- Identify the exact input or action the attacker controls.
- State required access, role, network position, and user interaction.
- Reject assumptions that require already possessing the victim's privilege.

## G2 — Reachability

- Prove the vulnerable path executes in a supported and realistic scenario.
- Distinguish default, common, optional, debug-only, test-only, and unsupported paths.

## G3 — Security boundary violation

Name the broken boundary precisely:

- user A → user B;
- tenant low → tenant high;
- untrusted file → filesystem outside allowed root;
- sandboxed process → host authority;
- unauthenticated client → authenticated action;
- package contributor → release/build authority;
- lower-integrity identity/token → higher-trust operation.

Suspicious code without a boundary or invariant violation fails this gate.

## G4 — Observable impact

Prove at least one concrete effect:

- unauthorized read, modification, deletion, execution, impersonation, privilege gain, policy bypass, secret disclosure, integrity loss, or meaningful availability impact.

Do not substitute theoretical downstream impact for what the PoC actually demonstrates.

## G5 — Causality

- The root cause explains the observed impact.
- Remove or patch the suspected condition and show the effect disappears when feasible.
- Exclude test harness mistakes, stale state, permission inheritance, and environmental artifacts.

## G6 — Reproducibility

- Exact prerequisites, commands, versions, and expected outputs are recorded.
- Reproduce from a clean clone/container/VM when feasible.
- Measure reliability for races or timing-sensitive results.

## G7 — Negative control

Use at least one control that should not exploit:

- correct tenant/user/path/token;
- patched validation;
- non-symlink path;
- sanitized input;
- same operation without the boundary mismatch;
- unsupported flag removed.

A result without a meaningful negative control is fragile.

## G8 — Intended behavior and downstream defenses

- Check documentation, tests, comments, and security model.
- Verify downstream services do not reject or neutralize the malformed authority/input.
- Distinguish accepted customization from broken isolation.

## G9 — Minimality and evidence integrity

- Minimize the PoC to the necessary steps.
- Preserve logs and artifacts without secrets or victim data.
- Hash attachments when practical.
- Separate observed facts from inference.

## G10 — Reportability

- The program accepts the product, class, and impact.
- The candidate is not merely hardening, best practice, self-XSS/self-attack, local same-privilege behavior, or a documented limitation.
- Severity and CVSS follow the demonstrated scenario only.

## Status meanings

- `NEW`: unreviewed lead.
- `PLAUSIBLE`: source evidence supports a falsifiable hypothesis.
- `REPRODUCED`: behavior reproduced, impact not yet proven.
- `IMPACT_PROVEN`: concrete impact observed.
- `REPORTABLE`: all applicable gates pass and triage objections are answered.
- `VALIDATED_NON_REPORTABLE`: real behavior, but no accepted security boundary/impact.
- `NEEDS_ENVIRONMENT`: missing authorized infrastructure or prerequisites.
- `REJECTED`: hypothesis disproven or fails a named gate.
