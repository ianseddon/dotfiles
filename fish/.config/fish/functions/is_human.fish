function is_human --description 'True for an interactive TTY shell with no coding agent marker set'
    status is-interactive; or return 1
    test -t 0; and test -t 1; or return 1
    for var in AI_AGENT PI_CODING_AGENT CLAUDECODE CODEX_SANDBOX GEMINI_CLI CURSOR_AGENT
        if set -q $var; and test -n "$$var"
            return 1
        end
    end
    return 0
end
