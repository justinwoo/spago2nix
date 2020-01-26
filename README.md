# Spago2Nix

[![Build Status](https://travis-ci.com/justinwoo/spago2nix.svg?branch=master)](https://travis-ci.com/justinwoo/spago2nix)

![](./logo-256.png)

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

When using in your own Nix derivation, the best practice is calling generated scripts from `spago-packages.nix`:

```nix
{ pkgs, stdenv }:

let 
  spagoPkgs = import ./spago-packages.nix { inherit pkgs; };
in
pkgs.stdenv.mkDerivation rec {
  # < ... >
  buildPhase = 
  '' 
    ${spagoPkgs.installSpagoStyle} # == spago2nix install
    ${spagoPkgs.buildSpagoStyle}   # == spago2nix build
    ${spagoPkgs.buildFromNixStore} # == spago2nix build
  '';
  # < ... >
}
```

## Further Reading

Here is a blog post I did about this project: <https://github.com/justinwoo/my-blog-posts/blob/master/posts/2019-06-22-spago2nix-why-and-how.md>

## Troubleshooting

#### Can I get some manual support from you?

Yes, I would really like to help your company use this tool if you need some specific help. As tweeted here: <https://twitter.com/jusrin00/status/1221363901692026892>

Please have your company reach me through Twitter or Gmail if you would like to buy support.

#### I get `MissingRevOrRepoResult` on a package with branch name as a version

Nix gives out the specific constant SHA256 hash for broken Git fetches, so the error is thrown. 
One of the causes for a broken fetch is wrong checkout revision. Nix supports fetches by commit hash and tags out of the box, but fails at plain branch names. 

You can use more verbose reference `refs/heads/branch-name` at `packages.dhall` before generating a `.nix` file.
However, __the branch name usage is discouraged in Spago__ ([refer to Note here](https://github.com/spacchetti/spago#override-a-package-in-the-package-set-with-a-remote-one)), it's better using a particular commit hash.

### I don't know how to compile my project in a derivation

Spago2nix will install and build your project dependencies, but you may still want to use `spago` to bundle your project. You should not use Spago installation or build commands in a derivation. Use Spago's `--no-install` and `--no-build` flags when bundling your project as part of the build phase of a derivation:

```nix
pkgs.stdenv.mkDerivation {
  # < ... >
  buildPhase = ''
    ${spago}/bin/spago bundle-app --no-install --no-build --to $out/index.js
  '';
  # < ... >
};
```

If you attempt to use Spago commands to install or build in your project, you'll see the following error:

```
spago: security: createProcess: runInteractiveProcess: exec: does not exist (No such file or directory)
```
