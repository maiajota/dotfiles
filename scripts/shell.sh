#!/usr/bin/env bash
set -euo pipefail

SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SHELL_SCRIPT_DIR/.." && pwd)"

source "$SHELL_SCRIPT_DIR/common.sh"

STARSHIP_COPR="atim/starship"
STARSHIP_CONFIG_SOURCE="$ROOT_DIR/shell/starship.toml"
STARSHIP_CONFIG_DEST="$HOME/.config/starship.toml"

install_zsh() {
    info "Verificando Zsh..."

    if command_exists zsh; then
        success "Zsh já está instalado."
        return 0
    fi

    info "Instalando Zsh..."

    case "${OS_ID:-unknown}" in
        fedora)
            sudo dnf install -y zsh
            ;;
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y zsh
            ;;
        arch)
            sudo pacman -S --needed --noconfirm zsh
            ;;
        *)
            error "Distribuição não suportada para instalação do Zsh."
            exit 1
            ;;
    esac

    success "Zsh instalado."
}

install_zsh_config() {
    local config_source="$SHELL_SCRIPT_DIR/../shell/.zshrc"
    local config_dest="$HOME/.zshrc"

    if [[ ! -f "$config_source" ]]; then
        error "Arquivo .zshrc não encontrado:"
        error "$config_source"
        exit 1
    fi

    info "Configurando Zsh..."

    if [[ -f "$config_dest" ]] && ! cmp -s "$config_source" "$config_dest"; then
        backup_file "$config_dest"
    fi

    cp "$config_source" "$config_dest"

    success "Configuração do Zsh instalada."
}

install_zsh_plugins() {
    info "Instalando plugins e utilitários do shell..."

    if ! command_exists dnf; then
        warning "Plugins do shell configurados para instalação via DNF — pulando."
        return 0
    fi

    local packages=(
        zsh-autosuggestions
        zsh-syntax-highlighting
        fzf
        fd-find
        bat
        eza
    )

    for package in "${packages[@]}"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            success "$package já está instalado."
        else
            sudo dnf install -y "$package"
            success "$package instalado."
        fi
    done
}

install_starship() {
    info "Verificando Starship..."

    if command_exists starship; then
        success "Starship já está instalado."
    elif command_exists dnf; then
        if ! dnf copr list 2>/dev/null | grep -q "atim/starship"; then
            info "Habilitando COPR: $STARSHIP_COPR"
            sudo dnf copr enable -y "$STARSHIP_COPR"
        fi
        sudo dnf install -y starship
        success "Starship instalado."
    else
        warning "Starship só está configurado para instalação via DNF/COPR — pulando."
        return 0
    fi

    if [[ ! -f "$STARSHIP_CONFIG_SOURCE" ]]; then
        warning "starship.toml não encontrado em $STARSHIP_CONFIG_SOURCE — pulando config."
        return 0
    fi

    mkdir -p "$(dirname "$STARSHIP_CONFIG_DEST")"

    if [[ -f "$STARSHIP_CONFIG_DEST" ]] && ! cmp -s "$STARSHIP_CONFIG_SOURCE" "$STARSHIP_CONFIG_DEST"; then
        backup_file "$STARSHIP_CONFIG_DEST"
    fi

    cp "$STARSHIP_CONFIG_SOURCE" "$STARSHIP_CONFIG_DEST"

    success "Configuração do Starship instalada."
}

set_default_shell() {
    local zsh_path

    zsh_path="$(command -v zsh)"

    if [[ "$SHELL" == "$zsh_path" ]]; then
        success "Zsh já é o shell padrão."
        return 0
    fi

    info "Definindo Zsh como shell padrão..."

    chsh -s "$zsh_path"

    success "Zsh definido como shell padrão."
}

setup_shell() {
    info "Configurando shell..."
    install_zsh
    install_zsh_plugins
    install_starship
    install_zsh_config
    set_default_shell
    success "Shell preparado."
}
