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
