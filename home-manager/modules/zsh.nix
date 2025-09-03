{ ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      cat = "bat";
      grep = "rg";
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
    defaultOptions = [
      "--layout=reverse"
    ];
  };
}

