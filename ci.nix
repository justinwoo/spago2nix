{ pkgs ? import <nixpkgs> {} }:

let
  easy-ps = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "50ebcb6107aec7562b8391e5b329c2856d79fc96";
    sha256 = "1j7mrk094mvaadpsxcz11namrzng9pzn4yzzlzmlcn90q3jzma1v";
  }) {
    inherit pkgs;
  };

  spago2nix = import ./default.nix {
    inherit pkgs;
  };

in pkgs.mkShell {
  buildInputs = [ easy-ps.purs spago2nix ];
}
