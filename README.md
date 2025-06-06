# Dotfiles

Modern dotfiles configuration using GNU Stow for symlink management.

## Structure

This repository uses the [GNU Stow](https://www.gnu.org/software/stow/) package manager to organize and deploy dotfiles. Each directory represents a "package" that can be independently managed.

```
dotfiles/
├── fish/           # Fish shell configuration
├── zellij/         # Zellij terminal multiplexer
├── ghostty/        # Ghostty terminal emulator
├── nvim/           # Neovim configuration
├── hyprland/       # Hyprland window manager
└── README.md
```

## New Setup (Fish + Zellij + Ghostty)

### Prerequisites

Install the required tools:

```bash
# Arch Linux
sudo pacman -S fish zellij ghostty stow

# Or using your preferred package manager
```

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
```

2. Install the configurations using stow:
```bash
# Install all configurations
stow */

# Or install specific configurations
stow fish
stow zellij
stow ghostty
```

3. Change your default shell to fish:
```bash
chsh -s $(which fish)
```

### Fish Shell Features

- **Modern prompt** with git integration
- **Vi key bindings** enabled by default
- **Zellij integration** - auto-starts zellij sessions
- **Modern tool aliases** (eza, bat, fd, rg if available)
- **Useful functions**:
  - `mkcd <dir>` - Create directory and cd into it
  - `extract <archive>` - Extract various archive formats
  - `zj [session] [layout]` - Zellij session manager

### Zellij Configuration

- **Alt-based keybindings** for easy navigation
- **Custom layouts** for different workflows
- **Catppuccin theme** for consistent appearance
- **Fish shell integration**

Key bindings:
- `Alt + h/j/k/l` - Navigate panes
- `Alt + t` - New tab
- `Alt + w` - Close tab
- `Alt + 1-9` - Switch to tab
- `Alt + |` - Split right
- `Alt + -` - Split down
- `Alt + r` - Resize mode
- `Alt + s` - Scroll mode

### Ghostty Configuration

- **Catppuccin theme** matching zellij
- **Fish shell integration**
- **Optimized for zellij** workflow
- **Smart clipboard handling**

## Migration from Zsh + Tmux + Kitty

### Removing Old Configuration

```bash
# Backup existing configurations
mkdir -p ~/.config/backup
mv ~/.config/zsh ~/.config/backup/ 2>/dev/null || true
mv ~/.tmux.conf ~/.config/backup/ 2>/dev/null || true
mv ~/.config/kitty ~/.config/backup/ 2>/dev/null || true

# Remove old shell configuration
rm ~/.zshrc ~/.zshenv 2>/dev/null || true
```

### Key Differences

| Old Stack | New Stack | Notes |
|-----------|-----------|-------|
| Zsh | Fish | More user-friendly, better autocompletion |
| Tmux | Zellij | Modern, Rust-based, better UX |
| Kitty | Ghostty | GPU-accelerated, better performance |

## Usage

### Managing Dotfiles with Stow

```bash
# Install a package
stow <package-name>

# Remove a package
stow -D <package-name>

# Reinstall a package
stow -R <package-name>

# Dry run (see what would happen)
stow -n <package-name>
```

### Adding New Configurations

1. Create a new directory with the package name
2. Mirror the home directory structure inside it
3. Place your configuration files in the appropriate locations
4. Use stow to install: `stow <package-name>`

Example:
```
new-package/
└── .config/
    └── new-app/
        └── config.toml
```

### Zellij Workflows

```bash
# Start a development session
zj dev dev

# Start a work session
zj work work  

# List all sessions
zj

# Attach to existing session
zj <session-name>
```

## Customization

### Fish Shell

- Edit `fish/.config/fish/config.fish` for shell configuration
- Add functions in `fish/.config/fish/functions/`
- Modify aliases and environment variables as needed

### Zellij

- Edit `zellij/.config/zellij/config.kdl` for keybindings and themes
- Add custom layouts in the `layouts` section
- Adjust keybindings to your preference

### Ghostty

- Edit `ghostty/.config/ghostty/ghostty` for terminal settings
- Adjust font, theme, and performance settings
- Customize keybindings for your workflow

## Troubleshooting

### Stow Conflicts

If stow reports conflicts:
```bash
# Remove conflicting files/links
rm ~/.config/fish/config.fish  # example

# Then retry stow
stow fish
```

### Shell Not Changing

If fish doesn't become your default shell:
```bash
# Check available shells
cat /etc/shells

# Ensure fish is in the list
which fish

# Change shell
chsh -s $(which fish)
```

### Zellij Not Auto-starting

If zellij doesn't auto-start, check:
1. Zellij is installed and in PATH
2. Fish configuration is properly sourced
3. No conflicts with other terminal multiplexers

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License. 