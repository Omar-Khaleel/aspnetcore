#!/usr/bin/env python3
"""Hash evidence files without reading outside the requested directory."""
from __future__ import annotations
import argparse, hashlib, json
from datetime import datetime, timezone
from pathlib import Path


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('directory')
    p.add_argument('--output', default='evidence-manifest.json')
    args = p.parse_args()
    base = Path(args.directory).resolve()
    if not base.is_dir():
        raise SystemExit(f'Not a directory: {base}')
    out = (base / args.output).resolve()
    if base not in out.parents:
        raise SystemExit('Output must remain inside evidence directory')
    rows = []
    for path in sorted(base.rglob('*')):
        if path.is_file() and path.resolve() != out:
            rows.append({
                'path': path.relative_to(base).as_posix(),
                'bytes': path.stat().st_size,
                'sha256': digest(path),
            })
    out.write_text(json.dumps({
        'generated_at': datetime.now(timezone.utc).isoformat(),
        'algorithm': 'sha256',
        'files': rows,
    }, indent=2), encoding='utf-8')
    print(out)
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
