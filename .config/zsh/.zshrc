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

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
