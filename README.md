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


## Workflow

The [workflow of `spago2nix`](https://github.com/purescript/spago/issues/547) is:

1. Ensure you have Spago installed, a `packages.dhall` file, and a `spago.dhall`
   file.

2. Run `spago2nix generate` to generate a new `spago-packages.nix` file which
   describes how to build the dependencies.

   You can add `spago2nix` to the `nativeBuildInputs` of a `mkShell` just by
   importing the `spago2nix` repository `default.nix`.

   ```nix
   spago2nix = import (builtins.fetchGit {
     url = "git@github.com:justinwoo/spago2nix.git";
     rev = "...";
   }) { inherit pkgs; };


   pkgs.mkShell {
     nativeBuildInputs = with pkgs; [
       spago2nix
     ];
   ```

   Then you'll be able to run `spago2nix generate` in an impure shell. It will
   call out to the network to look up hashes for the versions of packages
   in your `spago.dhall`.

   The output of `spago2nix generate` will be a `spago-packages.nix` file,
   which contains pure derivations for each package dependency, and which you
   should check into source control.

3. In the Nix expression which describes how to build your project, import
   the generated `spago-packages.nix` file to get the package dependencies.

   ```nix
   spagoPkgs = import ./spago-packages.nix { inherit pkgs; };
   ```

4. When describing the build steps, either use `spago2nix build` or
   `spago build --no-install` or call to the compiler directly
   with `purs compile "src/**/*.purs" ${spagoPackages.compilePaths}`.

   Or do something like this:

   ```nix
   pkgs.stdenv.mkDerivation {
     name = "myderiv";
     buildInputs = [
       spagoPkgs.installSpagoStyle
       spagoPkgs.buildSpagoStyle
       ];
     nativeBuildInputs = with pkgs; [
       easy-ps.purs-0_13_8
       easy-ps.spago
       ];
     src = ./.;
     unpackPhase = ''
       cp $src/spago.dhall .
       cp $src/packages.dhall .
       cp -r $src/src .
       install-spago-style
       '';
     buildPhase = ''
       build-spago-style "./src/**/*.purs"
       '';
     installPhase = ''
       mkdir $out
       mv output $out/
       '';
     }
   ```

This has a key drawback: steps 2 and 3 really ought to be a single step.
Because the `spago.dhall` file doesn't contain any cryptographic verification
of the dependencies, we can't do this as a pure one-step derivation.


## Further Reading

Here is a blog post I did about this project: <https://github.com/justinwoo/my-blog-posts/blob/master/posts/2019-06-22-spago2nix-why-and-how.md>

## Troubleshooting

#### Can I get some manual support from you?

Yes! Please consider supporting me through GitHub Sponsors and get in touch: <https://github.com/sponsors/justinwoo>

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
