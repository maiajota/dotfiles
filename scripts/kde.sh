#!/usr/bin/env bash
set -euo pipefail

KDE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$KDE_SCRIPT_DIR/.." && pwd)"

source "$KDE_SCRIPT_DIR/common.sh"

require_kde() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"

    if [[ "$desktop" != *"KDE"* ]]; then
        error "KDE Plasma não foi detectado."
        error "Desktop atual: ${desktop:-desconhecido}"
        exit 1
    fi

    success "KDE Plasma detectado."
}

detect_plasma_version() {
    if command_exists plasmashell; then
        local version

        version="$(plasmashell --version 2>/dev/null | head -n 1)"

        info "Versão do Plasma: $version"
    else
        warning "Não foi possível detectar a versão do Plasma."
    fi
}

detect_kde_session() {
    local session="${XDG_SESSION_DESKTOP:-unknown}"

    info "Sessão KDE: $session"
}

setup_kde() {
    info "Configurando KDE Plasma..."

    require_kde
    detect_plasma_version
    detect_kde_session

    success "Base do KDE preparada."
}

