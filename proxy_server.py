#!/usr/bin/env python3
"""
CORS-Proxy-Server für Weltenbibliothek
Leitet Requests von Flutter Web an Cloudflare API weiter
"""

import http.server
import socketserver
import urllib.request
import urllib.error
import json
from urllib.parse import urlparse, parse_qs

# Cloudflare API Konfiguration
CLOUDFLARE_API_BASE = "https://weltenbibliothek-api.brandy13062.workers.dev"
API_TOKEN = "_C578hgIAimVPG0WjfeAjk23RxQMQ9gox0W7ebLv"

class CORSProxyHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP Handler mit CORS-Support und API-Proxy"""
    
    def end_headers(self):
        """Füge CORS-Headers zu jeder Response hinzu"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.send_header('Access-Control-Max-Age', '3600')
        self.send_header('X-Frame-Options', 'ALLOWALL')
        self.send_header('Content-Security-Policy', 'frame-ancestors *')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight CORS requests"""
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        """Handle GET requests - proxy API calls"""
        
        # Prüfe ob es ein API-Call ist
        if self.path.startswith('/api/'):
            self._proxy_api_request('GET')
        else:
            # Normale Datei-Requests
            super().do_GET()
    
    def do_POST(self):
        """Handle POST requests - proxy API calls"""
        
        if self.path.startswith('/api/'):
            self._proxy_api_request('POST')
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_PUT(self):
        """Handle PUT requests - proxy API calls"""
        
        if self.path.startswith('/api/'):
            self._proxy_api_request('PUT')
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_DELETE(self):
        """Handle DELETE requests - proxy API calls"""
        
        if self.path.startswith('/api/'):
            self._proxy_api_request('DELETE')
        else:
            self.send_response(404)
            self.end_headers()
    
    def _proxy_api_request(self, method):
        """Leite API-Request an Cloudflare weiter"""
        
        try:
            # Baue vollständige Cloudflare URL
            cloudflare_url = f"{CLOUDFLARE_API_BASE}{self.path}"
            
            print(f"📡 Proxy {method}: {cloudflare_url}")
            
            # Request-Headers mit Bearer Token
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {API_TOKEN}'
            }
            
            # POST/PUT: Lese Body-Daten
            body_data = None
            if method in ['POST', 'PUT']:
                content_length = int(self.headers.get('Content-Length', 0))
                if content_length > 0:
                    body_data = self.rfile.read(content_length)
            
            # Sende Request an Cloudflare
            req = urllib.request.Request(
                cloudflare_url,
                data=body_data,
                headers=headers,
                method=method
            )
            
            with urllib.request.urlopen(req, timeout=15) as response:
                response_data = response.read()
                
                # Sende erfolgreiche Response zurück
                self.send_response(response.status)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(response_data)
                
                print(f"✅ Proxy Success: {response.status}")
        
        except urllib.error.HTTPError as e:
            # HTTP-Fehler von Cloudflare
            error_body = e.read()
            print(f"❌ Cloudflare Error {e.code}: {error_body.decode('utf-8', errors='ignore')}")
            
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(error_body)
        
        except Exception as e:
            # Andere Fehler
            print(f"❌ Proxy Error: {e}")
            
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = json.dumps({'error': str(e)}).encode('utf-8')
            self.wfile.write(error_response)

def run_proxy_server(port=5060):
    """Starte CORS-Proxy-Server"""
    
    Handler = CORSProxyHandler
    
    with socketserver.TCPServer(("0.0.0.0", port), Handler) as httpd:
        print(f"🚀 CORS-Proxy-Server gestartet auf Port {port}")
        print(f"📡 Cloudflare API: {CLOUDFLARE_API_BASE}")
        print(f"🔐 Bearer Token: {API_TOKEN[:20]}...")
        print(f"✅ CORS-Headers aktiv")
        print(f"\n🌐 Server läuft unter: http://0.0.0.0:{port}")
        httpd.serve_forever()

if __name__ == "__main__":
    # Starte Server
    run_proxy_server()
