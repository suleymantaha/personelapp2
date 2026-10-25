"""Serve the built app locally with Drift's cross-origin isolation headers."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1] / 'build' / 'web'
    if not (root / 'index.html').is_file():
        parser.error('First run flutter build web --no-web-resources-cdn')
    server = ThreadingHTTPServer(
        ('127.0.0.1', args.port), partial(Handler, directory=str(root)))
    print(f'Nizam: http://127.0.0.1:{args.port}', flush=True)
    server.serve_forever()
