#!/usr/bin/env bash
set -euo pipefail

PACKAGES_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$PACKAGES_SCRIPT_DIR/common.sh"

PACKAGE_MANAGER=""

detect_package_manager() {
    if command_exists dnf; then
        PACKAGE_MANAGER="dnf"
    elif command_exists apt-get; then
        PACKAGE_MANAGER="apt"
    elif command_exists pacman; then
        PACKAGE_MANAGER="pacman"
    else
        error "Nenhum gerenciador de pacotes suportado foi encontrado."
        exit 1
    fi

    info "Gerenciador de pacotes: $PACKAGE_MANAGER"
}

package_installed() {
    local package="$1"

    case "$PACKAGE_MANAGER" in
        dnf)
            rpm -q "$package" >/dev/null 2>&1
            ;;

        apt)
            dpkg -s "$package" >/dev/null 2>&1
            ;;

        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
    esac
}

install_package() {
    local package="$1"

    if package_installed "$package"; then
        success "$package já está instalado."
        return 0
    fi

    info "Instalando: $package"

    case "$PACKAGE_MANAGER" in
        dnf)
            sudo dnf install -y "$package"
            ;;

        apt)
            sudo apt-get install -y "$package"
            ;;

        pacman)
            sudo pacman -S --needed --noconfirm "$package"
            ;;
    esac

    success "$package instalado."
}

install_required_packages() {
    local packages=(
        git
        curl
        wget
        unzip
        rsync
        jetbrains-mono-fonts
    )

    info "Verificando pacotes básicos..."

    for package in "${packages[@]}"; do
        install_package "$package"
    done
}

setup_packages() {
    detect_package_manager
    install_required_packages
}
