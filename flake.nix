{
  description = "Zola flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    utils = {
      url = github:numtide/flake-utils;
    };
    # Use p2nix directly for the updates
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
