source ~/.config/fish/secrets.fish
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

# FZF - Kanagawa theme
set -gx FZF_DEFAULT_OPTS "\
  --color=bg+:#2A2A37,bg:#1F1F28,spinner:#E6C384,hl:#E46876 \
  --color=fg:#DCD7BA,header:#E46876,info:#957FB8,pointer:#7E9CD8 \
  --color=marker:#E6C384,fg+:#DCD7BA,prompt:#7E9CD8,hl+:#FF5D62 \
  --color=selected-bg:#363646"

# PATH

set -x fish_user_paths
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/.cargo/bin # cargo/rust
fish_add_path -g $BUN_INSTALL/bin # bun
fish_add_path -g $HOME/.config/composer/vendor/bin # composer/php
fish_add_path -g $HOME/go/bin # go
fish_add_path -g $PNPM_HOME $PNPM_HOME/bin # pnpm
fish_add_path -g $HOME/.lando/bin # lando

# Source local environment file if it exists
# if test -f ~/.local/bin/env
#     source ~/.local/bin/env
# end

# Enable vi key bindings
fish_vi_key_bindings

# init
starship init fish | source
# replaced with icezyclon/zoxide.fish plugin
#zoxide init fish | source 

function fish_prompt
    set -l last_status $status
    set -l pwd_info (pwd | string replace $HOME '~')

    # Git info
    set -l git_branch (git branch 2>/dev/null | grep '^\*' | cut -d' ' -f2)
    set -l git_info ''
    if test -n "$git_branch"
        set git_info " ($git_branch)"
    end

    # Status indicator
    set -l status_indicator ''
    if test $last_status -ne 0
        set status_indicator (set_color red)"✗ "
    end

    printf '%s%s%s%s%s ' \
        (set_color 83c092)$pwd_info \
        (set_color dbbc7f)$git_info \
        (set_color normal) \
        $status_indicator \
        (set_color a7c080)'❯'(set_color normal)
end
