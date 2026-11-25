# Formatters and linters behind `nix fmt`, pinned by flake.lock.
# treefmt walks only files tracked by git, so untracked local state is skipped.
let
  # Extensionless shell scripts that shfmt and shellcheck would otherwise skip.
  shellScripts = [
    ".githooks/*"
    "theme/.config/theme/hooks/*"
    "pi/.local/bin/agent-skills-pi"
    "borgmatic/.local/bin/backup-system"
    "herdr/.local/share/herdr-plugins/*/bin/*"
    "skills/herdr-secret-input/ask-secret"
    "skills/herdr-secret-input/herdr-plugin/bin/secret-prompt"
  ];
in
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    deadnix.enable = true;
    statix = {
      enable = true;
      disabled-lints = [ "empty_pattern" ];
    };
    shfmt = {
      enable = true;
      indent_size = 2;
    };
    shellcheck.enable = true;
  };

  settings = {
    formatter.shfmt.includes = shellScripts;
    formatter.shellcheck.includes = shellScripts;
    global.excludes = [
      "*.lock"
      "agents/.agents/skills/**"
    ];
  };
}
