---
name: repo-audit
description: Run a complete authorized defensive security audit of the current repository with one invocation. Automatically map the codebase, build a threat model, hunt candidates, create and validate isolated PoCs, adversarially triage every claim, repeat evidence and report review loops, and produce disclosure-ready reports only for findings that survive all gates. Use for full open-source repository security research; never use against live third-party systems or unauthorized targets.
---

# Autonomous Repository Security Audit Orchestrator

This is the primary one-command workflow. When invoked as `$repo-audit` with no additional text, start immediately and execute the complete audit using the defaults below. Do not ask the user to paste the long audit prompt again. Do not stop after making a plan, mapping the repository, or listing hypotheses. Continue through validation, adversarial triage, and final reporting as far as the execution environment permits.

## Non-negotiable authorization boundary

Operate only on source code, forks, accounts, infrastructure, and test environments the user owns or is explicitly authorized to assess. Treat possession of a public fork as authorization for source review and local isolated testing only, not for testing a deployed third-party service.

Never:

- attack production or live third-party systems;
- use real victim accounts, real secrets, persistence, destructive payloads, credential harvesting, or stealth;
- exfiltrate repository data or credentials;
- perform denial-of-service against external systems;
- report speculative impact as observed impact.

If external authorization is absent, remain local and non-invasive. Passive retrieval of public documentation or dependencies is allowed only when the environment permits it.

## Zero-prompt defaults

When the user supplies only `$repo-audit`, infer and record these defaults:

- **Repository:** current checked-out repository root.
- **Product baseline:** identify the product commit before audit-skill files or audit-only changes were added. Prefer the merge-base with an upstream default branch; otherwise use the parent of the first commit that introduced `.agents/skills`; otherwise use the current commit and state the uncertainty.
- **Worktree commit:** current `HEAD`, recorded separately from the product baseline.
- **Mode:** `deep`.
- **Program:** read `SECURITY.md`, repository metadata, disclosure documents, and official public program rules when network access is available. A Microsoft-owned repository is not automatically bounty-eligible; record scope verification separately from product ownership.
- **Final report language:** English.
- **Working summaries:** match the user's language; Arabic is acceptable.
- **Testing:** local, containerized, VM-based, or dedicated controlled accounts only.
- **Source modification:** prohibited on the vulnerable baseline except for isolated PoC fixtures, temporary instrumentation, or regression-test experiments in a separate worktree/copy. Preserve the original baseline.
- **Audit data:** store under `.security-audit/` and exclude `.agents/skills`, audit scripts, and audit artifacts from the product attack surface.
- **Network:** assume agent internet access may be unavailable. Continue from repository evidence and mark external scope or duplicate checks as unverified rather than guessing.

Ask a question only when a safety-critical ambiguity makes authorized local work impossible. Otherwise choose the conservative assumption, record it, and continue.

## Required sibling skills

Before each phase, read the applicable sibling skill when present:

- `../repo-map/SKILL.md`
- `../repo-threat-model/SKILL.md`
- `../repo-hunt/SKILL.md`
- `../repo-validate/SKILL.md`
- `../repo-triage/SKILL.md`
- `../repo-report/SKILL.md`

The user does not need to invoke these manually. The orchestrator owns sequencing, handoffs, deduplication, evidence gates, and completion. If a sibling skill is missing, follow the equivalent phase contract in this file and `references/orchestration-contract.md`.

## Persistent workspace and resume behavior

Create or reuse:

```text
.security-audit/
├── 00-scope.md
├── 01-inventory.json
├── 02-architecture.md
├── 03-threat-model.md
├── 04-attack-surface.md
├── 05-candidates.json
├── 06-evidence/<candidate-id>/
├── 07-triage.md
├── 08-coverage.md
├── 09-final-summary.md
├── reports/
├── lab/
└── state.json
```

Use `scripts/init_audit.py`, `scripts/repo_inventory.py`, `scripts/audit_state.py`, and `scripts/evidence_manifest.py` when useful.

On every invocation:

1. Read `state.json` and existing artifacts.
2. Verify they match the current repository and product baseline.
3. Resume the earliest incomplete or invalidated phase.
4. Preserve prior evidence; create timestamped reruns instead of overwriting decisive logs.
5. Revalidate downstream artifacts when an upstream assumption changes.

If a task ends because of runtime, context, approval, dependency, or environment limits, persist a precise checkpoint. On the next invocation of only `$repo-audit`, resume automatically. Never require the user to repeat the full instructions.

## State machine

Advance only when required artifacts and gates exist:

1. `BOOTSTRAP`
2. `SCOPE_LOCKED`
3. `REPO_MAPPED`
4. `THREAT_MODEL_READY`
5. `HUNT_COMPLETE`
6. `VALIDATION_ACTIVE`
7. `ADVERSARIAL_TRIAGE`
8. `VARIANT_ANALYSIS`
9. `REPORT_DRAFTED`
10. `REPORT_RED_TEAMED`
11. `COMPLETE`

A phase may return to an earlier phase when new evidence invalidates an assumption.

# Autonomous execution workflow

## Phase 0 — Bootstrap and scope lock

Perform, do not merely propose:

- locate repository root and record branch, `HEAD`, dirty state, remotes, tags, submodules, OS, architecture, and tool versions;
- identify product baseline independently from audit-only commits;
- read `SECURITY.md`, supported-version policy, release notes, build docs, and contribution docs;
- identify likely disclosure program and whether eligibility is verified, unverified, or out of scope;
- initialize `.security-audit/` and write authorization limitations;
- derive safe build/test commands without executing unknown scripts blindly;
- record permitted and unavailable capabilities, including network and credentials.

Do not audit the skill package itself as product code.

## Phase 1 — Complete repository and authority map

Execute the `repo-map` workflow across the full repository. Produce a security-oriented map, not a file-tree summary. Cover:

- components, packages, services, binaries, plugins, generators, examples, tests, deployment, and release paths;
- build graph, launch paths, runtime modes, supported platforms, and shipped versus non-shipped code;
- external entry points and attacker-controlled sources;
- authentication, authorization, tenant, token, path, sandbox, signature, and policy enforcement;
- sensitive sinks and high-authority operations;
- component, data-flow, authority, and lifecycle maps;
- exact source-to-sink flows with enforcement points;
- blind spots and explicit coverage notes.

Use independent read-only subagents for major components or languages when supported. The main agent must reconcile their claims against source references.

## Phase 2 — Repository-specific threat model

Execute the `repo-threat-model` workflow. Define testable security invariants and realistic attackers. Rank attack paths by realistic reachability, boundary value, demonstrated-impact potential, source confidence, novelty, and validation cost.

Reject unrealistic assumptions early, but preserve falsifiable hypotheses that can be tested locally.

## Phase 3 — Systematic vulnerability hunt

Execute the `repo-hunt` workflow. Search broadly but create candidates narrowly. Combine:

- manual trust-boundary and business-logic review;
- source → transform/sanitizer → sink tracing;
- callers/callees around high-authority operations;
- sibling-path, fallback-path, compatibility-path, and cross-platform comparisons;
- history-driven review and variant analysis of prior fixes;
- targeted CodeQL, Joern, Semgrep, language-native analysis, dependency review, and secret scanning as lead generators;
- parser fuzzing, property testing, race testing, and sanitizers where technically appropriate;
- CI/CD, package, release, update, cache, plugin, IPC, browser-origin, filesystem, identity, and tenant boundaries.

A candidate must have a concrete attacker source, plausible reachable path, named invariant, sensitive sink or authority decision, falsifiable root-cause hypothesis, realistic impact claim, validation experiment, and negative control.

Do not call scanner output a vulnerability.

## Phase 4 — Candidate queue and coverage control

Deduplicate candidates by root cause and trust boundary. Score and queue them. Ensure every major attack surface is marked:

- manually reviewed;
- semantically queried;
- dynamically exercised;
- fuzzed with coverage notes;
- not testable with a precise reason.

Prioritize candidates capable of crossing user, tenant, process, sandbox, filesystem, release, secret, signing, or privilege boundaries. Do not inflate low-value local behavior.

## Phase 5 — Isolated PoC and impact validation loop

Execute the `repo-validate` workflow for candidates in descending priority. For every candidate:

1. Pin the product baseline and create a disposable lab/worktree/copy.
2. Establish secure baseline behavior.
3. Build the smallest attacker-controlled trigger.
4. Trace and capture the exact reachable path.
5. Demonstrate the claimed invariant violation.
6. Demonstrate concrete confidentiality, integrity, availability, or authority impact.
7. Run meaningful negative controls.
8. Test whether downstream authorization, validation, sandboxing, signature checks, or canonicalization neutralize the input.
9. Reproduce from a clean state.
10. Minimize the PoC and hash the evidence.
11. Record cleanup and all non-demonstrated consequences.

A PoC must be practical and deterministic enough for a maintainer to reproduce. A crash, 200 response, suspicious log, or write to attacker-owned data is not automatically security impact.

Class-specific minimums include:

- two controlled principals/tenants for cross-user or cross-tenant claims;
- lexical and canonical path evidence for path/symlink/archive claims;
- issuer, audience, tenant, subject, workflow, and downstream-action proof for token/confused-deputy claims;
- sanitizer evidence plus attacker reachability and meaningful consequence for memory-safety claims;
- measured reliability and attacker control for race claims;
- dummy secrets and controlled forks/runners for CI/supply-chain claims.

If a candidate fails, classify it precisely and move to the next. Do not try to save it with invented chains.

## Phase 6 — Adversarial triage evidence loop

For every reproduced or impact-proven candidate, run the `repo-triage` workflow as a hostile maintainer. Use three roles, with subagents when supported:

- **Prover:** presents only source and dynamic evidence.
- **Breaker:** constructs the strongest rejection, alternative explanation, intended-behavior argument, scope objection, and downstream-defense challenge.
- **Adjudicator:** decides which evidence gate fails or what exact experiment resolves the dispute.

Then execute this loop, up to four evidence rounds:

1. Write the strongest rejection in its best form.
2. Compare it against current evidence.
3. If a safe local experiment can resolve a material objection, return to validation and run it.
4. Update evidence and rerun triage from scratch.
5. Stop only when the candidate is `REPORTABLE`, `VALIDATED_NON_REPORTABLE`, `NEEDS_ENVIRONMENT`, or `REJECTED`.

`REPORTABLE` requires every applicable gate to pass and every material objection to have an evidence-backed answer. An unresolved material objection blocks reporting.

## Phase 7 — Root-cause variant analysis

After a candidate reaches impact-proven status, generalize the invariant and search for sibling variants:

- parallel APIs, protocol versions, sync/async paths, platforms, legacy fallbacks, duplicated utilities, copied fixes, and lifecycle states;
- incomplete prior fixes and alternate entry points reaching the same sink;
- related components that use the same authority or canonicalization logic.

Validate variants separately when prerequisites or boundaries differ. Do not combine unrelated defects into an exaggerated chain.

## Phase 8 — Draft, attack, and revise the report

For every candidate marked `REPORTABLE`, execute `repo-report`, then red-team the exact draft rather than trusting the earlier triage.

### Report revision loop

Run up to three report revisions:

1. **Draft:** produce the complete vendor-ready report from evidence only.
2. **Report breaker:** attempt to reject the report as written. Look for hidden prerequisites, unsupported scope, ambiguous actor/victim identities, missing clean reproduction, non-causal root cause, downstream rejection, exaggerated title/CWE/CVSS, stale line numbers, and claims not backed by attachments.
3. **Evidence auditor:** map every factual sentence and impact claim to source, command output, log, screenshot, test, or clearly labeled inference.
4. **Revision:** remove unsupported claims, run additional safe experiments when necessary, and improve reproducibility.
5. **Final triage:** reapply all evidence gates to the revised report.

Stop revising when no material report objection remains or the three-round limit is reached. If a material objection remains, downgrade the candidate and write a gap memo instead of a final vulnerability report.

The final report must include title, component, exact baseline, affected versions if proven, CWE, conservative CVSS vector with reasoning, executive summary, realistic threat model, prerequisites, expected invariant, root cause with source references, exact environment, deterministic steps, minimal PoC, expected/actual behavior, positive evidence, negative controls, clean-run result, demonstrated impact, limitations and non-claims, remediation, regression test, and SHA-256 evidence manifest.

## Phase 9 — Final audit output

Write `.security-audit/09-final-summary.md` and return a concise user-facing summary containing:

- product baseline and worktree commit;
- scope verification status;
- coverage achieved and blind spots;
- counts by final candidate classification;
- each reportable finding and report path;
- strongest rejected or environment-blocked candidate and the exact missing proof;
- commands needed to reproduce PoCs;
- whether another `$repo-audit` invocation is needed to resume unfinished work.

Do not claim success merely because a report file exists. The report must have survived the report red-team loop.

# Completion conditions

The audit is complete only when:

- scope and baseline are fixed;
- architecture, threat model, attack surface, and coverage artifacts exist;
- priority surfaces have explicit review status;
- every candidate has a final classification;
- every reportable candidate has clean evidence, negative controls, a manifest, and passed adversarial triage;
- every final report has passed a separate report-text red-team review;
- unresolved limitations are stated plainly.

If no reportable vulnerability is found, say so directly. Preserve useful rejected candidates and exact missing proof, but do not manufacture a report.

## Supporting references

Read as needed:

- `references/orchestration-contract.md`
- `references/triage-loop.md`
- `references/methodology.md`
- `references/evidence-gates.md`
- `references/attack-surface-catalog.md`
- `references/language-playbooks.md`
- `references/candidate-schema.md`
- `references/reporting-standard.md`
- `assets/report-red-team-checklist.md`
