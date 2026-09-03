#!/usr/bin/env bash
set -euo pipefail

APPEARANCE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$APPEARANCE_SCRIPT_DIR/common.sh"

ICON_THEME="Papirus-Dark"
ICON_PACKAGE="papirus-icon-theme"

CURSOR_THEME="Bibata-Modern-Ice"
CURSOR_SIZE="24"
CURSOR_VERSION="2.0.7"
CURSOR_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/v${CURSOR_VERSION}/${CURSOR_THEME}.tar.xz"
ICONS_DEST="$HOME/.local/share/icons"

DMS_SETTINGS="$HOME/.config/DankMaterialShell/settings.json"
DMS_ICON_THEME_DARK="Papirus-Dark"
DMS_ICON_THEME_LIGHT="Papirus-Light"

install_icon_theme() {
    info "Verificando tema de ícones ($ICON_PACKAGE)..."

    if rpm -q "$ICON_PACKAGE" >/dev/null 2>&1; then
        success "$ICON_PACKAGE já está instalado."
        return 0
    fi

    sudo dnf install -y "$ICON_PACKAGE"

    success "$ICON_PACKAGE instalado."
}

install_cursor_theme() {
    info "Verificando cursor ($CURSOR_THEME)..."

    if [[ -d "$ICONS_DEST/$CURSOR_THEME" ]]; then
        success "$CURSOR_THEME já está instalado."
        return 0
    fi

    info "Baixando $CURSOR_THEME v$CURSOR_VERSION..."

    local temp_dir
    temp_dir="$(mktemp -d)"

    curl -fSL "$CURSOR_URL" -o "$temp_dir/cursor.tar.xz"

    mkdir -p "$ICONS_DEST"
    tar -xf "$temp_dir/cursor.tar.xz" -C "$ICONS_DEST"

    rm -rf "$temp_dir"

    success "$CURSOR_THEME instalado."
}

apply_gsettings() {
    if ! command_exists gsettings; then
        warning "gsettings não encontrado — pulando aplicação do tema."
        return 0
    fi

    info "Aplicando tema de ícones e cursor (GTK/gsettings)..."

    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

    success "Tema aplicado."
}

apply_xresources_cursor() {
    local index_file="$ICONS_DEST/default/index.theme"

    info "Definindo cursor padrão do X/Wayland..."

    mkdir -p "$ICONS_DEST/default"

    cat > "$index_file" <<EOF
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=$CURSOR_THEME
EOF

    success "Cursor padrão definido para $CURSOR_THEME."
}

configure_dms_icon_theme() {
    info "Definindo tema de ícones do DMS ($DMS_ICON_THEME_DARK)..."

    if ! command_exists jq; then
        warning "jq não encontrado — pulando ajuste do DMS."
        return 0
    fi

    mkdir -p "$(dirname "$DMS_SETTINGS")"

    if [[ -f "$DMS_SETTINGS" ]]; then
        local current
        current="$(jq -r '.iconThemeDark // ""' "$DMS_SETTINGS")"

        if [[ "$current" == "$DMS_ICON_THEME_DARK" ]]; then
            success "DMS já usa $DMS_ICON_THEME_DARK."
        else
            local tmp
            tmp="$(mktemp)"
            jq --arg d "$DMS_ICON_THEME_DARK" --arg l "$DMS_ICON_THEME_LIGHT" \
                '.iconThemeDark = $d | .iconThemeLight = $l' \
                "$DMS_SETTINGS" > "$tmp" && mv "$tmp" "$DMS_SETTINGS"
            success "settings.json do DMS atualizado."
        fi
    else
        jq -n --arg d "$DMS_ICON_THEME_DARK" --arg l "$DMS_ICON_THEME_LIGHT" \
            '{iconThemeDark: $d, iconThemeLight: $l}' > "$DMS_SETTINGS"
        info "settings.json do DMS criado (será mesclado no primeiro run)."
    fi

    # Se o DMS estiver rodando, aplica ao vivo.
    if command_exists dms && pgrep -f 'quickshell/dms' >/dev/null 2>&1; then
        dms ipc call settings set iconThemeDark "$DMS_ICON_THEME_DARK" >/dev/null 2>&1 || true
        dms ipc call settings set iconThemeLight "$DMS_ICON_THEME_LIGHT" >/dev/null 2>&1 || true
    fi

    success "Tema de ícones do DMS configurado."
}

setup_appearance() {
    info "Configurando aparência (ícones + cursor)..."

    install_icon_theme
    install_cursor_theme
    apply_gsettings
    apply_xresources_cursor
    configure_dms_icon_theme

    success "Aparência preparada."
}
