#!/usr/bin/env bash

# ==========================================
# Maia Dotfiles - Common Functions
# ==========================================

set -euo pipefail


# ------------------------------------------
# Colors
# ------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'


# ------------------------------------------
# Logging
# ------------------------------------------

info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}


# ------------------------------------------
# Command helpers
# ------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1
}


require_command() {
    if ! command_exists "$1"; then
        error "Comando obrigatório não encontrado: $1"
        exit 1
    fi
}


# ------------------------------------------
# Root check
# ------------------------------------------

require_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        error "Não execute este script como root."
        exit 1
    fi
}


# ------------------------------------------
# Backup
# ------------------------------------------

backup_file() {
    local file="$1"

    if [[ ! -e "$file" ]]; then
        return 0
    fi

    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if [[ -w "$file" ]]; then
        cp -a "$file" "$backup"
    else
        sudo cp -a "$file" "$backup"
    fi

    success "Backup criado: $backup"
}
