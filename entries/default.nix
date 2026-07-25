let
  directory = builtins.readDir ./.;
  fileNames = builtins.filter (
    fileName:
    fileName != "default.nix"
    && directory.${fileName} == "regular"
    && builtins.match ".*[.]nix" fileName != null
  ) (builtins.attrNames directory);

  entryName = fileName: builtins.substring 0 (builtins.stringLength fileName - 4) fileName;

  rawEntries = builtins.listToAttrs (
    map (fileName: {
      name = entryName fileName;
      value = import (./. + "/${fileName}");
    }) fileNames
  );

  validateEntry =
    name: entry:
    if !(entry ? description) then
      throw "MNPR entry `${name}` is missing `description`"
    else if !builtins.isString entry.description || entry.description == "" then
      throw "MNPR entry `${name}` has an invalid `description`"
    else if !(entry ? source) || !(entry.source ? url) then
      throw "MNPR entry `${name}` is missing `source.url`"
    else
      entry;
in
builtins.mapAttrs validateEntry rawEntries
