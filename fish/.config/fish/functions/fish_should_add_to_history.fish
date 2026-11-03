function fish_should_add_to_history
    # Keep fish's rule that a leading space means "don't save", and never save
    # a command that sets a credential inline.
    string match -q -- ' *' $argv[1]; and return 1
    string match -qr -- '(?i)(token|secret|passw(or)?d|api_?key)=' $argv[1]; and return 1
    return 0
end
