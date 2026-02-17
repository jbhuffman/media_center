import json
import os
import time
import urllib.request
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

EXPECTED = os.getenv("EXPECTED_ORG", "").strip().lower()
DISALLOWED = os.getenv("DISALLOWED_ORG", "").strip().lower()

IPINFO_URL = os.getenv("IPINFO_URL", "https://ipinfo.io/json").strip()
IPINFO_TOKEN = os.getenv("IPINFO_TOKEN", "").strip()
TIMEOUT = float(os.getenv("IPINFO_TIMEOUT", "4.0"))

# Cache to avoid rate limits (seconds)
CACHE_TTL = int(os.getenv("CACHE_TTL", "600"))  # 10 minutes default

# Optional fallback for org lookup if ipinfo is rate-limiting
FALLBACK_URL = os.getenv("FALLBACK_URL", "https://ip-api.com/json").strip()

_cache = {
    "ts": 0.0,
    "payload": None,     # last payload we served
    "source": None,      # "ipinfo" or "fallback"
}

def _http_json(url: str) -> tuple[int, dict]:
    req = urllib.request.Request(url, headers={"User-Agent": "vpn-leak-check"})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
        code = getattr(resp, "status", 200)
        data = json.loads(resp.read().decode("utf-8"))
        return code, data

def fetch_ipinfo() -> dict:
    url = IPINFO_URL
    if IPINFO_TOKEN:
        parts = urllib.parse.urlsplit(url)
        q = urllib.parse.parse_qs(parts.query)
        q["token"] = [IPINFO_TOKEN]
        new_query = urllib.parse.urlencode(q, doseq=True)
        url = urllib.parse.urlunsplit((parts.scheme, parts.netloc, parts.path, new_query, parts.fragment))
    code, data = _http_json(url)
    if code == 429:
        raise RuntimeError("ipinfo rate limited (429)")
    return data

def fetch_fallback() -> dict:
    code, data = _http_json(FALLBACK_URL)
    if code == 429:
        raise RuntimeError("fallback rate limited (429)")
    return data

def normalize(info: dict, source: str) -> tuple[str, str]:
    # ipinfo: { ip, org }
    if source == "ipinfo":
        return str(info.get("ip", "")), str(info.get("org", ""))

    # ip-api: { query, org, as }
    # org is sometimes empty; "as" is often like "AS12345 SomeName"
    ip = str(info.get("query", "")) or str(info.get("ip", ""))
    org = str(info.get("org", "")) or str(info.get("as", ""))
    return ip, org

def build_payload(ip: str, org: str, source: str, warning: str | None = None) -> dict:
    org_l = org.lower()

    if DISALLOWED and DISALLOWED in org_l:
        ok = False
        reason = "disallowed_org_detected"
    elif EXPECTED:
        ok = EXPECTED in org_l
        reason = "expected_org_match" if ok else "expected_org_not_found"
    else:
        ok = True
        reason = "no_expected_org_configured"

    payload = {
        "ok": ok,
        "ip": ip,
        "org": org,
        "expected_org_substring": EXPECTED,
        "disallowed_org_substring": DISALLOWED,
        "source": source,
        "reason": reason,
    }
    if warning:
        payload["warning"] = warning
    return payload

def get_payload() -> dict:
    now = time.time()
    if _cache["payload"] and (now - _cache["ts"]) < CACHE_TTL:
        return _cache["payload"]

    # Try ipinfo first
    try:
        info = fetch_ipinfo()
        ip, org = normalize(info, "ipinfo")
        payload = build_payload(ip, org, "ipinfo")
        _cache["ts"] = now
        _cache["payload"] = payload
        _cache["source"] = "ipinfo"
        return payload
    except Exception as e_ipinfo:
        # If we have cached data, serve it with a warning rather than failing hard
        if _cache["payload"]:
            cached = dict(_cache["payload"])
            cached["warning"] = f"ipinfo_unavailable: {e_ipinfo}"
            return cached

        # No cache yet, try fallback
        try:
            info = fetch_fallback()
            ip, org = normalize(info, "fallback")
            payload = build_payload(ip, org, "fallback", warning=f"ipinfo_unavailable: {e_ipinfo}")
            _cache["ts"] = now
            _cache["payload"] = payload
            _cache["source"] = "fallback"
            return payload
        except Exception as e_fb:
            raise RuntimeError(f"ipinfo failed ({e_ipinfo}); fallback failed ({e_fb})")

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            payload = get_payload()
            body = (json.dumps(payload) + "\n").encode("utf-8")
            # Always 200 if the service handled the request; encode VPN status in JSON
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", f"max-age={CACHE_TTL}")
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
