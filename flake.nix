{
  description = "Development environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    # Use p2nix directly for the updates
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
    };
  };
  outputs = { nixpkgs, flake-utils, self, poetry2nix, ... } :
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ]
    (system:
      let
        pkgs = import nixpkgs {
            inherit system;
            overlays = [poetry2nix.overlays.default];
        };
        poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
          };
      in {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              poetry
              poetryEnv
              zola
              actionlint
            ];
            shellHook = ''
              pre-commit install --install-hooks
            '';
          };
    }
  );
}
