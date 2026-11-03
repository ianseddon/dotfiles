function fish_title
    # The repository (or directory) name, so herdr and Ghostty tabs read as
    # projects; while a command runs, its name first.
    set -l place (path basename (git rev-parse --show-toplevel 2>/dev/null; or pwd))
    if set -q argv[1]
        echo (string split -f1 ' ' -- $argv[1]) - $place
    else
        echo $place
    end
end
