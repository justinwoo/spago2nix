module Main where

import Prelude

import Control.Alt ((<|>))
import Core (DhallExpr(..), buildScript, exit, runCommand, runDhallToJSON)
import Data.Either (Either(..))
import Data.List (List)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff as Aff
import Effect.Class.Console (error, log)
import Generate as Generate
import Node.ChildProcess (Exit(Normally, BySignal))
import Node.FS.Aff (realpath)
import Options.Applicative (Parser, ParserInfo, ReadM, argument, command, customExecParser, fullDesc, header, help, helper, hsubparser, info, int, long, many, metavar, option, prefs, progDesc, readerError, showDefault, showHelpOnEmpty, str, value, (<**>))
import Simple.JSON as JSON

foreign import argv :: Array String

data Command
  = Generate { maxPackagesFetchedAtOnce :: Int }
  | Install { extraArgs :: List String }
  | Build { extraArgs :: List String, spagoDhall :: String }
  | BuildNix { extraArgs :: List String, spagoDhall :: String }

data Args = Args {
  command :: Command,
  cacheDir :: String
}

argParser :: ParserInfo Args
argParser = mainDesc $ hsubparser
  $ subcommand {
    cmd: "generate",
    opts: (ado
      maxPackagesFetchedAtOnce
        <- argument int
        (  metavar "N"
        <> value 1
        <> showDefault
        <> help "Specify the maximum number of packages to fetch simultaneously.")
      in Generate { maxPackagesFetchedAtOnce }
    ),
    desc: "Generate a Nix expression of packages from Spago. If N is given, it will limit the number of packages fetched at once."
  }
  <> subcommand {
    cmd: "install",
    opts: (ado
      extraArgs <- extraArgs
      in Install { extraArgs }),
    desc: "Install dependencies from spago-packages.nix in Spago style."
  }
  <> subcommand {
    cmd: "build",
    opts: (ado
      extraArgs <- extraArgs
      spagoDhall <- spagoDhall
      in Build { extraArgs, spagoDhall }),
    desc: "Build the project Spago style."
  }
  <> subcommand {
    cmd: "build-nix",
    opts: (ado
      extraArgs <- extraArgs
      spagoDhall <- spagoDhall
      in BuildNix { extraArgs, spagoDhall }),
    desc: "Build the project using dependency sources from Nix store."
  }
  where
    mainDesc :: Parser Command -> ParserInfo Args
    mainDesc subparsers = info (mainParser subparsers <**> helper)
      (  fullDesc
      <> header "spago2nix - generate Nix derivations from packages required in a spago project, and allow for installing them and building them." )
    mainParser :: Parser Command -> Parser Args
    mainParser subparsers = ado
      command <- subparsers
      cacheDir <- mainOpts
      in Args { command, cacheDir }
    mainOpts =
      option (nonempty str)
      (  long "cache-dir"
      <> metavar "DIR"
      <> value ".spago2nix"
      <> showDefault
      <> help "the cache directory spago2nix uses for intermediate outputs" )
    subcommand {cmd, opts, desc} = (command cmd (info opts (progDesc desc)))
    extraArgs =
      many $ argument str
      (  metavar "EXTRA_ARGS..."
      <> help "passthrough args for nix-shell")
    spagoDhall =
      option (nonempty str)
      (  long "spago-dhall"
      <> metavar "FILE"
      <> value "spago.dhall"
      <> showDefault
      <> help "the path to your spago.dhall" )
    nonempty :: ReadM String -> ReadM String
    nonempty reader = reader >>= case _ of
      "" -> readerError "cannot be the empty string"
      s -> pure s


main :: Effect Unit
main = do
  let prefs' = prefs showHelpOnEmpty
  customExecParser prefs' argParser >>= \(Args {cacheDir, command}) -> Aff.launchAff_ $ case command of
    Generate { maxPackagesFetchedAtOnce } -> Generate.generate cacheDir maxPackagesFetchedAtOnce
    Install { extraArgs } -> install cacheDir extraArgs
    Build args -> build SpagoStyle cacheDir args
    BuildNix args -> build NixStyle cacheDir args

install :: String -> List String -> Aff Unit
install cacheDir extraArgs = do
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
    installPath = cacheDir <> "/install"
    installCmd = installPath <> "/bin/install-spago-style"

data BuildStyle
  = SpagoStyle
  | NixStyle

build :: BuildStyle -> String -> { spagoDhall :: String, extraArgs :: List String } -> Aff Unit
build buildStyle cacheDir args = do
  nixBuildResult <- buildScript { attr: buildStyleAttr, path: buildPath, extraArgs: args.extraArgs }
  case nixBuildResult of
    Normally 0 -> pure unit
    Normally n -> do
      error $ "Error: the 'spago2nix build' command failed to failed to build the '" <> buildStyleAttr <> "' Nix attribute"
      exit n
    BySignal s -> do
      error $ "Error: the 'spago2nix build' command nix-build of " <> buildStyleAttr <> " was killed by " <> show s
      exit 1
  absSpagoDhall <- realpath args.spagoDhall
  json <- runDhallToJSON (DhallExpr ("(" <> absSpagoDhall <> ").sources")) <|> pure ""
  globs <- case JSON.readJSON json of
    Left _ -> do
      let defaultGlob = "src/**/*.purs"
      log $ "failed to read sources from " <> args.spagoDhall <> " using dhall-to-json."
      log $ "using default glob: " <> defaultGlob
      pure [defaultGlob]
    Right (xs :: Array String) -> do
      log $ "using sources from " <> args.spagoDhall <> ": " <> show xs
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
    buildPath = cacheDir <> "/build"
    buildCmd = buildPath <> case buildStyle of
      SpagoStyle -> "/bin/build-spago-style"
      NixStyle -> "/bin/build-from-store"
    buildStyleAttr = case buildStyle of
      SpagoStyle -> "buildSpagoStyle"
      NixStyle -> "buildFromNixStore"

