# git
abbr -a g git
abbr -a gs git status
abbr -a ga git add
abbr -a gc git commit
abbr -a gp git push
abbr -a gl git log --oneline --graph --decorate
abbr -a gd git diff
abbr -a gb git branch
abbr -a gco git checkout

# ls
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'

alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# nvim
abbr vim nvim
abbr vi nvim
abbr v nvim

# bat
if type -q bat
    alias cat=bat
    alias less=bat
    alias head='bat --line-range :10'
    alias tail='bat --line-range -10:'
end

# eza
if type -q eza
    alias ls=eza
    alias ll "eza -l -a --icons"
    abbr llt "eza -l -a --icons --tree"
end

# fd
if command -v fd >/dev/null
    alias find=fd
end

# ripgrep
if command -v rg >/dev/null
    alias grep=rg
end

# zoxide
if command -v z >/dev/null
    alias cd=z
end
