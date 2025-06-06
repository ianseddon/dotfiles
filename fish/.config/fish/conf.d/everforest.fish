# Everforest Fish Theme Configuration
# Based on the Everforest color scheme by sainnhe
# https://github.com/sainnhe/everforest

# Everforest Color Palette (Dark)
# Background colors
# bg_dim = '#1e2326'
# bg0 = '#272e33' 
# bg1 = '#2e383c'
# bg2 = '#374145'
# bg3 = '#414b50'
# bg4 = '#495156'
# bg5 = '#4f5b58'

# Foreground colors  
# fg = '#d3c6aa'
# red = '#e67e80'
# orange = '#e69875'
# yellow = '#dbbc7f'
# green = '#a7c080'
# aqua = '#83c092'
# blue = '#7fbbb3'
# purple = '#d699b6'
# grey0 = '#7a8478'
# grey1 = '#859289'
# grey2 = '#9da9a0'

# Fish color configuration using Everforest palette
set -g fish_color_normal d3c6aa                    # Default text
set -g fish_color_command 7fbbb3                   # Commands (blue) 
set -g fish_color_keyword d699b6                   # Keywords (purple)
set -g fish_color_quote dbbc7f                     # Quoted strings (yellow)
set -g fish_color_redirection 83c092               # Redirections (aqua)
set -g fish_color_end a7c080                       # Process separators (green)
set -g fish_color_error e67e80                     # Errors (red)
set -g fish_color_param d3c6aa                     # Parameters (default fg)
set -g fish_color_comment 7a8478                   # Comments (grey0)
set -g fish_color_selection --background=374145    # Selection background (bg2)
set -g fish_color_search_match --background=45443c # Search matches (bg_yellow)
set -g fish_color_history_current --bold           # Current history item
set -g fish_color_operator 83c092                  # Operators (aqua)
set -g fish_color_escape e69875                    # Escape sequences (orange)
set -g fish_color_cwd a7c080                       # Current directory (green)
set -g fish_color_cwd_root e67e80                  # Root directory (red)
set -g fish_color_valid_path --underline           # Valid paths
set -g fish_color_autosuggestion 7a8478            # Autosuggestions (grey0)
set -g fish_color_user 83c092                      # Username (aqua)
set -g fish_color_host d3c6aa                      # Hostname (default fg)
set -g fish_color_cancel e67e80 --reverse          # Cancelled commands

# Pager colors (for completions)
set -g fish_pager_color_completion d3c6aa          # Default completion text
set -g fish_pager_color_description 9da9a0         # Description text (grey2)
set -g fish_pager_color_prefix 7fbbb3 --bold       # Matching prefix (blue)
set -g fish_pager_color_progress --background=414b50 # Progress bar (bg3)

# FZF configuration with proper Everforest theme
set -gx FZF_DEFAULT_OPTS "\
  --color=bg+:#374145,bg:#272e33,spinner:#e69875,hl:#e67e80 \
  --color=fg:#d3c6aa,header:#e67e80,info:#d699b6,pointer:#83c092 \
  --color=marker:#e69875,fg+:#d3c6aa,prompt:#7fbbb3,hl+:#e67e80 \
  --color=selected-bg:#414b50"
