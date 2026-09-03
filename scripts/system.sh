#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Maia Dotfiles - System Detection
# ==========================================

SYSTEM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SYSTEM_SCRIPT_DIR/common.sh"

detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Não foi possível detectar o sistema operacional."
        exit 1
    fi

    source /etc/os-release

    OS_ID="${ID:-unknown}"
    OS_NAME="${NAME:-unknown}"
    OS_VERSION="${VERSION_ID:-unknown}"

    info "Sistema detectado: $OS_NAME"
    info "ID: $OS_ID"
    info "Versão: $OS_VERSION"
}


detect_desktop() {
    local desktop="${XDG_CURRENT_DESKTOP:-unknown}"
    local session="${XDG_SESSION_DESKTOP:-unknown}"

    info "Desktop atual: $desktop"
    info "Sessão: $session"
}


detect_display_manager() {
    local display_manager

    display_manager="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || echo unknown)")"

    if [[ "$display_manager" == "unknown" ]]; then
        warning "Nenhum display manager detectado."
        return 0
    fi

    info "Display Manager: $display_manager"
}
