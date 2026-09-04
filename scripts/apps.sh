#!/usr/bin/env bash
set -euo pipefail

APPS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$APPS_SCRIPT_DIR/common.sh"

FLATHUB_REPO="https://flathub.org/repo/flathub.flatpakrepo"

# Apps instalados via Flatpak (Flathub). Vazio por enquanto — mantido para
# facilitar adicionar apps que só existem como Flatpak.
FLATPAK_APPS=()

# Spotify: RPM nativo do repo negativo17 (reempacote do .deb oficial). Preferido
# ao Flatpak porque usa o GTK do sistema (tema/barra de título corretos) e sai
# do sandbox. https://negativo17.org/spotify-client/
SPOTIFY_REPO_URL="https://negativo17.org/repos/fedora-spotify.repo"
SPOTIFY_REPO_FILE="/etc/yum.repos.d/fedora-spotify.repo"
SPOTIFY_PACKAGE="spotify-client"
SPOTIFY_DESKTOP_OVERRIDE="$HOME/.local/share/applications/spotify.desktop"

# Steam: pacote nativo do RPM Fusion nonfree (melhor integração com Proton/drivers
# que o Flatpak). Trocar para com.valvesoftware.Steam se preferir sandbox.
STEAM_PACKAGE="steam"


setup_flatpak() {
    info "Verificando Flatpak..."

    if ! command_exists flatpak; then
        if command_exists dnf; then
            sudo dnf install -y flatpak
        else
            warning "Flatpak não encontrado e sem dnf para instalar — pulando."
            return 0
        fi
    fi

    if ! flatpak remotes --columns=name 2>/dev/null | grep -qx flathub; then
        info "Adicionando remote Flathub..."
        flatpak remote-add --if-not-exists flathub "$FLATHUB_REPO"
    fi

    success "Flatpak pronto (Flathub habilitado)."
}


install_flatpak_apps() {
    (( ${#FLATPAK_APPS[@]} )) || return 0

    for app in "${FLATPAK_APPS[@]}"; do
        if flatpak info "$app" >/dev/null 2>&1; then
            success "$app já está instalado."
            continue
        fi

        info "Instalando (Flatpak): $app"
        flatpak install -y --noninteractive flathub "$app"
        success "$app instalado."
    done
}


install_spotify() {
    if ! command_exists dnf; then
        warning "Spotify configurado apenas para instalação via DNF — pulando."
        return 0
    fi

    if rpm -q "$SPOTIFY_PACKAGE" >/dev/null 2>&1; then
        success "Spotify já está instalado."
        return 0
    fi

    # Remove uma eventual instalação anterior via Flatpak.
    if command_exists flatpak && flatpak info com.spotify.Client >/dev/null 2>&1; then
        info "Removendo Spotify (Flatpak) antigo..."
        sudo flatpak mask --remove com.spotify.Client >/dev/null 2>&1 || true
        sudo flatpak uninstall -y com.spotify.Client || true
    fi

    if [[ ! -f "$SPOTIFY_REPO_FILE" ]]; then
        info "Adicionando repo negativo17 (Spotify)..."
        sudo curl -fSL -o "$SPOTIFY_REPO_FILE" "$SPOTIFY_REPO_URL"
    fi

    info "Instalando Spotify ($SPOTIFY_PACKAGE)..."
    sudo dnf install -y "$SPOTIFY_PACKAGE"
    success "Spotify instalado."

    install_spotify_desktop_override
}

install_spotify_desktop_override() {
    # O Spotify (CEF) ignora o tema GTK e desenha uma barra de título feia.
    # Rodando em modo Wayland + `prefer-no-csd` no niri a barra some (fica só o
    # focus ring). Este override força `--ozone-platform=wayland` no lançador.
    local system_desktop="/usr/share/applications/spotify.desktop"
    [[ -f "$system_desktop" ]] || return 0

    info "Instalando override do lançador do Spotify (modo Wayland)..."
    mkdir -p "$(dirname "$SPOTIFY_DESKTOP_OVERRIDE")"

    sed 's|^Exec=spotify |Exec=spotify --ozone-platform=wayland |' \
        "$system_desktop" > "$SPOTIFY_DESKTOP_OVERRIDE"

    update-desktop-database "$(dirname "$SPOTIFY_DESKTOP_OVERRIDE")" 2>/dev/null || true
    success "Lançador do Spotify configurado (Wayland)."
}


enable_rpmfusion_nonfree() {
    command_exists dnf || return 0

    if rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
        success "RPM Fusion nonfree já está habilitado."
        return 0
    fi

    local fedora_ver
    fedora_ver="$(rpm -E %fedora)"

    info "Habilitando RPM Fusion nonfree (Fedora $fedora_ver)..."
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

    success "RPM Fusion nonfree habilitado."
}


install_steam() {
    if ! command_exists dnf; then
        warning "Steam configurado apenas para instalação via DNF — pulando."
        return 0
    fi

    if rpm -q "$STEAM_PACKAGE" >/dev/null 2>&1; then
        success "Steam já está instalado."
        return 0
    fi

    enable_rpmfusion_nonfree

    info "Instalando Steam ($STEAM_PACKAGE)..."
    sudo dnf install -y "$STEAM_PACKAGE"
    success "Steam instalado."
}


setup_apps() {
    info "Instalando aplicativos (Spotify, Steam)..."

    setup_flatpak
    install_flatpak_apps
    install_spotify
    install_steam

    success "Aplicativos instalados."
}
