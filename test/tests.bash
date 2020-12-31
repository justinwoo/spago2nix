#! /usr/bin/env nix-shell
#! nix-shell ../ci.nix -i bash

set -e

function run () {
  echo "$ $@"
  "$@"
}

run spago2nix
run spago2nix generate 8
run spago2nix install \
  --arg pkgs '(import ./deps.nix {}).pkgs'
run spago2nix build \
  --arg pkgs '(import ./deps.nix {}).pkgs'
run rm -rf output
run spago2nix build-nix \
  --arg pkgs '(import ./deps.nix {}).pkgs'
run nix-build build-project.nix
