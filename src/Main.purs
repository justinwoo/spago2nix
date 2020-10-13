module Main where

import Prelude

import Control.Alt ((<|>))
import Core (DhallExpr(..), buildScript, exit, runCommand, runDhallToJSON)
import Data.Either (Either(..))
import Data.Int as Int
import Data.List (List, (:))
import Data.List as List
import Data.Maybe (Maybe(Just, Nothing))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Class.Console (error, log)
import Generate as Generate
import Node.ChildProcess (Exit(Normally, BySignal))
import Simple.JSON as JSON

foreign import argv :: Array String

args :: List String
args = List.drop 2 $ List.fromFoldable argv

main :: Effect Unit
main = Aff.launchAff_ do
  case args of
    "generate" : rest -> generate rest
    "install" : rest -> install rest
    "build" : rest -> build SpagoStyle rest
    "build-nix" : rest -> build NixStyle rest
    "help" : rest -> log help
    List.Nil -> log help
    _ -> do
      log $ "Unknown arguments: " <> List.intercalate " " args

generate :: List String -> Aff Unit
generate extraArgs = do
  case (parse extraArgs) of
    Nothing -> do
      log $ "Expected an integer, but got: " <> List.intercalate " " extraArgs
      log $ "Specify the maximum number of packages to fetch simultaneously."
      exit 1
    Just n -> Generate.generate n
  where
    parse :: List String -> Maybe Int
    parse List.Nil = Just 0
    parse (List.Cons arg List.Nil) = Int.fromString arg
    parse _ = Nothing

install :: List String -> Aff Unit
install extraArgs = do
  nixBuildResult <- buildScript { attr: "installSpagoStyle", path: installPath, extraArgs }
  case nixBuildResult of
    Normally 0 -> pure unit
    Normally n -> do
      error "Error: the 'spago2nix install' command failed to build the 'installSpagoStyle' Nix attribute"
      exit n
    BySignal s -> do
      error $ "Error: the 'spago2nix install' command was killed by signal " <> show s <> " while building the 'installSpagoStyle' Nix attribute"
      exit 1
  installResult <- runCommand { cmd: installCmd, args: [] }
  case installResult of
    Normally 0 -> do
      log $ "Wrote install script to " <> installPath
      exit 0
    Normally n -> do
      error "Error: the 'spago2nix install' command failed"
      exit n
    BySignal s -> do
      error $ "Error: the 'spago2nix install' command was killed by signal " <> show s
      exit 1
  where
    installPath = ".spago2nix/install"
    installCmd = installPath <> "/bin/install-spago-style"

data BuildStyle
  = SpagoStyle
  | NixStyle

build :: BuildStyle -> List String -> Aff Unit
build buildStyle extraArgs = do
  nixBuildResult <- buildScript { attr: buildStyleAttr, path: buildPath, extraArgs }
  case nixBuildResult of
    Normally 0 -> pure unit
    Normally n -> do
      error $ "Error: the 'spago2nix build' command failed to failed to build the '" <> buildStyleAttr <> "' Nix attribute"
      exit n
    BySignal s -> do
      error $ "Error: the 'spago2nix build' command nix-build of " <> buildStyleAttr <> " was killed by " <> show s
      exit 1
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
  buildResult <- runCommand { cmd: buildCmd, args: globs }
  case buildResult of
    Normally 0 -> do
      log $ "Wrote build script to " <> buildPath
      exit 0
    Normally n -> do
      error "Error: the 'spago2nix build' command failed"
      exit n
    BySignal s -> do
      error $ "Error: the 'spago2nix build' command was killed by signal " <> show s
      exit 1
  where
    buildPath = ".spago2nix/build"
    buildCmd = buildPath <> case buildStyle of
      SpagoStyle -> "/bin/build-spago-style"
      NixStyle -> "/bin/build-from-store"
    buildStyleAttr = case buildStyle of
      SpagoStyle -> "buildSpagoStyle"
      NixStyle -> "buildFromNixStore"

help :: String
help = """spago2nix - generate Nix derivations from packages required in a spago project, and allow for installing them and building them.

  Usage: spago2nix (generate | install | build)

Available commands:
  generate [n]
    Generate a Nix expression of packages from Spago. If n is
    given, it will limit the number of packages fetched at once.
  install [passthrough args for nix-shell]
    Install dependencies from spago-packages.nix in Spago style
  build [passthrough args for nix-shell]
    Build the project Spago style
  build-nix [passthrough args for nix-shell]
    Build the project using dependency sources from Nix store
"""
