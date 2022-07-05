{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    utils = {
      url = github:numtide/flake-utils;
    };
  };

  outputs = { self, nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          package = pkgs.callPackage ./derivation.nix { 
              elm = pkgs.elmPackages.elm;
              elm-format = pkgs.elmPackages.elm-format;
          };

        in
        rec {
          checks = packages;
          packages.click = package;
          defaultPackage = package;
          overlay = (final: prev: {
            click = package;
          });

          devShells = pkgs.mkShell {
          buildInputs = with pkgs.elmPackages;  [
              elm
              elm-format
              #yarnPkg
              pkgs.yarn
            ];

            shellHook = ''
            '';
          };
        }
      ) // {
      hydraJobs =
        let
          hydraSystems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        in
        builtins.foldl'
          (hydraJobs: system:
            builtins.foldl'
              (hydraJobs: pkgName:
                nixpkgs.lib.recursiveUpdate hydraJobs {
                  ${pkgName}.${system} = self.packages.${system}.${pkgName};
                }
              )
              hydraJobs
              (builtins.attrNames self.packages.${system})
          )
          { }
          hydraSystems;
    };
}
