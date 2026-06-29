#!/usr/bin/env python3
# coloreditor.py — éditeur de palette système TRÈS précis (TUI truecolor).
# Édite COLOR_BG/COLOR_1..7 dans ~/.config/color.sh, applique color.sh
# (waybar/kitty/fish/rofi/dunst/cava/nvim) ET régénère le scheme Caelestia.
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
COLOR_SH = f"{HOME}/.config/color.sh"
SCHEME = f"{HOME}/.local/state/caelestia/scheme.json"

KEYS = [
    "COLOR_BG",
    "COLOR_1",
    "COLOR_2",
    "COLOR_3",
    "COLOR_4",
    "COLOR_5",
    "COLOR_6",
    "COLOR_7",
]
LABELS = {
    "COLOR_BG": "Fond",
    "COLOR_1": "Texte / premier plan (blanc)",
    "COLOR_2": "Accent principal",
    "COLOR_3": "Secondaire",
    "COLOR_4": "Accent 2",
    "COLOR_5": "Alerte / erreur",
    "COLOR_6": "Divers",
    "COLOR_7": "Extra",
}

R = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"


def swatch(hexcol, width=6):
    h = hexcol.lstrip("#")
    try:
        r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    except ValueError:
        return "?" * width
    return f"\033[48;2;{r};{g};{b}m{' ' * width}{R}"


def valid_hex(s):
    return bool(re.fullmatch(r"#?[0-9a-fA-F]{6}", s.strip()))


def norm_hex(s):
    s = s.strip().lstrip("#").lower()
    return f"#{s}"


def read_palette():
    pal = {}
    try:
        txt = open(COLOR_SH).read()
    except FileNotFoundError:
        print(f"Introuvable : {COLOR_SH}")
        sys.exit(1)
    for k in KEYS:
        m = re.search(rf'^{k}="?(#?[0-9a-fA-F]{{6}})"?', txt, re.M)
        pal[k] = norm_hex(m.group(1)) if m else "#000000"
    return pal


def write_palette(pal):
    txt = open(COLOR_SH).read()
    for k in KEYS:
        txt = re.sub(
            rf'^{k}=("?)#?[0-9a-fA-F]{{6}}\1',
            f'{k}="{pal[k]}"',
            txt,
            count=1,
            flags=re.M,
        )
    open(COLOR_SH, "w").write(txt)


def regen_scheme(pal):
    """Régénère le scheme M3 Caelestia (blanc-dominant) à partir de la palette."""
    if not os.path.exists(SCHEME):
        return
    d = json.load(open(SCHEME))
    white = pal["COLOR_1"].lstrip("#")
    blue = pal["COLOR_2"].lstrip("#")
    lime = pal["COLOR_3"].lstrip("#")
    teal = pal["COLOR_4"].lstrip("#")
    mag = pal["COLOR_5"].lstrip("#")
    bg = pal["COLOR_BG"].lstrip("#")
    s1, s2, s3, s4, s5 = "0a0a0a", "101010", "151515", "1c1c1c", "242424"
    gB, gM, gD, outline, outlineV = "cccccc", "999999", "666666", "3a3a3a", "1f1f1f"
    c = {
        "primary_paletteKeyColor": white,
        "secondary_paletteKeyColor": teal,
        "tertiary_paletteKeyColor": lime,
        "neutral_paletteKeyColor": "808080",
        "neutral_variant_paletteKeyColor": "808080",
        "background": bg,
        "onBackground": white,
        "surface": bg,
        "surfaceDim": bg,
        "surfaceBright": s5,
        "surfaceContainerLowest": s1,
        "surfaceContainerLow": s2,
        "surfaceContainer": s2,
        "surfaceContainerHigh": s3,
        "surfaceContainerHighest": s4,
        "onSurface": white,
        "surfaceVariant": s4,
        "onSurfaceVariant": gB,
        "inverseSurface": white,
        "inverseOnSurface": bg,
        "outline": outline,
        "outlineVariant": outlineV,
        "shadow": "000000",
        "scrim": "000000",
        "surfaceTint": white,
        "primary": white,
        "onPrimary": bg,
        "primaryContainer": s3,
        "onPrimaryContainer": white,
        "inversePrimary": teal,
        "primaryFixed": white,
        "primaryFixedDim": gB,
        "onPrimaryFixed": bg,
        "onPrimaryFixedVariant": gD,
        "secondary": teal,
        "onSecondary": bg,
        "secondaryContainer": s3,
        "onSecondaryContainer": teal,
        "secondaryFixed": teal,
        "secondaryFixedDim": "00cc88",
        "onSecondaryFixed": bg,
        "onSecondaryFixedVariant": "003d2a",
        "tertiary": lime,
        "onTertiary": bg,
        "tertiaryContainer": s3,
        "onTertiaryContainer": lime,
        "tertiaryFixed": lime,
        "tertiaryFixedDim": "88cc00",
        "onTertiaryFixed": bg,
        "onTertiaryFixedVariant": "2a3d00",
        "error": mag,
        "onError": bg,
        "errorContainer": "3a0014",
        "onErrorContainer": "ffb3cf",
        "term0": bg,
        "term1": mag,
        "term2": teal,
        "term3": lime,
        "term4": blue,
        "term5": white,
        "term6": teal,
        "term7": gB,
        "term8": gD,
        "term9": mag,
        "term10": teal,
        "term11": lime,
        "term12": blue,
        "term13": white,
        "term14": teal,
        "term15": white,
        "rosewater": white,
        "flamingo": white,
        "pink": white,
        "mauve": white,
        "red": mag,
        "maroon": mag,
        "peach": lime,
        "yellow": lime,
        "green": teal,
        "teal": teal,
        "sky": blue,
        "sapphire": blue,
        "blue": blue,
        "lavender": white,
        "klink": teal,
        "klinkSelection": lime,
        "kvisited": blue,
        "kvisitedSelection": white,
        "knegative": mag,
        "knegativeSelection": mag,
        "kneutral": lime,
        "kneutralSelection": lime,
        "kpositive": teal,
        "kpositiveSelection": teal,
        "text": white,
        "subtext1": gB,
        "subtext0": gM,
        "overlay2": gD,
        "overlay1": "555555",
        "overlay0": "3d3d3d",
        "surface2": s4,
        "surface1": s3,
        "surface0": s2,
        "base": bg,
        "mantle": s1,
        "crust": s2,
        "success": teal,
        "onSuccess": bg,
        "successContainer": s3,
        "onSuccessContainer": teal,
    }
    for k in d.get("colours", {}):
        if k in c:
            d["colours"][k] = c[k]
    d["name"] = "minimal"
    d["flavour"] = "custom"
    json.dump(d, open(SCHEME, "w"), indent=0)


def show(pal):
    os.system("clear")
    print(f"{BOLD}╔══ Éditeur de couleurs système ══╗{R}\n")
    for i, k in enumerate(KEYS, 1):
        print(f"  {BOLD}{i}{R}  {swatch(pal[k])}  {pal[k]}  {DIM}{LABELS[k]}{R}")
    print(f"\n  {BOLD}a{R}  appliquer (color.sh + scheme Caelestia)")
    print(f"  {BOLD}q{R}  quitter\n")


def main():
    pal = read_palette()
    while True:
        show(pal)
        choice = input("Choix (1-8 / a / q) > ").strip().lower()
        if choice == "q":
            break
        if choice == "a":
            print("\nÉcriture de la palette…")
            write_palette(pal)
            print("Application color.sh (waybar/kitty/fish/rofi/dunst/cava/nvim)…")
            try:
                subprocess.run(["bash", COLOR_SH], check=False)
            except Exception as e:  # noqa
                print("color.sh:", e)
            print("Régénération du scheme Caelestia…")
            regen_scheme(pal)
            print(f"\n{BOLD}✓ Appliqué.{R} Le shell se recolore en direct.")
            input("Entrée pour continuer…")
            continue
        if choice in [str(i) for i in range(1, len(KEYS) + 1)]:
            k = KEYS[int(choice) - 1]
            print(f"\n{swatch(pal[k])} {LABELS[k]} actuel : {pal[k]}")
            val = input("Nouveau hex (#rrggbb, vide=annuler) > ").strip()
            if val and valid_hex(val):
                pal[k] = norm_hex(val)
            elif val:
                print("Hex invalide.")
                input("Entrée…")


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        pass
