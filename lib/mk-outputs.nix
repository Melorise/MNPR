{
  entries,
  inputs,
}:
let
  inherit (inputs.nixpkgs) lib;
  entryNames = builtins.attrNames entries;

  isFlakeEntry = entry: entry.source.flake or true;
  sourceFor = name: inputs.${name};

  systemsFor =
    name: entry:
    if entry ? systems then
      entry.systems
    else
      let
        source = sourceFor name;
      in
      if isFlakeEntry entry && source ? packages then
        builtins.attrNames source.packages
      else
        [ ];

  systems = lib.unique (
    lib.concatMap (name: systemsFor name entries.${name}) entryNames
  );

  entriesForSystem =
    system:
    lib.filterAttrs (
      name: entry: builtins.elem system (systemsFor name entry)
    ) entries;

  annotate =
    entry: package:
    package
    // {
      meta = (package.meta or { }) // {
        inherit (entry) description;
      };
    };

  packagesFor =
    system:
    let
      systemEntries = entriesForSystem system;
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in
    lib.fix (
      packages:
      lib.mapAttrs (
        name: entry:
        annotate entry (
          if entry ? adapter then
            entry.adapter {
              inherit
                entries
                inputs
                packages
                pkgs
                system
                ;
              source = sourceFor name;
            }
          else
            let
              outputName = entry.primaryPackage or "default";
            in
            (sourceFor name).packages.${system}.${outputName}
        )
      ) systemEntries
    );

  legacyPackagesFor =
    system:
    let
      packageSet = packagesFor system;
    in
    lib.mapAttrs (
      name: entry:
      if entry ? adapter then
        {
          default = packageSet.${name};
        }
        // {
          ${name} = packageSet.${name};
        }
      else
        (sourceFor name).packages.${system}
    ) (entriesForSystem system);

  defaultAppsFor =
    system:
    lib.mapAttrs (
      name: entry:
      (sourceFor name).apps.${system}.default
      // {
        meta = ((sourceFor name).apps.${system}.default.meta or { }) // {
          inherit (entry) description;
        };
      }
    ) (
      lib.filterAttrs (
        name: entry:
        isFlakeEntry entry
        && lib.hasAttrByPath [
          "apps"
          system
          "default"
        ] (sourceFor name)
      ) (entriesForSystem system)
    );

  defaultModulesFor =
    outputName:
    lib.mapAttrs (
      name: _: (sourceFor name).${outputName}.default
    ) (
      lib.filterAttrs (
        name: entry:
        isFlakeEntry entry
        && lib.hasAttrByPath [
          outputName
          "default"
        ] (sourceFor name)
      ) entries
    );

  caches = builtins.concatLists (
    map (name: entries.${name}.caches or [ ]) entryNames
  );

  publicEntries = builtins.mapAttrs (
    _: entry: builtins.removeAttrs entry [ "adapter" ]
  ) entries;
in
{
  packages = lib.genAttrs systems packagesFor;
  legacyPackages = lib.genAttrs systems legacyPackagesFor;
  apps = lib.genAttrs systems defaultAppsFor;

  nixosModules = {
    caches = import ../modules/caches.nix {
      catalog = entries;
    };
  } // defaultModulesFor "nixosModules";

  homeManagerModules = defaultModulesFor "homeManagerModules";

  overlays = {
    default = final: _prev: {
      mnpr = inputs.self.packages.${final.system} or { };
    };
  } // defaultModulesFor "overlays";

  lib = {
    catalog = publicEntries;
    inherit caches;
    sources = builtins.mapAttrs (name: _: sourceFor name) entries;
  };
}
