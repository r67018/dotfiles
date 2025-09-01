{ config, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "JetBrainsMono NF";
          style = "Light";
        };
        size = 12;
      };
    };
  };
}

