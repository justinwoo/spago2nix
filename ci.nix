{ deps ? import ./deps.nix {}
, pkgs ? deps.pkgs }:

let
  spago2nix = import ./default.nix {
    inherit pkgs;
  };

in
pkgs.mkShell {
  buildInputs = [ deps.purescript spago2nix ];
}
