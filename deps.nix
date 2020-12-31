{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs {};
  easy-dhall-nix = import sources.easy-dhall-nix { inherit pkgs; };
  easy-purescript-nix = import sources.easy-purescript-nix { inherit pkgs; };
in
 {
  inherit pkgs;
  dhall-json = easy-dhall-nix.dhall-json-simple;
  spago = easy-purescript-nix.spago;
  purescript = easy-purescript-nix.purescript;
  nodejs = pkgs.nodejs-10_x;
}
