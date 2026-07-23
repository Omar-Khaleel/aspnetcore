# Orchestration contract

The `repo-audit` skill owns the entire workflow. Sibling skills are implementation stages, not user prerequisites.

## One-command behavior

Invocation with only `$repo-audit` means:

- use the current repository;
- default to deep authorized local review;
- infer product baseline and preserve the vulnerable baseline;
- execute map → threat model → hunt → validate → adversarial triage → variant analysis → report → report red-team;
- persist state and resume automatically on the next identical invocation.

The orchestrator must not return after only planning or candidate generation unless execution is blocked. It must write a checkpoint and explain the exact blocker.

## Handoff rules

- Mapping may refine scope but cannot claim vulnerabilities.
- Threat modeling produces falsifiable invariants, not findings.
- Hunting creates structured candidates, not reports.
- Validation may mark up to `IMPACT_PROVEN`, never `REPORTABLE`.
- Triage alone assigns `REPORTABLE`.
- Reporting may revoke `REPORTABLE` if the exact report text exposes a material evidence gap.
- A changed baseline, identity assumption, or root cause invalidates dependent stages and requires revalidation.

## Resume rules

Read `state.json`, verify repository and baseline, then resume the earliest incomplete stage. Preserve historical candidate IDs and evidence. Do not overwrite decisive evidence without timestamped reruns.

## Stop rules

Stop a candidate when:

- it is disproven;
- it is real but no accepted boundary/impact exists;
- decisive proof requires unavailable authorized infrastructure;
- all evidence gates pass and the report survives red-team review.

Do not stop because a candidate is difficult while a safe decisive experiment remains feasible.
