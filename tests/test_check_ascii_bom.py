#!/usr/bin/env python3
"""The real checker must fail when a raw-URL .ps1 starts with a UTF-8 BOM."""
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[1]
CHECKER = REPO / 'check-ascii-bom.py'
BOM = b'\xef\xbb\xbf'


def main() -> int:
    src = (REPO / 'Get-HelmerAI.ps1').read_bytes()
    if src.startswith(BOM):
        print('FAIL: repo Get-HelmerAI.ps1 still starts with a UTF-8 BOM')
        return 1

    r = subprocess.run([sys.executable, str(CHECKER)], cwd=str(REPO), capture_output=True, text=True)
    if r.returncode != 0:
        print('FAIL: checker failed on the clean repo')
        print(r.stdout)
        print(r.stderr)
        return 1

    with tempfile.TemporaryDirectory() as td:
        root = pathlib.Path(td)
        shutil.copy2(CHECKER, root / 'check-ascii-bom.py')
        (root / 'Get-HelmerAI.ps1').write_bytes(BOM + src)
        r = subprocess.run(
            [sys.executable, str(root / 'check-ascii-bom.py')],
            cwd=str(root),
            capture_output=True,
            text=True,
        )
        out = r.stdout + r.stderr
        if r.returncode != 1 or 'BOM not allowed' not in out:
            print('FAIL: BOM fixture was not rejected by check-ascii-bom.py')
            print(out)
            return 1

    print('OK test_check_ascii_bom')
    return 0


if __name__ == '__main__':
    sys.exit(main())
