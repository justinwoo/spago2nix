let
  easy-dhall-nix = pkgs: import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-dhall-nix";
    rev = "de5dfc71ce9e7597b62b470dee9254c6de09d515";
    sha256 = "1103sczf2xkwgbmmkmaqf59db6q0gb18vv4v3i7py1f8nlpyv02i";
  }) {
    inherit pkgs;
  };

in {
  pkgs ? import <nixpkgs> {},
  dhall-json ? (easy-dhall-nix pkgs).dhall-json-simple
}:

let
  easy-purescript-nix = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "50ebcb6107aec7562b8391e5b329c2856d79fc96";
    sha256 = "1j7mrk094mvaadpsxcz11namrzng9pzn4yzzlzmlcn90q3jzma1v";
  }) {
    inherit pkgs;
  };

in pkgs.stdenv.mkDerivation {
  name = "spago2nix";

  src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;

  buildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    target=$out/bin/spago2nix

    >>$target echo '#!/usr/bin/env node'
    >>$target echo "require('$src/bin/output.js')";

    chmod +x $target

    wrapProgram $target \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.nix-prefetch-git
        easy-purescript-nix.spago
        dhall-json
      ]}
  '';
}
