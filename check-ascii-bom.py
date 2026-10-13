#!/usr/bin/env python3
"""CI gate for script encoding.

Raw-URL .ps1 files (this repo, including release/) are fetched as:

    irm https://raw.githubusercontent.com/jehelmer-oss/helmerai-bootstrap/main/Get-HelmerAI.ps1 | iex

Windows PowerShell 5.1 leaves a UTF-8 BOM as U+FEFF in the Invoke-RestMethod
string. iex then fails with "Missing argument in parameter list" at line 1
(the parser shows the BOM before the first '#'). Those files must be UTF-8
without a BOM and ASCII-only.

Other Helmer AI trees (when present on the box) are run with -File, where
PS 5.1 still wants a BOM so UTF-8 is not read as ANSI. Those keep the
legacy "ASCII + BOM" rule.

Do not write a BOM in update_get_ps1 / ensure_bom_ascii / Out-File -Encoding
utf8 (Windows PowerShell 5.1 utf8 = utf8BOM).
"""
import pathlib
import sys

THIS_REPO = pathlib.Path(__file__).resolve().parent
RAW_URL_ROOTS = [
    THIS_REPO,
    pathlib.Path('/workspace/scripts/helmerai-bootstrap'),
]
FILE_RUN_ROOTS = [
    pathlib.Path('/workspace/mac-feed-repo/windows'),
    pathlib.Path('/workspace/scripts/tech-manuals-windows'),
]
EXTS = {'.ps1', '.psm1', '.bat', '.cmd'}
SKIP = {'dist', 'stage', '.git', 'launcher', '__pycache__'}
BOM = b'\xef\xbb\xbf'


def is_skipped(p: pathlib.Path) -> bool:
    return any(x in p.parts for x in SKIP)


def iter_scripts(root: pathlib.Path):
    if not root.exists():
        return
    for p in root.rglob('*'):
        if p.is_file() and p.suffix.lower() in EXTS and not is_skipped(p):
            yield p


def check_body(p: pathlib.Path, data: bytes, errs: list) -> None:
    try:
        text = data.decode('utf-8')
    except UnicodeDecodeError as e:
        errs.append(f'{p}: not valid UTF-8 ({e})')
        return
    bad = sorted({c for c in text if ord(c) > 127})
    if bad:
        errs.append(f'{p}: non-ASCII {bad!r}')


def main() -> int:
    errs = []
    checked = 0
    seen = set()

    for root in RAW_URL_ROOTS:
        for p in iter_scripts(root):
            key = str(p.resolve())
            if key in seen:
                continue
            seen.add(key)
            data = p.read_bytes()
            checked += 1
            if p.suffix.lower() in {'.ps1', '.psm1'} and data.startswith(BOM):
                errs.append(f'{p}: UTF-8 BOM not allowed on raw-URL .ps1 (breaks irm | iex on PS 5.1)')
            body = data
            while body.startswith(BOM):
                body = body[len(BOM):]
            check_body(p, body, errs)

    for root in FILE_RUN_ROOTS:
        for p in iter_scripts(root):
            key = str(p.resolve())
            if key in seen:
                continue
            seen.add(key)
            data = p.read_bytes()
            checked += 1
            if not data.startswith(BOM):
                errs.append(f'{p}: missing UTF-8 BOM')
                body = data
            else:
                body = data[len(BOM):]
            check_body(p, body, errs)

    if errs:
        print('FAIL ascii/bom check (%d files):' % checked)
        for e in errs:
            print(' ', e)
        return 1
    print('OK ascii+no-BOM (raw-URL .ps1): %d files' % checked)
    return 0


if __name__ == '__main__':
    sys.exit(main())
