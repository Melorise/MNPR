{
  description = "ChatGPT Desktop for Linux installer";

  source.url = "git+https://github.com/Melorise/codex-desktop-linux-builder.git?ref=nix";

  caches = [
    {
      substituter = "https://codex-desktop-linux.cachix.org";
      publicKey = "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk=";
    }
  ];
}
