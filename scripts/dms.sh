#!/usr/bin/env bash
set -euo pipefail

DMS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$DMS_SCRIPT_DIR/.." && pwd)"

source "$DMS_SCRIPT_DIR/common.sh"

DMS_COPR="avengemedia/dms"

NIRI_CONFIG_SOURCE="$ROOT_DIR/niri"
NIRI_CONFIG_DIR="$HOME/.config/niri"
NIRI_CONFIG="$NIRI_CONFIG_DIR/config.kdl"
NIRI_SESSION_FILE="/usr/share/wayland-sessions/niri.desktop"

SDDM_STATE_FILE="/var/lib/sddm/state.conf"

DMS_CONFIG_DIR="$HOME/.config/DankMaterialShell"
DMS_PLUGINS_DIR="$DMS_CONFIG_DIR/plugins"
DMS_PLUGIN_SETTINGS="$DMS_CONFIG_DIR/plugin_settings.json"
DMS_PLUGINS=(
    niriWindows
)

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

install_niri_config() {
    info "Instalando config do niri..."

    if [[ ! -f "$NIRI_CONFIG_SOURCE/config.kdl" ]]; then
        error "config.kdl não encontrado:"
        error "$NIRI_CONFIG_SOURCE/config.kdl"
        exit 1
    fi

    mkdir -p "$NIRI_CONFIG_DIR/dms"

    # Stub de cores para o `include "dms/colors.kdl"` não quebrar antes do
    # primeiro run do DMS (o próprio DMS regenera com o tema do wallpaper).
    [[ -f "$NIRI_CONFIG_DIR/dms/colors.kdl" ]] || : > "$NIRI_CONFIG_DIR/dms/colors.kdl"

    if [[ -f "$NIRI_CONFIG" ]] && ! cmp -s "$NIRI_CONFIG_SOURCE/config.kdl" "$NIRI_CONFIG"; then
        backup_file "$NIRI_CONFIG"
    fi

    cp "$NIRI_CONFIG_SOURCE/config.kdl" "$NIRI_CONFIG"

    if niri validate --config "$NIRI_CONFIG" >/dev/null 2>&1; then
        success "Config do niri instalada e validada."
    else
        warning "niri validate reportou problemas em $NIRI_CONFIG — revise manualmente."
    fi
}

install_dms_plugins() {
    if [[ ${#DMS_PLUGINS[@]} -eq 0 ]]; then
        return 0
    fi

    info "Instalando plugins do DMS..."

    if ! command_exists dms; then
        warning "dms não encontrado — pulando plugins."
        return 0
    fi

    mkdir -p "$DMS_CONFIG_DIR"

    for plugin in "${DMS_PLUGINS[@]}"; do
        if [[ -d "$DMS_PLUGINS_DIR/$plugin" ]]; then
            success "Plugin $plugin já está instalado."
        else
            info "Instalando plugin: $plugin"
            dms plugins install "$plugin"
        fi

        # Marca como habilitado no plugin_settings.json
        if command_exists jq; then
            local tmp
            tmp="$(mktemp)"
            if [[ -f "$DMS_PLUGIN_SETTINGS" ]]; then
                jq --arg p "$plugin" '.[$p] = ((.[$p] // {}) + {enabled: true})' \
                    "$DMS_PLUGIN_SETTINGS" > "$tmp" && mv "$tmp" "$DMS_PLUGIN_SETTINGS"
            else
                jq -n --arg p "$plugin" '{($p): {enabled: true}}' > "$DMS_PLUGIN_SETTINGS"
            fi
        fi

        # Aplica ao vivo se o DMS estiver rodando
        if pgrep -f 'quickshell/dms' >/dev/null 2>&1; then
            dms ipc call plugins enable "$plugin" >/dev/null 2>&1 || true
        fi
    done

    success "Plugins do DMS preparados."
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
    install_niri_config
    install_dms_plugins
    set_niri_as_default_session

    success "DankMaterialShell preparado (sessão padrão: niri)."
}
