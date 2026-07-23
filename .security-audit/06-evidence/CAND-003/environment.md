# CAND-003 validation environment

- Repository: `/workspace/aspnetcore`
- Worktree commit during resumed audit: `b8f104d6f6763c043224bd47de69c5ae35e1496b`
- Product baseline under review: `d144ac55`
- Date: 2026-07-23 UTC
- Tools available: `git`, `rg`, `sed`, `nl`, `python3`, shell utilities.
- Tool limitation: `dotnet` was not installed in this container, so handler unit tests and local TestServer-based dynamic callback validation could not be executed.
- Testing boundary: local source review only; no real identity provider, external callback endpoint, or user account was contacted.
