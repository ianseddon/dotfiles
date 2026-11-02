# Desktop: the Arch + Hyprland workstation. Its profile is
# `packages.x86_64-linux.desktop`. Arch keeps the desktop session, the system
# Docker daemon, and GUI apps; this adds nothing beyond the development tools.
{ pkgs, dev }:
dev
