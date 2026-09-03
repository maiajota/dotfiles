#!/usr/bin/env bash
set -euo pipefail

POKEMON_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$POKEMON_SCRIPT_DIR/common.sh"

install_pokemon_colorscripts() {
    info "Verificando Pokémon Colorscripts..."

    if command_exists pokemon-colorscripts; then
        success "Pokémon Colorscripts já está instalado."
        return 0
    fi

    info "Instalando Pokémon Colorscripts..."

    local temp_dir
    temp_dir="$(mktemp -d)"

    git clone \
        https://gitlab.com/phoneybadger/pokemon-colorscripts.git \
        "$temp_dir/pokemon-colorscripts"

    cd "$temp_dir/pokemon-colorscripts"

    sudo ./install.sh

    rm -rf "$temp_dir"

    success "Pokémon Colorscripts instalado."
}

setup_pokemon() {
    info "Configurando Pokémon Colorscripts..."

    install_pokemon_colorscripts

    success "Pokémon Colorscripts preparado."
}
