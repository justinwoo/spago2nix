let
  easy-dhall-nix = pkgs: import (pkgs.fetchFromGitHub {
    owner = "justinwoo";
    repo = "easy-dhall-nix";
    rev = "b4736f4496cf313d41203f75a87f229b9a435f76";
    sha256 = "0lzzbwnkfs5fqya0r2wzzrysmn08rl002cndkz9s261gydp03pz4";
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
    rev = "3cc22df4d4495b884d4537c715316fd83dfe4831";
    sha256 = "1h5cfligvgnbbhq98vmzsvb7b37gmvsk17k7qxncfb66l3jshcmp";
  });

in pkgs.stdenv.mkDerivation {
  name = "spago2nix";

  src = pkgs.nix-gitignore.gitignoreSource [".git"] ./.;

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
        dhall-json
      ]}
  '';
}
