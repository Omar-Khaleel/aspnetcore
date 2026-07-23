# Candidate schema

Store candidates in `.security-audit/05-candidates.json` as an array of objects.

```json
{
  "id": "CAND-001",
  "title": "Short falsifiable hypothesis",
  "status": "NEW",
  "class": "authorization|path|memory|parser|identity|supply-chain|other",
  "surface": "component/entry point",
  "product_baseline": "commit",
  "source_locations": ["path:line"],
  "attacker_control": "Exact controlled input/action",
  "attacker_privileges": "Exact starting authority",
  "victim_and_owner": "Distinct identities and assets",
  "prerequisites": ["Required access/configuration"],
  "security_invariant": "Statement expected to remain true",
  "suspected_root_cause": "Specific missing or incorrect enforcement",
  "sensitive_sink": "Operation/asset reached",
  "boundary": "Lower-trust -> higher-trust boundary",
  "expected_impact": "Claim to prove, not assume",
  "validation_plan": ["Deterministic steps"],
  "negative_controls": ["Control experiment"],
  "downstream_defenses_to_test": ["Authoritative checks"],
  "evidence": [],
  "failed_gates": [],
  "triage_objections": [],
  "triage_rounds": [],
  "report_revisions": [],
  "coverage_tags": [],
  "confidence": "low|medium|high",
  "priority": 0,
  "notes": ""
}
```

## Status progression

`NEW → PLAUSIBLE → REPRODUCED → IMPACT_PROVEN → REPORTABLE`

Terminal alternatives:

- `VALIDATED_NON_REPORTABLE`
- `NEEDS_ENVIRONMENT`
- `REJECTED`

Validation cannot assign `REPORTABLE`; adversarial triage owns that transition. Reporting may revoke it if the report-text red-team exposes a material gap.

## Discipline

- One root cause and boundary per candidate unless a demonstrated exploit chain requires linked defects.
- Split variants when prerequisites or affected boundaries differ materially.
- Deduplicate scanner alerts and sibling symptoms by root cause.
- Preserve rejection history; do not delete inconvenient failed experiments.
- Never promote a candidate by changing the threat model after the PoC fails.
