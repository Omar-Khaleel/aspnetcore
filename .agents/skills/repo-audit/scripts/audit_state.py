#!/usr/bin/env python3
"""Read and update .security-audit/state.json without executing project code."""
from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

STAGES = [
    "BOOTSTRAP", "SCOPE_LOCKED", "REPO_MAPPED", "THREAT_MODEL_READY",
    "HUNT_COMPLETE", "VALIDATION_ACTIVE", "ADVERSARIAL_TRIAGE",
    "VARIANT_ANALYSIS", "REPORT_DRAFTED", "REPORT_RED_TEAMED", "COMPLETE",
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def load(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"State file does not exist: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: Path, data: dict) -> None:
    data["updated_at"] = now()
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("command", choices=["show", "set-stage", "checkpoint"])
    p.add_argument("--repo", default=".")
    p.add_argument("--stage", choices=STAGES)
    p.add_argument("--note", default="")
    args = p.parse_args()

    state_path = Path(args.repo).resolve() / ".security-audit" / "state.json"
    data = load(state_path)

    if args.command == "show":
        print(json.dumps(data, indent=2, sort_keys=True))
        return 0

    if args.command == "set-stage":
        if not args.stage:
            raise SystemExit("--stage is required")
        data["stage"] = args.stage
        data.setdefault("stage_history", []).append({"stage": args.stage, "at": now(), "note": args.note})
        save(state_path, data)
        print(state_path)
        return 0

    data.setdefault("checkpoints", []).append({"at": now(), "stage": data.get("stage"), "note": args.note})
    save(state_path, data)
    print(state_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
