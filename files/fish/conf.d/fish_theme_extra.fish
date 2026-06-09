# ──────────────────────────────────────────────────────────────
#  Couleurs supplémentaires — pilotées par ~/.config/color.sh
#  (couleur des dossiers dans les listings ls / eza)
# ──────────────────────────────────────────────────────────────

# Dossiers en gras + accent bleu (di = directory, 24 bits)
set -gx EZA_COLORS "di=1;38;2;0;255;170:*.md=38;2;255;255;255:*.markdown=38;2;255;255;255:*.json=38;2;255;255;255:*.js=38;2;255;255;255:*.mjs=38;2;255;255;255:*.cjs=38;2;255;255;255:*.ts=38;2;255;255;255:*.tsx=38;2;255;255;255:*.jsx=38;2;255;255;255:*.config.js=38;2;255;255;255:*.config.ts=38;2;255;255;255:*.yml=38;2;255;255;255:*.yaml=38;2;255;255;255:Dockerfile=38;2;255;255;255:Dockerfile.*=38;2;255;255;255:Makefile=38;2;255;255;255"
set -gx LS_COLORS "di=1;38;2;0;255;170:*.md=38;2;255;255;255:*.markdown=38;2;255;255;255:*.json=38;2;255;255;255:*.js=38;2;255;255;255:*.mjs=38;2;255;255;255:*.cjs=38;2;255;255;255:*.ts=38;2;255;255;255:*.tsx=38;2;255;255;255:*.jsx=38;2;255;255;255:*.config.js=38;2;255;255;255:*.config.ts=38;2;255;255;255:*.yml=38;2;255;255;255:*.yaml=38;2;255;255;255:Dockerfile=38;2;255;255;255:Dockerfile.*=38;2;255;255;255:Makefile=38;2;255;255;255"

if status is-interactive
    # eza (installé) avec dossiers regroupés en tête
    alias ls 'eza --group-directories-first'
    alias ll 'eza -l --group-directories-first'
    alias la 'eza -la --group-directories-first'
end
