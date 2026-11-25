#!/bin/sh
# Sourced by non-interactive bash subshells via BASH_ENV. When a coding agent
# (pi, Claude Code, Codex, ...) runs bash commands after being launched from a
# human Fish shell, this overrides inherited interactive defaults (EDITOR=nvim,
# MANPAGER, pagers) so commands fail fast instead of hanging on input, while
# keeping EDITOR=nvim intact for the agent TUI itself (for example Ctrl+G).
if [ -n "${AI_AGENT:-}${PI_CODING_AGENT:-}${CLAUDECODE:-}${CODEX_SANDBOX:-}${GEMINI_CLI:-}${CURSOR_AGENT:-}" ]; then
  export EDITOR=true VISUAL=true GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true
  export PAGER=cat GIT_PAGER=cat MANPAGER=cat BAT_PAGER=cat
  export GIT_TERMINAL_PROMPT=0
fi
