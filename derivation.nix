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
    elmVersion = "0.19.1";
    #versionsDat = ./versions.dat;
    registryDat = ./registry.dat;
  };

  installPhase = ''
    mkdir -p $out/web
    cp src/index.html $out/web
    cp -r src/js $out/web/js
  '';

  buildPhase = ''
    elm make src/Main.elm --optimize --output=$out/web/main.js
  '';
}
