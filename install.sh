#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on supported system
check_system() {
    if [[ "$OSTYPE" != "linux-gnu"* ]] && [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script only supports Linux and macOS"
        exit 1
    fi
}

# Check if required tools are installed
check_dependencies() {
    local missing_deps=()
    
    command -v stow >/dev/null 2>&1 || missing_deps+=(stow)
    command -v git >/dev/null 2>&1 || missing_deps+=(git)
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install them and run this script again"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            print_info "On Arch Linux: sudo pacman -S ${missing_deps[*]}"
            print_info "On Ubuntu/Debian: sudo apt install ${missing_deps[*]}"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            print_info "On macOS: brew install ${missing_deps[*]}"
        fi
        exit 1
    fi
}

# Backup existing configurations
backup_configs() {
    print_info "Backing up existing configurations..."
    
    local backup_dir="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup existing configs if they exist
    [ -d "$HOME/.config/fish" ] && mv "$HOME/.config/fish" "$backup_dir/"
    [ -d "$HOME/.config/zellij" ] && mv "$HOME/.config/zellij" "$backup_dir/"
    [ -d "$HOME/.config/ghostty" ] && mv "$HOME/.config/ghostty" "$backup_dir/"
    [ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "$backup_dir/"
    [ -f "$HOME/.zshenv" ] && mv "$HOME/.zshenv" "$backup_dir/"
    [ -f "$HOME/.tmux.conf" ] && mv "$HOME/.tmux.conf" "$backup_dir/"
    
    if [ "$(ls -A $backup_dir 2>/dev/null)" ]; then
        print_success "Configurations backed up to: $backup_dir"
    else
        rmdir "$backup_dir"
        print_info "No existing configurations found to backup"
    fi
}

# Install configurations with stow
install_configs() {
    print_info "Installing configurations with stow..."
    
    local configs=()
    
    # Check which configurations are available
    [ -d "fish" ] && configs+=(fish)
    [ -d "zellij" ] && configs+=(zellij)
    [ -d "ghostty" ] && configs+=(ghostty)
    [ -d "nvim" ] && configs+=(nvim)
    [ -d "hyprland" ] && configs+=(hyprland)
    
    if [ ${#configs[@]} -eq 0 ]; then
        print_error "No configuration directories found!"
        exit 1
    fi
    
    for config in "${configs[@]}"; do
        print_info "Installing $config..."
        if stow "$config"; then
            print_success "$config installed successfully"
        else
            print_error "Failed to install $config"
            exit 1
        fi
    done
}

# Check if new tools are available and suggest installation
check_new_tools() {
    local tools_to_install=()
    
    command -v fish >/dev/null 2>&1 || tools_to_install+=(fish)
    command -v zellij >/dev/null 2>&1 || tools_to_install+=(zellij)
    command -v ghostty >/dev/null 2>&1 || tools_to_install+=(ghostty)
    
    if [ ${#tools_to_install[@]} -ne 0 ]; then
        print_warning "The following tools are not installed: ${tools_to_install[*]}"
        print_info "Please install them to use the new configuration:"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v pacman >/dev/null 2>&1; then
                print_info "  sudo pacman -S ${tools_to_install[*]}"
            elif command -v apt >/dev/null 2>&1; then
                print_info "  sudo apt install ${tools_to_install[*]}"
            elif command -v dnf >/dev/null 2>&1; then
                print_info "  sudo dnf install ${tools_to_install[*]}"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            print_info "  brew install ${tools_to_install[*]}"
        fi
    else
        print_success "All required tools are already installed!"
    fi
}

# Change default shell to fish
change_shell() {
    if command -v fish >/dev/null 2>&1; then
        local fish_path=$(which fish)
        
        # Check if fish is in /etc/shells
        if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
            print_warning "Fish shell not found in /etc/shells"
            print_info "You may need to add it manually:"
            print_info "  echo '$fish_path' | sudo tee -a /etc/shells"
        fi
        
        # Check current shell
        if [[ "$SHELL" != "$fish_path" ]]; then
            print_info "Would you like to change your default shell to fish? (y/N)"
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                if chsh -s "$fish_path"; then
                    print_success "Default shell changed to fish"
                    print_info "Please log out and back in for the change to take effect"
                else
                    print_error "Failed to change default shell"
                fi
            fi
        else
            print_success "Fish is already your default shell"
        fi
    else
        print_warning "Fish shell not installed, skipping shell change"
    fi
}

# Main function
main() {
    print_info "Starting dotfiles installation..."
    print_info "This will set up fish + zellij + ghostty configuration"
    
    check_system
    check_dependencies
    backup_configs
    install_configs
    check_new_tools
    change_shell
    
    print_success "Installation completed!"
    print_info "Next steps:"
    print_info "1. Install any missing tools (fish, zellij, ghostty)"
    print_info "2. Restart your terminal or log out and back in"
    print_info "3. Enjoy your new shell setup!"
    print_info ""
    print_info "Use 'zj' command for zellij session management"
    print_info "Check the README.md for more information"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 