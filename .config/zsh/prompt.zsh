##
## Prompt
##

# Load starship theme
# line 1: `starship` binary as command, from github release
# line 2: starship setup at clone(create init.zsh, completion)
# line 3: pull behavior same as clone, source init.zsh
zinit ice as"command" from"gh-r" \
  atload'export STARSHIP_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml; eval $(starship init zsh)' \
  atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
  atpull"%atclone" src"init.zsh"
zinit light starship/starship

# vim:ft=zsh
