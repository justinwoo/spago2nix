# Spago2Nix

### Does not yet work with a released version of Spago

Generate a derivation of Spago dependencies, and use them to install them into the directory structure used by Spago.

To skip Spago altogether, you can also use the following to build:

```
purs compile '.spago/*/*/src/**/*.purs' 'src/**/*.purs'
```

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
installing...
# ...
done
```

Then build however you'd like.

```
$ spago build --global-cache=skip
$ purs compile '.spago/*/*/src/**/*.purs' 'src/**/*.purs'
```
