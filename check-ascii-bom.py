#!/usr/bin/env python3
"""Fail if any .ps1/.psm1/.bat/.cmd under the Helmer AI trees has non-ASCII bytes or lacks UTF-8 BOM."""
import pathlib, sys
ROOTS = [
    pathlib.Path(__file__).resolve().parent,
    pathlib.Path('/workspace/scripts/helmerai-bootstrap'),
    pathlib.Path('/workspace/mac-feed-repo/windows'),
    pathlib.Path('/workspace/scripts/tech-manuals-windows'),
]
EXTS = {'.ps1', '.psm1', '.bat', '.cmd'}
SKIP = {'dist', 'release', 'stage', '.git', 'launcher', '__pycache__'}
errs = []
checked = 0
for root in ROOTS:
    if not root.exists():
        continue
    for p in root.rglob('*'):
        if not p.is_file() or p.suffix.lower() not in EXTS:
            continue
        if any(x in p.parts for x in SKIP):
            continue
        data = p.read_bytes()
        checked += 1
        if not data.startswith(b'\xef\xbb\xbf'):
            errs.append(f'{p}: missing UTF-8 BOM')
            body = data
        else:
            body = data[3:]
        try:
            text = body.decode('utf-8')
        except UnicodeDecodeError as e:
            errs.append(f'{p}: not valid UTF-8 ({e})')
            continue
        bad = sorted({c for c in text if ord(c) > 127})
        if bad:
            errs.append(f'{p}: non-ASCII {bad!r}')
if errs:
    print('FAIL ascii/bom check (%d files):' % checked)
    for e in errs:
        print(' ', e)
    sys.exit(1)
print('OK ascii+BOM: %d files' % checked)
