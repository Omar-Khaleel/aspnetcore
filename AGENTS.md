<!-- BEGIN UNIVERSAL-REPO-SECURITY-SKILLS -->
## Autonomous repository security audit routing

When the user invokes `$repo-audit` or asks for the complete repository security audit workflow, read and follow `.agents/skills/repo-audit/SKILL.md`. The skill contains all defaults and must execute the full map → threat model → hunt → isolated validation → adversarial triage → variant analysis → report red-team workflow. Do not ask the user to paste the long audit prompt. Resume from `.security-audit/state.json` when present.

For explicit stage invocations, read the matching `.agents/skills/<skill-name>/SKILL.md`.
<!-- END UNIVERSAL-REPO-SECURITY-SKILLS -->
