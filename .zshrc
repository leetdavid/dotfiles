

# ==============================================================================
# ZINIT
# ==============================================================================

# # Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit ice wait'0' blockf
zinit light zsh-users/zsh-completions

zinit ice wait'1'
zinit light zsh-users/zsh-autosuggestions

zinit ice wait'1'
zinit light Aloxaf/fzf-tab

zinit ice wait'2'
zinit light zsh-users/zsh-syntax-highlighting

# # Add in snippets
zinit ice wait'1'
zinit snippet OMZP::git
zinit snippet OMZP::sudo
# zinit snippet OMZP::kubectl
zinit snippet OMZP::command-not-found
# zinit snippet OMZP::gcloud
# zinit snippet OMZP::archlinux

# Load completions via zinit
zinit ice wait'0' atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay'
zinit light zdharma-continuum/fast-syntax-highlighting

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

export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/david/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=/Users/david/.opencode/bin:$PATH

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
