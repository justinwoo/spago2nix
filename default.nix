let
  easy-dhall-nix = pkgs: import (
    pkgs.fetchFromGitHub {
      owner = "justinwoo";
      repo = "easy-dhall-nix";
      rev = "9c4397c3af63c834929b1e6ac25eed8ce4fca5d4";
      sha256 = "1cbrqfbx29rymf4sia1ix4qssdybjdvw0is9gv7l0wsysidrcwhf";
    }
  ) {
    inherit pkgs;
  };

in
{ pkgs ? import <nixpkgs> {}
, dhall-json ? (easy-dhall-nix pkgs).dhall-json-simple
}:

  let
    easy-purescript-nix = import (
      pkgs.fetchFromGitHub {
        owner = "justinwoo";
        repo = "easy-purescript-nix";
        rev = "cc7196bff3fdb5957aabfe22c3fa88267047fe88";
        sha256 = "1xfl7rnmmcm8qdlsfn3xjv91my6lirs5ysy01bmyblsl10y2z9iw";
      }
    ) {
      inherit pkgs;
    };

  in
    pkgs.stdenv.mkDerivation {
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
        pkgs.coreutils
        pkgs.nix-prefetch-git
        easy-purescript-nix.spago
        dhall-json
      ]}
      '';
    }
