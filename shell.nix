{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = with pkgs; [
      elmPackages.elm
      elmPackages.elm-format
      elmPackages.elm-test
      elmPackages.elm-coverage
      elmPackages.elm-analyse
      nodejs
      nodePackages.parcel-bundler
      python39
      python39Packages.requests
    ];
}
