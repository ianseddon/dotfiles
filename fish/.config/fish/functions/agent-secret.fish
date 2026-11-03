function agent-secret --description 'Print one key from the Infisical agents project'
    # For tools that fetch their own key on demand: Claude Code's apiKeyHelper
    # and pi's `!command` keys in auth.json.
    set -l secrets (agent-secrets); or return
    string replace -rf "^$argv[1]=" '' -- $secrets
end
