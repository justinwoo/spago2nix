#! /usr/bin/env nix-shell
#! nix-shell ../ci.nix -i bash

spago2nix
spago2nix generate
spago2nix install -j 100
spago2nix build
rm -rf output
spago2nix build-nix
nix-build build-project.nix
