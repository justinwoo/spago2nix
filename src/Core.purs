module Core where

import Prelude

import Control.Monad.Except.Trans as ExceptT
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Foreign (ForeignError(..), MultipleErrors)
import Kishimen (genericSumToVariant, variantToGenericSum)
import Simple.JSON as JSON
import Simple.JSON.Utils (printMultipleErrors)

spagoPackagesNix :: String
spagoPackagesNix = "spago-packages.nix"

-- process.exit with exit code
foreign import _exit :: forall a. Int -> Effect a

exit :: forall a. Int -> Aff a
exit = liftEffect <<< _exit

-- {"packageName":"variant","version":"v6.0.1","repo":{"tag":"Remote","contents":"https://github.com/natefaubion/purescript-variant.git"}}
type Package =
  { packageName :: String
  , version :: Version
  , repo :: Repo
  }

readPackage :: String -> Either MyError Package
readPackage = lmap mkJSONError <<< JSON.readJSON

data MyError
  = SpagoRunError String
  | SpagoOutputDeformed String
  | JSONError String
  | NixPrefetchGitFailed String
  | MissingRevOrRepoResult String
  | NixPrefetchGitOutputDeformed String
  | FileContentsCorrupted Package String String

mkJSONError :: MultipleErrors -> MyError
mkJSONError = JSONError <<< printMultipleErrors

-- {"tag":"Remote","contents":"https://github.com/natefaubion/purescript-variant.git"}
data Repo
  = Remote URL
  | Local String

-- | URL from which the package can be fetched
newtype URL = URL String

-- | the actual version/tag in the package set
newtype Version = Version String

-- | the revision (git commit) of the package (at a given version)
newtype Revision = Revision String

-- | sha256 hash for nix
newtype SHA256 = SHA256 String

derive instance genericMyError :: Generic MyError _
instance showMyError :: Show MyError where show = genericShow

type NixPrefetchGitResult =
  { url :: URL
  , rev :: Revision
  , sha256 :: SHA256
  }

data FetchResult
  = CantFetchLocal Package
  | Fetched { package :: Package, result :: NixPrefetchGitResult }

instance readForeignRepo :: JSON.ReadForeign Repo where
  readImpl f = do
    r :: { tag :: String, contents :: String } <- JSON.readImpl f
    case r.tag of
      "Remote" -> pure $ Remote (URL r.contents)
      "Local" -> pure $ Local r.contents
      _ -> ExceptT.throwError $ pure $ ForeignError $ "Unknown Repo type: " <> r.tag

instance writeForeignRepo :: JSON.WriteForeign Repo where
  writeImpl (Remote url) = JSON.writeImpl { tag: "Remote", contents: JSON.writeImpl url }
  writeImpl (Local s) = JSON.writeImpl { tag: "Local", contents: JSON.writeImpl s }

derive newtype instance showURL :: Show URL
derive newtype instance readForeignURL :: JSON.ReadForeign URL
derive newtype instance writeForeignURL :: JSON.WriteForeign URL

derive newtype instance showVersion :: Show Version
derive newtype instance readForeignVersion :: JSON.ReadForeign Version
derive newtype instance writeForeignVersion :: JSON.WriteForeign Version

derive newtype instance showRevision :: Show Revision
derive newtype instance readForeignRevision :: JSON.ReadForeign Revision
derive newtype instance writeForeignRevision :: JSON.WriteForeign Revision

derive newtype instance showSHA :: Show SHA256
derive newtype instance eqSHA :: Eq SHA256
derive newtype instance readForeignSHA :: JSON.ReadForeign SHA256
derive newtype instance writeForeignSHA :: JSON.WriteForeign SHA256

derive instance genericRepo :: Generic Repo _
instance showRepo :: Show Repo where show = genericShow

derive instance genericFetchResult :: Generic FetchResult _
instance showFetchResult :: Show FetchResult where show = genericShow
instance readForeignFetchResult :: JSON.ReadForeign FetchResult where
  readImpl = map variantToGenericSum <<< JSON.readImpl
instance writeForeignFetchResult :: JSON.WriteForeign FetchResult where
  writeImpl = JSON.writeImpl <<< genericSumToVariant
