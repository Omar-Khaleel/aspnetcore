# Security audit scope

- Repository: `/workspace/aspnetcore`
- Worktree commit: `d68b893f6dc3415fbe7a551442605c032430b017`
- Product baseline: `d144ac55` (parent of the audit-skill installation commit, selected because `.agents/skills` was introduced by `d68b893f`).
- Branch: `work`
- Mode: deep, local, defensive source review.
- Product source modification: prohibited; no ASP.NET Core product source files were changed.
- Excluded from product attack surface: `.agents/skills/`, `.security-audit/`, and the removed installer ZIP.
- Disclosure policy: `SECURITY.md` directs private reports to MSRC and says qualifying reports may fall under the .NET Core Bug Bounty; bounty eligibility was not externally verified in this run.
- Authorization: local source review and local non-invasive testing only. No live Microsoft, GitHub, NuGet, CI, cloud, or third-party services were attacked.
- Network/credentials: no product credentials or controlled tenant/account infrastructure were available; external duplicate/scope checks remain unverified.

## Safe commands used

- `python3 .agents/skills/repo-audit/scripts/init_audit.py --mode deep .`
- `python3 .agents/skills/repo-audit/scripts/repo_inventory.py --output .security-audit/01-inventory.json .`
- Read-only `rg`, `sed`, `jq`, `git`, and shell inspection commands.
