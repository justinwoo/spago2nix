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
    pkgs.stdenv.mkDerivation {
      name = "spago2nix";

      src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;

      buildInputs = [ pkgs.makeWrapper ];

      installPhase = ''
        mkdir -p $out/bin
        target=$out/bin/spago2nix

        >>$target echo '#!${nodejs}/bin/node'
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
