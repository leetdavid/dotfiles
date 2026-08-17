# Keep command-line tools available to non-interactive zsh processes.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/Library/pnpm:$HOME/.opencode/bin:$HOME/.bun/bin:$PATH"

if [[ -x "/opt/homebrew/bin/fnm" ]]; then
  eval "$(/opt/homebrew/bin/fnm env --shell zsh)"
fi

. "$HOME/.cargo/env"
