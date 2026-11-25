# Neovim wrapped with its LSP servers, formatters, plugin helpers, and
# prebuilt Treesitter parsers + queries from nixpkgs so desktop and m75q
# behave identically without mason or `:TSInstall`.
{ pkgs }:
let
  inherit (pkgs) lib;

  # Neovim 0.12 ships c, lua, markdown, markdown_inline, query, vim, and vimdoc;
  # adding them here would shadow its built-in queries.
  languages = [
    "bash"
    "css"
    "diff"
    "dockerfile"
    "fish"
    "git_config"
    "git_rebase"
    "gitignore"
    "go"
    "gomod"
    "gosum"
    "html"
    "javascript"
    "json"
    "luadoc"
    "luap"
    "nix"
    "python"
    "qmljs"
    "regex"
    "rust"
    "sql"
    "svelte"
    "toml"
    "tsx"
    "typescript"
    "yaml"
  ];

  # Queries inherited by other languages (for example typescript inherits ecma)
  # that do not have a parser of their own.
  sharedQueries = [
    "ecma"
    "html_tags"
    "jsx"
  ];

  ts = pkgs.vimPlugins.nvim-treesitter;
  treesitterFiles = pkgs.symlinkJoin {
    name = "nvim-treesitter-files";
    paths =
      lib.concatMap (lang: [
        ts.grammarPlugins.${lang}
        ts.queries.${lang}
      ]) languages
      ++ map (lang: ts.queries.${lang}) sharedQueries;
  };
  treesitterSite = pkgs.runCommand "nvim-treesitter-site" { } ''
    mkdir -p $out/share/nvim/site
    ln -s ${treesitterFiles}/parser $out/share/nvim/site/parser
    ln -s ${treesitterFiles}/queries $out/share/nvim/site/queries
  '';

  # Tools Neovim invokes by name: LSP servers (nvim/.config/nvim/lsp/*.lua),
  # conform formatters (lua/plugins/conform.lua), and fzf-lua helpers.
  # Appended via --suffix PATH so project-local versions (node_modules/.bin,
  # fnm, uv, nix develop) always win.
  tools = with pkgs; [
    basedpyright
    bat
    biome
    dockerfile-language-server
    fd
    fzf
    gofumpt
    gopls
    gotools
    lua-language-server
    prettier
    ripgrep
    ruff
    rust-analyzer
    stylua
    tailwindcss-language-server
    vscode-langservers-extracted
    vtsls
    yaml-language-server
  ];
in
pkgs.symlinkJoin {
  name = "neovim-with-tools-${pkgs.neovim.version}";
  paths = [
    pkgs.neovim
    treesitterSite
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/nvim \
      --suffix PATH : ${lib.makeBinPath tools} \
      --run 'export XDG_DATA_DIRS="''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:${treesitterSite}/share"'
  '';
}
