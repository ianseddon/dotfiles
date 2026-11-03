# zoxide's own init, so `cd`/`cdi` track the installed zoxide.
status is-interactive; and command -q zoxide; and zoxide init fish --cmd cd | source
