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
alias vim=nvim
alias vi=nvim

# stuff... but better
if command -v eza >/dev/null
    alias ls=eza
end

if command -v bat >/dev/null
    alias cat=bat
end

if command -v fd >/dev/null
    alias find=fd
end

if command -v rg >/dev/null
    alias grep=rg
end

if command -v z >/dev/null
    alias cd=z
end
