function zj --description 'Zellij session manager'
    # If no arguments, list sessions
    if test (count $argv) -eq 0
        zellij list-sessions
        return
    end
    
    set session_name $argv[1]
    
    # If session exists, attach to it
    if zellij list-sessions | grep -q "^$session_name"
        zellij attach $session_name
    else
        # Create new session
        if test (count $argv) -gt 1
            # Use specified layout
            zellij --session $session_name --layout $argv[2]
        else
            # Use default layout
            zellij --session $session_name
        end
    end
end 