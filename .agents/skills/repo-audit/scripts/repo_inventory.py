#!/usr/bin/env python3
"""Create a deterministic, dependency-free repository inventory.

The script reads metadata only. It does not execute project code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

SKIP_DIRS = {
    ".git", ".security-audit", "node_modules", "vendor", "dist", "build", "target",
    ".venv", "venv", "__pycache__", ".idea", ".vscode", "coverage", ".next"
}
MANIFESTS = {
    "package.json", "package-lock.json", "pnpm-lock.yaml", "yarn.lock",
    "requirements.txt", "pyproject.toml", "poetry.lock", "Pipfile", "Pipfile.lock",
    "go.mod", "go.sum", "Cargo.toml", "Cargo.lock", "pom.xml", "build.gradle",
    "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "Gemfile", "Gemfile.lock",
    "composer.json", "composer.lock", "Dockerfile", "docker-compose.yml", "docker-compose.yaml",
    "Makefile", "CMakeLists.txt", "WORKSPACE", "MODULE.bazel", "BUILD", "BUILD.bazel",
    "global.json", "Directory.Build.props", "Directory.Packages.props"
}
ENTRY_NAMES = {
    "main.c", "main.cc", "main.cpp", "main.rs", "main.go", "main.py", "app.py", "server.py",
    "index.js", "index.ts", "server.js", "server.ts", "Program.cs", "Startup.cs"
}
EXT_LANG = {
    ".c": "C", ".h": "C/C++ Header", ".cc": "C++", ".cpp": "C++", ".cxx": "C++",
    ".rs": "Rust", ".go": "Go", ".java": "Java", ".kt": "Kotlin", ".kts": "Kotlin",
    ".cs": "C#", ".fs": "F#", ".js": "JavaScript", ".mjs": "JavaScript", ".cjs": "JavaScript",
    ".ts": "TypeScript", ".tsx": "TypeScript/React", ".jsx": "JavaScript/React",
    ".py": "Python", ".php": "PHP", ".rb": "Ruby", ".swift": "Swift", ".scala": "Scala",
    ".sh": "Shell", ".ps1": "PowerShell", ".sql": "SQL", ".proto": "Protocol Buffers",
    ".yml": "YAML", ".yaml": "YAML", ".json": "JSON", ".xml": "XML"
}


def git(repo: Path, *args: str) -> str:
    try:
        return subprocess.check_output(["git", *args], cwd=repo, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return "unknown"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("repo", nargs="?", default=".")
    p.add_argument("--output", default=None)
    p.add_argument("--max-hash-size", type=int, default=2_000_000)
    args = p.parse_args()

    repo = Path(args.repo).resolve()
    output = Path(args.output).resolve() if args.output else repo / ".security-audit" / "01-inventory.json"
    output.parent.mkdir(parents=True, exist_ok=True)

    languages = Counter()
    manifests = []
    entries = []
    workflows = []
    security_files = []
    largest = []
    extensions = Counter()
    top_dirs = defaultdict(lambda: {"files": 0, "bytes": 0})
    total_files = total_bytes = 0

    for current, dirs, names in os.walk(repo):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        cur = Path(current)
        rel_dir = cur.relative_to(repo)
        top = rel_dir.parts[0] if rel_dir.parts else "."
        for name in sorted(names):
            path = cur / name
            try:
                if path.is_symlink() or not path.is_file():
                    continue
                size = path.stat().st_size
            except OSError:
                continue
            rel = path.relative_to(repo).as_posix()
            total_files += 1
            total_bytes += size
            top_dirs[top]["files"] += 1
            top_dirs[top]["bytes"] += size
            ext = path.suffix.lower()
            extensions[ext or "<none>"] += 1
            if ext in EXT_LANG:
                languages[EXT_LANG[ext]] += 1
            if name in MANIFESTS or name.endswith(('.csproj', '.sln', '.vcxproj')):
                manifests.append(rel)
            if name in ENTRY_NAMES or rel.startswith(('cmd/', 'bin/', 'src/main', 'apps/')):
                entries.append(rel)
            if rel.startswith('.github/workflows/') or rel.startswith('.gitlab-ci') or name in {'Jenkinsfile', 'azure-pipelines.yml'}:
                workflows.append(rel)
            if name.lower() in {'security.md', 'threatmodel.md', 'threat-model.md', 'codeowners'}:
                security_files.append(rel)
            largest.append((size, rel))

    largest.sort(reverse=True)
    manifest_hashes = {}
    for rel in manifests:
        path = repo / rel
        try:
            if path.stat().st_size <= args.max_hash_size:
                manifest_hashes[rel] = sha256(path)
        except OSError:
            pass

    data = {
        "schema": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "repository": str(repo),
        "git": {
            "commit": git(repo, "rev-parse", "HEAD"),
            "branch": git(repo, "branch", "--show-current"),
            "root": git(repo, "rev-parse", "--show-toplevel"),
            "submodules": git(repo, "submodule", "status"),
            "dirty": bool(git(repo, "status", "--porcelain")),
        },
        "counts": {"files": total_files, "bytes": total_bytes},
        "languages_by_file_count": dict(languages.most_common()),
        "extensions": dict(extensions.most_common()),
        "top_level_directories": dict(sorted(top_dirs.items())),
        "manifests": manifests,
        "manifest_sha256": manifest_hashes,
        "entrypoint_candidates": entries[:500],
        "ci_workflows": workflows,
        "security_files": security_files,
        "largest_files": [{"path": rel, "bytes": size} for size, rel in largest[:100]],
        "notes": [
            "This is a structural inventory, not an architecture or vulnerability assessment.",
            "Generated/vendor/build directories may be intentionally excluded."
        ],
    }
    output.write_text(json.dumps(data, indent=2), encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
