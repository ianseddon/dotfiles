function _agent_secrets_token_file
    # tmpfs, so a cached token never outlives the boot. Tailscale SSH sessions
    # don't set XDG_RUNTIME_DIR.
    set -l dir $XDG_RUNTIME_DIR
    test -n "$dir"; or set dir /run/user/(id -u)
    echo $dir/infisical-agents.token
end
