module Main where

import Prelude

import Control.Alt ((<|>))
import Core (DhallExpr(..), buildScript, exit, runCommand, runDhallToJSON)
import Data.Either (Either(..))
import Data.List (List, (:))
import Data.List as List
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Class.Console (log)
import Generate as Generate
import Simple.JSON as JSON

foreign import argv :: Array String

args :: List String
args = List.drop 2 $ List.fromFoldable argv

main :: Effect Unit
main = Aff.launchAff_ do
  case args of
    "generate" : List.Nil -> Generate.generate
    "install" : rest -> install rest
    "build" : rest -> build rest
    "help" : rest -> log help
    List.Nil -> log help
    _ -> do
      log $ "Unknown arguments: " <> List.intercalate " " args

install :: List String -> Aff Unit
install extraArgs = do
  buildScript { attr: "installSpagoStyle", path: installPath, extraArgs }
  runCommand { cmd: "bash", args: [installPath] }
  log $ "Wrote install script to " <> installPath
  exit 0
  where
    installPath = ".spago2nix/install"

build :: List String -> Aff Unit
build extraArgs = do
  buildScript { attr: "buildSpagoStyle", path: buildPath, extraArgs }
  json <- runDhallToJSON (DhallExpr "(./spago.dhall).sources") <|> pure ""
  globs <- case JSON.readJSON json of
    Left _ -> do
      let defaultGlob = "src/**/*.purs"
      log $ "failed to read sources from spago.dhall using dhall-to-json."
      log $ "using default glob: " <> defaultGlob
      pure [defaultGlob]
    Right (xs :: Array String) -> do
      log $ "using sources from spago.dhall: " <> show xs
      pure xs
  runCommand { cmd: "bash", args: [buildPath] <> globs }
  log $ "Wrote build script to " <> buildPath
  exit 0
  where
    buildPath = ".spago2nix/build"

help :: String
help = """spago2nix - generate Nix derivations from packages required in a spago project, and allow for installing them and building them.

  Usage: spago2nix (generate | install | build)

Available commands:
  generate
    Generate a Nix expression of packages from Spago
  install [passthrough args for nix-shell]
    Install dependencies from spago-packages.nix in Spago style
  build [passthrough args for nix-shell]
    Build the project Spago style
"""
