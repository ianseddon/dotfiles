source ~/.config/fish/secrets.fish
source ~/.config/fish/alias.fish

# Disable greeting
set -g fish_greeting

# Environment variables

## Application preferences
set -gx BROWSER vivaldi
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx MANPAGER 'nvim +Man!'

## Tool-specific environment variables
set -gx BUN_INSTALL "$HOME/.bun"
set -gx PNPM_HOME "$HOME/.local/share/pnpm"

# PATH

fish_add_path -g ~/.local/bin
fish_add_path -g "$HOME/.cargo/bin" # cargo/rust
fish_add_path -g "$BUN_INSTALL/bin" # bun
fish_add_path -g "$HOME/.config/composer/vendor/bin" # composer/php
fish_add_path -g "$HOME/go/bin" # go
fish_add_path -g "$PNPM_HOME" # pnpm

# Source local environment file if it exists
# if test -f ~/.local/bin/env
#     source ~/.local/bin/env
# end

# Enable vi key bindings
fish_vi_key_bindings

# init
starship init fish | source
zoxide init fish | source

# Zellij integration
if test -n "$ZELLIJ"
    # Custom prompt for zellij sessions
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
else
    # Regular prompt when not in zellij
    function fish_prompt
        set -l last_status $status
        set -l pwd_info (pwd | string replace $HOME '~')

        # Git info
        set -l git_branch (git branch 2>/dev/null | grep '^\*' | cut -d' ' -f2)
        set -l git_info ''
        if test -n "$git_branch"
            set git_info " on (set_color yellow)$git_branch"
        end

        # Status indicator
        set -l status_indicator ''
        if test $last_status -ne 0
            set status_indicator (set_color red)" [$last_status]"
        end

        printf '%s%s%s%s%s%s ' \
            (set_color cyan)$pwd_info \
            (set_color normal)$git_info \
            $status_indicator \
            (set_color normal) \
            (set_color green)'❯'(set_color normal)
    end
end

# Auto-start zellij if not already in a session and if it's installed
if status is-interactive; and not set -q ZELLIJ; and command -v zellij >/dev/null
    exec zellij
end
