{ pkgs ? import <nixpkgs> {} }:

let
  easy-dhall-nix = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-dhall-nix";
    rev = "b4736f4496cf313d41203f75a87f229b9a435f76";
    sha256 = "0lzzbwnkfs5fqya0r2wzzrysmn08rl002cndkz9s261gydp03pz4";
  }) {
    inherit pkgs;
  };

  easy-purescript-nix = import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-purescript-nix";
    rev = "e54b442633f59adedc3fbc81889ca7cb6b3ef087";
    sha256 = "17i19dnqmd71bdz83bc3aak2rx3p1lvgwp1cc02w3sm9i24s9pvz";
  });

in pkgs.stdenv.mkDerivation {
  name = "spago2nix";

  src = ./.;

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
        easy-dhall-nix.dhall-json-simple
      ]}
  '';
}
