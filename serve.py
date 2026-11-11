import http.server
import socketserver
import os
import io
import zipfile

PORT = 9000
SHARE_DIR = "/home/skull/Desktop/domino"

class ForceDownloadHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self._zip_path = None
        super().__init__(*args, directory=SHARE_DIR, **kwargs)

    def end_headers(self):
        if self.path != '/' and not self.path.endswith('/') and not self.path.startswith('/zip'):
            filename = os.path.basename(self.path)
            self.send_header("Content-Disposition", f"attachment; filename=\"{filename}\"")
        super().end_headers()

    def list_directory(self, path):
        listing = super().list_directory(path)
        if listing is None:
            return None
        html = listing.read().decode('utf-8')
        # Absolute ZIP link for the folder currently being viewed
        rel = os.path.relpath(path, SHARE_DIR)
        if rel == '.' or rel.startswith('..'):
            zip_href = '/zip/'
        else:
            zip_href = '/zip/' + rel.replace(os.sep, '/') + '/'
        zip_link = (f'<h2 style="text-align:center">'
                    f'<a href="{zip_href}" style="font-size:18px;color:#2E7D32;text-decoration:none">'
                    f'&#128229; Download this folder as ZIP</a></h2>')
        html = html.replace('<hr>', zip_link + '<hr>', 1)
        listing = io.BytesIO(html.encode('utf-8'))
        listing.seek(0)
        return listing

    def send_head(self):
        if self.path.startswith('/zip'):
            return self._zip_head()
        return super().send_head()

    def _zip_head(self):
        rel = self.path[len('/zip'):]
        if rel.startswith('/'):
            rel = rel[1:]
        src = os.path.normpath(os.path.join(SHARE_DIR, rel))
        if not os.path.isdir(src):
            self.send_error(404, "Folder not found")
            return None

        buf = io.BytesIO()
        with zipfile.ZipFile(buf, 'w', zipfile.ZIP_DEFLATED) as zf:
            folder_name = os.path.basename(os.path.normpath(src))
            for root, dirs, files in os.walk(src):
                dirs.sort(); files.sort()
                for f in files:
                    full = os.path.join(root, f)
                    arc = os.path.join(folder_name, os.path.relpath(full, src))
                    try:
                        zf.write(full, arc)
                    except ValueError:
                        # File has a pre-1980 mtime (e.g. from an APK) — ZIP can't
                        # store it, so write with a safe fixed timestamp.
                        zinfo = zipfile.ZipInfo(arc, (2020, 1, 1, 0, 0, 0))
                        with open(full, 'rb') as fp:
                            data = fp.read()
                        zf.writestr(zinfo, data)

        data = buf.getvalue()
        self._zip_path = None
        self.send_response(200)
        self.send_header("Content-type", "application/zip")
        self.send_header("Content-Disposition",
                         f"attachment; filename=\"{folder_name}.zip\"")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Last-Modified", self.date_time_string())
        self.end_headers()
        self._zip_data = data
        return io.BytesIO(data)

class ReusableTCPServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

with ReusableTCPServer(("", PORT), ForceDownloadHandler) as httpd:
    print(f"Serving {SHARE_DIR} on port {PORT}")
    httpd.serve_forever()
