#!/usr/bin/env bash
set -euo pipefail

FASTFETCH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FASTFETCH_SCRIPT_DIR/.." && pwd)"

source "$FASTFETCH_SCRIPT_DIR/common.sh"

FASTFETCH_CONFIG_SOURCE="$ROOT_DIR/fastfetch/config.jsonc"
FASTFETCH_CONFIG_DEST="$HOME/.config/fastfetch/config.jsonc"

install_fastfetch() {
    info "Verificando fastfetch..."

    if command_exists fastfetch; then
        success "fastfetch já está instalado."
        return 0
    fi

    if ! command_exists dnf; then
        error "fastfetch atualmente está configurado para instalação via DNF."
        exit 1
    fi

    sudo dnf install -y fastfetch

    success "fastfetch instalado."
}

install_fastfetch_config() {
    if [[ ! -f "$FASTFETCH_CONFIG_SOURCE" ]]; then
        warning "config.jsonc não encontrado em $FASTFETCH_CONFIG_SOURCE — pulando."
        return 0
    fi

    info "Configurando fastfetch..."

    mkdir -p "$(dirname "$FASTFETCH_CONFIG_DEST")"

    if [[ -f "$FASTFETCH_CONFIG_DEST" ]] && ! cmp -s "$FASTFETCH_CONFIG_SOURCE" "$FASTFETCH_CONFIG_DEST"; then
        backup_file "$FASTFETCH_CONFIG_DEST"
    fi

    cp "$FASTFETCH_CONFIG_SOURCE" "$FASTFETCH_CONFIG_DEST"

    success "Configuração do fastfetch instalada."
}

setup_fastfetch() {
    info "Configurando fastfetch..."

    install_fastfetch
    install_fastfetch_config

    success "fastfetch preparado."
}
