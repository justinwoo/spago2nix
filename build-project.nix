{ pkgs ? (import ./deps.nix {}).pkgs }:

let
  easy-ps = import (
    pkgs.fetchFromGitHub {
      owner = "justinwoo";
      repo = "easy-purescript-nix";
      rev = "cc7196bff3fdb5957aabfe22c3fa88267047fe88";
      sha256 = "1xfl7rnmmcm8qdlsfn3xjv91my6lirs5ysy01bmyblsl10y2z9iw";
    }
  ) {
    inherit pkgs;
  };

  spago2nix = import ./spago-packages.nix {
    inherit pkgs;
  };

in
spago2nix.mkBuildProjectOutput {
  src = ./src;

  purs = easy-ps.purs;
}
