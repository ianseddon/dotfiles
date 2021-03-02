#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Customize prompt symbol as per: https://github.com/sindresorhus/pure#options
PURE_PROMPT_SYMBOL=λ

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# nvm setup
source /usr/share/nvm/init-nvm.sh

# pyenv setup
eval "$(pyenv init -)"

# virtualenvwrapper setup
PROJECT_HOME="$HOME/devel"

# add poetry packages to PATH
export PATH="$HOME/.poetry/bin:$PATH"

# add pip packages to PATH
export PATH="$HOME/.local/bin:$PATH"
