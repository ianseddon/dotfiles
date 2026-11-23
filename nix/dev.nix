# Development tools: what every Nix-managed machine gets. Machine-specific
# packages go in hosts/<name>.nix instead.
{ pkgs, pi }:
let
  # pi-agent-browser-native needs agent-browser 0.43.0 or later, and nixpkgs
  # still ships 0.41.1. Delete this override once pkgs.agent-browser.version
  # reaches 0.43.0; the assertion below fails the build to say so.
  agent-browser-package =
    assert pkgs.lib.versionOlder pkgs.agent-browser.version "0.43.0";
    pkgs.agent-browser.overrideAttrs (finalAttrs: previousAttrs: {
      version = "0.43.0";
      src = pkgs.fetchFromGitHub {
        owner = "vercel-labs";
        repo = "agent-browser";
        tag = "v${finalAttrs.version}";
        hash = "sha256-+hmbSIgTqs5uZW7j0hAhz/9Fd24Np80DfoccqN4fGF4=";
      };
      cargoHash = "sha256-MKTL/1k3gvGB0ylg4iAi2WyZ1sNrEpBJVtvjc7J6maA=";
      # This test launches Chrome, which the build sandbox doesn't have.
      checkFlags = (previousAttrs.checkFlags or [ ]) ++ [
        "--skip=native::actions::tests::a_rejected_write_with_stripped_credentials_still_reaches_the_replay"
      ];
      passthru = previousAttrs.passthru // {
        dashboard = previousAttrs.passthru.dashboard.overrideAttrs (dashboardAttrs: {
          inherit (finalAttrs) version src;
          pnpmDeps = pkgs.fetchPnpmDeps {
            pname = "agent-browser-dashboard";
            inherit (finalAttrs) version src;
            pnpm = pkgs.pnpm_11;
            pnpmWorkspaces = [ "dashboard" ];
            fetcherVersion = 4;
            hash = "sha256-gSxTBHR2Fcaq/hUSiOMK5W+6+fLw/D2sCRurXEP8ApI=";
          };
        });
      };
    });

  # agent-browser drives Chrome over CDP. Point it at nixpkgs' Chromium so both
  # machines automate the same pinned browser without `agent-browser install`,
  # and without putting a second `chromium` on PATH next to the desktop's.
  # --set-default keeps AGENT_BROWSER_EXECUTABLE_PATH overridable per call.
  agent-browser = pkgs.symlinkJoin {
    name = "agent-browser-${agent-browser-package.version}";
    paths = [ agent-browser-package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/agent-browser \
        --set-default AGENT_BROWSER_EXECUTABLE_PATH ${pkgs.chromium}/bin/chromium
    '';
  };
  # Fish completions for tools whose packages don't install one, generated
  # from the same binaries at build time so they move with nixpkgs. acli had
  # one until 1.3.41 removed its `completion` command; add it back here
  # (`acli completion fish`) once a release restores it.
  completions = pkgs.runCommand "generated-fish-completions" { } ''
    dir=$out/share/fish/vendor_completions.d
    mkdir -p $dir
    export HOME=$TMPDIR INFISICAL_DISABLE_UPDATE_CHECK=true
    ${pkgs.infisical}/bin/infisical completion fish > $dir/infisical.fish
  '';
  # gh extensions from nixpkgs instead of `gh extension install`, so they move
  # with `nix flake update`. gh only looks in ~/.local/share/gh/extensions,
  # which the `gh` Stow package links to this profile directory.
  ghExtensions = with pkgs; [ gh-dash gh-enhance gh-stack ];
  ghExtensionDir = pkgs.runCommand "gh-extensions" { } (''
    mkdir -p $out/share/gh/extensions
  '' + pkgs.lib.concatMapStrings (ext: ''
    mkdir $out/share/gh/extensions/${ext.pname}
    ln -s ${ext}/bin/${ext.pname} $out/share/gh/extensions/${ext.pname}/${ext.pname}
  '') ghExtensions);
in
with pkgs; [
  completions
  ghExtensionDir
  git
  git-lfs
  gh
  # Atlassian CLI (Jira/Confluence).
  acli
  # Diff pager for git and gh-dash.
  delta
  lazygit
  lazydocker
  # Installs the dotfiles themselves.
  stow
  # `wt`: git worktrees with setup/teardown hooks (worktrunk.dev).
  worktrunk
  ripgrep
  fd
  jq
  # kislyuk/yq: jq for YAML/XML/TOML (yq, xq, tomlq), not mikefarah's yq-go.
  yq
  # Structural search and rewrite, by syntax tree rather than text.
  ast-grep
  bat
  eza
  # Markdown in the terminal.
  glow
  btop
  awscli2
  ssm-session-manager-plugin
  pgcli
  hyperfine

  # Linters: shell scripts (dotfiles, firstmate, herdr plugins) and GitHub
  # Actions workflows.
  shellcheck
  shfmt
  actionlint
  # Python, for projects that don't pin their own (uv runs those).
  ruff
  basedpyright

  fish
  # Plugins load from the profile's share/fish (nix/.config/fish/conf.d/nix.fish).
  fishPlugins.tide
  fishPlugins.fzf-fish
  # Desktop notification when a long command finishes.
  fishPlugins.done
  # Drops failed commands from history, so autosuggestions skip typos.
  fishPlugins.sponge
  # Shell history in SQLite with directory, exit code, duration and host.
  atuin
  # Per-directory environments; nix-direnv caches `use flake`.
  direnv
  nix-direnv
  herdr
  # The herdr plugins' pickers (herdr/.local/share/herdr-plugins, herdr-worktrunk)
  # are fzf; workspace-pickr also lists zoxide's top repos.
  fzf
  zoxide
  neovim
  # nvim-treesitter (main) compiles its parsers with `tree-sitter build`
  # and the gcc below.
  tree-sitter
  # Code review: hunk for my own agents' changes, tuicr for other people's.
  hunk
  tuicr

  # Coding agent and its tools. pi installs its own packages (settings.json
  # `packages`) with the npm below; secrets come from Infisical.
  pi
  agent-browser
  infisical
  # Other agents. Their self-updaters are off; they move with nixpkgs like
  # everything else.
  claude-code
  codex

  # Node 24 is the default everywhere, including systemd units, scripts, and
  # pi's package installs. fnm switches per project from .node-version/.nvmrc
  # in fish (hooked in conf.d/nix.fish), defaulting to its newest 24.x.
  fnm
  # Standalone Corepack supplies pnpm/yarn shims without a bundled copy.
  nodejs-slim_24
  nodejs-slim_24.npm
  (corepack.override { nodejs-slim = nodejs-slim_24; })
  bun
  # Python is uv's: it installs interpreters per project (.python-version)
  # and runs tools with `uv tool` / `uvx`. No global Nix Python.
  uv
  gcc
  gnumake
  pkg-config
]
# The extensions themselves are on PATH too, for their completions and gh-stack's skill.
++ ghExtensions
