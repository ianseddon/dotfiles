# Development tools: what every Nix-managed machine gets. Machine-specific
# packages go in hosts/<name>.nix instead.
{ pkgs, system, herdr, omp, worktrunk }:
with pkgs; [
  git
  gh
  # `wt`: git worktrees with setup/teardown hooks (worktrunk.dev), from its own
  # flake at a release tag (see flake.nix).
  worktrunk.packages.${system}.default
  ripgrep
  fd
  jq
  awscli2
  ssm-session-manager-plugin
  pgcli

  fish
  herdr.packages.${system}.default
  zellij
  neovim
  tuicr

  # Standalone Corepack supplies pnpm/yarn shims without a bundled copy.
  nodejs-slim_24
  nodejs-slim_24.npm
  (corepack.override { nodejs-slim = nodejs-slim_24; })
  bun
  python312
  uv
  gcc
  gnumake
  pkg-config

  omp.packages.${system}.default
]
