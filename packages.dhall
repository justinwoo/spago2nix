let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.13.8-20210226/packages.dhall sha256:7e973070e323137f27e12af93bc2c2f600d53ce4ae73bb51f34eb7d7ce0a43ea

in  upstream // { sunde = upstream.sunde // { version = "v2.0.0" } }
