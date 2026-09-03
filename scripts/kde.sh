#!/usr/bin/env bash
set -euo pipefail

KDE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$KDE_SCRIPT_DIR/.." && pwd)"

source "$KDE_SCRIPT_DIR/common.sh"

is_kde_session() {
    local desktop="${XDG_CURRENT_DESKTOP:-}"

    [[ "$desktop" == *"KDE"* ]]
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

    if ! is_kde_session; then
        warning "Sessão atual não é KDE (${XDG_CURRENT_DESKTOP:-desconhecido}) — pulando etapa do KDE."
        return 0
    fi

    detect_plasma_version
    detect_kde_session

    success "Base do KDE preparada."
}

