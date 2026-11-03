# Abbreviations expand as you type, so history keeps the real command and
# commands pasted from docs or agent output (grep -E, find -name, ...) run the
# tool they name. Aliases are only for commands whose output is all that changes.

# git
abbr -a g git
abbr -a gs git status
abbr -a ga git add
abbr -a gc git commit
abbr -a gp git push
abbr -a gl git log --oneline --graph --decorate
abbr -a gd git diff
abbr -a gb git branch
abbr -a gco git checkout

# nvim
abbr -a vim nvim
abbr -a vi nvim
abbr -a v nvim

# Modern replacements, typed as the old names.
abbr -a cat bat
abbr -a grep rg
abbr -a find fd
abbr -a fda fd -IH

# eza
alias ls eza
abbr -a ll eza -la --icons
abbr -a la eza -a
abbr -a llt eza -la --icons --tree

# .. -> cd .., ... -> cd ../.., and so on
abbr -a dotdot --regex '^\.\.+$' --function _abbr_multicd
# !! anywhere -> the previous command (e.g. `sudo !!`)
abbr -a !! --position anywhere --function _abbr_last_command
# r#pkg -> nix run nixpkgs#pkg
abbr -a nixrun --regex '^r#\S+' --function _abbr_nix_run
# cmd --help -> paged and highlighted by bat
abbr -a --position anywhere -- --help '--help 2>&1 | bat -plhelp'
