"""Mock MangaDex API untuk uji UI tanpa jaringan asli.

Jalankan:
    python tools/mock_mangadex.py 8099
Lalu build web dengan base URL mock:
    flutter build web --release --dart-define=MANGADEX_BASE_URL=http://127.0.0.1:8099
"""

import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse

COVERS = [
    "https://picsum.photos/seed/isekaiku1/400/600",
    "https://picsum.photos/seed/isekaiku2/400/600",
    "https://picsum.photos/seed/isekaiku3/400/600",
    "https://picsum.photos/seed/isekaiku4/400/600",
    "https://picsum.photos/seed/isekaiku5/400/600",
    "https://picsum.photos/seed/isekaiku6/400/600",
    "https://picsum.photos/seed/isekaiku7/400/600",
    "https://picsum.photos/seed/isekaiku8/400/600",
    "https://picsum.photos/seed/isekaiku9/400/600",
]

TITLES = [
    "Isekai Ku Baca Manga",
    "Petualangan di Dunia Lain",
    "Kembali ke Masa Lalu",
    "Sekai no Hajimari",
    "Ksatria Terakhir",
    "Rahasia Pulau Utara",
    "Dunia Kedua",
    "Jejak Sang Pahlawan",
    "Langit Kedua",
]


def manga_payload():
    data = []
    for index, title in enumerate(TITLES):
        data.append(
            {
                "id": f"manga-{index}",
                "type": "manga",
                "attributes": {
                    "title": {"id": title, "en": title},
                    "description": {
                        "id": "Deskripsi contoh untuk menguji tata letak "
                        "halaman detail di aplikasi Isekaiku."
                    },
                    "year": 2024,
                    "contentRating": "safe",
                    "status": "ongoing" if index % 3 else "completed",
                    "originalLanguage": "ja",
                    "follows": 120000 - index * 7000,
                    "tags": [
                        {"attributes": {"name": {"id": "Fantasi"}}},
                        {"attributes": {"name": {"id": "Aksi"}}},
                    ],
                },
                "relationships": [
                    {"type": "author", "attributes": {"name": "KineticPlasma"}},
                    {
                        "type": "cover_art",
                        "attributes": {"fileName": COVERS[index]},
                    },
                ],
            }
        )
    return {"result": "ok", "response": "collection", "data": data}


def chapter_payload():
    data = []
    for number in range(1, 13):
        data.append(
            {
                "id": f"chapter-{number}",
                "type": "chapter",
                "attributes": {
                    "title": f"Pertemuan ke-{number}",
                    "chapter": str(number),
                    "volume": str((number - 1) // 6 + 1),
                    "translatedLanguage": "id" if number % 2 else "en",
                    "pages": 18,
                    "publishAt": "2024-05-01T00:00:00+00:00",
                },
            }
        )
    return {"result": "ok", "data": data}


class Handler(BaseHTTPRequestHandler):
    def _send(self, payload, status=200):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802
        path = urlparse(self.path).path
        if path == "/manga":
            self._send(manga_payload())
        elif path.startswith("/manga/") and path.endswith("/feed"):
            self._send(chapter_payload())
        elif path.startswith("/manga/"):
            manga_id = path.split("/")[-1]
            data = manga_payload()["data"]
            found = next((m for m in data if m["id"] == manga_id), data[0])
            self._send({"result": "ok", "data": found})
        elif path.startswith("/at-home/server/"):
            self._send(
                {
                    "result": "ok",
                    "baseUrl": "https://picsum.photos",
                    "chapter": {"hash": "mock", "data": [], "dataSaver": []},
                }
            )
        else:
            self._send({"result": "error", "message": "not found"}, 404)

    def log_message(self, *args):  # senyap
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8099
    print(f"Mock MangaDex berjalan di http://127.0.0.1:{port}")
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
