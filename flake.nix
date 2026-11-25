{
  description = "Ian's Nix-managed development machines";

  # nixpkgs is the primary input, so most tools move together with
  # `nix flake update`. pi tracks a release tag because nixpkgs trails its
  # releases and its main branch often does not build.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.pi = {
    url = "github:earendil-works/pi/v1.6.0";
    flake = false;
  };
  inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      pi,
      treefmt-nix,
    }:
    let
      system = "x86_64-linux";
      # Unfree packages are allowed by name, so a new one is a deliberate edit.
      unfree = [
        "acli"
        "acli-unwrapped"
        "claude-code"
      ];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfree;
      };

      dev = import ./nix/dev.nix {
        inherit pkgs;
        pi = pkgs.callPackage (pi + "/nix/package.nix") { source = pi; };
      };

      # nix/hosts/<name>.nix: the development tools plus that machine's own
      # packages. Each becomes a profile: `nix profile add path:.#<name>`.
      hosts = {
        desktop = import ./nix/hosts/desktop.nix { inherit pkgs dev; };
        m75q = import ./nix/hosts/m75q.nix { inherit pkgs dev; };
      };

      profile =
        name: paths:
        pkgs.buildEnv {
          name = "${name}-tools";
          inherit paths;
          pathsToLink = [
            "/bin"
            "/share"
          ];
        };

      treefmtEval = treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix;
    in
    {
      packages.${system} = builtins.mapAttrs profile hosts;

      # The development tools without any host's extras, for trying them out.
      devShells.${system} = {
        default = pkgs.mkShell { packages = dev; };
      };

      formatter.${system} = treefmtEval.config.build.wrapper;

      checks.${system} = {
        formatting = treefmtEval.config.build.check self;
      };
    };
}
