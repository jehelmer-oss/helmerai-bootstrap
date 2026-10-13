#!/usr/bin/env python3
"""Write .ps1 files as UTF-8 without a BOM (ASCII-only).

Windows PowerShell 5.1 ``Out-File -Encoding utf8`` and
``[IO.File]::WriteAllText(..., UTF8Encoding $true)`` re-add a BOM.
Publish and sync steps must use this helper (or write_bytes of UTF-8
without the EF BB BF prefix) so ``irm | iex`` keeps working.
"""
import argparse
import pathlib
import sys

BOM = b'\xef\xbb\xbf'


def strip_file(path: pathlib.Path, check_ascii: bool = True) -> bool:
    data = path.read_bytes()
    changed = False
    while data.startswith(BOM):
        data = data[len(BOM):]
        changed = True
    try:
        text = data.decode('utf-8')
    except UnicodeDecodeError as e:
        raise SystemExit(f'{path}: not valid UTF-8 ({e})')
    if text.startswith('\ufeff'):
        text = text.lstrip('\ufeff')
        data = text.encode('utf-8')
        changed = True
    if check_ascii:
        bad = sorted({c for c in text if ord(c) > 127})
        if bad:
            raise SystemExit(f'{path}: non-ASCII {bad!r}')
    if changed:
        path.write_bytes(data)
    return changed


def main() -> int:
    ap = argparse.ArgumentParser(description='Strip UTF-8 BOM from .ps1 files')
    ap.add_argument('paths', nargs='+', type=pathlib.Path)
    args = ap.parse_args()
    n = 0
    for p in args.paths:
        if not p.is_file():
            print('skip missing', p)
            continue
        if strip_file(p):
            print('stripped BOM', p)
            n += 1
        else:
            print('ok no BOM', p)
    return 0


if __name__ == '__main__':
    sys.exit(main())
