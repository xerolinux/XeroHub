#!/usr/bin/env python3
"""
Unofficial Chaotic-AUR Tool
A native PyQt6 GUI to enable/disable Chaotic-AUR and browse its status, deployments, packages, and team.

Key features:
- Polkit (pkexec) elevation for enable/disable actions (system auth prompt)
- Packages page uses Chaotic backend API:
  https://chaotic-backend.garudalinux.org/builder/packages?repo=true
- About Dev popup (instant open) with cached avatar/logo and clickable links
- Dark purple theme
"""

import sys
import os
import re
import json
import shutil
import tempfile
import subprocess
from datetime import datetime
from typing import Any, Dict, List, Optional

from PyQt6.QtCore import Qt, QThread, pyqtSignal, QUrl, QTimer, QSize
from PyQt6.QtGui import QColor, QPixmap, QPainter, QBrush, QLinearGradient, QDesktopServices, QPainterPath
from PyQt6.QtSvg import QSvgRenderer
from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QPushButton,
    QFrame,
    QScrollArea,
    QLineEdit,
    QTextEdit,
    QStackedWidget,
    QGridLayout,
    QSizePolicy,
    QMessageBox,
    QTableWidget,
    QTableWidgetItem,
    QHeaderView,
    QDialog,
    QDialogButtonBox,
)


DARK_PURPLE_STYLE = """
QMainWindow, QWidget { background-color: #1a1025; color: #e8e0f0; }
QLabel { color: #e8e0f0; background: transparent; }
QLabel#title { font-size: 22px; font-weight: bold; color: #c9a0ff; }
QLabel#description { font-size: 13px; color: #b8a8c8; }
QLabel#sectionTitle { font-size: 18px; font-weight: bold; color: #d4b0ff; padding: 10px 0; }
QPushButton {
    background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #6b4c9a, stop:1 #4a3570);
    color: #ffffff; border: 1px solid #7d5cad; border-radius: 8px;
    padding: 10px 20px; font-size: 13px; font-weight: bold; min-width: 100px;
}
QPushButton:hover { background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #8b6cba, stop:1 #6a5590); }
QPushButton:pressed { background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #4a3570, stop:1 #3a2560); }
QPushButton:disabled { background: #2a2035; color: #6a5a7a; border: 1px solid #3a2a4a; }
QPushButton#navButton { background: transparent; border: none; border-radius: 6px; padding: 10px 20px; text-align: left; font-weight: normal; min-width: 0px; }
QPushButton#navButton:hover { background: rgba(107, 76, 154, 0.3); }
QPushButton#navButton[active="true"] { background: rgba(107, 76, 154, 0.5); border-left: 3px solid #c9a0ff; }
QPushButton#enableButton { background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #4caf50, stop:1 #2e7d32); border: 1px solid #66bb6a; }
QPushButton#disableButton { background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #f44336, stop:1 #c62828); border: 1px solid #ef5350; }
QLineEdit { background-color: #2a1f35; color: #e8e0f0; border: 1px solid #4a3a5a; border-radius: 6px; padding: 10px 15px; font-size: 14px; }
QLineEdit:focus { border: 2px solid #7d5cad; }
QTextEdit { background-color: #2a1f35; color: #e8e0f0; border: 1px solid #4a3a5a; border-radius: 6px; padding: 10px; font-family: monospace; font-size: 12px; }
QScrollArea { background: transparent; border: none; }
QScrollBar:vertical { background: #2a1f35; width: 10px; border-radius: 5px; }
QScrollBar::handle:vertical { background: #6b4c9a; border-radius: 5px; min-height: 30px; }
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }
QFrame#card { background-color: #251830; border: 1px solid #3a2a4a; border-radius: 12px; padding: 15px; }
QFrame#separator { background-color: #3a2a4a; max-height: 1px; min-height: 1px; }
QTableWidget { background-color: #251830; color: #e8e0f0; border: 1px solid #3a2a4a; border-radius: 8px; gridline-color: #3a2a4a; }
QTableWidget::item { padding: 8px; }
QTableWidget::item:selected { background-color: rgba(107, 76, 154, 0.4); }
QHeaderView::section { background-color: #352745; color: #c9a0ff; padding: 10px; border: none; border-bottom: 2px solid #6b4c9a; font-weight: bold; }
"""

MINI_LOGO_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
<defs><linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:#c9a0ff"/><stop offset="100%" style="stop-color:#6b4c9a"/></linearGradient></defs>
<circle cx="50" cy="50" r="45" fill="url(#g1)"/><path d="M50 15 L60 35 L80 35 L65 50 L72 70 L50 58 L28 70 L35 50 L20 35 L40 35 Z" fill="#1a1025"/><circle cx="50" cy="50" r="12" fill="#c9a0ff"/></svg>'''


class PolkitWorker(QThread):
    """Execute a root shell script using pkexec (polkit)."""
    finished = pyqtSignal(bool, str)
    progress = pyqtSignal(str)

    def __init__(self, script_text: str):
        super().__init__()
        self.script_text = script_text

    def run(self):
        path = None
        try:
            pkexec = shutil.which("pkexec")
            if not pkexec:
                self.finished.emit(False, "pkexec not found. Install polkit to enable GUI authentication.")
                return

            self.progress.emit("Requesting administrator authentication (polkit)...")

            fd, path = tempfile.mkstemp(prefix="chaotic-aur-", suffix=".sh")
            os.close(fd)
            with open(path, "w", encoding="utf-8") as f:
                f.write(self.script_text)

            os.chmod(path, 0o755)

            proc = subprocess.run([pkexec, "/bin/bash", path], capture_output=True, text=True)
            out = (proc.stdout or "").strip()
            err = (proc.stderr or "").strip()

            if proc.returncode == 0:
                self.finished.emit(True, out if out else "Operation completed successfully.")
            else:
                self.finished.emit(False, err if err else (out if out else f"Operation failed (exit code {proc.returncode})."))
        except Exception as e:
            self.finished.emit(False, str(e))
        finally:
            try:
                if path and os.path.exists(path):
                    os.remove(path)
            except Exception:
                pass


class FetchWorker(QThread):
    """Fetch bytes over HTTPS (for SVG/logo and simple assets)."""
    finished = pyqtSignal(bytes)
    error = pyqtSignal(str)

    def __init__(self, url: str, timeout: int = 30):
        super().__init__()
        self.url = url
        self.timeout = timeout

    def run(self):
        try:
            import urllib.request
            import ssl

            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE

            req = urllib.request.Request(self.url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, context=ctx, timeout=self.timeout) as r:
                self.finished.emit(r.read())
        except Exception as e:
            self.error.emit(str(e))


class PackagesApiWorker(QThread):
    """Fetch packages from Chaotic backend API."""
    finished = pyqtSignal(list)
    error = pyqtSignal(str)
    progress = pyqtSignal(str)

    API_URL = "https://chaotic-backend.garudalinux.org/builder/packages?repo=true"

    def run(self):
        try:
            import urllib.request
            import ssl

            self.progress.emit("Connecting to packages API...")

            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE

            req = urllib.request.Request(self.API_URL, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, context=ctx, timeout=30) as r:
                raw = r.read().decode("utf-8", errors="ignore")

            self.progress.emit("Parsing package data...")
            payload = json.loads(raw)
            items = self._extract_items(payload)

            normalized: List[Dict[str, Any]] = []
            for it in items:
                if not isinstance(it, dict):
                    normalized.append({"name": str(it), "version": "", "arch": "", "repo": "true", "file": str(it)})
                    continue

                name = (it.get("pkgname") or it.get("name") or it.get("package") or it.get("pkg") or it.get("pkg_name") or "")
                version = (it.get("pkgver") or it.get("version") or it.get("pkg_version") or it.get("ver") or "")
                arch = (it.get("arch") or it.get("architecture") or it.get("pkgarch") or "")
                repo = it.get("repo")
                if isinstance(repo, bool):
                    repo = "true" if repo else "false"
                repo = (repo or it.get("repository") or it.get("repo_name") or "true")

                file_ = (it.get("filename") or it.get("file") or it.get("pkgfile") or it.get("pkg_file") or "")
                if not file_:
                    file_ = f"{name}-{version}" if name and version else (name or "(unknown)")

                normalized.append({"name": str(name), "version": str(version), "arch": str(arch), "repo": str(repo), "file": str(file_)})

            normalized.sort(key=lambda x: (x.get("name") or x.get("file") or "").lower())
            self.finished.emit(normalized)
        except Exception as e:
            self.error.emit(str(e))

    @staticmethod
    def _extract_items(payload: Any) -> List[Any]:
        if isinstance(payload, list):
            return payload
        if isinstance(payload, dict):
            for key in ("packages", "data", "result", "items"):
                if key in payload and isinstance(payload[key], list):
                    return payload[key]
            if payload and all(isinstance(v, dict) for v in payload.values()):
                out = []
                for k, v in payload.items():
                    if isinstance(v, dict) and not (v.get("name") or v.get("pkgname")):
                        vv = dict(v)
                        vv["name"] = k
                        out.append(vv)
                    else:
                        out.append(v)
                return out
        return [payload]


class GitLabWorker(QThread):
    finished = pyqtSignal(list)
    error = pyqtSignal(str)

    def run(self):
        try:
            import urllib.request
            import ssl

            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE

            url = "https://gitlab.com/api/v4/projects/chaotic-aur%2Fpkgbuilds/pipelines?per_page=20"
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, context=ctx, timeout=30) as r:
                self.finished.emit(json.loads(r.read()))
        except Exception as e:
            self.error.emit(str(e))


class StatusIndicator(QWidget):
    def __init__(self):
        super().__init__()
        l = QHBoxLayout(self)
        l.setContentsMargins(0, 0, 0, 0)
        l.setSpacing(8)
        self.led = QLabel("●")
        self.led.setFixedWidth(20)
        self.text = QLabel("Checking...")
        l.addWidget(self.led)
        l.addWidget(self.text)
        l.addStretch()
        self.setFixedHeight(30)

    def set_status(self, enabled: bool):
        if enabled:
            self.led.setStyleSheet("color: #4caf50; font-size: 16px;")
            self.text.setText("Enabled")
            self.text.setStyleSheet("color: #4caf50; font-weight: bold;")
        else:
            self.led.setStyleSheet("color: #f44336; font-size: 16px;")
            self.text.setText("Disabled")
            self.text.setStyleSheet("color: #f44336; font-weight: bold;")


class LoadingSpinner(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.angle = 0
        self.timer = QTimer(self)
        self.timer.timeout.connect(self._rot)
        self.setFixedSize(40, 40)
        self.hide()

    def start(self):
        self.timer.start(50)
        self.show()

    def stop(self):
        self.timer.stop()
        self.hide()

    def _rot(self):
        self.angle = (self.angle + 10) % 360
        self.update()

    def paintEvent(self, _e):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        p.translate(20, 20)
        p.rotate(self.angle)
        g = QLinearGradient(-15, -15, 15, 15)
        g.setColorAt(0, QColor("#6b4c9a"))
        g.setColorAt(1, QColor("#c9a0ff"))
        p.setPen(Qt.PenStyle.NoPen)
        p.setBrush(QBrush(g))
        for i in range(8):
            p.rotate(45)
            p.setOpacity((i + 1) / 8)
            p.drawEllipse(-3, -15, 6, 6)


class HomePage(QWidget):
    def __init__(self):
        super().__init__()
        self.svg_data: Optional[bytes] = None
        self._avatar_pix: Optional[QPixmap] = None
        self._avatar_worker: Optional[FetchWorker] = None
        self.setup_ui()

    def setup_ui(self):
        l = QVBoxLayout(self)
        l.setSpacing(10)
        l.setContentsMargins(25, 20, 25, 20)

        top = QHBoxLayout()
        top.setSpacing(12)

        self.mini = QLabel()
        self.mini.setFixedSize(36, 36)
        self._set_mini_logo()
        top.addWidget(self.mini)

        tl = QVBoxLayout()
        tl.setSpacing(3)

        title = QLabel("Unofficial Chaotic-AUR Tool")
        title.setObjectName("title")

        desc = QLabel(
            "The Chaotic-AUR is an unofficial package repository that provides pre-built packages from the Arch User Repository (AUR), "
            "allowing users to install software without needing to compile it themselves. It automates the building of AUR packages, "
            "but users should verify the packages for safety since it is not an officially supervised repository."
        )
        desc.setObjectName("description")
        desc.setWordWrap(True)

        tl.addWidget(title)
        tl.addWidget(desc)
        top.addLayout(tl, 1)

        self.status = StatusIndicator()
        top.addWidget(self.status)

        l.addLayout(top)

        sep = QFrame()
        sep.setObjectName("separator")
        sep.setFrameShape(QFrame.Shape.HLine)
        l.addWidget(sep)

        self.logo = QLabel()
        self.logo.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.logo.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Preferred)
        self.logo.setMinimumHeight(260)
        self.logo.setMaximumHeight(420)
        l.addWidget(self.logo, 1)

        bl = QHBoxLayout()
        bl.setSpacing(15)
        bl.addStretch()

        self.en_btn = QPushButton("Enable Chaotic-AUR")
        self.en_btn.setObjectName("enableButton")
        self.en_btn.clicked.connect(self.enable)

        self.dis_btn = QPushButton("Disable Chaotic-AUR")
        self.dis_btn.setObjectName("disableButton")
        self.dis_btn.clicked.connect(self.disable)

        self.about_btn = QPushButton("About Dev")
        self.about_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.about_btn.clicked.connect(self.show_about_dev)

        bl.addWidget(self.en_btn)
        bl.addWidget(self.dis_btn)
        bl.addWidget(self.about_btn)
        bl.addStretch()
        l.addLayout(bl)

        self.prog = QLabel("")
        self.prog.setStyleSheet("color: #a090b0;")
        self.prog.setAlignment(Qt.AlignmentFlag.AlignCenter)
        l.addWidget(self.prog)

        self.out = QTextEdit()
        self.out.setReadOnly(True)
        self.out.setMaximumHeight(110)
        self.out.setText("Waiting For User Action...")
        l.addWidget(self.out)

        self._load_logo()
        self._prefetch_avatar()

    def _set_mini_logo(self):
        try:
            r = QSvgRenderer(MINI_LOGO_SVG.encode())
            pm = QPixmap(36, 36)
            pm.fill(Qt.GlobalColor.transparent)
            p = QPainter(pm)
            r.render(p)
            p.end()
            self.mini.setPixmap(pm)
        except Exception:
            self.mini.setText("⭐")

    def _load_logo(self):
        self.logo.setText("Loading...")
        self.logo.setStyleSheet("font-size: 24px; color: #6b4c9a;")
        self.lw = FetchWorker("https://aur.chaotic.cx/assets/logo.svg")
        self.lw.finished.connect(self._on_logo)
        self.lw.error.connect(lambda _e: self.logo.setText("Chaotic-AUR"))
        self.lw.start()

    def _on_logo(self, data: bytes):
        try:
            self.svg_data = data
            self._resize_logo()
            self.logo.resizeEvent = lambda _e: self._resize_logo()
        except Exception:
            self.logo.setText("Chaotic-AUR")

    def _resize_logo(self):
        if not self.svg_data:
            return
        try:
            r = QSvgRenderer(self.svg_data)
            if not r.isValid():
                return
            aw = max(self.logo.width() - 20, 400)
            ah = max(self.logo.height() - 20, 200)
            sz = r.defaultSize()
            if sz.width() <= 0 or sz.height() <= 0:
                return
            asp = sz.width() / sz.height()
            if aw / asp <= ah:
                w, h = aw, int(aw / asp)
            else:
                w, h = int(ah * asp), ah
            pm = QPixmap(w, h)
            pm.fill(Qt.GlobalColor.transparent)
            p = QPainter(pm)
            r.render(p)
            p.end()
            self.logo.setPixmap(pm)
        except Exception:
            pass

    def _prefetch_avatar(self):
        if self._avatar_worker is not None:
            return
        url = "https://i.imgur.com/5EEl7bB.png"
        self._avatar_worker = FetchWorker(url, timeout=25)
        self._avatar_worker.finished.connect(self._on_avatar)
        self._avatar_worker.error.connect(lambda _e: None)
        self._avatar_worker.start()

    def _on_avatar(self, data: bytes):
        try:
            pix = QPixmap()
            if pix.loadFromData(data):
                pix = pix.scaled(140, 140, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
                self._avatar_pix = pix
        except Exception:
            pass

    def check(self):
        try:
            r = subprocess.run(["grep", "-q", r"\[chaotic-aur\]", "/etc/pacman.conf"], capture_output=True)
            enabled = r.returncode == 0
            self.status.set_status(enabled)
            self.en_btn.setEnabled(not enabled)
            self.dis_btn.setEnabled(enabled)
        except Exception:
            self.status.set_status(False)
            self.en_btn.setEnabled(True)
            self.dis_btn.setEnabled(False)

    def enable(self):
        script = r"""#!/usr/bin/env bash
set -euo pipefail

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

if ! grep -qE '^[[:space:]]*\[chaotic-aur\][[:space:]]*$' /etc/pacman.conf; then
  printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> /etc/pacman.conf
fi

pacman -Sy --noconfirm || true
"""
        self._run_polkit(script, "Enabling...")

    def disable(self):
        script = r"""#!/usr/bin/env bash
set -euo pipefail

cp /etc/pacman.conf "/etc/pacman.conf.bak.$(date +%s)"

tmp="$(mktemp)"
awk '
  BEGIN { skip=0 }
  /^[[:space:]]*\[chaotic-aur\][[:space:]]*$/ { skip=1; next }
  skip && /^[[:space:]]*\[[^\]]+\][[:space:]]*$/ { skip=0 }
  skip { next }
  { print }
' /etc/pacman.conf | sed -E '/^[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman\.d\/chaotic-mirrorlist[[:space:]]*$/d' > "$tmp"
cat "$tmp" > /etc/pacman.conf
rm -f "$tmp"

pacman -Rns --noconfirm chaotic-keyring chaotic-mirrorlist || true
pacman-key --delete 3056513887B78AEB || true
pacman -Sy --noconfirm || true
"""
        self._run_polkit(script, "Disabling...")

    def _run_polkit(self, script_text: str, msg: str):
        self.en_btn.setEnabled(False)
        self.dis_btn.setEnabled(False)
        self.about_btn.setEnabled(False)
        self.prog.setText(msg)
        self.out.append(msg)

        self.worker = PolkitWorker(script_text)
        self.worker.progress.connect(lambda m: self.out.append(m))
        self.worker.finished.connect(self._done)
        self.worker.start()

    def _done(self, ok: bool, msg: str):
        self.prog.setText(msg)
        self.out.append(msg)
        self.about_btn.setEnabled(True)
        self.check()
        if ok:
            QMessageBox.information(self, "Done", msg)
        else:
            QMessageBox.warning(self, "Error", msg)

    def show_about_dev(self):
        dlg = QDialog(self)
        dlg.setWindowTitle("About Dev")
        dlg.setModal(True)

        layout = QVBoxLayout(dlg)
        layout.setContentsMargins(22, 18, 22, 18)
        layout.setSpacing(12)

        title = QLabel("DarkXero")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setStyleSheet("font-size: 54px; font-weight: 900; color: #c9a0ff;")
        layout.addWidget(title)

        avatar = QLabel()
        avatar.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(avatar)

        if self._avatar_pix is not None:
            avatar.setPixmap(self._avatar_pix)
        else:
            avatar.setText("⏳ Loading avatar...")
            avatar.setStyleSheet("color: #a090b0; font-size: 12px;")
            self._prefetch_avatar()

        info = QLabel(
            '<div style="text-align:center; font-size: 13px; color: #e8e0f0;">'
            '🏠 <b>Homepage</b>: <a style="color:#c9a0ff; text-decoration:none;" href="https://xerolinux.xyz">https://xerolinux.xyz</a><br>'
            '☕ <b>Donate</b>: <a style="color:#c9a0ff; text-decoration:none;" href="https://ko-fi.com/xerolinux">https://ko-fi.com/xerolinux</a><br>'
            '💬 <b>Discord</b>: <a style="color:#c9a0ff; text-decoration:none;" href="https://discord.xerolinux.xyz">https://discord.xerolinux.xyz</a><br>'
            '🐘 <b>Fosstodon</b>: <a style="color:#c9a0ff; text-decoration:none;" href="https://fosstodon.org/@XeroLinux">https://fosstodon.org/@XeroLinux</a><br>'
            '📺 <b>YouTube</b>: <a style="color:#c9a0ff; text-decoration:none;" href="https://youtube.com/@XeroLinux">https://youtube.com/@XeroLinux</a>'
            '</div>'
        )
        info.setTextFormat(Qt.TextFormat.RichText)
        info.setAlignment(Qt.AlignmentFlag.AlignCenter)
        info.setOpenExternalLinks(True)
        info.setWordWrap(True)
        layout.addWidget(info)

        buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Ok)
        buttons.accepted.connect(dlg.accept)
        layout.addWidget(buttons)

        dlg.setStyleSheet("""
            QDialog { background-color: #1a1025; }
            QDialogButtonBox QPushButton {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #6b4c9a, stop:1 #4a3570);
                color: #ffffff; border: 1px solid #7d5cad; border-radius: 8px;
                padding: 8px 18px; font-size: 13px; font-weight: bold; min-width: 90px;
            }
            QDialogButtonBox QPushButton:hover {
                background: qlineargradient(x1:0, y1:0, x2:0, y2:1, stop:0 #8b6cba, stop:1 #6a5590);
            }
        """)
        dlg.resize(560, 360)
        dlg.exec()


class StatusPage(QWidget):
    def __init__(self):
        super().__init__()
        self.setup_ui()

    def setup_ui(self):
        l = QVBoxLayout(self)
        l.setSpacing(15)
        l.setContentsMargins(25, 20, 25, 20)
        l.addWidget(QLabel("Build Status", objectName="sectionTitle"))
        l.addWidget(QLabel("Recent GitLab CI pipelines for Chaotic-AUR builds."))

        b = QPushButton("Refresh")
        b.setFixedWidth(120)
        b.clicked.connect(self.load)
        l.addWidget(b)

        self.spin = LoadingSpinner()
        l.addWidget(self.spin, alignment=Qt.AlignmentFlag.AlignCenter)

        self.tbl = QTableWidget()
        self.tbl.setColumnCount(5)
        self.tbl.setHorizontalHeaderLabels(["ID", "Status", "Branch", "Created", "Duration"])
        self.tbl.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        l.addWidget(self.tbl)

    def load(self):
        self.spin.start()
        self.tbl.setRowCount(0)
        self.w = GitLabWorker()
        self.w.finished.connect(self._done)
        self.w.error.connect(self._err)
        self.w.start()

    def _done(self, data: list):
        self.spin.stop()
        self.tbl.setRowCount(len(data))
        for i, p in enumerate(data):
            self.tbl.setItem(i, 0, QTableWidgetItem(str(p.get("id", ""))))

            st = p.get("status", "")
            si = QTableWidgetItem(st.upper())
            si.setForeground(QColor({"success": "#4caf50", "failed": "#f44336", "running": "#2196f3"}.get(st, "#e8e0f0")))
            self.tbl.setItem(i, 1, si)
            self.tbl.setItem(i, 2, QTableWidgetItem(p.get("ref", "")))

            cr = p.get("created_at", "")
            try:
                cr = datetime.fromisoformat(cr.replace("Z", "+00:00")).strftime("%Y-%m-%d %H:%M")
            except Exception:
                pass
            self.tbl.setItem(i, 3, QTableWidgetItem(cr))

            dur = p.get("duration", 0) or 0
            self.tbl.setItem(i, 4, QTableWidgetItem(f"{dur // 60}m {dur % 60}s" if dur else ""))

    def _err(self, _e: str):
        self.spin.stop()


class DeploymentsPage(QWidget):
    def __init__(self):
        super().__init__()
        self.setup_ui()

    def setup_ui(self):
        l = QVBoxLayout(self)
        l.setSpacing(15)
        l.setContentsMargins(25, 20, 25, 20)
        l.addWidget(QLabel("Deployments & Mirrors", objectName="sectionTitle"))
        l.addWidget(QLabel("Chaotic-AUR mirrors worldwide."))

        sc = QScrollArea()
        sc.setWidgetResizable(True)
        w = QWidget()
        self.gl = QGridLayout(w)
        self.gl.setSpacing(12)
        sc.setWidget(w)
        l.addWidget(sc)

    def load(self):
        while self.gl.count():
            it = self.gl.takeAt(0)
            if it.widget():
                it.widget().deleteLater()

        mirrors = [
            ("CDN (Primary)", "Global", "cdn-mirror.chaotic.cx"),
            ("Germany", "Europe", "de-mirror.chaotic.cx"),
            ("Spain", "Europe", "es-mirror.chaotic.cx"),
            ("France", "Europe", "fr-mirror.chaotic.cx"),
            ("USA", "N. America", "us-mi-mirror.chaotic.cx"),
            ("Brazil", "S. America", "br-mirror.chaotic.cx"),
            ("India", "Asia", "in-mirror.chaotic.cx"),
            ("S. Korea", "Asia", "kr-mirror.chaotic.cx"),
            ("Singapore", "Asia", "sg-mirror.chaotic.cx"),
            ("Australia", "Oceania", "au-mirror.chaotic.cx"),
        ]

        for i, (n, loc, u) in enumerate(mirrors):
            c = QFrame()
            c.setObjectName("card")
            cl = QVBoxLayout(c)
            cl.setSpacing(4)
            cl.addWidget(QLabel(f"<b style='color:#c9a0ff'>{n}</b>"))
            cl.addWidget(QLabel(f"📍 {loc}"))
            cl.addWidget(QLabel(f"<span style='color:#888'>{u}</span>"))
            cl.addWidget(QLabel("<span style='color:#4caf50'>● Online</span>"))
            self.gl.addWidget(c, i // 2, i % 2)


class PackagesPage(QWidget):
    def __init__(self):
        super().__init__()
        self.items: List[Dict[str, Any]] = []
        self.setup_ui()

    def setup_ui(self):
        l = QVBoxLayout(self)
        l.setSpacing(12)
        l.setContentsMargins(25, 20, 25, 20)

        l.addWidget(QLabel("Packages", objectName="sectionTitle"))
        l.addWidget(QLabel(
            "Native packages list fetched from the Chaotic backend API.\n"
            "Use the search box to filter results."
        ))

        sl = QHBoxLayout()
        self.si = QLineEdit()
        self.si.setPlaceholderText("Search by package name or file...")
        self.si.textChanged.connect(self.filter)

        b = QPushButton("Refresh Package List")
        b.setFixedWidth(200)
        b.clicked.connect(self.load)

        sl.addWidget(self.si)
        sl.addWidget(b)
        l.addLayout(sl)

        self.prog = QLabel("Click 'Refresh Package List' to fetch packages from the backend API")
        self.prog.setStyleSheet("color:#a090b0;")
        l.addWidget(self.prog)

        self.spin = LoadingSpinner()
        l.addWidget(self.spin, alignment=Qt.AlignmentFlag.AlignCenter)

        self.tbl = QTableWidget()
        self.tbl.setColumnCount(5)
        self.tbl.setHorizontalHeaderLabels(["Package", "Version", "Arch", "Repo", "File"])
        self.tbl.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.tbl.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)

        self.tbl.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.tbl.horizontalHeader().setSectionResizeMode(1, QHeaderView.ResizeMode.ResizeToContents)
        self.tbl.horizontalHeader().setSectionResizeMode(2, QHeaderView.ResizeMode.ResizeToContents)
        self.tbl.horizontalHeader().setSectionResizeMode(3, QHeaderView.ResizeMode.ResizeToContents)
        self.tbl.horizontalHeader().setSectionResizeMode(4, QHeaderView.ResizeMode.Stretch)

        l.addWidget(self.tbl)

    def load(self):
        self.spin.start()
        self.tbl.setRowCount(0)
        self.items = []
        self.si.clear()
        self.prog.setText("Fetching packages...")

        self.w = PackagesApiWorker()
        self.w.progress.connect(self.prog.setText)
        self.w.finished.connect(self._done)
        self.w.error.connect(self._err)
        self.w.start()

    def _done(self, items: list):
        self.spin.stop()
        self.items = items
        self._show(self.items)
        self.prog.setText(f"Loaded {len(self.items)} packages.")

    def _err(self, e: str):
        self.spin.stop()
        self.prog.setText(f"Error: {e}")

    def _show(self, items: List[Dict[str, Any]]):
        self.tbl.setRowCount(len(items))
        for i, it in enumerate(items):
            self.tbl.setItem(i, 0, QTableWidgetItem(it.get("name", "") or ""))
            self.tbl.setItem(i, 1, QTableWidgetItem(it.get("version", "") or ""))
            self.tbl.setItem(i, 2, QTableWidgetItem(it.get("arch", "") or ""))
            self.tbl.setItem(i, 3, QTableWidgetItem(it.get("repo", "") or ""))
            self.tbl.setItem(i, 4, QTableWidgetItem(it.get("file", "") or ""))

    def filter(self, text: str):
        if not text:
            self._show(self.items)
            self.prog.setText(f"Showing {len(self.items)} packages.")
            return
        q = text.lower().strip()
        filt = [it for it in self.items if q in ((it.get("name", "").lower() + " " + it.get("file", "").lower()))]
        self._show(filt)
        self.prog.setText(f"Found {len(filt)} matches for '{text}'.")


class TeamMemberCard(QFrame):
    """
    Compact team card designed to fit without scrolling at the app minimum size.
    Loads avatar from GitHub (PNG) and shows Name + @handle + role.
    """
    def __init__(self, name: str, github_user: str, role: str = "Member"):
        super().__init__()
        self._img_worker: Optional[FetchWorker] = None
        self._name = name
        self._user = github_user
        self._role = role
        self._setup_ui()
        self._load_avatar()

    def _setup_ui(self):
        self.setObjectName("card")
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        l = QHBoxLayout(self)
        l.setSpacing(10)
        l.setContentsMargins(12, 10, 12, 10)

        # Avatar
        self.avatar = QLabel()
        self.avatar.setFixedSize(40, 40)
        self.avatar.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.avatar.setStyleSheet(
            "background:#321a45; border:1px solid #5c3a7d; border-radius:20px; "
            "font-weight:900; color:#e8e0f0; font-size:13px;"
        )
        l.addWidget(self.avatar)

        # Text block (keeps width small)
        info = QVBoxLayout()
        info.setSpacing(1)
        info.setContentsMargins(0, 0, 0, 0)

        self.name_lbl = QLabel(self._name)
        self.name_lbl.setStyleSheet("font-weight:900; font-size:13px; color:#f3eaff;")
        self.name_lbl.setWordWrap(False)
        self.name_lbl.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)

        self.user_lbl = QLabel(f"@{self._user}")
        self.user_lbl.setStyleSheet("color:#bda9d1; font-size:11px;")

        self.role_lbl = QLabel(self._role)
        self.role_lbl.setStyleSheet("color:#9c84b6; font-size:11px;")

        info.addWidget(self.name_lbl)
        info.addWidget(self.user_lbl)
        info.addWidget(self.role_lbl)

        l.addLayout(info, 1)

        # GitHub button (slimmer)
        btn = QPushButton("GitHub")
        btn.setFixedSize(84, 32)
        btn.setCursor(Qt.CursorShape.PointingHandCursor)
        btn.clicked.connect(lambda: QDesktopServices.openUrl(QUrl(f"https://github.com/{self._user}")))
        l.addWidget(btn)

        # Initials fallback immediately
        parts = [p for p in re.split(r"\s+", (self._name or "").strip()) if p]
        initials = "".join([p[0].upper() for p in parts[:2]]) or "??"
        self.avatar.setText(initials[:2])

    def _load_avatar(self):
        url = f"https://github.com/{self._user}.png?size=96"
        self._img_worker = FetchWorker(url, timeout=25)
        self._img_worker.finished.connect(self._set_avatar_from_bytes)
        self._img_worker.error.connect(lambda _e: None)
        self._img_worker.start()

    def _set_avatar_from_bytes(self, data: bytes):
        try:
            pix = QPixmap()
            if not pix.loadFromData(data):
                return
            size = self.avatar.size()
            pix = pix.scaled(size, Qt.AspectRatioMode.KeepAspectRatioByExpanding, Qt.TransformationMode.SmoothTransformation)

            out = QPixmap(size)
            out.fill(Qt.GlobalColor.transparent)
            painter = QPainter(out)
            painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)
            path = QPainterPath()
            path.addEllipse(0, 0, size.width(), size.height())
            painter.setClipPath(path)
            painter.drawPixmap(0, 0, pix)
            painter.end()

            self.avatar.setStyleSheet("background:transparent; border:1px solid #5c3a7d; border-radius:20px;")
            self.avatar.setText("")
            self.avatar.setPixmap(out)
        except Exception:
            pass


class TeamPage(QWidget):
    """
    No-scroll Team page:
    - No QScrollArea
    - Fixed 2-column grid of compact cards (8 members => 4 rows)
    - Centered link buttons
    The app minimum size ensures everything fits without vertical/horizontal scrolling.
    """
    def __init__(self):
        super().__init__()
        self.setup_ui()

    def setup_ui(self):
        l = QVBoxLayout(self)
        l.setSpacing(10)
        l.setContentsMargins(18, 16, 18, 16)

        l.addWidget(QLabel("The Chaotic Team", objectName="sectionTitle"))

        filler = QLabel(
            "The Chaotic-AUR repository is maintained by a dedicated team of volunteers who build, test, and "
            "publish pre-compiled packages for the community. By automating AUR builds on reliable infrastructure, "
            "they help users install software quickly without waiting for local compilation. As with any unofficial "
            "repository, transparency and trust matter, so the team focuses on clear tooling, and "
            "open communication, while encouraging users to review packages and report issues when something looks off."
        )
        filler.setWordWrap(True)
        filler.setObjectName("description")
        l.addWidget(filler)

        members = [
            ("Nιƈσ", "dr460nf1r3"),
            ("Pedro Lara Campos", "PedroHLC"),
            ("lordkitsuna", "lordkitsuna"),
            ("Peter Jung", "ptr1337"),
            ("IslandC0der", "IslandC0der"),
            ("SGS", "sgse"),
            ("Technetium1", "Technetium1"),
            ("Paulo Matias", "thotypous"),
        ]

        # Grid: 2 columns, 4 rows
        grid = QGridLayout()
        grid.setHorizontalSpacing(10)
        grid.setVerticalSpacing(10)
        grid.setContentsMargins(0, 0, 0, 0)

        for idx, (name, user) in enumerate(members):
            card = TeamMemberCard(name=name, github_user=user, role="Member")
            grid.addWidget(card, idx // 2, idx % 2)

        # Make both columns stretch evenly so no horizontal scroll is needed.
        grid.setColumnStretch(0, 1)
        grid.setColumnStretch(1, 1)

        l.addLayout(grid)

        # Push links to bottom
        l.addStretch()

        l.addWidget(QLabel("<b style='color:#d4b0ff'>Links</b>"))

        ll = QHBoxLayout()
        ll.setSpacing(10)
        ll.addStretch()
        for t, u in [
            ("GitHub", "https://github.com/chaotic-aur"),
            ("GitLab", "https://gitlab.com/chaotic-aur"),
            ("Website", "https://aur.chaotic.cx"),
            ("Telegram", "https://t.me/chaotic_aur"),
        ]:
            b = QPushButton(t)
            b.setFixedSize(92, 34)
            b.setCursor(Qt.CursorShape.PointingHandCursor)
            b.clicked.connect(lambda _, url=u: QDesktopServices.openUrl(QUrl(url)))
            ll.addWidget(b)
        ll.addStretch()

        l.addLayout(ll)


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Unofficial Chaotic-AUR Tool")
        self.setMinimumSize(950, 700)

        c = QWidget()
        self.setCentralWidget(c)

        ml = QHBoxLayout(c)
        ml.setSpacing(0)
        ml.setContentsMargins(0, 0, 0, 0)

        ml.addWidget(self._sidebar())

        self.stack = QStackedWidget()
        self.pages = [HomePage(), PackagesPage(), StatusPage(), DeploymentsPage(), TeamPage()]
        for p in self.pages:
            self.stack.addWidget(p)
        ml.addWidget(self.stack)

        QTimer.singleShot(100, self._init)

    def _sidebar(self):
        f = QFrame()
        f.setFixedWidth(220)
        f.setStyleSheet("QFrame{background:#150d1f;border-right:1px solid #3a2a4a;}")
        l = QVBoxLayout(f)
        l.setSpacing(5)
        l.setContentsMargins(10, 20, 10, 20)

        l.addWidget(QLabel("<span style='font-size:16px;font-weight:bold;color:#c9a0ff;'>Chaotic-AUR</span>"))

        self.btns: List[QPushButton] = []
        for label, idx in [
            ("🏠 Home", 0),
            ("📦 Packages", 1),
            ("📊 Build Status", 2),
            ("🚀 Deployments", 3),
            ("👥 The Chaotic Team", 4),
        ]:
            b = QPushButton(label)
            b.setObjectName("navButton")
            b.clicked.connect(lambda _=False, x=idx: self._nav(x))
            l.addWidget(b)
            self.btns.append(b)

        l.addStretch()
        l.addWidget(QLabel("<span style='color:#5a4a6a;font-size:10px;'>v1.0.0</span>"))

        self.btns[0].setProperty("active", True)
        self.btns[0].setStyle(self.btns[0].style())
        return f

    def _nav(self, i: int):
        self.stack.setCurrentIndex(i)
        for j, b in enumerate(self.btns):
            b.setProperty("active", j == i)
            b.setStyle(b.style())

    def _init(self):
        self.pages[0].check()
        self.pages[2].load()
        self.pages[3].load()
        self.pages[1].load()


def main():
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setStyleSheet(DARK_PURPLE_STYLE)
    w = MainWindow()
    w.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
