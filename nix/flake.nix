{
  description = "Ian's Nix-managed development machines";

  # nixpkgs is the only input, so every tool moves with `nix flake update` and
  # no file names a version. A tool nixpkgs lacks, or packages too far behind,
  # can come from its own flake, but track its default branch rather than a
  # release tag so updating stays one command.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  # pi ships releases faster than nixpkgs packages them. Its repository's
  # nix/package.nix builds against our nixpkgs, so it's a source, not a flake.
  # The one input pinned to a release: pi's main branch often doesn't build,
  # and it has no release branch. Bump the tag when pi releases.
  inputs.pi.url = "github:earendil-works/pi/v1.5.0";
  inputs.pi.flake = false;

  outputs = { nixpkgs, pi, ... }:
    let
      system = "x86_64-linux";
      # Unfree packages are allowed by name, so a new one is a deliberate edit.
      unfree = [ "acli" "acli-unwrapped" "claude-code" ];
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfree;
      };

      # Delete the patch once earendil-works/pi#11685 merges; until then
      # pi-schema has no tarball and the package fails to evaluate.
      piSource = pkgs.applyPatches {
        name = "pi-source";
        src = pi;
        patches = [ ./patches/pi-schema-tarball.patch ];
      };

      dev = import ./dev.nix {
        inherit pkgs;
        pi = pkgs.callPackage (piSource + "/nix/package.nix") { source = piSource; };
      };

      # hosts/<name>.nix: the development tools plus that machine's own
      # packages. Each becomes a profile: `nix profile add path:./nix#<name>`.
      hosts = {
        desktop = import ./hosts/desktop.nix { inherit pkgs dev; };
        m75q = import ./hosts/m75q.nix { inherit pkgs dev; };
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
