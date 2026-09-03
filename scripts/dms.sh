#!/usr/bin/env bash
set -euo pipefail

DMS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DMS_SCRIPT_DIR/common.sh"

DMS_COPR="avengemedia/dms"

NIRI_CONFIG_DIR="$HOME/.config/niri"
NIRI_CONFIG="$NIRI_CONFIG_DIR/config.kdl"
NIRI_DEFAULT_CONFIG="/usr/share/doc/niri/default-config.kdl"
NIRI_SESSION_FILE="/usr/share/wayland-sessions/niri.desktop"

SDDM_STATE_FILE="/var/lib/sddm/state.conf"

enable_dms_copr() {
    info "Verificando COPR do DMS ($DMS_COPR)..."

    if ! command_exists dnf; then
        error "DMS atualmente está configurado para instalação via DNF/COPR."
        exit 1
    fi

    if dnf copr list 2>/dev/null | grep -q "avengemedia/dms"; then
        success "COPR $DMS_COPR já está habilitado."
        return 0
    fi

    info "Habilitando COPR: $DMS_COPR"

    sudo dnf copr enable -y "$DMS_COPR"

    success "COPR do DMS habilitado."
}

install_dms() {
    info "Verificando DankMaterialShell..."

    if command_exists dms; then
        success "DMS já está instalado."
        return 0
    fi

    info "Instalando DMS (dms, quickshell, matugen, dgop, danksearch)..."

    sudo dnf install -y dms

    success "DMS instalado."
}

install_niri() {
    info "Verificando niri..."

    if command_exists niri; then
        success "niri já está instalado."
        return 0
    fi

    info "Instalando niri..."

    sudo dnf install -y niri

    success "niri instalado."
}

configure_niri_autostart() {
    info "Configurando autostart do DMS no niri..."

    mkdir -p "$NIRI_CONFIG_DIR/dms"

    # O niri gera o config no primeiro start; se ainda não existe, parte do template padrão.
    if [[ ! -f "$NIRI_CONFIG" ]]; then
        if [[ -f "$NIRI_DEFAULT_CONFIG" ]]; then
            info "Criando config.kdl a partir do template padrão do niri."
            cp "$NIRI_DEFAULT_CONFIG" "$NIRI_CONFIG"
        else
            info "Criando config.kdl mínimo."
            : > "$NIRI_CONFIG"
        fi
    fi

    # Já configurado? Não mexe (evita empilhar backups a cada re-run).
    if grep -qE 'spawn-at-startup\s+"dms"\s+"run"' "$NIRI_CONFIG" \
        && grep -q 'include "dms/colors.kdl"' "$NIRI_CONFIG"; then
        success "Autostart do DMS já configurado no niri."
        return 0
    fi

    backup_file "$NIRI_CONFIG"

    # O DMS substitui a waybar: comenta o spawn padrão se estiver presente.
    if grep -qE '^\s*spawn-at-startup\s+"waybar"' "$NIRI_CONFIG"; then
        sed -i -E 's|^(\s*)(spawn-at-startup\s+"waybar")|\1/-\2|' "$NIRI_CONFIG"
        info "waybar desativada no niri (o DMS assume a barra)."
    fi

    # Stub de cores para o include não quebrar antes do primeiro run do DMS
    # (o próprio DMS regenera esse arquivo com o tema do wallpaper).
    [[ -f "$NIRI_CONFIG_DIR/dms/colors.kdl" ]] || : > "$NIRI_CONFIG_DIR/dms/colors.kdl"

    if ! grep -q 'include "dms/colors.kdl"' "$NIRI_CONFIG"; then
        printf '\n// DMS (dotfiles)\ninclude "dms/colors.kdl"\n' >> "$NIRI_CONFIG"
    fi

    grep -qE 'spawn-at-startup\s+"dms"\s+"run"' "$NIRI_CONFIG" \
        || printf 'spawn-at-startup "dms" "run"\n' >> "$NIRI_CONFIG"

    success "Autostart do DMS configurado no niri."

    if niri validate --config "$NIRI_CONFIG" >/dev/null 2>&1; then
        success "Config do niri validada."
    else
        warning "niri validate reportou problemas em $NIRI_CONFIG — revise manualmente."
    fi
}

set_niri_as_default_session() {
    info "Definindo niri como sessão padrão no SDDM..."

    if [[ ! -f "$NIRI_SESSION_FILE" ]]; then
        error "Sessão do niri não encontrada: $NIRI_SESSION_FILE"
        exit 1
    fi

    sudo mkdir -p "$(dirname "$SDDM_STATE_FILE")"

    sudo tee "$SDDM_STATE_FILE" >/dev/null <<EOF
[Last]
# Name of the last logged-in user.
# This user will be preselected when the login screen appears
User=$USER

# Name of the session for the last logged-in user.
# This session will be preselected when the login screen appears.
Session=$NIRI_SESSION_FILE
EOF

    sudo chown sddm:sddm "$SDDM_STATE_FILE"
    sudo chmod 600 "$SDDM_STATE_FILE"

    success "niri definido como sessão padrão."
}

setup_dms() {
    info "Configurando DankMaterialShell..."

    enable_dms_copr
    install_dms
    install_niri
    configure_niri_autostart
    set_niri_as_default_session

    success "DankMaterialShell preparado (sessão padrão: niri)."
}
