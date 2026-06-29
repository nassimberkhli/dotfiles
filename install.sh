#!/usr/bin/env bash
set -Eeuo pipefail

# ──────────────────────────────────────────────────────────────────────
# install.sh — installateur complet du repo dotfiles
#
# Usage:
#   ./install.sh
#
# Ne PAS lancer avec sudo.
# Le script appelle sudo uniquement quand nécessaire.
# ──────────────────────────────────────────────────────────────────────

IFS=$'\n\t'

if [ "$(id -u)" -eq 0 ]; then
    echo "[error] Ne lance pas ce script avec sudo."
    echo "        Utilise : ./install.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$SCRIPT_DIR/files"
PACMAN_AVAILABLE_CACHE=""
SUDO_KEEPALIVE_PID=""

cd "$SCRIPT_DIR"

log() {
    printf '\033[1;32m[ok]\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33m[warn]\033[0m %s\n' "$*"
}

err() {
    printf '\033[1;31m[error]\033[0m %s\n' "$*"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

cleanup() {
    if [ -n "${SUDO_KEEPALIVE_PID:-}" ]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi

    if [ -n "${PACMAN_AVAILABLE_CACHE:-}" ] && [ -f "$PACMAN_AVAILABLE_CACHE" ]; then
        rm -f "$PACMAN_AVAILABLE_CACHE"
    fi
}

trap cleanup EXIT

require_file() {
    if [ ! -f "$1" ]; then
        err "Fichier manquant : $1"
        exit 1
    fi
}

require_dir() {
    if [ ! -d "$1" ]; then
        err "Dossier manquant : $1"
        exit 1
    fi
}

sudo_keepalive() {
    sudo -v

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &

    SUDO_KEEPALIVE_PID="$!"
}

clean_pkg_name() {
    sed 's/\r$//' |
        sed 's/#.*$//' |
        awk '{$1=$1};1' |
        sed '/^$/d'
}

dedupe_array() {
    local -n arr="$1"
    local -A seen=()
    local out=()

    for item in "${arr[@]}"; do
        [ -z "$item" ] && continue

        if [ -z "${seen[$item]+x}" ]; then
            seen["$item"]=1
            out+=("$item")
        fi
    done

    arr=("${out[@]}")
}

refresh_available_cache() {
    if [ -n "${PACMAN_AVAILABLE_CACHE:-}" ] && [ -f "$PACMAN_AVAILABLE_CACHE" ]; then
        rm -f "$PACMAN_AVAILABLE_CACHE"
    fi

    PACMAN_AVAILABLE_CACHE="$(mktemp)"
    pacman -Slq | sort -u >"$PACMAN_AVAILABLE_CACHE"
}

official_pkg_exists() {
    local pkg="$1"

    if [ -z "${PACMAN_AVAILABLE_CACHE:-}" ] || [ ! -f "$PACMAN_AVAILABLE_CACHE" ]; then
        refresh_available_cache
    fi

    grep -Fxq "$pkg" "$PACMAN_AVAILABLE_CACHE"
}

is_installed() {
    pacman -Qq "$1" >/dev/null 2>&1
}

is_foreign_installed() {
    pacman -Qqm 2>/dev/null | grep -Fxq "$1"
}

cpu_is_amd() {
    grep -qi 'AuthenticAMD' /proc/cpuinfo 2>/dev/null
}

cpu_is_intel() {
    grep -qi 'GenuineIntel' /proc/cpuinfo 2>/dev/null
}

gpu_info() {
    if have lspci; then
        lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true
    fi
}

has_nvidia_gpu() {
    gpu_info | grep -qi 'nvidia'
}

has_amd_gpu() {
    gpu_info | grep -qi 'amd\|ati'
}

has_intel_gpu() {
    gpu_info | grep -qi 'intel'
}

is_hardware_incompatible_package() {
    local pkg="$1"

    case "$pkg" in
    amd-ucode)
        cpu_is_amd || return 0
        ;;

    intel-ucode)
        cpu_is_intel || return 0
        ;;

    nvidia | nvidia-* | lib32-nvidia-*)
        has_nvidia_gpu || return 0
        ;;

    vulkan-radeon | lib32-vulkan-radeon | amdvlk | lib32-amdvlk | xf86-video-amdgpu)
        has_amd_gpu || return 0
        ;;

    vulkan-intel | lib32-vulkan-intel | intel-media-driver | libva-intel-driver)
        has_intel_gpu || return 0
        ;;
    esac

    return 1
}

is_denied_package() {
    local pkg="$1"

    case "$pkg" in
    "") return 0 ;;

    # Paquets virtuels / providers / non installables directement
    cargo) return 0 ;;
    java-environment) return 0 ;;
    java-runtime) return 0 ;;
    libgcc) return 0 ;;
    sh) return 0 ;;

    # Paquets debug
    *-debug) return 0 ;;

    # Paquets connus comme non reproductibles ou supprimés
    antigravity-bin) return 0 ;;
    yay-debug) return 0 ;;

    # On privilégie les paquets officiels quand ils existent
    waybar-git) return 0 ;;
    spdlog-git) return 0 ;;
    fmt-git) return 0 ;;

    hyprland-git) return 0 ;;
    hyprutils-git) return 0 ;;
    hyprlang-git) return 0 ;;
    hyprcursor-git) return 0 ;;
    hyprgraphics-git) return 0 ;;
    aquamarine-git) return 0 ;;
    xdg-desktop-portal-hyprland-git) return 0 ;;
    hyprlock-git) return 0 ;;
    hypridle-git) return 0 ;;
    hyprpaper-git) return 0 ;;
    hyprpicker-git) return 0 ;;
    hyprsunset-git) return 0 ;;
    hyprpolkitagent-git) return 0 ;;

    *) return 1 ;;
    esac
}

remove_installed_package() {
    local pkg="$1"

    if ! is_installed "$pkg"; then
        return 0
    fi

    warn "Suppression du paquet conflictuel : $pkg"

    if sudo pacman -Rns --noconfirm "$pkg"; then
        log "Supprimé : $pkg"
    else
        warn "Suppression classique impossible, suppression forcée : $pkg"
        sudo pacman -Rdd --noconfirm "$pkg"
        log "Supprimé avec -Rdd : $pkg"
    fi
}

enable_multilib_if_needed() {
    if grep -Eq '^\[multilib\]' /etc/pacman.conf; then
        log "multilib déjà activé"
        return 0
    fi

    if grep -Eq '^#\[multilib\]' /etc/pacman.conf; then
        warn "Activation du dépôt multilib"

        sudo sed -i '
      /^#\[multilib\]/ {
        s/^#//
        n
        s/^#//
      }
    ' /etc/pacman.conf
    else
        warn "Section multilib absente, ajout en fin de /etc/pacman.conf"

        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' |
            sudo tee -a /etc/pacman.conf >/dev/null
    fi

    log "multilib activé"
}

sync_databases_only() {
    log "Synchronisation des bases pacman"
    sudo pacman -Syy --noconfirm
    refresh_available_cache
}

install_keyring() {
    log "Mise à jour du keyring"
    sudo pacman -S --needed --noconfirm archlinux-keyring
}

remove_dynamic_git_conflicts() {
    log "Détection dynamique des paquets AUR -git remplaçables par des paquets officiels"

    refresh_available_cache

    local foreign_pkgs=()

    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        foreign_pkgs+=("$pkg")
    done < <(pacman -Qqm 2>/dev/null || true)

    if [ "${#foreign_pkgs[@]}" -eq 0 ]; then
        log "Aucun paquet AUR installé"
        return 0
    fi

    local removed_any=0

    for pkg in "${foreign_pkgs[@]}"; do
        if [[ "$pkg" == *-git ]]; then
            local base_pkg="${pkg%-git}"

            if official_pkg_exists "$base_pkg"; then
                warn "$pkg remplace un paquet officiel disponible : $base_pkg"
                remove_installed_package "$pkg"
                removed_any=1
            fi
        fi
    done

    # Cas critiques connus : ABI cassée ou conflits fréquents
    local known_conflicts=(
        waybar-git
        spdlog-git
        fmt-git
        hyprland-git
        hyprutils-git
        hyprlang-git
        hyprcursor-git
        hyprgraphics-git
        aquamarine-git
        xdg-desktop-portal-hyprland-git
        hyprlock-git
        hypridle-git
        hyprpaper-git
        hyprpicker-git
        hyprsunset-git
        hyprpolkitagent-git
    )

    for pkg in "${known_conflicts[@]}"; do
        if is_installed "$pkg"; then
            remove_installed_package "$pkg"
            removed_any=1
        fi
    done

    if [ "$removed_any" -eq 0 ]; then
        log "Aucun paquet -git conflictuel à supprimer"
    fi
}

conflict_tokens_for_official_package() {
    local pkg="$1"

    pacman -Si "$pkg" 2>/dev/null |
        awk -F': ' '/^Conflicts With/ {print $2}' |
        tr ' ' '\n' |
        sed '/^$/d' |
        sed '/^None$/d' |
        sed 's/[<>=].*$//'
}

remove_declared_conflicts_for_targets() {
    local targets=("$@")
    local conflicts=()

    for pkg in "${targets[@]}"; do
        while IFS= read -r conflict; do
            [ -z "$conflict" ] && continue
            conflicts+=("$conflict")
        done < <(conflict_tokens_for_official_package "$pkg")
    done

    dedupe_array conflicts

    for conflict in "${conflicts[@]}"; do
        if is_installed "$conflict"; then
            warn "Conflit déclaré par pacman détecté : $conflict"
            remove_installed_package "$conflict"
        fi
    done
}

full_system_upgrade() {
    log "Mise à jour complète du système"

    if sudo pacman -Syu --noconfirm; then
        log "Système à jour"
        return 0
    fi

    warn "Première tentative de mise à jour échouée"
    warn "Nouvelle tentative après suppression des conflits AUR dynamiques"

    remove_dynamic_git_conflicts
    refresh_available_cache

    sudo pacman -Syu --noconfirm
    log "Système à jour après correction"
}

install_official_targets() {
    local requested=("$@")
    local targets=()
    local skipped=()

    refresh_available_cache

    for pkg in "${requested[@]}"; do
        [ -z "$pkg" ] && continue

        if is_denied_package "$pkg"; then
            skipped+=("$pkg")
            continue
        fi

        if is_hardware_incompatible_package "$pkg"; then
            skipped+=("$pkg")
            continue
        fi

        if official_pkg_exists "$pkg"; then
            targets+=("$pkg")
        else
            skipped+=("$pkg")
        fi
    done

    dedupe_array targets
    dedupe_array skipped

    if [ "${#skipped[@]}" -gt 0 ]; then
        warn "Paquets officiels ignorés : ${skipped[*]}"
    fi

    if [ "${#targets[@]}" -eq 0 ]; then
        warn "Aucun paquet officiel à installer"
        return 0
    fi

    remove_declared_conflicts_for_targets "${targets[@]}"

    log "Installation des paquets officiels"
    sudo pacman -S --needed --noconfirm "${targets[@]}"
}

install_core_desktop_stack() {
    log "Installation de la base système et desktop"

    local packages=(
        base
        base-devel
        linux
        linux-firmware
        archlinux-keyring

        git
        rsync
        curl
        wget
        unzip
        zip
        ca-certificates
        less
        jq
        tree
        lsof
        ncdu
        bat
        eza
        btop
        pciutils

        networkmanager
        network-manager-applet
        iwd
        openssh

        fish
        kitty
        firefox
        neovim

        pipewire
        pipewire-pulse
        wireplumber
        pavucontrol
        libpulse

        hyprland
        hyprutils
        hyprlang
        hyprcursor
        hyprgraphics
        aquamarine
        xdg-desktop-portal-hyprland
        hyprlock
        hypridle
        hyprpaper
        hyprpicker
        hyprpolkitagent

        waybar
        spdlog
        fmt

        rofi
        dunst
        grim
        slurp
        wl-clipboard
        nwg-look
        thunar

        sddm
        tlp
        tlp-rdw

        docker
        docker-compose

        ttf-nerd-fonts-symbols
        woff2-font-awesome
    )

    install_official_targets "${packages[@]}"
}

install_yay() {
    if have yay && yay --version >/dev/null 2>&1; then
        log "yay déjà installé"
        return 0
    fi

    if have yay; then
        warn "yay existe mais semble cassé"

        local yay_bin
        yay_bin="$(command -v yay || true)"

        if [ -n "$yay_bin" ]; then
            local owner
            owner="$(pacman -Qqo "$yay_bin" 2>/dev/null || true)"

            if [ -n "$owner" ]; then
                remove_installed_package "$owner"
            fi
        fi
    fi

    log "Installation de yay-bin"

    local tmpdir
    tmpdir="$(mktemp -d)"

    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    cd "$tmpdir/yay-bin"

    makepkg -si --noconfirm

    cd "$SCRIPT_DIR"
    rm -rf "$tmpdir"

    log "yay installé"
}

install_pkglist_official() {
    local list="$SRC_ROOT/pkglist-officiel.txt"

    if [ ! -f "$list" ]; then
        warn "Liste officielle absente : $list"
        return 0
    fi

    log "Installation dynamique de pkglist-officiel.txt"

    local pkgs=()

    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        pkgs+=("$pkg")
    done < <(clean_pkg_name <"$list")

    if [ "${#pkgs[@]}" -eq 0 ]; then
        warn "pkglist-officiel.txt vide"
        return 0
    fi

    install_official_targets "${pkgs[@]}"
}

install_pkglist_aur() {
    local list="$SRC_ROOT/pkglist-aur.txt"

    if [ ! -f "$list" ]; then
        warn "Liste AUR absente : $list"
        return 0
    fi

    if ! have yay; then
        warn "yay absent, installation AUR ignorée"
        return 0
    fi

    log "Installation dynamique de pkglist-aur.txt"

    refresh_available_cache

    local aur_packages=()
    local official_fallback=()
    local skipped=()

    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue

        if is_denied_package "$pkg"; then
            skipped+=("$pkg")
            continue
        fi

        if is_hardware_incompatible_package "$pkg"; then
            skipped+=("$pkg")
            continue
        fi

        # Si le paquet AUR est devenu officiel, on installe la version officielle.
        if official_pkg_exists "$pkg"; then
            official_fallback+=("$pkg")
            skipped+=("$pkg")
            continue
        fi

        # Si un -git a un équivalent officiel, on installe l'officiel.
        if [[ "$pkg" == *-git ]]; then
            local base_pkg="${pkg%-git}"

            if official_pkg_exists "$base_pkg"; then
                official_fallback+=("$base_pkg")
                skipped+=("$pkg")
                continue
            fi
        fi

        if yay -Si "$pkg" >/dev/null 2>&1; then
            aur_packages+=("$pkg")
        else
            skipped+=("$pkg")
        fi
    done < <(clean_pkg_name <"$list")

    dedupe_array official_fallback
    dedupe_array aur_packages
    dedupe_array skipped

    if [ "${#skipped[@]}" -gt 0 ]; then
        warn "Paquets AUR ignorés ou remplacés : ${skipped[*]}"
    fi

    if [ "${#official_fallback[@]}" -gt 0 ]; then
        log "Installation des remplacements officiels issus de la liste AUR"
        install_official_targets "${official_fallback[@]}"
    fi

    if [ "${#aur_packages[@]}" -eq 0 ]; then
        warn "Aucun paquet AUR à installer"
        return 0
    fi

    local failed=()

    for pkg in "${aur_packages[@]}"; do
        log "Installation AUR : $pkg"

        if yay -S --needed --noconfirm "$pkg"; then
            log "AUR installé : $pkg"
        else
            warn "Échec AUR : $pkg"
            failed+=("$pkg")
        fi
    done

    if [ "${#failed[@]}" -gt 0 ]; then
        warn "Paquets AUR échoués : ${failed[*]}"
    fi
}

repair_binary_linkage() {
    local cmd="$1"

    if ! have "$cmd"; then
        return 0
    fi

    local bin
    bin="$(command -v "$cmd")"

    # Si un vieux binaire local masque celui de pacman
    if [[ "$bin" == /usr/local/bin/* ]]; then
        warn "$cmd est dans /usr/local/bin et peut masquer le paquet officiel : $bin"

        local official_name="$cmd"

        if official_pkg_exists "$official_name"; then
            local backup="${bin}.bak.$(date +%Y%m%d%H%M%S)"
            sudo mv "$bin" "$backup"
            warn "Ancien binaire déplacé : $backup"
            install_official_targets "$official_name"
            return 0
        fi
    fi

    if ! ldd "$bin" >/dev/null 2>&1; then
        return 0
    fi

    if ! ldd "$bin" 2>/dev/null | grep -q 'not found'; then
        return 0
    fi

    warn "$cmd a des bibliothèques manquantes"
    ldd "$bin" 2>/dev/null | grep 'not found' || true

    local owner
    owner="$(pacman -Qqo "$bin" 2>/dev/null || true)"

    if [ -z "$owner" ]; then
        warn "Impossible de trouver le paquet propriétaire de $bin"
        return 0
    fi

    warn "$cmd appartient à : $owner"

    if [[ "$owner" == *-git ]]; then
        local base_pkg="${owner%-git}"

        if official_pkg_exists "$base_pkg"; then
            warn "$owner est remplacé par le paquet officiel $base_pkg"
            remove_installed_package "$owner"
            install_official_targets "$base_pkg"
            return 0
        fi
    fi

    if official_pkg_exists "$owner"; then
        warn "Réinstallation du paquet officiel : $owner"
        sudo pacman -S --noconfirm "$owner"
        return 0
    fi

    if have yay && yay -Si "$owner" >/dev/null 2>&1; then
        warn "Rebuild du paquet AUR : $owner"
        yay -S --noconfirm "$owner" || warn "Rebuild échoué : $owner"
    fi
}

repair_known_binary_linkages() {
    log "Vérification des binaires critiques"

    local commands=(
        waybar
        Hyprland
        hyprctl
        hyprlock
        hyprpaper
        hyprpicker
        kitty
        rofi
        dunst
        nvim
    )

    for cmd in "${commands[@]}"; do
        repair_binary_linkage "$cmd"
    done
}

install_vimix_cursors() {
    log "Installation des curseurs Vimix"

    local tmpdir
    tmpdir="$(mktemp -d)"

    if git clone https://github.com/vinceliuice/Vimix-cursors.git "$tmpdir/Vimix-cursors"; then
        cd "$tmpdir/Vimix-cursors"
        sudo ./install.sh
        cd "$SCRIPT_DIR"
        rm -rf "$tmpdir"
        log "Curseurs Vimix installés"
    else
        cd "$SCRIPT_DIR"
        rm -rf "$tmpdir"
        warn "Installation des curseurs Vimix ignorée"
    fi
}

fix_user_permissions() {
    log "Réparation des droits utilisateur"

    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.claude"

    local paths=(
        "$HOME/.config/hypr"
        "$HOME/.config/kitty"
        "$HOME/.config/waybar"
        "$HOME/.config/fish"
        "$HOME/.config/nvim"
        "$HOME/.config/cava"
        "$HOME/.config/dunst"
        "$HOME/.config/rofi"
        "$HOME/.config/swayosd"
        "$HOME/.local/share/wallpapers"
        "$HOME/.claude"
    )

    for path in "${paths[@]}"; do
        if [ -e "$path" ]; then
            sudo chown -R "$USER:$USER" "$path" || true
            chmod -R u+rwX "$path" || true
        fi
    done
}

apply_dotfiles() {
    require_file "$SCRIPT_DIR/update.sh"
    require_file "$SCRIPT_DIR/files.sh"
    require_dir "$SRC_ROOT"

    log "Application des dotfiles"

    chmod +x "$SCRIPT_DIR/update.sh"
    fix_user_permissions

    "$SCRIPT_DIR/update.sh" --system

    fix_user_permissions
}

enable_service_if_exists() {
    local service="$1"

    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
        sudo systemctl enable --now "$service"
        log "Service activé : $service"
    else
        warn "Service absent, ignoré : $service"
    fi
}

disable_service_if_exists() {
    local service="$1"

    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
        sudo systemctl disable --now "$service" || true
        log "Service désactivé : $service"
    else
        warn "Service absent, ignoré : $service"
    fi
}

mask_service_if_exists() {
    local service="$1"

    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
        sudo systemctl mask "$service" || true
        log "Service masqué : $service"
    else
        warn "Service absent, ignoré : $service"
    fi
}

configure_services() {
    log "Configuration des services système"

    disable_service_if_exists systemd-resolved.service
    disable_service_if_exists systemd-networkd.service

    enable_service_if_exists NetworkManager.service
    enable_service_if_exists NetworkManager-dispatcher.service
    enable_service_if_exists sddm.service

    if pacman -Qi tlp >/dev/null 2>&1; then
        enable_service_if_exists tlp.service
        mask_service_if_exists systemd-rfkill.service
        mask_service_if_exists systemd-rfkill.socket
    else
        warn "tlp non installé, configuration TLP ignorée"
    fi

    if pacman -Qi docker >/dev/null 2>&1; then
        enable_service_if_exists docker.service
        sudo usermod -aG docker "$USER" || true
    fi
}

configure_user_services() {
    log "Configuration des services utilisateur"

    systemctl --user daemon-reload || true

    systemctl --user enable --now pipewire.service >/dev/null 2>&1 ||
        warn "pipewire.service utilisateur ignoré"

    systemctl --user enable --now pipewire-pulse.service >/dev/null 2>&1 ||
        warn "pipewire-pulse.service utilisateur ignoré"

    systemctl --user enable --now wireplumber.service >/dev/null 2>&1 ||
        warn "wireplumber.service utilisateur ignoré"
}

configure_shell() {
    if ! have fish; then
        warn "fish absent, shell non modifié"
        return 0
    fi

    local fish_path
    fish_path="$(command -v fish)"

    if ! grep -Fxq "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    sudo chsh -s "$fish_path" "$USER" || warn "chsh a échoué"
    fish -c "set -U fish_greeting ''" || true

    log "Shell configuré : fish"
}

warn_repo_issues() {
    log "Vérification rapide du repo"

    if grep -R -nE '<<<<<<<|=======|>>>>>>>' README.md files 2>/dev/null; then
        warn "Conflits Git détectés dans le repo. À nettoyer."
    fi

    if grep -q 'FILES\["tlp"\]="/usr/share/tlp"' "$SCRIPT_DIR/files.sh" 2>/dev/null; then
        warn 'files.sh contient FILES["tlp"]="/usr/share/tlp"'
        warn "/usr/share/tlp est géré par pacman. Il vaut mieux versionner /etc/tlp.conf ou /etc/tlp.d"
    fi
}

show_versions() {
    echo
    log "Versions principales"

    pacman -Q hyprland waybar spdlog fmt 2>/dev/null || true

    echo

    if have Hyprland; then
        Hyprland --version 2>/dev/null | head -n 5 || true
    fi

    if have hyprctl && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        echo
        warn "Tu es dans une session Hyprland active."
        warn "Si Hyprland vient d'être mis à jour, redémarre ou reconnecte-toi."
        hyprctl version 2>/dev/null | head -n 5 || true
    fi
}

main() {
    sudo_keepalive

    require_dir "$SRC_ROOT"
    warn_repo_issues

    enable_multilib_if_needed
    sync_databases_only
    install_keyring

    remove_dynamic_git_conflicts
    full_system_upgrade

    install_core_desktop_stack
    install_yay

    install_pkglist_official
    install_pkglist_aur

    repair_known_binary_linkages

    install_vimix_cursors

    apply_dotfiles

    configure_shell
    configure_services
    configure_user_services

    repair_known_binary_linkages
    show_versions

    log "Installation terminée"
    echo
    echo "Redémarrage conseillé :"
    echo "  reboot"
}

main "$@"
