#!/usr/bin/env python3
import http.server
import socketserver

PORT = 5060

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()

with socketserver.TCPServer(("0.0.0.0", PORT), CORSRequestHandler) as httpd:
    print(f"✅ CORS Server läuft auf Port {PORT}")
    httpd.serve_forever()
