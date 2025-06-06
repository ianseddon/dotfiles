# Environment variables configuration for Fish
# This file is automatically loaded by Fish on startup

# Application preferences
set -gx BROWSER firefox
set -gx EDITOR nvim
set -gx VISUAL nvim

# Tool-specific environment variables
set -gx BUN_INSTALL "$HOME/.bun"
set -gx PNPM_HOME "$HOME/.local/share/pnpm"

# FZF configuration with Everforest theme
set -gx FZF_DEFAULT_OPTS "\
  --color=bg+:#a7c080,bg:#414b50,spinner:#fab388,hl:#f38ba9 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#d3c6aa \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# Add directories to PATH
fish_add_path -g "$BUN_INSTALL/bin" # bun
fish_add_path -g "$HOME/.cargo/bin" # cargo/rust
fish_add_path -g "$HOME/.config/composer/vendor/bin" # composer/php
fish_add_path -g "$HOME/go/bin" # go
fish_add_path -g "$PNPM_HOME" # pnpm
