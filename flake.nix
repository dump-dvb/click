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
          packages.default = package;

          devShells.default = pkgs.mkShell {
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
        overlays.default = final: prev: {
          inherit (self.packages.${prev.system})
          click;
        };

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
