#!/usr/bin/env python3
"""Initialize a non-destructive, resumable .security-audit workspace."""
from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def run(cmd: list[str], cwd: Path) -> str:
    try:
        return subprocess.check_output(cmd, cwd=cwd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return "unknown"


def git_ok(repo: Path, *args: str) -> bool:
    try:
        subprocess.check_call(["git", *args], cwd=repo, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return False


def baseline(repo: Path, head: str) -> tuple[str, str]:
    refs = ["upstream/HEAD", "origin/HEAD", "upstream/main", "upstream/master", "origin/main", "origin/master"]
    for ref in refs:
        if git_ok(repo, "rev-parse", "--verify", ref):
            value = run(["git", "merge-base", "HEAD", ref], repo)
            if value not in {"", "unknown"}:
                return value, f"merge-base with {ref}"

    first = run(["git", "log", "--reverse", "--format=%H", "--", ".agents/skills"], repo)
    first_commit = first.splitlines()[0] if first not in {"", "unknown"} else ""
    if first_commit and git_ok(repo, "rev-parse", "--verify", f"{first_commit}^"):
        return run(["git", "rev-parse", f"{first_commit}^"], repo), "parent of first .agents/skills commit"

    return head, "current HEAD; no distinct upstream/audit commit detected"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", nargs="?", default=".")
    parser.add_argument("--mode", default="deep", choices=["quick", "standard", "deep", "report-only"])
    parser.add_argument("--program", default="auto-detect")
    args = parser.parse_args()

    repo = Path(args.repo).resolve()
    if not repo.is_dir():
        raise SystemExit(f"Not a directory: {repo}")

    out = repo / ".security-audit"
    for child in ["06-evidence", "reports", "reports/drafts", "lab"]:
        (out / child).mkdir(parents=True, exist_ok=True)

    now = datetime.now(timezone.utc).isoformat()
    head = run(["git", "rev-parse", "HEAD"], repo)
    product_baseline, baseline_method = baseline(repo, head)
    state_path = out / "state.json"
    old = {}
    if state_path.exists():
        try:
            old = json.loads(state_path.read_text(encoding="utf-8"))
        except Exception:
            old = {}

    state = {
        "schema": 2,
        "created_at": old.get("created_at", now),
        "updated_at": now,
        "repository": str(repo),
        "worktree_commit": head,
        "product_baseline": old.get("product_baseline", product_baseline),
        "baseline_detection": old.get("baseline_detection", baseline_method),
        "branch": run(["git", "branch", "--show-current"], repo),
        "dirty": bool(run(["git", "status", "--porcelain"], repo)),
        "remotes": run(["git", "remote", "-v"], repo),
        "mode": old.get("mode", args.mode),
        "program": old.get("program", args.program),
        "scope_verification": old.get("scope_verification", "unverified"),
        "stage": old.get("stage", "BOOTSTRAP"),
        "stage_history": old.get("stage_history", []),
        "checkpoints": old.get("checkpoints", []),
        "candidates": old.get("candidates", {}),
        "report_revisions": old.get("report_revisions", {}),
    }
    state_path.write_text(json.dumps(state, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    scope = out / "00-scope.md"
    if not scope.exists():
        scope.write_text(
            "# Audit scope\n\n"
            f"- Repository: `{repo}`\n"
            f"- Product baseline: `{state['product_baseline']}`\n"
            f"- Baseline detection: `{state['baseline_detection']}`\n"
            f"- Worktree commit: `{state['worktree_commit']}`\n"
            f"- Branch: `{state['branch']}`\n"
            f"- Dirty: `{state['dirty']}`\n"
            f"- Mode: `{state['mode']}`\n"
            f"- Program: `{state['program']}`\n"
            f"- Scope verification: `{state['scope_verification']}`\n"
            f"- Initialized: `{now}`\n\n"
            "## Authorization and restrictions\n\n"
            "Source review and active tests are restricted to local or dedicated authorized environments. "
            "Repository ownership does not imply authorization to test deployed third-party services.\n",
            encoding="utf-8",
        )

    defaults = {
        "05-candidates.json": "[]\n",
        "07-triage.md": "# Adversarial triage\n\n",
        "08-coverage.md": "# Security review coverage\n\n",
        "09-final-summary.md": "# Final audit summary\n\nStatus: incomplete\n",
    }
    for name, content in defaults.items():
        path = out / name
        if not path.exists():
            path.write_text(content, encoding="utf-8")

    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
