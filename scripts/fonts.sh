#!/usr/bin/env bash
set -euo pipefail

FONTS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FONTS_SCRIPT_DIR/.." && pwd)"

source "$FONTS_SCRIPT_DIR/common.sh"

FONTS_SOURCE="$ROOT_DIR/fonts"
FONTS_DEST="$HOME/.local/share/fonts"

NERD_FONT_NAME="JetBrainsMono"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${NERD_FONT_NAME}.tar.xz"
NERD_FONT_DEST="$FONTS_DEST/${NERD_FONT_NAME}NerdFont"

install_system_fonts() {
    info "Instalando fontes do sistema..."

    local packages=(
        jetbrains-mono-fonts
        rsms-inter-fonts
    )

    for package in "${packages[@]}"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            success "$package já está instalado."
        else
            sudo dnf install -y "$package"
            success "$package instalado."
        fi
    done
}

install_nerd_font() {
    info "Verificando $NERD_FONT_NAME Nerd Font..."

    if [[ -d "$NERD_FONT_DEST" ]] && compgen -G "$NERD_FONT_DEST/*.ttf" >/dev/null; then
        success "$NERD_FONT_NAME Nerd Font já está instalada."
        return 0
    fi

    info "Baixando $NERD_FONT_NAME Nerd Font..."

    local temp_dir
    temp_dir="$(mktemp -d)"

    curl -fSL "$NERD_FONT_URL" -o "$temp_dir/nerd-font.tar.xz"

    mkdir -p "$NERD_FONT_DEST"
    tar -xf "$temp_dir/nerd-font.tar.xz" -C "$NERD_FONT_DEST" --wildcards '*.ttf'

    rm -rf "$temp_dir"

    success "$NERD_FONT_NAME Nerd Font instalada."
}

install_local_fonts() {
    if [[ ! -d "$FONTS_SOURCE" ]] || ! compgen -G "$FONTS_SOURCE/*" >/dev/null; then
        return 0
    fi

    info "Copiando fontes do repositório..."

    mkdir -p "$FONTS_DEST"
    rsync -a "$FONTS_SOURCE/" "$FONTS_DEST/"

    success "Fontes do repositório instaladas."
}

setup_fonts() {
    info "Configurando fontes..."

    install_system_fonts
    install_nerd_font
    install_local_fonts

    info "Atualizando cache de fontes..."
    fc-cache -f >/dev/null

    success "Fontes preparadas."
}
