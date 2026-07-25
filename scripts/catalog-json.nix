let
  entries = import ../entries;
in
builtins.mapAttrs (
  _: entry: {
    inherit (entry) description source;
    caches = entry.caches or [ ];
  }
) entries
