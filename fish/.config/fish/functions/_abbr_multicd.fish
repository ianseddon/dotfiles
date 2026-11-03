function _abbr_multicd --description 'Expand .., ..., .... to cd ../.., etc.'
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
