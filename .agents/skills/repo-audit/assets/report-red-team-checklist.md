# Final report red-team checklist

- [ ] Exact product baseline and tested environment are stated.
- [ ] Product ownership is not confused with bounty eligibility.
- [ ] Attacker, victim, owner, tenant, token, path, process, and authority are unambiguous.
- [ ] Every prerequisite is visible.
- [ ] Root cause is causal and source-referenced.
- [ ] PoC is minimal, deterministic, and copy-pasteable.
- [ ] Positive result demonstrates the claimed impact.
- [ ] Negative control isolates the security-relevant condition.
- [ ] Clean reproduction succeeds.
- [ ] Downstream authorization/validation does not neutralize the path.
- [ ] No self-attack, same-privilege, debug-only, or unsupported-config explanation remains.
- [ ] Title, CWE, and CVSS match only the proven path.
- [ ] All attachments are listed and hashed.
- [ ] Observed, inferred, and not-demonstrated claims are separated.
- [ ] Remediation fixes the invariant, not only the PoC string.
- [ ] Suggested regression test fails on the vulnerable baseline and would pass after a correct fix.
