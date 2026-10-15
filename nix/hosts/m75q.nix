# M75q: the headless Arch development host, reached over Tailscale SSH.
# Its profile is `packages.x86_64-linux.m75q`: the development tools plus what
# exists because of this machine rather than because of development.
{ pkgs, dev, ... }:
dev
++ (with pkgs; [
  # Installs this host's dotfiles (`stow --target="$HOME" nix`).
  stow

  # Rootless engine (dockerd-rootless, run by the stowed user unit) and a
  # CLI wrapped with the compose/buildx plugins; docker-compose keeps the
  # legacy hyphenated command for scripts that still call it.
  docker
  docker-compose
])
