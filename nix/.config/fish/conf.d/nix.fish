# Nix owns the development toolchain on every machine, so its profile comes
# before Arch's /usr/bin. Arch keeps the base system, the desktop session, and
# recovery: Bash stays the login shell and needs no Nix profile.
# Inside `nix develop` the shell's own PATH wins.
if not set -q IN_NIX_SHELL; and test -d "$HOME/.nix-profile/bin"
    fish_add_path --path --move "$HOME/.nix-profile/bin"
end

# The profile's completions (share/fish/vendor_completions.d). fish builds its
# search path from XDG_DATA_DIRS before conf.d runs, and SSH logins don't get
# environment.d, so add the directory here as well as exporting the variable.
set -l nix_share "$HOME/.nix-profile/share"
if test -d $nix_share/fish/vendor_completions.d
    contains -- $nix_share/fish/vendor_completions.d $fish_complete_path
    or set -g fish_complete_path $fish_complete_path[1] $nix_share/fish/vendor_completions.d $fish_complete_path[2..]
end
# Plugins in the profile (Tide, fzf.fish, done, sponge, direnv's hook) live in
# share/fish/vendor_{functions,conf}.d, which fish also only finds through
# XDG_DATA_DIRS at startup. When it missed them, load them now.
if test -d $nix_share/fish/vendor_conf.d; and not contains -- $nix_share/fish/vendor_conf.d $__fish_vendor_confdirs
    set -g fish_function_path $fish_function_path[1] $nix_share/fish/vendor_functions.d $fish_function_path[2..]
    for f in $nix_share/fish/vendor_conf.d/*.fish
        source $f
    end
end
if not contains -- $nix_share (string split : -- "$XDG_DATA_DIRS")
    set -gx XDG_DATA_DIRS $nix_share (string split -n : -- "$XDG_DATA_DIRS"; or printf '%s\n' /usr/local/share /usr/share)
    set -gx XDG_DATA_DIRS (string join : $XDG_DATA_DIRS)
end

# Per-project Node from .node-version/.nvmrc (searched up the tree), else
# package.json engines, else `fnm default`, the newest installed 24.x. Sourced
# after the profile so fnm's directory lands in front of Nix's node. Move the
# default to a new 24.x with `fnm install 24 && fnm default 24`; Nix's own
# Node 24 still serves everything outside fish (systemd, scripts, pi).
#
# Our own hook instead of --use-on-cd, which only fires in a directory that
# itself holds a version file and, when the pin isn't installed, keeps the
# previous project's Node. This one installs a missing pin, and falls back
# to the default rather than a stale version if that fails (e.g. offline).
if status is-interactive; and command -q fnm
    fnm env --version-file-strategy=recursive --shell fish | source

    function _fnm_autoload_hook --on-variable PWD --description 'Use the directory\'s pinned Node'
        status --is-command-substitution; and return
        fnm use --silent-if-unchanged --install-if-missing --log-level=error
        or fnm use default --silent-if-unchanged --log-level=quiet
    end
    _fnm_autoload_hook
end
