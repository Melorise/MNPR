{
  description = "ChatGPT Desktop for Linux installer";

  source.url = "git+https://github.com/Melorise/codex-desktop-linux-builder.git?ref=nix";

  caches = [
    {
      substituter = "https://melorise-codex-desktop.cachix.org";
      publicKey = "melorise-codex-desktop.cachix.org-1:PN32aGXkz7tWwvCuwQfKo3/P/dOG/oa8mS8y58pdB5U=";
    }
  ];
}
