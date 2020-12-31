let upstream =
      https://raw.githubusercontent.com/purescript/package-sets/psc-0.13.3-20190827/src/packages.dhall sha256:93f6b11068b42eac6632d56dab659a151c231381e53a16de621ae6d0dab475ce

in  upstream ⫽ { sunde = upstream.sunde ⫽ { version = "v2.0.0" } }
