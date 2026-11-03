function with-agent-secrets --description 'Run a command with the Infisical agents project in its environment'
    # Only the launched command gets the keys; Infisical's own token stays out
    # of its environment, so the agent can't fetch anything else with it.
    set -l secrets (agent-secrets)
    switch $status
        case 0
            env $secrets $argv
        case 2
            echo "with-agent-secrets: starting without secrets" >&2
            command $argv
        case '*'
            return 1
    end
end
