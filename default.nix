{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "spago2nix";

  src = ./.;

  buildInputs = [
    pkgs.makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    target=$out/bin/spago2nix

    >>$target echo '#!/usr/bin/env node'
    >>$target echo "require('$src/bin/output.js')";

    chmod +x $target

    wrapProgram $target \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.nix-prefetch-git
      ]}
  '';
}
