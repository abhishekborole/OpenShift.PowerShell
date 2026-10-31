"""Loopback HTTPS fixture; no cluster credentials or external network access."""
import http.server
import json
import ssl
import sys
from pathlib import Path


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        if self.path == '/version?redirect=1':
            self.send_response(302)
            self.send_header('Location', 'https://untrusted.invalid/version')
            self.end_headers()
            return
        if self.headers.get('Authorization') != 'Bearer fixture-token' and not self.connection.getpeercert():
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b'{"message":"do-not-echo-this-body"}')
            return
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'gitVersion': 'v1.33.fixture', 'method': 'GET'}).encode())

    def do_POST(self):
        size = int(self.headers.get('Content-Length', '0'))
        body = json.loads(self.rfile.read(size))
        self.send_response(201)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'receivedName': body['metadata']['name'], 'contentType': self.headers['Content-Type']}).encode())

    do_PUT = do_POST
    do_PATCH = do_POST
    do_DELETE = do_POST


server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.minimum_version = ssl.TLSVersion.TLSv1_2
context.load_cert_chain(sys.argv[1], sys.argv[2])
context.load_verify_locations(sys.argv[4])
context.verify_mode = ssl.CERT_OPTIONAL
server.socket = context.wrap_socket(server.socket, server_side=True)
Path(sys.argv[3]).write_text(str(server.server_port))
server.serve_forever()
