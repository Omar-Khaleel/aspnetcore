---
name: repo-report
description: Automatically produce and red-team disclosure-ready reports for all REPORTABLE candidates in the current authorized repository with no extra prompt. Drafts from validated evidence only, attacks the exact report text as a hostile triager, audits every factual claim against evidence, revises up to three rounds, and emits a final report or gap memo without inventing impact.
---

# Autonomous Vulnerability Report and Report Red-Team

When invoked as `$repo-report` with no additional text, start immediately. Select all candidates marked `REPORTABLE`. If none are reportable, do not manufacture a report; produce a concise gap memo or no-reportable-findings summary.

Read the candidate record, evidence directory, scope, architecture, threat model, coverage, and triage history.

## Mandatory report contents

Write the vendor submission in the requested language; default to English. Include:

1. Title naming component, broken boundary/root cause, attacker, and demonstrated impact.
2. Product/component and exact product baseline, version/tag if proven, and tested worktree details.
3. Vulnerability class, accurate CWE, and conservative CVSS vector with metric-by-metric reasoning.
4. One-paragraph executive summary.
5. Realistic threat model, attacker privileges, victim conditions, and user interaction.
6. Expected security invariant and crossed boundary.
7. Root cause with exact files, symbols, and complete relevant flow.
8. Reproduction environment and dependency versions.
9. Numbered deterministic setup and reproduction steps.
10. Minimal PoC or regression-test harness.
11. Expected behavior and actual behavior.
12. Positive evidence, meaningful negative controls, and clean-run result.
13. Demonstrated impact only.
14. Reliability, scope, limitations, prerequisites, and explicit non-claims.
15. Why normal controls and downstream defenses do not stop the demonstrated path.
16. Remediation at the invariant/root-cause level.
17. Suggested regression test.
18. Evidence manifest with filenames and SHA-256 hashes.

## Evidence language

Clearly distinguish:

- **Observed:** direct source, command, log, test, state, screenshot, or artifact evidence.
- **Inferred:** conclusion derived from named observations.
- **Not demonstrated:** plausible consequence not proven by the PoC.

Do not hide prerequisites or use sensational language. RCE, account takeover, sandbox escape, cross-tenant access, or privilege escalation may appear only when that exact result is demonstrated.

## Report red-team loop

Run up to three revisions for each draft:

1. Save a draft.
2. Act as a hostile vendor triager reviewing the exact text.
3. Check for unsupported scope, stale file/line references, ambiguous identities, missing commands, hidden setup, non-causal root cause, invalid negative control, missing clean reproduction, downstream rejection, intended behavior, duplicate/known-fix risk, exaggerated title/CWE/CVSS, and claims not present in evidence.
4. Build a claim-to-evidence matrix for every factual or impact-bearing sentence.
5. Run additional safe local experiments only when they resolve a material report gap.
6. Remove or label every unsupported statement.
7. Reapply the complete `repo-triage` rejection matrix to the revised draft.
8. Stop when no material objection remains.

If a material objection remains after three revisions, remove `REPORTABLE`, classify appropriately, and write `<candidate-id>-gaps.md` rather than a final vulnerability report.

## Output files

Save:

- draft revisions under `.security-audit/reports/drafts/<candidate-id>/`;
- final report as `.security-audit/reports/<candidate-id>-report.md`;
- claim/evidence matrix as `.security-audit/reports/<candidate-id>-claim-evidence.md`;
- gap memo when required;
- updated triage and state records.

## Final quality bar

A maintainer must be able to reproduce without guessing, identify the faulty invariant, understand actor/victim/authority boundaries, see why controls fail, verify the evidence hashes, and convert the PoC into a regression test. A polished narrative cannot compensate for missing proof.
