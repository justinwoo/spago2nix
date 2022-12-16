# shell environment for generating bin/output.js
# Usage:
#
#     nix-shell mkbin.nix
#

{ pkgs ? import <nixpkgs> { }
, nodejs ? pkgs.nodejs-14_x
}:
let
  easy-purescript-nix = import
    (
      pkgs.fetchFromGitHub {
        owner = "justinwoo";
        repo = "easy-purescript-nix";
        rev = "e00a54ca6bd0290e8301eff140d109c1f300e40d";
        sha256 = "1yrnnpxkzs59ik5dj9v67ysn4viff775v24kizpl0ylf24c74928";
      }
    ) {
    inherit pkgs;
  };

in
pkgs.mkShell {
  nativeBuildInputs = [
    easy-purescript-nix.purs-0_13_8
    easy-purescript-nix.spago
    nodejs
  ];
  shellHook = ''
    npm install
    npm run mkbin
    exit 0
  '';
}
