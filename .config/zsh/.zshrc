## ░▀▀█░█▀▀░█░█░█▀▄░█▀▀
## ░▄▀░░▀▀█░█▀█░█▀▄░█░░
## ░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀

while read file
do 
  source "$ZDOTDIR/$file.zsh"
done <<-EOF
env
aliases
options
plugins
keybinds
prompt
EOF

# vim:ft=zsh

