---
name: repo-map
description: Automatically build a complete security-oriented map of the current authorized repository with no extra prompt: baseline, components, build graph, entry points, identities, privileges, trust boundaries, data flows, lifecycle states, sensitive sinks, and coverage notes. Use before vulnerability hunting or when the codebase is unfamiliar.
---

# Autonomous Security-Oriented Repository Mapping

When invoked as `$repo-map` with no additional text, start immediately on the current repository. Do not ask the user to restate the mapping prompt.

## Defaults

- Current repository root.
- Deep mapping mode.
- Read-only product review; writes are limited to `.security-audit/`.
- Product baseline is the upstream merge-base or the commit before `.agents/skills` was introduced; record uncertainty.
- Exclude `.agents/skills` and `.security-audit` from the product map.
- Use local evidence when network access is unavailable.

If `.security-audit/` does not exist, initialize it. If scope is incomplete, record conservative assumptions and continue with local source review.

## Mandatory deliverables

Produce or update:

- `.security-audit/00-scope.md`
- `.security-audit/01-inventory.json`
- `.security-audit/02-architecture.md`
- `.security-audit/04-attack-surface.md`
- `.security-audit/08-coverage.md`
- `.security-audit/state.json`

## Execute the mapping

1. Record repository root, product baseline, worktree commit, branch/tag, dirty state, remotes, submodules, OS, architecture, and tool versions.
2. Identify languages, manifests, generated/vendor code, binaries, services, packages, plugins, examples, tests, deployments, release workflows, and supported platforms.
3. Derive the actual build graph, launch paths, runtime modes, and minimal safe test recipe from manifests, CI, Makefiles, scripts, and docs. Do not execute unknown project scripts blindly.
4. Distinguish shipped/reachable code from tests, examples, debug tools, deprecated code, generated code, and development-only utilities.
5. Enumerate externally influenced entry points: network, HTTP, RPC, IPC, sockets, files, archives, environment, config, CLI, plugins, webhooks, browser messages, package metadata, CI events, update artifacts, database records, queues, and inter-process state.
6. Identify precise attacker control and required privileges for each entry point.
7. Locate security enforcement: authentication, object/function authorization, tenant selection, token binding, policy checks, origin validation, signatures, path roots, canonicalization, sandbox policy, ACLs, privilege changes, trust stores, and approval gates.
8. Locate sensitive sinks: process execution, dynamic loading, file read/write, privileged APIs, secret/key access, network egress, deserialization, database mutation, account/resource ownership, release/publish/signing actions, cross-tenant resources, and security-setting changes.
9. Build four separate maps:
   - component map;
   - data-flow map;
   - authority/identity map;
   - lifecycle map covering install, build, startup, runtime, retry, recovery, update, migration, shutdown, and cleanup.
10. Build tables for components, entry points, trust boundaries, source-to-sink flows, enforcement points, identities/tenants, and sensitive assets.
11. Identify high-centrality and high-authority functions plus callers and alternate paths.
12. Inspect tests, docs, and prior fixes for encoded security assumptions.
13. Record blind spots, excluded directories, unavailable builds, and every major surface's current coverage state.

## Parallel mapping

When subagents are supported, delegate independent read-only mapping by language, component, identity/auth subsystem, parser/input subsystem, CI/supply-chain subsystem, and platform-specific code. Require file/symbol references. Wait for all results, reconcile contradictions, and keep the main agent responsible for the authoritative map.

## Quality gates

The map is incomplete if it is only a file tree or grep dump. Every important claim must identify:

- the component owning authority;
- the lower-trust source;
- the trust transition;
- the enforcement point;
- the sensitive sink or protected asset;
- source paths, symbols, manifests, or commands supporting the claim.

Do not infer runtime reachability merely because a function exists.

## Final output

Summarize the top security-relevant surfaces, why they are reachable, attacker prerequisites, protected asset, enforcing component, likely invariant, best next review technique, and remaining uncertainty. Mark state as `REPO_MAPPED` only when the mandatory deliverables are usable.
