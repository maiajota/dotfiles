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

# Prompt
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
