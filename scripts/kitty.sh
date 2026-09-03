#!/usr/bin/env bash
set -euo pipefail

KITTY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$KITTY_SCRIPT_DIR/.." && pwd)"

source "$KITTY_SCRIPT_DIR/common.sh"

KITTY_CONFIG_SOURCE="$ROOT_DIR/kitty"
KITTY_CONFIG_DEST="$HOME/.config/kitty"

install_kitty() {
    info "Verificando Kitty..."

    if command_exists kitty; then
        success "Kitty já está instalado."
        return 0
    fi

    info "Instalando Kitty..."

    case "${OS_ID:-unknown}" in
        fedora)
            sudo dnf install -y kitty
            ;;

        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y kitty
            ;;

        arch)
            sudo pacman -S --needed --noconfirm kitty
            ;;

        *)
            error "Distribuição não suportada para instalação do Kitty."
            exit 1
            ;;
    esac

    success "Kitty instalado."
}

install_kitty_config() {
    if [[ ! -d "$KITTY_CONFIG_SOURCE" ]]; then
        warning "Diretório de configuração do Kitty não existe."
        warning "Pulando configuração."
        return 0
    fi

    info "Configurando Kitty..."

    mkdir -p "$KITTY_CONFIG_DEST"

    rsync -a "$KITTY_CONFIG_SOURCE/" "$KITTY_CONFIG_DEST/"

    success "Configuração do Kitty instalada."
}

setup_kitty() {
    install_kitty
    install_kitty_config
}
