# zoxide's own init, so `cd`/`cdi` track the installed zoxide.
is_human; and command -q zoxide; and zoxide init fish --cmd cd | source
