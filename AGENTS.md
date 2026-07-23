<!-- BEGIN UNIVERSAL-REPO-SECURITY-SKILLS -->
## Autonomous repository security audit routing

When the user invokes `$repo-audit` or asks for the complete repository security audit workflow, read and follow `.agents/skills/repo-audit/SKILL.md`. The skill contains all defaults and must execute the full map → threat model → hunt → isolated validation → adversarial triage → variant analysis → report red-team workflow. Do not ask the user to paste the long audit prompt. Resume from `.security-audit/state.json` when present.

For explicit stage invocations, read the matching `.agents/skills/<skill-name>/SKILL.md`.

ASP.NET Core repository bootstrap requirements for future bare `$repo-audit` runs:

- Before declaring .NET unavailable, check `./.dotnet/dotnet`.
- If `./.dotnet/dotnet` is missing, run `./restore.sh` from the repository root.
- Run `source ./activate.sh` before .NET commands when necessary.
- Prefer `./.dotnet/dotnet` for build and test commands when PATH changes are not persistent.
- Never treat a missing system-wide `dotnet` command as a final blocker when this repository provides `restore.sh` and `activate.sh`.
- Build and test only the relevant component or project; do not build the entire ASP.NET Core repository unless strictly necessary.
- Prioritize fully local dynamic audit surfaces: Kestrel HTTP parsers/state machines, request-smuggling/parser differential cases, malformed headers/chunked bodies/content-length/timeouts/connection state, SignalR JSON/MessagePack parsing and hub authorization, MVC/Razor/Components parser and binding boundaries, and Data Protection/caching only when a completely local lab is possible.
- Deprioritize protected GitHub CI/release infrastructure, OAuth/OIDC flows requiring external identity providers, and already rejected candidates unless genuinely new evidence exists.
- For Kestrel and SignalR, use existing unit tests and fuzzing targets first, put isolated PoC/regression harnesses under `.security-audit/lab/`, and preserve commands and outputs under `.security-audit/06-evidence/`.
- Do not mark the audit `COMPLETE` merely because one hypothesis was rejected; continue until the selected local component has systematic source review, targeted dynamic tests, and fuzzing or structured malformed-input testing.
<!-- END UNIVERSAL-REPO-SECURITY-SKILLS -->
