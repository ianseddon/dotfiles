# fzf.fish (fishPlugins.fzf-fish) options; its key bindings are set in
# fish_user_key_bindings. Not named fzf.fish, which would hide the plugin's own.
set -g fzf_diff_highlighter delta --paging=never --width=20
set -g fzf_preview_dir_cmd eza --all --color=always --icons
set -g fzf_fd_opts --hidden --exclude=.git
