# Syntax highlighting and pager colours in the terminal's 16 ANSI colours, so they
# follow the theme (`theme set` re-colours the terminal) on every machine, and
# change live in running shells. Roles from kanagawa.nvim's fish theme.
is_human; or return

set -l foreground normal
set -l selection --background=brblack
set -l comment brblack
set -l red red
set -l orange bryellow # no ANSI orange; bright yellow is the closest in most themes
set -l yellow yellow
set -l green green
set -l purple magenta
set -l cyan cyan
set -l pink brmagenta

# Syntax highlighting
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection $selection
set -g fish_color_search_match $selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion pager
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
