#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# Maia Dotfiles
# ==========================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ROOT_DIR/scripts/common.sh"
source "$ROOT_DIR/scripts/system.sh"
source "$ROOT_DIR/scripts/packages.sh"
source "$ROOT_DIR/scripts/sddm.sh"
source "$ROOT_DIR/scripts/kde.sh"
source "$ROOT_DIR/scripts/kitty.sh"
source "$ROOT_DIR/scripts/shell.sh"
source "$ROOT_DIR/scripts/pokemon.sh"
source "$ROOT_DIR/scripts/ani-cli.sh"

# ==========================================
# Bootstrap
# ==========================================

require_not_root

echo
echo "=========================================="
echo "        Maia Dotfiles"
echo "=========================================="
echo

info "Diretório do projeto:"
echo "       $ROOT_DIR"
echo

info "Sistema:"
grep -E '^(NAME|VERSION)=' /etc/os-release

echo

info "Usuário: $USER"
info "Home:   $HOME"

echo

detect_os
detect_desktop
detect_display_manager

echo

setup_packages

echo

setup_sddm

echo

setup_kde

echo

setup_kitty
setup_shell
setup_pokemon
setup_ani_cli

echo

success "Bootstrap executado com sucesso."
