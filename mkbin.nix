# shell environment for generating bin/output.js
# Usage:
#
#     nix-shell mkbin.nix
#

{ pkgs ? import <nixpkgs> {}
, nodejs ? pkgs.nodejs-10_x
}:

  let
    easy-purescript-nix = import (
      pkgs.fetchFromGitHub {
        owner = "justinwoo";
        repo = "easy-purescript-nix";
        rev = "1ec689df0adf8e8ada7fcfcb513876307ea34226";
        sha256 = "12hk2zbjkrq2i5fs6xb3x254lnhm9fzkcxph0a7ngxyzfykvf4hi";
      }
    ) {
      inherit pkgs;
    };

  in
    pkgs.mkShell {
      nativeBuildInputs = [
        easy-purescript-nix.purs
        easy-purescript-nix.spago
        nodejs
      ];
      shellHook = ''
        npm install
        npm run mkbin
        exit 0
      '';
    }
