#!/usr/bin/env python3
"""Serve the repo the way raw.githubusercontent.com serves .ps1 files.

GitHub raw uses Content-Type: text/plain; charset=utf-8 and does not strip
a leading UTF-8 BOM. Invoke-RestMethod on Windows PowerShell 5.1 then keeps
U+FEFF in the string that iex parses.
"""
import argparse
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class RawHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        path = self.translate_path(self.path)
        if path.lower().endswith('.ps1'):
            try:
                fh = open(path, 'rb')
            except OSError:
                self.send_error(404, 'File not found')
                return None
            fs = os.fstat(fh.fileno())
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.send_header('Content-Length', str(fs.st_size))
            self.end_headers()
            return fh
        return SimpleHTTPRequestHandler.send_head(self)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--bind', default='127.0.0.1')
    ap.add_argument('--port', type=int, default=18080)
    ap.add_argument('--root', default='.')
    args = ap.parse_args()
    os.chdir(args.root)
    httpd = ThreadingHTTPServer((args.bind, args.port), RawHandler)
    print('serving %s on %s:%d' % (os.getcwd(), args.bind, args.port), flush=True)
    httpd.serve_forever()


if __name__ == '__main__':
    main()
