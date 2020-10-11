{ sources ? import nix/sources.nix
, pkgs ? import sources.nixpkgs { }
}:

let
  easy-ps = import sources.easy-purescript-nix {
    inherit pkgs;
  };

  spago2nix = import ./default.nix {
    inherit pkgs;
  };

in
pkgs.mkShell {
  buildInputs = [ easy-ps.purs spago2nix ];
}
