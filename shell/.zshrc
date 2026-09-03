# ==========================================
# Maia Dotfiles - Zsh
# ==========================================

# Histórico
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Navegação
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS

# Correções e completions
setopt CORRECT

autoload -Uz compinit
compinit

# PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Prompt (Starship)
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
fi

# Fastfetch no início da sessão interativa
if [[ -o interactive ]] && command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi
