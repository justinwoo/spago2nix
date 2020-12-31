let
  fetch = arg@{url, sha256}: builtins.fetchTarball arg;

  json = builtins.fromJSON (builtins.readFile ./sources.json);

  sources = builtins.mapAttrs (_: v: fetch { inherit (v) url sha256; }) json;

in sources
