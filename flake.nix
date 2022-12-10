{
  description = "PureScript build derivations from spago.dhall";

  nixConfig.sandbox = "relaxed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    easy-purescript-nix = {
      url = "github:justinwoo/easy-purescript-nix";
      flake = false;
    };
  };

  outputs = { self, ... }@inputs:
    inputs.flake-utils.lib.eachSystem ["x86_64-linux"] (system:
    let

      nixpkgs = inputs.nixpkgs.legacyPackages.${system};
      easy-purescript-nix = import inputs.easy-purescript-nix {pkgs = nixpkgs;};
      nix-prefetch-git-patched = import ./nix/nix-prefetch-git-patched.nix nixpkgs;
      spago2nix = import ./default.nix {
        pkgs = nixpkgs // {
          nix-prefetch-git = nix-prefetch-git-patched;
        };
      };

      # Generate spago-package.nix file from PureScript project Spago files.
      spago-packages-nix = {
        spago-dhall ? "spago.dhall", # the main spago.dhall file name, i.e. "spago.dhall"
        srcs-dhall # array of .dhall files, i.e. [./spago.dhall ./packages.dhall]
      }:
        nixpkgs.stdenv.mkDerivation {

        # https://zimbatm.com/notes/nix-packaging-the-heretic-way
        # So that spago2nix can fetch packages from Github.
        __noChroot = true;

        # We need HTTPS to fetch from github.
        SYSTEM_CERTIFICATE_PATH = "${nixpkgs.cacert}/etc/ssl/certs";
        SSL_CERT_FILE = "${nixpkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        NIX_SSL_CERT_FILE = "${nixpkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        GIT_SSL_CAINFO = "${nixpkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        name = "spago-packages";
        nativeBuildInputs = [
          spago2nix
          easy-purescript-nix.spago
        ];
        srcs = srcs-dhall;
        unpackPhase = ''
          for _src in $srcs; do
            cp "$_src" $(stripHash "$_src")
          done
        '';
        buildPhase = ''
          spago2nix generate 4 -- --config ${spago-dhall} --global-cache skip
          '';
        installPhase = ''
          mkdir $out
          cp spago-packages.nix $out/
          '';
        };

      # Produce nativeBuildInputs from PureScript project Spago files.
      #
      # For a derivation which has those nativeBuildInputs,
      # the PureScript project can be build in the buildPhase by executing
      # install-spago-style or build-spago-style.
      spago2nix_nativeBuildInputs = args@{
        spago-dhall ? "spago.dhall", # the main spago.dhall file name, i.e. "spago.dhall"
        srcs-dhall # array of .dhall files, i.e. [./spago.dhall ./packages.dhall]
      }:
        let
          # https://nixos.wiki/wiki/Import_From_Derivation
          ifd = import "${spago-packages-nix args}/spago-packages.nix" {pkgs=nixpkgs;};
        in
        [ ifd.installSpagoStyle ifd.buildSpagoStyle ];

    in

    {
      packages = {
        inherit spago2nix;
        inherit spago-packages-nix;
        inherit spago2nix_nativeBuildInputs;
      };
      apps = {
        spago2nix = {
          type = "app";
          program = "${spago2nix}/bin/spago2nix";
        };
      };
    }
    );
}
