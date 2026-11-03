function fish_user_key_bindings
    # Runs after fish_hybrid_key_bindings (config.fish) has set up vi mode.

    # Yank to the desktop clipboard: wl-copy locally, OSC 52 from m75q.
    bind yy fish_clipboard_copy
    bind -M visual -m default y 'fish_clipboard_copy; commandline -f end-selection repaint-mode'

    # Setting up the key bindings erased what plugins bound while conf.d loaded.
    # fzf.fish: ctrl-t files, ctrl-s git status, ctrl-g git log; ctrl-alt-p
    # processes and ctrl-v variables keep their defaults. History is atuin's.
    fzf_configure_bindings --directory=ctrl-t --git_status=ctrl-s --git_log=ctrl-g --history=
    if functions -q _atuin_search
        bind ctrl-r _atuin_search
        bind -M insert ctrl-r _atuin_search
    end

    for mode in default insert
        # ctrl-b: to the root of this repository or worktree.
        bind -M $mode ctrl-b 'cd (git rev-parse --show-toplevel 2>/dev/null; or pwd); commandline -f repaint'
        # alt-, / alt-.: back and forward through directory history.
        bind -M $mode alt-comma 'prevd >/dev/null; commandline -f repaint'
        bind -M $mode alt-. 'nextd >/dev/null; commandline -f repaint'
        # ctrl-z on an empty line: resume the job just suspended.
        bind -M $mode ctrl-z 'if test -z (commandline); fg 2>/dev/null; end; commandline -f repaint'
    end
end
