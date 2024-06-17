{ pkgs ? import <nixpkgs> { }
, easy-dhall-nix ? import ./nix/easy-dhall-nix.nix { inherit pkgs; }
, dhall-json ? easy-dhall-nix.dhall-json-simple
, nodejs ? pkgs.nodejs-14_x
, easy-purescript-nix ? import ./nix/easy-purescript-nix.nix { inherit pkgs; }
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.coreutils
    pkgs.nix-prefetch-git
    easy-purescript-nix.spago
    dhall-json
    easy-purescript-nix.purs-0_13_8
    pkgs.pulp
  ];
}
