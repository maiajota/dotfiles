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

# ------------------------------------------
# Plugins
# ------------------------------------------

# Autosuggestions
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] \
    && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# fzf (Ctrl+R histórico, Ctrl+T arquivos, Alt+C cd)
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)

# Syntax highlighting (precisa ser o último a carregar)
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] \
    && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ------------------------------------------
# Aliases
# ------------------------------------------

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lh --group-directories-first --icons=auto'
    alias la='eza -lah --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --icons=auto'
fi

command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v fd  >/dev/null 2>&1 && alias find='fd'

alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

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
