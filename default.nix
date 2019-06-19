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
    rev = "7f6b91f42a9a00fdc10e28dfb89202b929c8ff55";
    sha256 = "1arnk5abdgiv4x83aa80vkld9qs2z7808xlz7jvmhbc3p7ya497b";
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
        easy-purescript-nix.purs
        easy-purescript-nix.spago
        easy-dhall-nix.dhall-json-simple
      ]}
  '';
}
