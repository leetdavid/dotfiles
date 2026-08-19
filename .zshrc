

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

# Completion styling (keep before fzf-tab loads)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Add in zsh plugins/snippets (Turbo)
zinit for \
  wait'0' lucid blockf atinit'ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay' zsh-users/zsh-completions \
  wait'1' lucid zsh-users/zsh-autosuggestions \
  wait'1' lucid Aloxaf/fzf-tab \
  wait'1' lucid OMZP::git \
  wait'1' lucid OMZP::sudo \
  wait'1' lucid OMZP::command-not-found \
  wait'2' lucid zdharma-continuum/fast-syntax-highlighting

# If on Windows (MING64)
if [ "$MSYSTEM" = "MINGW64" ]; then
  export PATH="/c/Users/david/.cargo/bin:$PATH"
  export PATH="/c/Users/david/.local/bin:$PATH"
  export PATH="/c/ProgramData/chocolatey/bin:$PATH"
  export PATH="/c/Users/david/AppData/Local/Programs/Ollama:$PATH"
  export PATH="/c/Users/david/AppData/Local/Programs/Zed/bin:$PATH"

  installzshrc() {
    cp ~/dotfiles/.zshrc ~/.zshrc
    cp ~/dotfiles/.zshrc /c/Users/david/.zshrc
    echo "Installed .zshrc to ~/.zshrc and /c/Users/david/.zshrc"
  }
  export PATH="/c/users/david/.local/bin:$PATH"
  export PATH=$PATH:/c/ProgramData/chocolatey/bin
fi

# If on Linux, use linuxbrew with sudo
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  function brew() { (cd /home/linuxbrew && sudo -Hu linuxbrew /home/linuxbrew/.linuxbrew/bin/brew "$@") }
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ==============================================================================
# Plugins
# ==============================================================================

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# if the .op file is present, source it
if [[ -f "$HOME/.op" ]]; then
  source "$HOME/.op"
fi

eval "$(starship init zsh)"

eval "$(fnm env --use-on-cd --shell zsh)"

# ==============================================================================
# Paths
# ==============================================================================

export PATH="$HOME/.local/bin:$PATH"

export XDG_CONFIG_PATH="$HOME/.config/"

# pnpm
export PNPM_HOME="/Users/david/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

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

# if it's macos
if [[ "$(uname -s)" == "Darwin" ]]; then

  export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"

  # Low Power Mode Script
  lowpower() {
    local current target lp_status

    current="$(pmset -g | awk '/lowpowermode/ {print $2; exit}')"

    case "$1" in
      "")
      [[ "$current" == "1" ]] && target=0 || target=1
      ;;
      0|1)
      target="$1"
      ;;
      *)
        echo "Usage: lowpower [0|1]"
        return 1
        ;;
    esac

    sudo -v || return 1
    sudo pmset -a lowpowermode "$target" >/dev/null

    lp_status="$(pmset -g | awk '/lowpowermode/ {print $2; exit}')"
    [[ "$lp_status" == "1" ]] && echo "Low Power Mode: ON" || echo "Low Power Mode: OFF"
  }
fi

alias claude="claude --permission-mode bypassPermissions"
alias k="kubectl"
alias ll="ls -l"
alias lg="lazygit"
alias oc="opencode"
alias p="pnpm"
alias v="nvim"
alias watch="watch "
alias zj="zellij"


alias tf="terraform"
alias ppi="command pi"
alias gp="git push"
alias gpl="git pull --rebase"
alias pi="pnpm install"
alias pc="pnpm check"
alias pcf="pnpm check:fix"
alias pb="pnpm build"
alias pd="pnpm dev"
alias vl="vercel link --repo"
alias vp="vercel env pull .env"

reload() {
    source ~/.zshrc
}

# Run at end
# zinit cdreplay -q

# opencode
export PATH=/Users/david/.opencode/bin:$PATH

# bun completions
[ -s "/Users/david/.bun/_bun" ] && source "/Users/david/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH=$PATH:/Users/david/.spicetify
# >>> railway initialize >>>
[[ -f "$HOME/.railway/env" ]] && source "$HOME/.railway/env"
# <<< railway initialize <<<
