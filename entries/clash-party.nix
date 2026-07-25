{
  description = "Clash Party, built from source with a reproducible Nix flake";

  source.url = "git+https://github.com/Melorise/cp-nix.git?ref=main";

  caches = [
    {
      substituter = "https://melorise-cp-nix.cachix.org";
      publicKey = "melorise-cp-nix.cachix.org-1:GNg96VizkktTdGMrvl6+PLPHY3jPce4a72HqP2cj4S4=";
    }
  ];
}
