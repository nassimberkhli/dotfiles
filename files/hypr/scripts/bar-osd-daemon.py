#!/usr/bin/env python3
# ──────────────────────────────────────────────────────────────────────────
#  bar-osd-daemon.py — OSD volume / luminosité « terminal TUI ».
#
#  Style minimaliste façon ncurses/htop : une boîte en box-drawing dessinée
#  intégralement en texte monospace + markup Pango.
#      ┌─ vol ───────────────────┐
#      │ ██████████████░░░░░  80% │
#      └─────────────────────────┘
#  Deux couleurs seulement :
#      color_4 -> bordure de la boîte + label « vol »/« bri » + tête de scan
#      color_1 -> barre pleine + pourcentage   (vide = color_1 atténué)
#
#  Animation « loading bar » : à l'ouverture la barre se remplit depuis 0, et à
#  chaque changement elle court (ease-out) jusqu'à la nouvelle valeur. Pendant
#  la course, la cellule de tête clignote en color_4 (curseur de scan) et le %
#  défile — effet terminal/geek.
#
#  Architecture : daemon GTK (lancé via exec-once) qui écoute un FIFO. Les
#  raccourcis passent par bar-osd.sh qui change le volume/lumière puis écrit
#  une ligne « <kind> <value> <muted> » dans le FIFO. Couleurs relues à CHAQUE
#  affichage depuis bar-osd.colors (généré par color.sh).
# ──────────────────────────────────────────────────────────────────────────
import fcntl
import os
import sys
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, GtkLayerShell, GLib, Gdk  # noqa: E402

RUNTIME = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
FIFO = os.path.join(RUNTIME, "bar-osd.fifo")
COLORS_FILE = os.path.expanduser("~/.config/hypr/scripts/bar-osd.colors")

BAR_CELLS = 22        # largeur de la barre (en caractères)
TIMEOUT_MS = 1500     # durée d'affichage avant disparition
DIM_FACTOR = 0.62     # atténuation des cellules vides (vers le fond)
FRAME_MS = 16         # ~60 fps pour l'animation
EASE = 0.30           # fraction parcourue vers la cible à chaque frame
FILL_CHAR = "█"
EMPTY_CHAR = "░"
HEAD_CHAR = "█"       # cellule de tête pendant la course (colorée en color_4)

# Couleurs par défaut si bar-osd.colors est absent.
DEFAULT_COLORS = {
    "fg": "#ffffff",      # color_1 — barre pleine + pourcentage
    "border": "#00ffaa",  # color_4 — bordure + label + tête de scan
    "bg": "#000000",      # fond de la boîte
}


def load_colors():
    """Relit bar-osd.colors (KEY=#hex par ligne) à chaque affichage."""
    colors = dict(DEFAULT_COLORS)
    try:
        with open(COLORS_FILE) as fh:
            for line in fh:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, val = line.partition("=")
                key, val = key.strip(), val.strip()
                if key in colors and val:
                    colors[key] = val
    except OSError:
        pass
    return colors


def _rgb255(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def mix_hex(a, b, t):
    """Mélange a→b (t=0 → a, t=1 → b)."""
    ar, ag, ab = _rgb255(a)
    br, bg, bb = _rgb255(b)
    r = round(ar + (br - ar) * t)
    g = round(ag + (bg - ag) * t)
    bl = round(ab + (bb - ab) * t)
    return f"#{r:02x}{g:02x}{bl:02x}"


class BarOsd(Gtk.Window):
    def __init__(self):
        super().__init__()
        self.kind = "volume"
        self.muted = False
        self.target = 0          # valeur visée
        self.display = 0.0       # valeur affichée (animée)
        self.colors = dict(DEFAULT_COLORS)
        self._visible = False
        self._anim = None
        self._timeout = None

        # ── Layer-shell : overlay, centré horizontalement, près du bas ──
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, 90)
        GtkLayerShell.set_namespace(self, "bar-osd")

        # ── Un seul label monospace contient toute la « boîte » TUI ──
        self.label = Gtk.Label()
        self.label.set_use_markup(True)
        self.label.set_justify(Gtk.Justification.LEFT)
        self.label.get_style_context().add_class("osd")
        self.add(self.label)

        self.css = Gtk.CssProvider()
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), self.css,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )

    # ── Construit le markup de la boîte pour l'état courant ─────────────
    def render(self, animating):
        c1 = self.colors["fg"]
        c4 = self.colors["border"]
        dim = mix_hex(c1, self.colors["bg"], DIM_FACTOR)

        label = "bri" if self.kind == "brightness" else "vol"
        shown = 0 if self.muted else int(round(self.display))
        cells = 0 if self.muted else int(round(self.display / 100 * BAR_CELLS))
        cells = max(0, min(BAR_CELLS, cells))
        pct = "muet" if self.muted else f"{shown:3d}%"   # toujours 4 caractères

        def span(color, text):
            return f'<span foreground="{color}">{text}</span>' if text else ""

        # Corps de la barre : pendant la course, la tête est en color_4.
        if animating and cells > 0:
            body = span(c1, " " + FILL_CHAR * (cells - 1)) + span(c4, HEAD_CHAR)
        else:
            body = span(c1, " " + FILL_CHAR * cells)
        body += span(dim, EMPTY_CHAR * (BAR_CELLS - cells))

        inner = 1 + BAR_CELLS + 2 + len(pct) + 1
        head = f"─ {label} "                          # segment après ┌
        top = "┌" + head + "─" * (inner - len(head)) + "┐"
        bottom = "└" + "─" * inner + "┘"

        mid = span(c4, "│") + body + span(c1, f"  {pct} ") + span(c4, "│")
        return span(c4, top) + "\n" + mid + "\n" + span(c4, bottom)

    def _paint(self, animating):
        self.label.set_markup(self.render(animating))

    # ── Animation : course ease-out de display vers target ─────────────
    def _tick(self):
        diff = self.target - self.display
        if self.muted or abs(diff) < 0.6:
            self.display = 0.0 if self.muted else float(self.target)
            self._paint(False)
            self._anim = None
            return False
        self.display += diff * EASE
        self._paint(True)
        return True

    def _start_anim(self):
        if self._anim is not None:
            GLib.source_remove(self._anim)
        self._paint(not self.muted)
        self._anim = GLib.timeout_add(FRAME_MS, self._tick)

    # ── Affichage déclenché par un message du FIFO ─────────────────────
    def show_osd(self, kind, value, muted):
        self.kind = kind
        self.muted = muted
        self.target = max(0, min(100, value))
        self.colors = load_colors()

        # À l'ouverture (fenêtre cachée), on repart de 0 → remplissage complet.
        if not self._visible:
            self.display = 0.0
        self._visible = True

        self.css.load_from_data(f"""
            .osd {{
                background-color: {self.colors['bg']};
                border-radius: 0;
                padding: 10px 14px;
                font-family: monospace;
                font-size: 15px;
            }}
        """.encode())

        self.show_all()
        self._start_anim()

        if self._timeout is not None:
            GLib.source_remove(self._timeout)
        self._timeout = GLib.timeout_add(TIMEOUT_MS, self._hide)

    def _hide(self):
        self.hide()
        self._visible = False
        self._timeout = None
        if self._anim is not None:
            GLib.source_remove(self._anim)
            self._anim = None
        return False


def main():
    # Instance unique : si un autre daemon détient déjà le verrou, on sort —
    # deux lecteurs du même FIFO se voleraient les messages.
    lock = open(os.path.join(RUNTIME, "bar-osd.lock"), "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        sys.exit(0)

    # FIFO ouvert en lecture+écriture (O_RDWR) pour ne jamais recevoir d'EOF
    # et ne jamais bloquer les écrivains.
    try:
        if not os.path.exists(FIFO):
            os.mkfifo(FIFO)
    except OSError:
        pass
    fd = os.open(FIFO, os.O_RDWR | os.O_NONBLOCK)

    win = BarOsd()
    buf = {"data": b""}

    def on_fifo(_src, _cond):
        try:
            chunk = os.read(fd, 4096)
        except BlockingIOError:
            return True
        if not chunk:
            return True
        buf["data"] += chunk
        while b"\n" in buf["data"]:
            line, _, buf["data"] = buf["data"].partition(b"\n")
            parts = line.decode(errors="ignore").split()
            if len(parts) >= 2:
                kind = parts[0]
                try:
                    value = int(float(parts[1]))
                except ValueError:
                    continue
                muted = len(parts) >= 3 and parts[2] in ("1", "muted", "true")
                win.show_osd(kind, value, muted)
        return True

    GLib.io_add_watch(fd, GLib.IO_IN, on_fifo)
    Gtk.main()


if __name__ == "__main__":
    main()
