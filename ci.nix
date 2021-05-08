{ pkgs ? import <nixpkgs> { } }:
let
  easy-ps = import
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

  spago2nix = import ./default.nix {
    inherit pkgs;
  };

in
pkgs.mkShell {
  buildInputs = [
    easy-ps.purs-0_13_8
    spago2nix
  ];
}
