{
  description = "Client for Spark App Store";

  source = {
    url = "git+https://gitee.com/Melorise/spark-store.git?ref=nixos";
    flake = false;
  };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  dependencies = [ "amber-pm" ];

  adapter =
    {
      packages,
      pkgs,
      source,
      ...
    }:
    pkgs.callPackage "${source}/nix/package.nix" {
      apm = packages."amber-pm";
    };
}
