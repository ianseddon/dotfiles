# Shell history in atuin's database (config: ~/.config/atuin/config.toml).
# Up-arrow stays fish's own prefix search; ctrl-r is atuin's search (rebound in
# fish_user_key_bindings, which runs after this). No `?` binding: that sends
# the prompt to Atuin AI.
status is-interactive; and command -q atuin; and atuin init fish --disable-up-arrow --disable-ai | source
