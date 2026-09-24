# Arch owns the host toolchain; Nix profile tools are fallbacks outside nix develop.
if not set -q IN_NIX_SHELL; and test -d "$HOME/.nix-profile/bin"
    fish_add_path --path --move --append "$HOME/.nix-profile/bin"
end
