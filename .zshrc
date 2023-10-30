# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# poetry
PATH=$HOME/.local/bin:$PATH

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
