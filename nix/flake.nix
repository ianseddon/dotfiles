{
  description = "Ian's Nix-managed development machines";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.herdr.url = "github:herdrdev/herdr/v0.9.3";
  inputs.herdr.inputs.nixpkgs.follows = "nixpkgs";
  inputs.omp.url = "github:can1357/oh-my-pi/v18.8.0";
  inputs.omp.inputs.nixpkgs.follows = "nixpkgs";
  # nixpkgs trails worktrunk releases (0.74.0 there), and `wt config plugins omp`
  # needs 0.78.0 or later.
  inputs.worktrunk.url = "github:max-sixty/worktrunk/v0.80.0";
  inputs.worktrunk.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, herdr, omp, worktrunk, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      args = { inherit pkgs system herdr omp worktrunk; };

      dev = import ./dev.nix args;

      # hosts/<name>.nix: the development tools plus that machine's own
      # packages. Each becomes a profile: `nix profile add path:./nix#<name>`.
      hosts = {
        m75q = import ./hosts/m75q.nix (args // { inherit dev; });
      };

      profile = name: paths: pkgs.buildEnv {
        name = "${name}-tools";
        inherit paths;
        pathsToLink = [ "/bin" "/share" ];
      };
    in
    {
      packages.${system} = builtins.mapAttrs profile hosts;

      # The development tools without any host's extras, for trying them out.
      devShells.${system} = {
        default = pkgs.mkShell { packages = dev; };
      };
    };
}
