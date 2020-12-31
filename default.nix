{ sources ? import ./nix/sources.nix
, deps ? import ./deps.nix { inherit sources; }
, pkgs ? deps.pkgs
, dhall-json ? deps.dhall-json
, nodejs ? deps.pkgs.nodejs-10_x
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
    deps.spago
    dhall-json
  ]}
  '';
}
