# done (fishPlugins.done) notifies when a command that ran longer than this
# finishes. It decides whether to enable itself as it loads, so these have to
# be set first: the 00- prefix sorts this file ahead of the plugin's done.fish.
set -g __done_min_cmd_duration 15000
# Interactive programs and agents end when you quit them, not when work finishes.
set -g __done_exclude '^git (?!push|pull|fetch)' '^(nvim|vim|v|lazygit|lazydocker|btop|hunk|tuicr|claude|pi|codex|ssh|man|less|bat|glow)\b'

# Inside herdr (on either machine), let herdr deliver the notification: its
# toasts reach the desktop's Ghostty even from m75q, and it knows whether this
# pane is the one you're looking at. done's own window-focus check would only
# see the Ghostty window.
if set -q HERDR_PANE_ID
    function _done_herdr_notify -a title message
        herdr pane get $HERDR_PANE_ID 2>/dev/null | jq -e .result.pane.focused >/dev/null
        and return
        herdr notification show $title --body $message >/dev/null
    end
    set -g __done_allow_nongraphical 1
    set -g __done_notification_command '_done_herdr_notify "$title" "$message"'
end
