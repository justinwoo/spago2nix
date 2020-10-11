{ sources ? import nix/sources.nix
, pkgs ? import sources.nixpkgs {}
, nodejs ? pkgs.nodejs-10_x
}:

  let
    dhall-json = (import sources.easy-dhall-nix {
      inherit pkgs;
    }).dhall-json-simple;

    easy-purescript-nix = import sources.easy-purescript-nix {
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
