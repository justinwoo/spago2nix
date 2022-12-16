# To test, run:
#
#     nix build
#
{
  description = "Test uint build with spago2nix_nativeBuildInputs";

  nixConfig.sandbox = "relaxed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    spago2nix.url = "path:..";
    easy-purescript-nix = {
      url = "github:justinwoo/easy-purescript-nix";
      flake = false;
    };
    uint = {
      url = "github:purescript-contrib/purescript-uint";
      flake = false;
    };
  };

  outputs = { self, uint, spago2nix, flake-utils, ... }@inputs:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system:
    let
      nixpkgs = inputs.nixpkgs.legacyPackages.${system};
      easy-purescript-nix = import inputs.easy-purescript-nix {pkgs = nixpkgs;};
    in
    {
      packages.default = nixpkgs.stdenv.mkDerivation {
        name = "test-uint";
        src = uint;
        nativeBuildInputs = [
            easy-purescript-nix.purs-0_15_4
        ] ++ (
          spago2nix.packages.${system}.spago2nix_nativeBuildInputs {
            srcs-dhall = [
              "${uint}/spago.dhall" "${uint}/packages.dhall"];
          }
        );
        unpackPhase = ''
          cp -r $src/src .
          install-spago-style
          '';
        buildPhase = ''
          build-spago-style "./src/**/*.purs"
          '';
        installPhase = ''
          mkdir -p $out
          mv output $out/
          '';
      };
    });
}
