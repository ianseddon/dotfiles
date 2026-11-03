function _abbr_nix_run --description 'Expand r#pkg to nix run nixpkgs#pkg'
    string replace -r '^r#' 'nix run nixpkgs#' -- $argv[1]
end
