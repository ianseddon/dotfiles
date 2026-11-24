source ~/.config/fish/alias.fish

# Disable greeting
set -g fish_greeting

# Environment variables
set -gx VAULT_WORK $HOME/obsidian/work/
set -gx VAULT_PERSONAL $HOME/obsidian/ian/

## Application preferences
set -gx BROWSER firefox
set -gx EDITOR nvim
set -gx VISUAL $EDITOR
set -gx SUDO_EDITOR $EDITOR
#set -gx PAGER less
set -gx MANPAGER "sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"

## Tool-specific environment variables
set -gx BUN_INSTALL $HOME/.bun
set -gx PNPM_HOME $HOME/.local/share/pnpm

# fzf in the terminal's 16 colours, so it follows the theme (-1: the default fg/bg;
# 0: the theme's darker background, for the current and selected lines).
set -gx FZF_DEFAULT_OPTS "\
  --color=fg:-1,bg:-1,fg+:-1,bg+:0,selected-bg:0 \
  --color=hl:1,hl+:9,header:1,info:5,pointer:4,prompt:4 \
  --color=marker:11,spinner:11"

# PATH

# Nix's profile (conf.d/nix.fish) owns the development tools and the system
# comes next, so these user-level install dirs go last: they only add tools
# neither provides (uv tools, bun globals, cargo/go builds). fish_user_paths
# would put them in front of everything, so it stays empty.
set -gx fish_user_paths
fish_add_path --path --append \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $BUN_INSTALL/bin \
    $HOME/.config/composer/vendor/bin \
    $HOME/go/bin \
    $PNPM_HOME $PNPM_HOME/bin \
    $HOME/.lando/bin

# Source local environment file if it exists
# if test -f ~/.local/bin/env
#     source ~/.local/bin/env
# end

# Vi key bindings, keeping emacs keys (ctrl-a/e/w, alt-f/b, ...) where vi
# doesn't bind them. Additions are in fish_user_key_bindings.
set -g fish_key_bindings fish_hybrid_key_bindings

# Ghostty's cursor-shape integration stands down under vi bindings, so fish
# sets the shape per mode: a line while inserting, a block otherwise.
set -g fish_cursor_default block
set -g fish_cursor_insert line
set -g fish_cursor_replace_one underscore
set -g fish_cursor_replace underscore
set -g fish_cursor_visual block
set -g fish_cursor_external block blink

# The prompt is Tide (conf.d/tide.fish).
