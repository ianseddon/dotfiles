##
## Env vars & path
##

### Preferences
export BROWSER=firefox
export EDITOR=nvim
#export TERMINAL=kitty
export VISUAL=nvim

### History
### General
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8" # catppuccin mocha

### Path
export PATH="$BUN_INSTALL/bin:$PATH" # bun
export PATH="$HOME/.cargo/bin:$PATH" # cargo
export PATH="$HOME/.config/composer/vendor/bin:$PATH" # composer
export PATH="$HOME/go/bin:$PATH" # go
export PATH="$PNPM_HOME:$PATH" # pnpm

# vim:ft=zsh
