#! /usr/bin/env nix-shell
#! nix-shell ../ci.nix -i bash

set -e

spago2nix
spago2nix generate 8
spago2nix install
spago2nix build
rm -rf output
spago2nix build-nix
nix-build build-project.nix
