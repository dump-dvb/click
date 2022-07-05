{ pkgs, lib, pkg-config, stdenv, elm, elm-format, yarn}:
let
  /*yarnPkg = pkgs.yarn2nix.mkYarnPackage {
    name = "myproject-node-packages";
    packageJSON = ./package.json;
    unpackPhase = ":";
    src = null;
    yarnLock = ./yarn.lock;
    publishBinsFor = ["parcel-bundler"];
  }; */
in stdenv.mkDerivation {
  name = "click";
  src = pkgs.lib.cleanSource ./.;
  
  #with pkgs.elmPackages; 
  buildInputs = [
    elm
    elm-format
    #yarnPkg
    yarn
  ];

  patchPhase = ''
    rm -rf elm-stuff
  '';
  # ln -sf ${yarnPkg}/node_modules .

  shellHook = ''
  '';
  # ln -fs ${yarnPkg}/node_modules .

  configurePhase = pkgs.elmPackages.fetchElmDeps {
    elmPackages = import ./elm-srcs.nix;
    versionsDat = ./versions.dat;
  };

  installPhase = ''
    mkdir -p $out
    parcel build -d $out index.html
  '';
}
