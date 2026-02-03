# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

This repository contains configuration files for:

- **Shell**: Zsh with custom aliases and completions
- **Prompt**: Starship
- **Editor**: Zed (keymap configuration)
- **Fonts**: Comic Code Ligatures, ZedMono Nerd Font
- **Tools**: zoxide, eza, fzf, fnm (Fast Node Manager), kubectl, lazygit, opencode, pnpm, nvim

## Installation

### Prerequisites

Ensure you have the following installed:

```bash
# macOS (using Homebrew)
brew install stow zoxide eza fzf fnm kubectl lazygit

# Starship prompt
curl -sS https://starship.rs/install.sh | sh
```

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/leetdavid/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Use stow to symlink dotfiles
stow .
```

## Updating

To update dotfiles after making changes:

```bash
cd ~/dotfiles
stow -R .
```

## Managing Files

### Adding New Files

To add a new configuration file to be managed by stow:

1. Create the file in the repository in the same relative location as it would be in your home directory (e.g., `nvim/.config/nvim/init.lua` for `~/.config/nvim/init.lua`)
2. Ensure the parent directory structure mirrors your home directory
3. Run `stow -R .` to recreate all symlinks

### Unstowing Files

To stop managing a file with stow but keep the actual file in place:

```bash
# Unstow a specific package (e.g., "nvim")
stow -D nvim

# The file will remain at its original location (e.g., ~/.config/nvim/init.lua)
# but will no longer be symlinked to the dotfiles repo

# If you want to restore management later, re-stow the package
stow nvim
```

**Note:** After unstowing, changes to the file in `~` will no longer be reflected in the dotfiles repository.
