{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ sources =
    [ "src/**/*.purs", "test/**/*.purs" ]
, name =
    "my-project"
, dependencies =
    [ "console"
    , "generics-rep"
    , "integers"
    , "kishimen"
    , "node-fs-aff"
    , "parallel"
    , "prelude"
    , "optparse"
    , "simple-json-utils"
    , "sunde"
    , "validation"
    ]
, packages =
    ./packages.dhall
}
