# shell environment for generating bin/output.js
# Usage:
#
#     nix-shell mkbin.nix
#

{ sources ? import nix/sources.nix
, pkgs ? import sources.nixpkgs {}
, nodejs ? pkgs.nodejs-10_x
}:

  let
    easy-purescript-nix = import sources.easy-purescript-nix {
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
