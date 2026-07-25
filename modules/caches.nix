{ catalog }:
{
  config,
  lib,
  ...
}:
let
  cacheEntries = lib.mapAttrs (_: entry: entry.caches or [ ]) catalog;
  cacheNames = builtins.attrNames (
    lib.filterAttrs (_: caches: caches != [ ]) cacheEntries
  );
  enabledNames = config.mnpr.caches.enable;
  enabledCaches = lib.concatMap (name: cacheEntries.${name}) enabledNames;
in
{
  options.mnpr.caches.enable = lib.mkOption {
    type = lib.types.listOf (lib.types.enum cacheNames);
    default = [ ];
    example = cacheNames;
    description = "需要添加到 Nix daemon 配置的 MNPR 软件缓存。";
  };

  config = lib.mkIf (enabledNames != [ ]) {
    nix.settings.substituters = lib.unique (
      map (cache: cache.substituter) enabledCaches
    );
    nix.settings.trusted-public-keys = lib.unique (
      map (cache: cache.publicKey) enabledCaches
    );
  };
}
