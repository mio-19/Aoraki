#!/usr/bin/env python3
"""
AsteroidOS YouTube Music Stream Resolver Daemon (asteroid-ytmusicd)
Provides local HTTP REST API and 302 stream redirection for standalone
YouTube Music audio streaming on smartwatches.
"""

import http.server
import json
import logging
import os
import re
import socketserver
import sys
import threading
import time
import urllib.parse

try:
    import yt_dlp
except ImportError:
    yt_dlp = None

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s: %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger("asteroid-ytmusicd")

PORT = int(os.environ.get("YTMUSICD_PORT", "8082"))
HOST = os.environ.get("YTMUSICD_HOST", "127.0.0.1")

# Curated high-fidelity YouTube Music stations with real YouTube IDs
DEFAULT_STATIONS = [
    {
        "id": "rFZHOHl-L8A",
        "title": "Lofi Beats Chillout",
        "artist": "Lofi Girl",
        "genre": "Lofi / Relax",
        "thumbnail": "https://i.ytimg.com/vi/rFZHOHl-L8A/hqdefault.jpg"
    },
    {
        "id": "4xDzrJKXOOY",
        "title": "Synthwave Sunset Run",
        "artist": "Lofi Records",
        "genre": "Synthwave / Retro",
        "thumbnail": "https://i.ytimg.com/vi/4xDzrJKXOOY/hqdefault.jpg"
    },
    {
        "id": "kJQP7kiw5Fk",
        "title": "Global Top Hits Live",
        "artist": "Luis Fonsi",
        "genre": "Pop / Hits",
        "thumbnail": "https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg"
    },
    {
        "id": "dQw4w9WgXcQ",
        "title": "Classics Reimagined",
        "artist": "Rick Astley",
        "genre": "Pop / Retro",
        "thumbnail": "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg"
    },
    {
        "id": "u_mbp7-6UAE",
        "title": "Coffeehouse Acoustic",
        "artist": "Acoustic Sessions",
        "genre": "Acoustic / Warm",
        "thumbnail": "https://i.ytimg.com/vi/u_mbp7-6UAE/hqdefault.jpg"
    }
]

# Cache format: { video_id: { "url": str, "title": str, "artist": str, "thumbnail": str, "expires": float } }
STREAM_CACHE = {}
CACHE_LOCK = threading.Lock()
CACHE_TTL = 3.5 * 3600  # 3.5 hours (YouTube googlevideo URLs expire after 6 hours)


def resolve_stream_url(video_id_or_url):
    """Resolve YouTube Music video ID or URL to a direct streaming URL using yt_dlp."""
    if not video_id_or_url:
        return None

    # Sanitize video ID
    match = re.search(r"([a-zA-Z0-9_-]{11})", video_id_or_url)
    video_id = match.group(1) if match else video_id_or_url

    now = time.time()
    with CACHE_LOCK:
        if video_id in STREAM_CACHE:
            cached = STREAM_CACHE[video_id]
            if cached.get("expires", 0) > now:
                logger.info("Serving %s from in-memory cache", video_id)
                return cached

    if yt_dlp is None:
        logger.error("yt_dlp library is not installed")
        return None

    url = f"https://music.youtube.com/watch?v={video_id}"
    ydl_opts = {
        "format": "ba/b",
        "quiet": True,
        "no_warnings": True,
        "extract_flat": False,
        "socket_timeout": 10,
    }

    try:
        logger.info("Resolving YouTube Music stream for %s ...", video_id)
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            stream_url = info.get("url")
            title = info.get("title", "Unknown Track")
            artist = info.get("uploader") or info.get("channel", "YouTube Music")
            thumbnail = info.get("thumbnail") or f"https://i.ytimg.com/vi/{video_id}/hqdefault.jpg"

            if stream_url:
                data = {
                    "id": video_id,
                    "url": stream_url,
                    "title": title,
                    "artist": artist,
                    "thumbnail": thumbnail,
                    "expires": now + CACHE_TTL,
                }
                with CACHE_LOCK:
                    STREAM_CACHE[video_id] = data
                logger.info("Successfully resolved %s -> '%s'", video_id, title)
                return data
            else:
                logger.warning("No stream URL found in metadata for %s", video_id)
                return None
    except Exception as exc:
        logger.error("Failed to extract YouTube Music stream for %s: %s", video_id, exc)
        return None


class StreamResolverHandler(http.server.BaseHTTPRequestHandler):
    def send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()

    def do_HEAD(self):
        self._handle_request(is_head=True)

    def do_GET(self):
        self._handle_request(is_head=False)

    def _handle_request(self, is_head=False):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        query = urllib.parse.parse_qs(parsed.query)

        if path in ("/health", "/status"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            if not is_head:
                payload = json.dumps({"status": "ok", "service": "asteroid-ytmusicd"}).encode()
                self.wfile.write(payload)
            return

        if path in ("/api/stations", "/api/playlists"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_cors_headers()
            self.end_headers()
            if not is_head:
                stations = []
                for s in DEFAULT_STATIONS:
                    item = dict(s)
                    item["streamUrl"] = f"http://127.0.0.1:{PORT}/stream?id={s['id']}"
                    stations.append(item)
                payload = json.dumps({"stations": stations}).encode()
                self.wfile.write(payload)
            return

        if path == "/stream":
            video_id = query.get("id", [None])[0] or query.get("v", [None])[0]
            if not video_id:
                self.send_error(400, "Missing required parameter 'id'")
                return

            res = resolve_stream_url(video_id)
            if res and res.get("url"):
                self.send_response(302)
                self.send_header("Location", res["url"])
                self.send_header("Cache-Control", "public, max-age=7200")
                self.send_cors_headers()
                self.end_headers()
                return
            else:
                self.send_error(502, f"Could not extract streaming URL for {video_id}")
                return

        if path == "/resolve":
            video_id = query.get("id", [None])[0] or query.get("v", [None])[0]
            if not video_id:
                self.send_error(400, "Missing required parameter 'id'")
                return

            res = resolve_stream_url(video_id)
            if res:
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_cors_headers()
                self.end_headers()
                if not is_head:
                    self.wfile.write(json.dumps(res).encode())
                return
            else:
                self.send_error(502, f"Could not extract streaming URL for {video_id}")
                return

        if path == "/search":
            q = query.get("q", [""])[0]
            if not q or not yt_dlp:
                self.send_error(400, "Missing query parameter 'q'")
                return

            ydl_opts = {
                "format": "ba/b",
                "quiet": True,
                "no_warnings": True,
                "extract_flat": True,
                "socket_timeout": 8,
            }
            try:
                with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                    res = ydl.extract_info(f"ytsearch3:{q}", download=False)
                    entries = res.get("entries", [])
                    results = []
                    for e in entries:
                        vid = e.get("id")
                        results.append({
                            "id": vid,
                            "title": e.get("title", "Unknown"),
                            "artist": e.get("uploader", "YouTube Music"),
                            "thumbnail": f"https://i.ytimg.com/vi/{vid}/hqdefault.jpg",
                            "streamUrl": f"http://127.0.0.1:{PORT}/stream?id={vid}",
                        })
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.send_cors_headers()
                    self.end_headers()
                    if not is_head:
                        self.wfile.write(json.dumps({"results": results}).encode())
                return
            except Exception as exc:
                self.send_error(500, f"Search failed: {exc}")
                return

        self.send_error(404, "Endpoint not found")

    def log_message(self, format, *args):
        # Override default noisy stderr logging with clean logger output
        logger.info("%s - %s", self.address_string(), format % args)


class ThreadedHTTPServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    allow_reuse_address = True
    daemon_threads = True


def main():
    logger.info("Starting asteroid-ytmusicd on %s:%d ...", HOST, PORT)
    server = ThreadedHTTPServer((HOST, PORT), StreamResolverHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Stopping asteroid-ytmusicd ...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
