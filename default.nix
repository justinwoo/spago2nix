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

  easy-purescript-nix = pkgs: import (
    pkgs.fetchFromGitHub {
      owner = "justinwoo";
      repo = "easy-purescript-nix";
      rev = "e8a1ffafafcdf2e81adba419693eb35f3ee422f8";
      sha256 = "0bk32wckk82f1j5i5gva63f3b3jl8swc941c33bqc3pfg5cgkyyf";
    }
  ) {
    inherit pkgs;
  };

in
{ pkgs ? import <nixpkgs> {}
, dhall-json ? (easy-dhall-nix pkgs).dhall-json-simple
, nodejs ? pkgs.nodejs-10_x
, spago ? (easy-purescript-nix pkgs).spago
}:

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
    spago
    dhall-json
  ]}
  '';
}
