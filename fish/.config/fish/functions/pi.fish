function pi --wraps pi --description 'pi with the agents secrets from Infisical'
    with-agent-secrets pi $argv
end
