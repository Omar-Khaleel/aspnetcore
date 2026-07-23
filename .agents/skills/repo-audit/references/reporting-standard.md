# Reporting standard

## Required sections

1. Title
2. Product / component / affected versions or commit
3. Vulnerability class, CWE, and CVSS vector
4. Executive summary
5. Threat model and attacker prerequisites
6. Security boundary and expected invariant
7. Root cause analysis with source references
8. Reproduction environment
9. Exact reproduction steps
10. PoC or regression test
11. Expected behavior
12. Actual behavior
13. Evidence and negative control
14. Demonstrated impact
15. Scope, limitations, and explicit non-claims
16. Remediation guidance
17. Evidence manifest and hashes

## Title formula

`[Component] [boundary/root cause] allows [attacker] to [demonstrated impact]`

Avoid sensational terms such as RCE, account takeover, sandbox escape, or privilege escalation unless the PoC demonstrates that exact outcome.

## CVSS discipline

- Score the proven attack path, not the strongest imaginable chain.
- Account for required privileges, user interaction, adjacent/local access, and scope change accurately.
- Explain ambiguous metrics.
- Provide severity separately from business importance or bounty expectation.

## Evidence language

Use:

- **Observed:** direct command/log/source evidence.
- **Inferred:** conclusion derived from named observations.
- **Not demonstrated:** plausible consequence not proven by the PoC.

## Quality bar

A maintainer should be able to reproduce the result without guessing, identify the faulty invariant, see why normal controls fail, and turn the PoC into a regression test.
