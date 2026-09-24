{
  description = "Ian's headless Arch development tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.herdr.url = "github:herdrdev/herdr/v0.9.1";
  inputs.herdr.inputs.nixpkgs.follows = "nixpkgs";
  inputs.omp.url = "github:can1357/oh-my-pi";
  inputs.omp.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, herdr, omp, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      tools = with pkgs; [
        git
        gh
        stow
        ripgrep
        fd
        jq

        fish
        herdr.packages.${system}.default
        zellij
        neovim

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

        # Rootless engine (dockerd-rootless, run by the stowed user unit) and a
        # CLI wrapped with the compose/buildx plugins; docker-compose keeps the
        # legacy hyphenated command for scripts that still call it.
        docker
        docker-compose

        omp.packages.${system}.default
      ];
    in
    {
      packages.${system}.dev = pkgs.buildEnv {
        name = "dev-tools";
        paths = tools;
        pathsToLink = [ "/bin" "/share" ];
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = tools;
      };
    };
}
