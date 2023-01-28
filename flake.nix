{
  description = "Zola flake";
  nixConfig.bash-prompt = "\[nix-develop\]$ ";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    utils = {
      url = github:numtide/flake-utils;
    };
    # https://github.com/nix-community/poetry2nix/issues/734
    # ModuleNotFoundError: No module named 'hatchling'
    # Needed a more recent version of poetry2nix where overrides/build-systems.json had an entry for datadog Python package
    # Can be removed when nixpkgs unstable has poetry2nix >=1.32.0
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
  };
  };
  outputs = { nixpkgs, utils, self, poetry2nix, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        inherit (poetry2nix.legacyPackages.${system}) mkPoetryEnv;
        pkgs = import nixpkgs {
            inherit system;
          };
          poetryEnv = mkPoetryEnv {
            projectDir = ./.;
            editablePackageSources = {
            };
          };
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ poetryEnv zola poetry ];
            shellHook = ''
            pre-commit install --install-hooks
          '';
      };
    }
  );
}
