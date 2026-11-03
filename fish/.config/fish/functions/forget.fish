function forget --description 'Delete the previous command from history'
    history delete --exact --case-sensitive -- $history[1]
end
