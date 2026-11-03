function agent-secrets --description 'Print the Infisical agents project as KEY=VALUE lines'
    # The agents' API keys (Kagi, OpenCode Go, CLIProxyAPI, ...) live in
    # Infisical's `agents` project, read by this machine's own identity
    # (agent-secrets-login). Exits 2 when this machine has no identity yet.
    set -l conf ~/.config/infisical/agents.env
    if not test -r $conf
        echo "agent-secrets: no $conf; run agent-secrets-login" >&2
        return 2
    end

    set -l cache (_agent_secrets_token_file)
    set -l values $cache.values
    # Claude Code and pi ask for their key on every request; a five-minute
    # copy on the runtime tmpfs saves an Infisical round trip each time.
    if test -s $values; and test (math (date +%s) - (path mtime $values)) -lt 300
        cat $values
        return
    end

    set -l settings (string match -r '^INFISICAL_[A-Z_]+=.*' <$conf)
    # For the infisical calls only, so none of it reaches a caller's environment.
    set -l infisical env INFISICAL_DOMAIN=https://infisical.ians.cloud INFISICAL_DISABLE_UPDATE_CHECK=true
    set -l project (string replace -rf '^INFISICAL_PROJECT_ID=' '' -- $settings)

    # Universal Auth access tokens last far longer than an hour; refreshing
    # hourly keeps a revoked identity from working for long.
    if not test -s $cache; or test (math (date +%s) - (path mtime $cache)) -gt 3600
        set -l token ($infisical (string match -r '^INFISICAL_UNIVERSAL_AUTH_.*' -- $settings) \
            infisical login --method=universal-auth --plain --silent)
        or begin
            echo "agent-secrets: Infisical login failed" >&2
            return 1
        end
        install -m 600 /dev/null $cache
        printf '%s\n' $token >$cache
    end

    set -l json ($infisical INFISICAL_TOKEN=(cat $cache) \
        infisical export --projectId=$project --env=prod --format=json --silent)
    or begin
        rm -f $cache $values
        echo "agent-secrets: couldn't read the agents project" >&2
        return 1
    end
    set -l secrets (printf '%s\n' $json | jq -r '.[] | "\(.key)=\(.value)"')
    install -m 600 /dev/null $values
    printf '%s\n' $secrets >$values
    printf '%s\n' $secrets
end
