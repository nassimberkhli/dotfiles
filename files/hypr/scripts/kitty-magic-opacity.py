#!/usr/bin/env python3
# Règle l'opacité de fond des terminaux kitty selon leur workspace :
#   - workspace spécial "magic" -> opaque (1.0)
#   - workspaces normaux        -> transparent (0.5)
# Réagit dynamiquement à la création ET au déplacement des fenêtres,
# en écoutant le socket d'événements de Hyprland.
#
# Prérequis dans kitty.conf :
#   allow_remote_control yes
#   listen_on unix:/tmp/kitty-{kitty_pid}
#   dynamic_background_opacity yes
#   background_opacity 0.5

import json
import os
import socket
import subprocess
import threading

MAGIC = "special:magic"
OPAQUE = "1.0"
TRANSPARENT = "0.5"

# Événements Hyprland après lesquels on réévalue l'opacité.
EVENTS = {
    "openwindow",
    "movewindow",
    "movewindowv2",
    "workspace",
    "workspacev2",
}


def apply_all():
    try:
        out = subprocess.check_output(["hyprctl", "clients", "-j"])
    except (subprocess.CalledProcessError, FileNotFoundError):
        return
    for c in json.loads(out):
        if c.get("class") != "kitty":
            continue
        pid = c.get("pid")
        ws = (c.get("workspace") or {}).get("name", "")
        opacity = OPAQUE if ws == MAGIC else TRANSPARENT
        subprocess.run(
            [
                "kitten", "@",
                "--to", f"unix:/tmp/kitty-{pid}",
                "set-background-opacity", opacity,
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )


def handle_event():
    # Application immédiate, puis quelques rattrapages décalés : à l'ouverture
    # d'un terminal, son socket de remote-control n'écoute pas encore. Les
    # appels qui échouent (socket absent) retournent instantanément, donc ces
    # réessais sont sans coût.
    apply_all()
    for delay in (0.25, 0.6, 1.0):
        threading.Timer(delay, apply_all).start()


def main():
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    runtime = os.environ.get("XDG_RUNTIME_DIR", "")
    path = f"{runtime}/hypr/{sig}/.socket2.sock"

    handle_event()  # état initial

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)
    with sock.makefile("r") as stream:
        for line in stream:
            event = line.split(">>", 1)[0]
            if event in EVENTS:
                handle_event()


if __name__ == "__main__":
    main()
