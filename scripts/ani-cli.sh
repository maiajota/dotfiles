#!/usr/bin/env bash
set -euo pipefail

ANI_CLI_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ANI_CLI_SCRIPT_DIR/common.sh"

install_ani_cli() {
    info "Verificando ani-cli..."

    if command_exists ani-cli; then
        success "ani-cli já está instalado."
        return 0
    fi

    if ! command_exists dnf; then
        error "ani-cli atualmente está configurado para instalação via DNF/COPR."
        exit 1
    fi

    info "Habilitando COPR do ani-cli..."

    sudo dnf copr enable -y derisis13/ani-cli

    info "Instalando ani-cli..."

    sudo dnf install -y ani-cli

    success "ani-cli instalado."
}

setup_ani_cli() {
    info "Configurando ani-cli..."

    install_ani_cli

    success "ani-cli preparado."
}

