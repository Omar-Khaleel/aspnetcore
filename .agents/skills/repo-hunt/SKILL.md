---
name: repo-hunt
description: Automatically hunt realistic vulnerability candidates across the complete current authorized repository with no extra prompt. Runs missing map and threat-model prerequisites, performs manual boundary review, source-to-sink tracing, history and variant analysis, targeted semantic queries, supply-chain review, fuzzing analysis, deduplication, and candidate prioritization.
---

# Autonomous Vulnerability Candidate Hunt

When invoked as `$repo-hunt` with no additional text, start immediately. If mapping or threat modeling is missing or stale, execute those workflows first. Do not ask the user to invoke them separately.

## Inputs

Read all `.security-audit/` scope, architecture, threat-model, attack-surface, and coverage artifacts plus source, tests, docs, history, and build metadata.

## ASP.NET Core hunt priorities

For this ASP.NET Core repository, prioritize local, dynamically testable attack surfaces before external-service-dependent leads:

1. Kestrel HTTP/1, HTTP/2, and HTTP/3 parsers and state machines.
2. Request smuggling and parser differential behavior.
3. Header parsing, chunked-body parsing, content-length handling, timeout behavior, and connection-state transitions.
4. SignalR JSON/MessagePack protocol parsing and hub authorization.
5. MVC/Razor/Components parser and binding boundaries.
6. Data Protection and caching only where a completely local lab can exercise the invariant.

Deprioritize CI/release candidates that require protected GitHub infrastructure, OAuth/OIDC candidates that require external identity providers, and candidates already classified `REJECTED` unless genuinely new evidence changes their gate analysis. Prefer existing unit tests and fuzzing targets as lead generators for Kestrel and SignalR, then add only isolated audit harnesses under `.security-audit/lab/` when needed.

## Mandatory deliverables

Produce or update:

- `.security-audit/05-candidates.json`
- `.security-audit/08-coverage.md`
- `.security-audit/state.json`

Use stable candidate IDs and preserve rejected history.

## Execute the hunt

For every prioritized invariant and high-authority operation:

1. Locate all enforcement points and every sibling/parallel/fallback path expected to enforce the same rule.
2. Trace attacker-controlled sources through decoding, normalization, validation, mutation, caching, retry, redirect, serialization, alias expansion, and fallback to sensitive sinks.
3. Inspect callers and callees around high-authority operations.
4. Compare platforms, protocols, API versions, sync/async paths, legacy code, migration paths, and compatibility fallbacks.
5. Inspect tests and docs for assumed invariants, missing negative tests, and contradictory behavior.
6. Inspect Git history for security fixes, incomplete patches, copied code, renamed helpers, revert/regression, TODO/FIXME/HACK/bypass comments, and unpatched variants.
7. Use CodeQL, Joern, Semgrep, language-native tools, compiler diagnostics, targeted scripts, dependency scanners, or secret scanners only when they improve coverage. Treat output as leads, not findings.
8. Review CI/CD event trust, tokens, secrets, artifact provenance, cache keys, checkout refs, release signing, package source precedence, installers, updates, and plugins.
9. Identify parsers, decoders, archive handlers, protocol state machines, and concurrency boundaries suitable for fuzzing, property tests, sanitizers, or race tests.
10. Review identity and authority mismatches across users, tenants, subscriptions/projects, origins, branches/events, paths, processes, tokens, and workflow states.

## High-value patterns

Prioritize cases where:

- policy check and action use different identity, tenant, object, path, canonical form, token, or lifecycle state;
- validation occurs before a security-relevant transformation;
- one entry point checks authorization but a sibling or fallback does not;
- a cache omits identity, tenant, permission, version, origin, or authority from its key;
- revocation, rename, deletion, recreation, retry, rollback, or partial failure leaves stale authority;
- untrusted content crosses into a build, release, plugin host, privileged service, sandbox host, or signer;
- parser assumptions differ between layers;
- a prior fix covers one function but misses variants.

## Candidate creation gate

Create a candidate only when all are present:

- concrete attacker-controlled source/action;
- plausible reachable path in supported or credibly deployed behavior;
- named security invariant;
- actual sensitive sink or authority decision;
- specific falsifiable root-cause hypothesis;
- realistic prerequisites and victim conditions;
- expected impact to prove, not assume;
- practical isolated validation plan;
- meaningful negative control;
- strongest known rejection argument.

Do not add generic “might be vulnerable” items or scanner-only alerts.

## Candidate queue

Deduplicate by root cause and boundary. Score priority using reachability, boundary value, potential demonstrated impact, source confidence, novelty, and validation cost. Classify initial confidence and note required environment.

When subagents are supported, delegate independent hunting by boundary/component and require compact candidate records with source references. The main agent must deduplicate, challenge, and reject weak leads before adding them.

## Completion

Continue until every major attack surface has a coverage status and the high-priority queue is stable. Mark state as `HUNT_COMPLETE`; do not write a vendor report during this stage.
