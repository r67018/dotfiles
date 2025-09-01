{ ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      cat = "bat";
      vi = "nvim";
      vim = "nvim";
    };
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}

