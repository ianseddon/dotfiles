# Hunk

User configuration and trusted global extensions for Hunk 0.24.1.

Deploy with:

```bash
stow --no-folding --target="$HOME" hunk
mkdir -p ~/.config/hunk/extensions
cp -R ~/dotfiles/hunk/extensions/vim-navigation ~/.config/hunk/extensions/
cp -R ~/dotfiles/hunk/extensions/rendered-markdown ~/.config/hunk/extensions/
cd ~/.config/hunk/extensions/rendered-markdown
bun install --frozen-lockfile
```

The extensions are copied rather than symlinked so their runtime dependencies
resolve normally. `node_modules` stays out of version control, and Stow's
`--no-folding` keeps Hunk's live state out of the repository.
