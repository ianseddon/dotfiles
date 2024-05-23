# Set the zinit home directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if it's not already installed
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source zinit
source "$ZINIT_HOME/zinit.zsh"

# Plugin setup
zinit light-mode for zdharma-continuum/zinit-annex-bin-gem-node
zinit light NICHOLAS85/z-a-linkbin # enable linkbin

##
## Completions
##

zinit ice blockf atpull'zinit creinstall -q .'; zinit light zsh-users/zsh-completions

autoload -U compinit && compinit

zinit cdreplay -q

##
## Prompt
##

# powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# powerlevel10k prompt (pure w/ zsh-async)
zinit ice pick"async.zsh" src"pure.zsh"; zinit light sindresorhus/pure

##
## Plugins
##
zinit light-mode for \
  hlissner/zsh-autopair \
  zsh-users/zsh-syntax-highlighting \
  MichaelAquilina/zsh-you-should-use \
  zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab
# lazy
zinit ice wait'3' lucid; zinit light zsh-users/zsh-history-substring-search
zinit ice wait'2' lucid; zinit light zdharma-continuum/history-search-multi-word

##
## Programs
##

# bat (cat/less)
zi for \
    from'gh-r' \
    lbin'!' \
    id-as \
    null \
  @sharkdp/bat
# dust (du)
zi for \
    from'gh-r' \
    lbin'!' \
    id-as \
    null \
  @bootandy/dust
# fd (find)
zi for \
    from'gh-r' \
    lbin'!' \
    id-as \
    null \
  @sharkdp/fd
# fnm
zinit for \
    as'completion' \
    atclone"./fnm completions --shell zsh > _fnm.zsh" \
    atload'eval $(fnm env --shell zsh)' \
    atpull'%atclone' \
    blockf \
    from'gh-r' \
    nocompile \
    sbin'fnm' \
  @Schniz/fnm
# fzf
zi for \
    from'gh-r'  \
    sbin'fzf'   \
  junegunn/fzf
# exa
zi for \
    atclone'cp -vf completions/exa.zsh _exa'  \
    from'gh-r' \
    sbin'**/exa -> exa' \
  ogham/exa
# lazygit
zi for \
    from'gh-r' \
    sbin'**/lazygit' \
  jesseduffield/lazygit
# neovim
zi for \
    from'gh-r' \
    sbin'**/nvim -> nvim' \
    ver'nightly' \
  neovim/neovim
# ripgrep (rg)
zi for \
    from'gh-r' \
    sbin'**/rg -> rg' \
  BurntSushi/ripgrep
# stow
zinit build for @aspiers/stow
# tmux
zinit for \
    configure'--disable-utf8proc' \
    make \
  @tmux/tmux

##
## Snippets
##
zinit snippet OMZP::archlinux # aliases / functions
zinit snippet OMZP::aws # completions
#zinit snippet OMZP::bun # completions
zinit snippet OMZP::command-not-found # suggest packages
zinit snippet OMZP::git # aliases / functions
zinit snippet OMZP::helm # aliases / completions
zinit snippet OMZP::kubectl # completions
zinit snippet OMZP::kubectx # prompt info
zinit snippet OMZP::npm # aliases / completions
zinit snippet OMZP::nvm # completions / source
#zinit snippet OMZP::poetry # completions
zinit snippet OMZP::sudo # 2x escape to prefix w/ sudo
zinit snippet OMZP::tmux # aliases / autostart

# vim:ft=zsh
