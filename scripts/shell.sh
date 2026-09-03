#!/usr/bin/env bash
set -euo pipefail

SHELL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SHELL_SCRIPT_DIR/common.sh"

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
    install_zsh_config
    set_default_shell
    success "Shell preparado."
}
