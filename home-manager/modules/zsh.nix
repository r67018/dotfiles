{ ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      cat = "bat";
      grep = "rg";
      vi = "nvim";
      vim = "nvim";
      c = "wl-copy";
      p = "wl-paste";
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

