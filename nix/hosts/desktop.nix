# Desktop: the Arch + Hyprland workstation. Its profile is
# `packages.x86_64-linux.desktop`. Arch keeps the desktop session, the system
# Docker daemon, and GUI apps; this adds what only the desktop should have.
{ pkgs, dev }:
let
  # The package doesn't install its completions; generate them as dev.nix does.
  passCliCompletions = pkgs.runCommand "pass-cli-fish-completions" { } ''
    dir=$out/share/fish/vendor_completions.d
    mkdir -p $dir
    HOME=$TMPDIR ${pkgs.proton-pass-cli}/bin/pass-cli completions fish > $dir/pass-cli.fish
  '';
in
dev
++ (with pkgs; [
  # Proton Pass CLI, for its SSH agent. Desktop only: a signed-in vault on
  # m75q would be in reach of every unattended agent there.
  proton-pass-cli
  passCliCompletions
])
