#!/usr/bin/env bash

set -euo pipefail

REAL_HOME=$(getent passwd "${SUDO_USER:-${USER}}" | cut -d: -f6 2>/dev/null || echo "$HOME")
export HOME="$REAL_HOME"

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$SCRIPT_DIR/files" # <- ton dossier repo s'appelle 'files'
source "$SCRIPT_DIR/files.sh" || {
    echo "Erreur : impossible de sourcer $SCRIPT_DIR/files.sh"
    exit 1
}

MODE=""
DRY_RUN=0

have() { command -v "$1" >/dev/null 2>&1; }

usage() {
    echo "Usage: $0 [--system | --repos] [--dry-run]"
    exit 1
}

for arg in "$@"; do
    case "$arg" in
    --system) MODE="system" ;;
    --repos) MODE="repos" ;;
    --dry-run) DRY_RUN=1 ;;
    -h | --help) usage ;;
    *)
        echo "Option inconnue: $arg"
        usage
        ;;
    esac
done

[ -z "$MODE" ] && usage
[ -d "$SRC_ROOT" ] || {
    echo "Erreur: dossier '$SRC_ROOT' introuvable."
    exit 1
}

log() { printf '%s\n' "$*"; }

is_system_path() {
    [[ "$1" == /etc/* || "$1" == /usr/* || "$1" == /var/* ]]
}

copy_item() {
    local src="$1"
    local dst="$2"
    local use_sudo="${3:-0}"
    local chown_user="${4:-0}"

    # Dry-run
    if [ "$DRY_RUN" -eq 1 ]; then
        if [ -d "$src" ]; then
            log "[dry-run] (dir)  ${use_sudo:+sudo }rsync -a ${chown_user:+--chown=$(id -u):$(id -g) }'$src/' '$dst/'"
        elif [ -f "$src" ]; then
            log "[dry-run] (file) ${use_sudo:+sudo }rsync -a ${chown_user:+--chown=$(id -u):$(id -g) }'$src' '$dst'"
        else
            log "[skip] $src inexistant"
        fi
        return 0
    fi

    # Source présente ?
    if [ ! -e "$src" ]; then
        log "[skip] $src inexistant"
        return 0
    fi

    # Crée destination
    if [ -d "$src" ]; then
        if [ "$use_sudo" -eq 1 ]; then sudo mkdir -p "$dst"; else mkdir -p "$dst"; fi
    else
        local parent
        parent="$(dirname "$dst")"
        if [ "$use_sudo" -eq 1 ]; then sudo mkdir -p "$parent"; else mkdir -p "$parent"; fi
    fi

    if have rsync; then
        local cmd=(rsync -a)
        [ "$chown_user" -eq 1 ] && cmd+=(--chown="$(id -u)":"$(id -g)")

        if [ -d "$src" ]; then
            if [ "$use_sudo" -eq 1 ]; then
                sudo "${cmd[@]}" "$src/" "$dst/"
            else
                "${cmd[@]}" "$src/" "$dst/"
            fi
        else
            if [ "$use_sudo" -eq 1 ]; then
                sudo "${cmd[@]}" "$src" "$dst"
            else
                # <<< LIGNE CORRIGÉE ICI >>>
                "${cmd[@]}" "$src" "$dst"
            fi
        fi
    else
        # Fallback sans rsync
        if [ -d "$src" ]; then
            if [ "$use_sudo" -eq 1 ]; then
                sudo cp -r "$src"/. "$dst"/
                [ "$chown_user" -eq 1 ] && sudo chown -R "$(id -u)":"$(id -g)" "$dst"
            else
                cp -r "$src"/. "$dst"/
            fi
        else
            if [ "$use_sudo" -eq 1 ]; then
                sudo cp "$src" "$dst"
                [ "$chown_user" -eq 1 ] && sudo chown "$(id -u)":"$(id -g)" "$dst"
            else
                cp "$src" "$dst"
            fi
        fi
    fi

    log "[ok] $src → $dst"
}

# --- Parcours du mapping ---
for rel in "${!FILES[@]}"; do
    dest="${FILES[$rel]}"
    src_repo="$SRC_ROOT/$rel"

    if [ "$MODE" = "system" ]; then
        # repo -> système
        if is_system_path "$dest"; then
            copy_item "$src_repo" "$dest" 1 0
        else
            copy_item "$src_repo" "$dest" 0 0
        fi
    else
        # système -> repo
        if is_system_path "$dest"; then
            if sudo test -e "$dest"; then
                copy_item "$dest" "$src_repo" 1 1
            else
                log "[skip] $dest absent (système)"
            fi
        else
            if [ -e "$dest" ]; then
                copy_item "$dest" "$src_repo" 0 0
            else
                log "[skip] $dest absent (user)"
            fi
        fi
    fi
done
