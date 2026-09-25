# Keep command-line tools available to non-interactive zsh processes.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/Library/pnpm:$HOME/.opencode/bin:$HOME/.bun/bin:$PATH"
. "$HOME/.cargo/env"

if [[ -x "/opt/homebrew/bin/fnm" ]]; then
  eval "$(/opt/homebrew/bin/fnm env --shell zsh)"
fi
# Prioritize Homebrew over cargo binaries
export PATH="/opt/homebrew/bin:$PATH"

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
# uv
export PATH="/Users/david/.local/bin:$PATH"
