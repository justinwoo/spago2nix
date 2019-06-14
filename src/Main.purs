module Main where

import Prelude

import Core (_exit, spagoPackagesNix)
import Data.Array as Array
import Data.List (List, (:))
import Data.List as List
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Generate as Generate
import Node.ChildProcess as CP

foreign import argv :: Array String

args :: List String
args = List.drop 2 $ List.fromFoldable argv

main :: Effect Unit
main = Aff.launchAff_ do
  case args of
    "generate" : List.Nil -> Generate.generate
    "install" : rest -> install rest
    List.Nil -> log help
    _ -> do
      log $ "Unknown arguments: " <> List.intercalate " " args

install :: List String -> Aff Unit
install extraArgs = do
  log "installing..."
  output <- liftEffect $ CP.spawn "nix-shell" spawnArgs CP.defaultSpawnOptions
    { detached = true
    , stdio = CP.inherit
    }
  liftEffect $ CP.onExit output \_ -> do
    log "done"
    _exit 0
  where
    spawnArgs =
      [ spagoPackagesNix
      , "-A"
      , "installSpagoStyle"
      , "--run"
      , "exit"
      ] <> (Array.fromFoldable extraArgs)

help :: String
help = """
spago2nix - generate Nix derivations from packages required in a spago project, and allow for installing them and building them.

  Usage: spago2nix (generate | install)

Available commands:
  generate
    Generate a Nix expression of packages from Spago
  install [passthrough args for nix-shell]
    Install dependencies from spago-packages.nix in Spago style
"""
