# Tide (fishPlugins.tide), as chosen in `tide configure`: lean style, two lines,
# 16 colours (drawn from Ghostty's Kanagawa Wave palette), transient prompt.
# Kept as globals here rather than the universals `tide configure` writes.
# To change the look, run `tide configure` and regenerate this file:
#   for v in (set -U --names | string match "tide_*"); echo set -g $v (string escape -- $$v); end

set -gx VIRTUAL_ENV_DISABLE_PROMPT true
set -g tide_aws_bg_color normal
set -g tide_aws_color yellow
set -g tide_aws_icon 
set -g tide_bun_bg_color normal
set -g tide_bun_color white
set -g tide_bun_icon 󰳓
set -g tide_character_color brgreen
set -g tide_character_color_failure brred
set -g tide_character_icon ❯
set -g tide_character_vi_icon_default ❮
set -g tide_character_vi_icon_replace ▶
set -g tide_character_vi_icon_visual V
set -g tide_cmd_duration_bg_color normal
set -g tide_cmd_duration_color brblack
set -g tide_cmd_duration_decimals 0
set -g tide_cmd_duration_icon
set -g tide_cmd_duration_threshold 3000
set -g tide_context_always_display false
set -g tide_context_bg_color normal
set -g tide_context_color_default yellow
set -g tide_context_color_root bryellow
set -g tide_context_color_ssh yellow
set -g tide_context_hostname_parts 1
set -g tide_crystal_bg_color normal
set -g tide_crystal_color brwhite
set -g tide_crystal_icon 
set -g tide_direnv_bg_color normal
set -g tide_direnv_bg_color_denied normal
set -g tide_direnv_color bryellow
set -g tide_direnv_color_denied brred
set -g tide_direnv_icon ▼
set -g tide_distrobox_bg_color normal
set -g tide_distrobox_color brmagenta
set -g tide_distrobox_icon 󰆧
set -g tide_docker_bg_color normal
set -g tide_docker_color blue
set -g tide_docker_default_contexts default colima
set -g tide_docker_icon 
set -g tide_elixir_bg_color normal
set -g tide_elixir_color magenta
set -g tide_elixir_icon 
set -g tide_gcloud_bg_color normal
set -g tide_gcloud_color blue
set -g tide_gcloud_icon 󰊭
set -g tide_git_bg_color normal
set -g tide_git_bg_color_unstable normal
set -g tide_git_bg_color_urgent normal
set -g tide_git_color_branch brgreen
set -g tide_git_color_conflicted brred
set -g tide_git_color_dirty bryellow
set -g tide_git_color_operation brred
set -g tide_git_color_staged bryellow
set -g tide_git_color_stash brgreen
set -g tide_git_color_untracked brblue
set -g tide_git_color_upstream brgreen
set -g tide_git_icon
set -g tide_git_truncation_length 24
set -g tide_git_truncation_strategy
set -g tide_go_bg_color normal
set -g tide_go_color brcyan
set -g tide_go_icon 
set -g tide_java_bg_color normal
set -g tide_java_color yellow
set -g tide_java_icon 
set -g tide_jobs_bg_color normal
set -g tide_jobs_color green
set -g tide_jobs_icon 
set -g tide_jobs_number_threshold 1000
set -g tide_kubectl_bg_color normal
set -g tide_kubectl_color blue
set -g tide_kubectl_icon 󱃾
set -g tide_left_prompt_frame_enabled false
set -g tide_left_prompt_items pwd git newline character
set -g tide_left_prompt_prefix ''
set -g tide_left_prompt_separator_diff_color ' '
set -g tide_left_prompt_separator_same_color ' '
set -g tide_left_prompt_suffix ' '
set -g tide_nix_shell_bg_color normal
set -g tide_nix_shell_color brblue
set -g tide_nix_shell_icon 
set -g tide_node_bg_color normal
set -g tide_node_color green
set -g tide_node_icon 
set -g tide_os_bg_color normal
set -g tide_os_color brwhite
set -g tide_os_icon 
set -g tide_php_bg_color normal
set -g tide_php_color blue
set -g tide_php_icon 
set -g tide_private_mode_bg_color normal
set -g tide_private_mode_color brwhite
set -g tide_private_mode_icon 󰗹
set -g tide_prompt_add_newline_before false
set -g tide_prompt_color_frame_and_connection brblack
set -g tide_prompt_color_separator_same_color brblack
set -g tide_prompt_icon_connection ' '
set -g tide_prompt_min_cols 34
set -g tide_prompt_pad_items false
set -g tide_prompt_transient_enabled true
set -g tide_pulumi_bg_color normal
set -g tide_pulumi_color yellow
set -g tide_pulumi_icon 
set -g tide_pwd_bg_color normal
set -g tide_pwd_color_anchors brcyan
set -g tide_pwd_color_dirs cyan
set -g tide_pwd_color_truncated_dirs magenta
set -g tide_pwd_icon
set -g tide_pwd_icon_home
set -g tide_pwd_icon_unwritable 
set -g tide_pwd_markers .bzr .citc .git .hg .node-version .python-version .ruby-version .shorten_folder_marker .svn .terraform bun.lockb Cargo.toml composer.json CVS go.mod package.json build.zig
set -g tide_python_bg_color normal
set -g tide_python_color cyan
set -g tide_python_icon 󰌠
set -g tide_right_prompt_frame_enabled false
set -g tide_right_prompt_items status cmd_duration context jobs direnv bun node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig
set -g tide_right_prompt_prefix ' '
set -g tide_right_prompt_separator_diff_color ' '
set -g tide_right_prompt_separator_same_color ' '
set -g tide_right_prompt_suffix ''
set -g tide_ruby_bg_color normal
set -g tide_ruby_color red
set -g tide_ruby_icon 
set -g tide_rustc_bg_color normal
set -g tide_rustc_color red
set -g tide_rustc_icon 
set -g tide_shlvl_bg_color normal
set -g tide_shlvl_color yellow
set -g tide_shlvl_icon 
set -g tide_shlvl_threshold 1
set -g tide_status_bg_color normal
set -g tide_status_bg_color_failure normal
set -g tide_status_color green
set -g tide_status_color_failure red
set -g tide_status_icon ✔
set -g tide_status_icon_failure ✘
set -g tide_terraform_bg_color normal
set -g tide_terraform_color magenta
set -g tide_terraform_icon 󱁢
set -g tide_time_bg_color normal
set -g tide_time_color brblack
set -g tide_time_format ''
set -g tide_toolbox_bg_color normal
set -g tide_toolbox_color magenta
set -g tide_toolbox_icon 
set -g tide_vi_mode_bg_color_default normal
set -g tide_vi_mode_bg_color_insert normal
set -g tide_vi_mode_bg_color_replace normal
set -g tide_vi_mode_bg_color_visual normal
set -g tide_vi_mode_color_default white
set -g tide_vi_mode_color_insert cyan
set -g tide_vi_mode_color_replace green
set -g tide_vi_mode_color_visual yellow
set -g tide_vi_mode_icon_default D
set -g tide_vi_mode_icon_insert I
set -g tide_vi_mode_icon_replace R
set -g tide_vi_mode_icon_visual V
set -g tide_zig_bg_color normal
set -g tide_zig_color yellow
set -g tide_zig_icon 
