

# ==============================================================================
# ZINIT
# ==============================================================================

# # Set the directory we want to store zinit and plugins
# ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# # Download Zinit, if it's not there yet
# if [ ! -d "$ZINIT_HOME" ]; then
#    mkdir -p "$(dirname $ZINIT_HOME)"
#    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
# fi

# # Source/Load zinit
# source "${ZINIT_HOME}/zinit.zsh"

# # Add in zsh plugins
# zinit light zsh-users/zsh-syntax-highlighting
# zinit light zsh-users/zsh-completions
# zinit light zsh-users/zsh-autosuggestions
# zinit light Aloxaf/fzf-tab

# # Add in snippets
# zinit snippet OMZP::git
# zinit snippet OMZP::sudo
# zinit snippet OMZP::kubectl
# zinit snippet OMZP::command-not-found
# zinit snippet OMZP::pyenv
# zinit snippet OMZP::gcloud
# # zinit snippet OMZP::archlinux


# ==============================================================================
# Plugins
# ==============================================================================

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

eval "$(starship init zsh)"

eval "$(fnm env --use-on-cd --shell zsh)"

# ==============================================================================
# Paths
# ==============================================================================

# PATH="$PATH:"
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/Users/david/.local/bin:$PATH"


# ==============================================================================
# Shortcuts
# ==============================================================================

# if terminal is interactive
if [[ $- == *i* ]]; then
  # Better cd (zoxide)
  eval "$(zoxide init --cmd cd zsh)"

  # Better ls (eza)
  alias ls="eza --icons=always"

  eval "$(fzf --zsh)"
fi

alias k="kubectl"
alias lg="lazygit"
alias oc="opencode"
alias p="pnpm"
alias v="nvim"
alias watch="watch "

# Load completions
autoload -Uz compinit && compinit

# Run at end
# zinit cdreplay -q
