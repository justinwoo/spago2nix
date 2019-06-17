# Spago2Nix

[![Build Status](https://travis-ci.com/justinwoo/spago2nix.svg?branch=master)](https://travis-ci.com/justinwoo/spago2nix)

### Does not yet work with a released version of Spago

Generate a derivation of Spago dependencies, and use them to install them into the directory structure used by Spago.

## Installation

For now, simply clone this repo and run `npm link`. Requires a Node runtime and nix-prefetch-git.

Remember to set npm prefix to something like `~/.npm`.

## Usage

First, generate the spago-packages.nix:

```bash
$ spago2nix generate
getting packages..
got 65 packages from Spago list-packages.
# ...
wrote spago-packages.nix
```

Then install these, optionally with more jobs provided to Nix:

```bash
$ spago2nix install -j 100
/nix/store/...-install-spago-style
installing dependencies...
# ...
done.
Wrote install script to .spago2nix/install
```

Then build the project:

```bash
$ spago2nix build
/nix/store/...-build-spago-style
building project...
done.
Wrote build script to .spago2nix/build
```
