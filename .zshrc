# poetry
#PATH=$HOME/.local/bin:$PATH

# rye
source "$HOME/.rye/env"

# nvm
source /usr/share/nvm/init-nvm.sh

# prezto
PURE_PROMPT_SYMBOL=λ
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# aliases
alias g='git'
alias h='hamster'
alias vim='nvim'

# bun completions
[ -s "/home/ian/.bun/_bun" ] && source "/home/ian/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# cargo
export PATH="$HOME/.cargo/bin:$PATH"

# composer
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# go
export PATH="$HOME/go/bin:$PATH"

# pnpm
export PNPM_HOME="/home/ian/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
 j*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# zoxide
alias cd='z'
eval "$(zoxide init zsh)"
# zoxide end

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/bin/terraform terraform
