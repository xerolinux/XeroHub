#!/usr/bin/env python3
"""
xero-grubs — GTK4 GRUB Theme Previewer
Standalone viewer for XeroLinux GRUB themes.
Launchable via: bash -c "python3 <(curl -fsSL 'https://raw.githubusercontent.com/xerolinux/xero-grubs/main/xero-grubs.py')"
"""

import subprocess
import urllib.request
import warnings
from pathlib import Path

warnings.filterwarnings("ignore", category=DeprecationWarning)

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Gdk, GdkPixbuf, Gio, Adw

APP_ID = "io.xerolinux.grubs"
ASSET_BASE_URL = "https://raw.githubusercontent.com/xerolinux/xero-grubs/main/assets"
CACHE_DIR = Path.home() / ".cache" / "xero-grubs"

THEMES = [
    ("Catppuccin", "catppuccin.webp"),
    ("Daft Punk", "daft-punk.webp"),
    ("Nordic", "nordic.webp"),
    ("Star Wars", "star-wars.webp"),
    ("TRON", "tron.webp"),
    ("Xero Dunes", "xero-dunes.webp"),
    ("Xero Purple", "xero-purple.webp"),
    ("Xero Sweet", "xero-sweet.webp"),
]

CSS = """
headerbar {
    min-height: 30px;
    padding: 0 6px;
}
.main-header {
    font-size: 20px;
    font-weight: 700;
}
.main-desc {
    font-size: 13px;
    opacity: 0.7;
}
.theme-card {
    background: alpha(@card_bg_color, 0.5);
    border: 2px solid alpha(currentColor, 0.15);
    border-radius: 8px;
    padding: 10px;
}
.theme-card:hover {
    border-color: @accent_color;
}
.theme-name {
    font-size: 14px;
    font-weight: 700;
    padding: 8px 0 4px 0;
}
.preview-image {
    border-radius: 5px;
}
.install-button {
    background: linear-gradient(to right, #ff00ff, #00ffff, #ffff00);
    color: #000000;
    border: none;
    border-radius: 8px;
    padding: 16px;
    font-size: 16px;
    font-weight: 800;
}
.install-button:hover {
    background: linear-gradient(to right, #ffff00, #ff00ff, #00ffff);
}
"""


def has_local_assets():
    """Check if all theme images exist in the local assets/ dir."""
    try:
        assets_dir = Path(__file__).resolve().parent / "assets"
        return all((assets_dir / fn).exists() for _, fn in THEMES)
    except Exception:
        return False


def ensure_cached_images():
    """Download theme preview images to cache if not already present."""
    if has_local_assets():
        return
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    for _, filename in THEMES:
        dest = CACHE_DIR / filename
        if dest.exists():
            continue
        url = f"{ASSET_BASE_URL}/{filename}"
        try:
            urllib.request.urlretrieve(url, str(dest))
        except Exception:
            pass


def get_image_path(filename):
    """Return local path to a theme image, preferring local assets/ over cache."""
    try:
        local = Path(__file__).resolve().parent / "assets" / filename
        if local.exists():
            return str(local)
    except Exception:
        pass
    cached = CACHE_DIR / filename
    if cached.exists():
        return str(cached)
    return None


def find_terminal():
    """Detect available terminal emulator."""
    terminals = [
        "konsole", "gnome-terminal", "xfce4-terminal",
        "alacritty", "kitty", "terminator", "xterm",
    ]
    for term in terminals:
        try:
            subprocess.run(
                ["which", term], check=True,
                capture_output=True, text=True,
            )
            return term
        except Exception:
            continue
    return None


def launch_install(widget):
    """Launch the GRUB themes installer in a terminal."""
    cmd = "git clone https://github.com/xerolinux/xero-grubs && cd xero-grubs/ && sudo ./install.sh; cd .. && rm -rf xero-grubs"
    wrapped = f"{cmd}; echo '\\nPress Enter to close...'; read"
    term = find_terminal()
    if not term:
        print("No suitable terminal emulator found")
        return
    try:
        if term == "konsole":
            subprocess.Popen([term, "-e", "bash", "-c", wrapped])
        elif term in ("gnome-terminal", "xfce4-terminal"):
            subprocess.Popen([term, "--", "bash", "-c", wrapped])
        else:
            subprocess.Popen([term, "-e", "bash", "-c", wrapped])
    except Exception as e:
        print(f"Error launching terminal: {e}")


def load_scaled_texture(path, max_height=180):
    """Load an image file and return a Gdk.Texture scaled to fit max_height."""
    try:
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
        w, h = pixbuf.get_width(), pixbuf.get_height()
        if h > max_height:
            scale = max_height / h
            new_w = int(w * scale)
            pixbuf = pixbuf.scale_simple(new_w, max_height, GdkPixbuf.InterpType.BILINEAR)
        return Gdk.Texture.new_for_pixbuf(pixbuf)
    except Exception as e:
        print(f"Error loading {path}: {e}")
        return None


def build_theme_card(name, filename):
    """Build a single theme card widget."""
    path = get_image_path(filename)

    card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    card.add_css_class("theme-card")

    if path:
        texture = load_scaled_texture(path, 180)
        if texture:
            picture = Gtk.Picture.new_for_paintable(texture)
            picture.set_can_shrink(True)
            picture.set_content_fit(Gtk.ContentFit.CONTAIN)
            picture.set_hexpand(True)
            picture.add_css_class("preview-image")
            card.append(picture)
        else:
            placeholder = Gtk.Label(label="Preview unavailable")
            placeholder.set_size_request(-1, 180)
            card.append(placeholder)
    else:
        placeholder = Gtk.Label(label="Preview unavailable")
        placeholder.set_size_request(-1, 180)
        card.append(placeholder)

    label = Gtk.Label(label=name)
    label.add_css_class("theme-name")
    label.set_halign(Gtk.Align.CENTER)
    card.append(label)

    return card


class GrubApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.DEFAULT_FLAGS)
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        # Load CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        win = Adw.ApplicationWindow(application=app, title="GRUB Themes")

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        outer.set_margin_top(20)
        outer.set_margin_bottom(20)
        outer.set_margin_start(20)
        outer.set_margin_end(20)

        # Header
        header = Gtk.Label(label="GRUB Themes")
        header.add_css_class("main-header")
        header.set_halign(Gtk.Align.START)
        outer.append(header)

        # Description
        desc = Gtk.Label(
            label=(
                "Transform your bootloader with our complete collection of 8 stunning GRUB themes. "
                "Each theme is professionally designed to make your boot experience as beautiful as "
                "your desktop. The installation script provides an interactive menu where you can "
                "preview and choose any theme."
            )
        )
        desc.add_css_class("main-desc")
        desc.set_halign(Gtk.Align.START)
        desc.set_wrap(True)
        desc.set_xalign(0)
        outer.append(desc)

        # 4x2 Grid
        grid = Gtk.Grid()
        grid.set_row_spacing(15)
        grid.set_column_spacing(15)
        grid.set_column_homogeneous(True)

        for i, (name, filename) in enumerate(THEMES):
            row = i // 4
            col = i % 4
            card = build_theme_card(name, filename)
            card.set_hexpand(True)
            grid.attach(card, col, row, 1, 1)

        outer.append(grid)

        # Install button
        install_btn = Gtk.Button(label="Install GRUB Themes (Interactive Installer)")
        install_btn.add_css_class("install-button")
        install_btn.set_margin_top(15)
        install_btn.connect("clicked", launch_install)
        outer.append(install_btn)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_child(outer)
        scrolled.set_propagate_natural_height(True)

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar(title_widget=Gtk.Label(label="GRUB Themes")))
        toolbar_view.set_content(scrolled)

        win.set_content(toolbar_view)
        win.set_default_size(1200, -1)
        win.present()


def main():
    ensure_cached_images()
    app = GrubApp()
    app.run(None)


if __name__ == "__main__":
    main()
