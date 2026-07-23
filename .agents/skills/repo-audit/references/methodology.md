# Methodology

## Core principle

Security review is an evidence pipeline, not a pattern-matching contest. Automated tools expand coverage; human reasoning establishes the threat model, authority, exploitability, and impact.

## Review loop

For each prioritized surface:

1. Identify the security invariant.
2. Identify attacker-controlled sources and authority context.
3. Trace the path to sensitive operations.
4. Locate validation, normalization, policy, or binding steps.
5. Form a falsifiable hypothesis.
6. Design the smallest safe experiment that distinguishes vulnerable from secure behavior.
7. Run positive and negative controls.
8. Minimize and reproduce from a clean state.
9. Perform variant analysis around the root cause.
10. Attempt to reject the result.

## Four maps

Maintain four distinct maps:

- **Component map:** what exists and how it is built/launched.
- **Data-flow map:** where untrusted data enters, changes, and reaches sinks.
- **Authority map:** which identity, role, tenant, token, path owner, or process privilege authorizes each action.
- **Lifecycle map:** install, update, startup, runtime, shutdown, migration, recovery, and cleanup states.

Most high-value logic flaws appear where these maps disagree.

## Priority heuristic

Rank hypotheses with a transparent score, not intuition alone:

`priority = reachability × boundary_value × impact × confidence × novelty ÷ validation_cost`

Use ordinal values and keep the reasoning. The score is a queueing aid, not severity.

## Recommended analysis families

- Manual secure code review for business logic and policy boundaries.
- CodeQL for semantic/data-flow queries and variant analysis.
- Joern/CPG for cross-language graph exploration and taint analysis.
- Semgrep for fast structural searches and custom project rules.
- Language-native linters and compiler warnings.
- Dependency scanners such as OSV-Scanner or Trivy.
- Secret scanners such as Gitleaks, with strict handling of discovered material.
- Fuzzing with coverage guidance and Fuzz Introspector-style gap analysis.
- Sanitizers for memory, undefined behavior, races, or uninitialized reads.
- Git history and previous fixes to discover incomplete patches and variants.

Tool output is a lead. Confirm it manually and dynamically.

## History-driven review

Inspect:

- recent security fixes and neighboring code;
- checks added in one path but omitted in parallel paths;
- refactors that moved policy away from execution;
- compatibility fallbacks and legacy code;
- TODO, FIXME, HACK, unsafe, bypass, trusted, internal-only, and temporary comments;
- tests that encode known security assumptions;
- release notes mentioning hardening or validation.

Convert a known fix into a generalized invariant, then search for variants.

## Coverage notes

For every major surface, record one of:

- reviewed manually;
- scanned with named rule/query set;
- exercised dynamically;
- fuzzed with coverage result;
- not testable and why.

Absence of findings without coverage notes is not a completed audit.
