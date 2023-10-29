#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILE_LIST="$DOTFILES_DIR/filelist.txt"

while IFS= read -r file; do
  # Ignore empty lines and comments
  [[ "$file" == \#* ]] || [[ -z "$file" ]] && continue
  
  SRC="$HOME/$file"
  DEST="$DOTFILES_DIR/$file"

  # If the file exists in the home directory but is not in the dotfiles repo
  if [[ -f "$SRC" && ! -L "$SRC" && ! -e "$DEST" ]]; then
    # Create the directory structure in the dotfiles repo if it does not exist
    mkdir -p "$(dirname "$DEST")"
    # Move the file to the dotfiles repo
    mv "$SRC" "$DEST"
    # Symlink it back to the original location
    ln -s "$DEST" "$SRC"
    echo "Moved and linked $file"
  # If the file is in the dotfiles repo but not symlinked
  elif [[ -e "$DEST" && ! -L "$SRC" ]]; then
    ln -s "$DEST" "$SRC"
    echo "Linked $file"
  fi
done < "$FILE_LIST"
