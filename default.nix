{ pkgs ? import <nixpkgs> { }
, easy-dhall-nix ? import ./nix/easy-dhall-nix.nix { inherit pkgs; }
, dhall-json ? easy-dhall-nix.dhall-json-simple
, nodejs ? pkgs.nodejs-14_x
, easy-purescript-nix ? import ./nix/easy-purescript-nix.nix { inherit pkgs; }
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
      easy-purescript-nix.spago
      dhall-json
    ]}
  '';
}
