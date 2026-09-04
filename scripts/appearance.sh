#!/usr/bin/env bash
set -euo pipefail

APPEARANCE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPEARANCE_ROOT_DIR="$(cd "$APPEARANCE_SCRIPT_DIR/.." && pwd)"

source "$APPEARANCE_SCRIPT_DIR/common.sh"

ICON_THEME="Papirus-Dark"
ICON_PACKAGE="papirus-icon-theme"

XSETTINGSD_SOURCE="$APPEARANCE_ROOT_DIR/xsettingsd/xsettingsd.conf"
XSETTINGSD_DEST="$HOME/.config/xsettingsd/xsettingsd.conf"

CURSOR_THEME="Bibata-Modern-Ice"
CURSOR_SIZE="24"
CURSOR_VERSION="2.0.7"
CURSOR_URL="https://github.com/ful1e5/Bibata_Cursor/releases/download/v${CURSOR_VERSION}/${CURSOR_THEME}.tar.xz"
ICONS_DEST="$HOME/.local/share/icons"

GTK_THEME="adw-gtk3-dark"
GTK_FONT="Inter 10"
ADW_GTK3_VERSION="6.5"
ADW_GTK3_URL="https://github.com/lassekongo83/adw-gtk3/releases/download/v${ADW_GTK3_VERSION}/adw-gtk3v${ADW_GTK3_VERSION}.tar.xz"
THEMES_DEST="$HOME/.local/share/themes"

QT6CT_CONFIG="$HOME/.config/qt6ct/qt6ct.conf"

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

install_gtk_theme() {
    info "Verificando tema GTK (adw-gtk3)..."

    if [[ -d "$THEMES_DEST/adw-gtk3-dark" ]]; then
        success "adw-gtk3 já está instalado."
        return 0
    fi

    info "Baixando adw-gtk3 v$ADW_GTK3_VERSION..."

    local temp_dir
    temp_dir="$(mktemp -d)"

    curl -fSL "$ADW_GTK3_URL" -o "$temp_dir/adw-gtk3.tar.xz"

    mkdir -p "$THEMES_DEST"
    tar -xf "$temp_dir/adw-gtk3.tar.xz" -C "$THEMES_DEST"

    rm -rf "$temp_dir"

    success "adw-gtk3 instalado."
}

install_qt6ct() {
    info "Verificando qt6ct..."

    if rpm -q qt6ct >/dev/null 2>&1; then
        success "qt6ct já está instalado."
    elif command_exists dnf; then
        sudo dnf install -y qt6ct
        success "qt6ct instalado."
    else
        warning "qt6ct só está configurado para instalação via DNF — pulando."
        return 0
    fi

    if [[ -f "$QT6CT_CONFIG" ]] && grep -q "icon_theme=$ICON_THEME" "$QT6CT_CONFIG"; then
        return 0
    fi

    mkdir -p "$(dirname "$QT6CT_CONFIG")"

    # Config base; o DMS reescreve as cores via template matugen do qt6ct.
    cat > "$QT6CT_CONFIG" <<EOF
[Appearance]
icon_theme=$ICON_THEME
style=Fusion
standard_dialogs=default

[Fonts]
fixed="JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0"
general="Inter,10,-1,5,50,0,0,0,0,0"

[Interface]
cursor_flash_time=1000
double_click_interval=400
EOF

    success "qt6ct configurado."
}

write_gtk_settings() {
    info "Escrevendo settings.ini do GTK..."

    local dark="0"
    [[ "$GTK_THEME" == *dark* ]] && dark="1"

    local ini
    for ver in 3.0 4.0; do
        ini="$HOME/.config/gtk-$ver/settings.ini"
        mkdir -p "$(dirname "$ini")"

        cat > "$ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=$GTK_FONT
gtk-application-prefer-dark-theme=$dark
EOF
    done

    success "settings.ini do GTK escrito (3.0 e 4.0)."
}

apply_gsettings() {
    if ! command_exists gsettings; then
        warning "gsettings não encontrado — pulando aplicação do tema."
        return 0
    fi

    info "Aplicando tema (gsettings)..."

    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
    gsettings set org.gnome.desktop.interface font-name "$GTK_FONT"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

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

    # Se o DMS estiver rodando, aplica ao vivo (ícones + tema GTK/Qt).
    if command_exists dms && pgrep -f 'quickshell/dms' >/dev/null 2>&1; then
        dms ipc call settings set iconThemeDark "$DMS_ICON_THEME_DARK" >/dev/null 2>&1 || true
        dms ipc call settings set iconThemeLight "$DMS_ICON_THEME_LIGHT" >/dev/null 2>&1 || true
        dms ipc call settings set gtkThemingEnabled true >/dev/null 2>&1 || true
        dms ipc call settings set qtThemingEnabled true >/dev/null 2>&1 || true
    fi

    success "Tema de ícones do DMS configurado."
}

setup_xsettingsd() {
    info "Configurando xsettingsd (tema para apps XWayland)..."

    if command_exists dnf && ! rpm -q xsettingsd >/dev/null 2>&1; then
        sudo dnf install -y xsettingsd
    fi

    if [[ ! -f "$XSETTINGSD_SOURCE" ]]; then
        warning "xsettingsd.conf não encontrado em $XSETTINGSD_SOURCE — pulando."
        return 0
    fi

    mkdir -p "$(dirname "$XSETTINGSD_DEST")"

    if [[ -f "$XSETTINGSD_DEST" ]] && ! cmp -s "$XSETTINGSD_SOURCE" "$XSETTINGSD_DEST"; then
        backup_file "$XSETTINGSD_DEST"
    fi

    cp "$XSETTINGSD_SOURCE" "$XSETTINGSD_DEST"

    # Recarrega ao vivo se já estiver rodando (niri o inicia via spawn-at-startup).
    if pgrep -x xsettingsd >/dev/null 2>&1; then
        pkill -HUP -x xsettingsd || true
    fi

    success "xsettingsd configurado."
}

setup_flatpak_theming() {
    if ! command_exists flatpak; then
        return 0
    fi

    info "Aplicando tema aos apps Flatpak (override global)..."

    # Extensão do tema GTK3 (usada por apps Flatpak que ainda dependem de GTK3).
    flatpak install -y --noninteractive flathub "org.gtk.Gtk3theme.${GTK_THEME}" >/dev/null 2>&1 || true

    flatpak override --user \
        --env=GTK_THEME="$GTK_THEME" \
        --env=ICON_THEME="$ICON_THEME" \
        --env=XCURSOR_THEME="$CURSOR_THEME" \
        --env=XCURSOR_SIZE="$CURSOR_SIZE" \
        --filesystem=xdg-config/gtk-3.0:ro \
        --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem="$THEMES_DEST":ro \
        --filesystem="$HOME/.themes":ro \
        --filesystem=/usr/share/icons:ro \
        --filesystem="$ICONS_DEST":ro \
        --filesystem="$HOME/.icons":ro

    success "Override de tema do Flatpak aplicado."
}

setup_appearance() {
    info "Configurando aparência (ícones + cursor + GTK/Qt)..."

    install_icon_theme
    install_cursor_theme
    install_gtk_theme
    install_qt6ct
    write_gtk_settings
    apply_gsettings
    apply_xresources_cursor
    setup_xsettingsd
    setup_flatpak_theming
    configure_dms_icon_theme

    success "Aparência preparada."
}
