import http.server
import socketserver
import socket
import os
import sys

PORT = 3000
WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

# Ensure proper MIME types across Windows systems
MIME_MAP = {
    ".js": "application/javascript",
    ".mjs": "application/javascript",
    ".wasm": "application/wasm",
    ".json": "application/json",
    ".css": "text/css",
    ".html": "text/html; charset=utf-8",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".woff": "font/woff",
    ".woff2": "font/woff2",
    ".ttf": "font/ttf",
    ".otf": "font/otf",
    ".map": "application/json",
}

class SPAServer(http.server.SimpleHTTPRequestHandler):
    # Register MIME types
    extensions_map = http.server.SimpleHTTPRequestHandler.extensions_map.copy()
    extensions_map.update(MIME_MAP)

    def __init__(self, *args, **kwargs):
        self.path = "/"
        self.requestline = ""
        self.request_version = "HTTP/1.1"
        self.command = "GET"
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def log_request(self, code='-', size='-'):
        if not hasattr(self, 'requestline') or not self.requestline:
            self.requestline = str(getattr(self, 'raw_requestline', b''))[:50]
        try:
            super().log_request(code, size)
        except Exception:
            pass

    def end_headers(self):
        # Allow multi-device / LAN / PAN cross-origin access and prevent stale caching
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        # Enforce strict zero-caching so users always receive fresh compiled Flutter bundles
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        current_path = getattr(self, "path", "")
        if current_path == "/" or current_path.endswith(".html") or not current_path or "index.html" in current_path:
            # Instruct modern browsers to immediately wipe legacy service workers and disk cache
            self.send_header("Clear-Site-Data", '"cache", "storage"')
        super().end_headers()

    def parse_request(self):
        # Check for TLS ClientHello handshake (starts with 0x16 0x03)
        # This happens when mobile Chrome/Safari auto-prefixes https:// instead of http://
        if hasattr(self, "raw_requestline") and self.raw_requestline and self.raw_requestline[0] == 0x16:
            self.log_message("[HTTPS NOT SUPPORTED] Client attempted HTTPS (TLS). Tell mobile user to type: http:// (not https://)")
            try:
                self.wfile.write(
                    b"HTTP/1.1 400 Bad Request\r\n"
                    b"Content-Type: text/plain\r\n"
                    b"Connection: close\r\n\r\n"
                    b"Bad Request: Plain HTTP server. Please type http:// instead of https:// in your browser address bar.\r\n"
                )
            except Exception:
                pass
            self.close_connection = True
            return False
        try:
            return super().parse_request()
        except Exception:
            self.close_connection = True
            return False

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        try:
            # Force server to ignore conditional 304 headers so the latest asset is ALWAYS transmitted
            if "if-modified-since" in self.headers:
                del self.headers["if-modified-since"]
            if "if-none-match" in self.headers:
                del self.headers["if-none-match"]

            # Extract requested path without query string or hash
            clean_path = self.path.split('?')[0].split('#')[0]
            local_path = os.path.normpath(os.path.join(WEB_DIR, clean_path.lstrip("/\\")))

            # Check if this request is targeting a specific file with an extension
            filename = os.path.basename(clean_path)
            has_extension = "." in filename and not filename.startswith(".")

            if os.path.exists(local_path) and os.path.isfile(local_path):
                # File exists on disk — serve normally
                return super().do_GET()

            if has_extension:
                # Requested a specific file asset (like .map, .png, .js) that does NOT exist
                # Return 404 instead of index.html so browser/devtools does not fail parsing
                self.send_error(404, f"File not found: {clean_path}")
                return

            # Client-side SPA route (e.g. /dashboard/manufacturer, /verify/SCX-001)
            # Fall back to /index.html
            self.path = "/index.html"
            return super().do_GET()
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
            # Client aborted connection (e.g. tab closed, page refreshed, devtools canceled map fetch)
            pass

    def copyfile(self, source, outputfile):
        try:
            super().copyfile(source, outputfile)
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
            pass

    def log_message(self, format, *args):
        # Format clean single-line logs; suppress noisy 404s for optional source maps (.map)
        try:
            first_arg = str(args[0]) if args else ""
            if ".map" in first_arg and "404" in str(args):
                return
            super().log_message(format, *args)
        except Exception:
            pass


class ThreadedSPAHTTPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = True

    def handle_error(self, request, client_address):
        exc_type, _, _ = sys.exc_info()
        if exc_type and issubclass(exc_type, (ConnectionResetError, ConnectionAbortedError, BrokenPipeError, ValueError)):
            # Normal client-side navigation / refresh abort or bad protocol header — ignore quietly
            return
        super().handle_error(request, client_address)


def get_active_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(0.5)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        if not ip.startswith(("127.", "169.254.")):
            return ip
    except Exception:
        pass
    try:
        hostname = socket.gethostname()
        for ip in socket.gethostbyname_ex(hostname)[2]:
            if not ip.startswith(("127.", "169.254.")):
                return ip
    except Exception:
        pass
    return "127.0.0.1"


if __name__ == "__main__":
    if not os.path.exists(WEB_DIR):
        print(f"[ERROR] Web build directory not found: {WEB_DIR}")
        sys.exit(1)
    
    active_ip = get_active_ip()
    print("==================================================================")
    print(" SupplyChainX Multi-Device Web Server (SPA Mode)")
    print(f" Localhost:              http://127.0.0.1:{PORT}")
    print(f" Other Devices On Wi-Fi: http://{active_ip}:{PORT}")
    print(f" Backend API Endpoint:   http://{active_ip}:8000/api/v1")
    print(f" Directory:              {WEB_DIR}")
    print("==================================================================")
    
    with ThreadedSPAHTTPServer(("0.0.0.0", PORT), SPAServer) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")


