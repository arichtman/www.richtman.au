{
  description = "Development environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    mado = {
      url = "github:akiomik/mado";
    };
  };
  outputs = { nixpkgs, flake-utils, ... }@inputs :
    flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ]
    (system:
      let
        pkgs = import nixpkgs {
            inherit system;
        };
      in {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              inputs.mado.packages.${system}.default
              zola
              actionlint
              prek
            ];
          };
    }
  );
}
