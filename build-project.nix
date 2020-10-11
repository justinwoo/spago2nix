{ sources ? import nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

let
  easy-ps = import sources.easy-purescript-nix {
    inherit pkgs;
  };

  spago2nix = import ./spago-packages.nix {
    inherit pkgs;
  };

in
spago2nix.mkBuildProjectOutput {
  src = ./src;

  purs = easy-ps.purs;
}
