#'PY'
import json
import os
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

EXPECTED = os.getenv("EXPECTED_ORG", "").strip().lower()
URL = os.getenv("IPINFO_URL", "https://ipinfo.io/json")
TIMEOUT = float(os.getenv("IPINFO_TIMEOUT", "4.0"))

def fetch_ipinfo():
    req = urllib.request.Request(URL, headers={"User-Agent": "vpn-leak-check"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        return json.loads(resp.read().decode("utf-8"))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            info = fetch_ipinfo()
            org = str(info.get("org", ""))
            ip = str(info.get("ip", ""))
            ok = True
            if EXPECTED:
                ok = EXPECTED in org.lower()

            payload = {"ok": ok, "ip": ip, "org": org, "expected_org_substring": EXPECTED}
            body = (json.dumps(payload) + "\n").encode("utf-8")

            self.send_response(200 if ok else 500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except Exception as e:
            body = (json.dumps({"ok": False, "error": str(e)}) + "\n").encode("utf-8")
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, fmt, *args):
        return

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8090"))
    HTTPServer(("0.0.0.0", port), Handler).serve_forever()
#PY