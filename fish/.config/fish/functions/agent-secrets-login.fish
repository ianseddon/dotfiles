function agent-secrets-login --description "Store this machine's Infisical identity for with-agent-secrets"
    # Prompts instead of taking arguments, so the client secret stays out of
    # shell history and process listings. The file is this machine's secret
    # zero; it never belongs in the repo.
    set -l conf ~/.config/infisical/agents.env
    read -P 'Infisical project ID: ' -l project; or return 1
    read -P 'Client ID: ' -l id; or return 1
    read -s -P 'Client secret: ' -l secret; or return 1
    mkdir -p (path dirname $conf)
    install -m 600 /dev/null $conf
    printf '%s\n' \
        "INFISICAL_PROJECT_ID=$project" \
        "INFISICAL_UNIVERSAL_AUTH_CLIENT_ID=$id" \
        "INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET=$secret" >$conf
    set -l cache (_agent_secrets_token_file)
    rm -f $cache $cache.values
    echo "Saved $conf"
end
