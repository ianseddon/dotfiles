function with-agent-secrets --description 'Run a command with the Infisical agents project in its environment'
    # The agents' API keys (Kagi, OpenCode Go, ...) live in Infisical's `agents`
    # project, read by this machine's own identity (agent-secrets-login). Only
    # the launched command gets them; Infisical's own token stays out of its
    # environment, so the agent can't fetch anything else with it.
    set -l conf ~/.config/infisical/agents.env
    if not test -r $conf
        echo "with-agent-secrets: no $conf; run agent-secrets-login. Starting without secrets." >&2
        command $argv
        return
    end

    set -l settings (string match -r '^INFISICAL_[A-Z_]+=.*' <$conf)
    set -lx INFISICAL_DOMAIN https://infisical.ians.cloud
    set -lx INFISICAL_DISABLE_UPDATE_CHECK true
    set -l project (string replace -rf '^INFISICAL_PROJECT_ID=' '' -- $settings)

    # Universal Auth access tokens last far longer than an hour; refreshing
    # hourly keeps a revoked identity from working for long.
    set -l cache (_agent_secrets_token_file)
    if not test -s $cache; or test (math (date +%s) - (path mtime $cache)) -gt 3600
        set -l token (env (string match -r '^INFISICAL_UNIVERSAL_AUTH_.*' -- $settings) \
            infisical login --method=universal-auth --plain --silent)
        or begin
            echo "with-agent-secrets: Infisical login failed" >&2
            return 1
        end
        install -m 600 /dev/null $cache
        printf '%s\n' $token >$cache
    end

    set -l secrets (env INFISICAL_TOKEN=(cat $cache) \
        infisical export --projectId=$project --env=prod --format=json --silent \
        | jq -r '.[] | "\(.key)=\(.value)"')
    or begin
        rm -f $cache
        echo "with-agent-secrets: couldn't read the agents project" >&2
        return 1
    end
    env $secrets $argv
end
