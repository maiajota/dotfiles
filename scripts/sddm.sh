#!/usr/bin/env bash
set -euo pipefail

SDDM_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SDDM_SCRIPT_DIR/.." && pwd)"

source "$SDDM_SCRIPT_DIR/common.sh"

SDDM_SERVICE="sddm.service"
SDDM_THEME_NAME="maia-theme"
SDDM_THEME_SOURCE="$ROOT_DIR/sddm/theme/$SDDM_THEME_NAME"
SDDM_THEME_DEST="/usr/share/sddm/themes/$SDDM_THEME_NAME"
SDDM_CONFIG="/etc/sddm.conf"

install_sddm() {
    info "Verificando SDDM..."

    if rpm -q sddm >/dev/null 2>&1; then
        success "SDDM já está instalado."
        return 0
    fi

    info "Instalando SDDM..."

    sudo dnf install -y sddm

    success "SDDM instalado."
}

install_sddm_theme() {
    info "Verificando tema Maia..."

    if [[ ! -d "$SDDM_THEME_SOURCE" ]]; then
        error "Tema não encontrado:"
        error "$SDDM_THEME_SOURCE"
        exit 1
    fi

    if [[ ! -f "$SDDM_THEME_SOURCE/Main.qml" ]]; then
        error "Main.qml não encontrado no tema."
        exit 1
    fi

    if [[ ! -f "$SDDM_THEME_SOURCE/metadata.desktop" ]]; then
        error "metadata.desktop não encontrado no tema."
        exit 1
    fi

    info "Instalando tema: $SDDM_THEME_NAME"

    sudo mkdir -p "/usr/share/sddm/themes"

    sudo rm -rf "$SDDM_THEME_DEST"

    sudo cp -a "$SDDM_THEME_SOURCE" "$SDDM_THEME_DEST"

    success "Tema Maia instalado."
}

configure_sddm() {
    info "Configurando SDDM..."

    if [[ -f "$SDDM_CONFIG" ]]; then
        backup_file "$SDDM_CONFIG"
    fi

    sudo tee "$SDDM_CONFIG" >/dev/null <<EOF
[Theme]
Current=$SDDM_THEME_NAME
EOF

    success "Configuração do SDDM criada."
}

enable_sddm() {
    info "Configurando SDDM como display manager..."

    sudo systemctl enable --force "$SDDM_SERVICE"

    success "SDDM configurado como display manager padrão."
}

initialize_sddm_state() {
    local state_file="/var/lib/sddm/state.conf"
    local sddm_user="$USER"
    local plasma_session="/usr/share/wayland-sessions/plasma.desktop"

    info "Inicializando estado do SDDM..."

    sudo mkdir -p "/var/lib/sddm"

    sudo tee "$state_file" >/dev/null <<EOF
[Last]
# Name of the last logged-in user.
# This user will be preselected when the login screen appears
User=$sddm_user

# Name of the session for the last logged-in user.
# This session will be preselected when the login screen appears.
Session=$plasma_session
EOF

    sudo chown sddm:sddm "$state_file"
    sudo chmod 600 "$state_file"

    success "Estado inicial do SDDM configurado para: $sddm_user"
}

setup_sddm() {
    install_sddm
    install_sddm_theme
    configure_sddm
    initialize_sddm_state
    enable_sddm
}
