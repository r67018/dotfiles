{ config, ... }:
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Super";
      terminal = "alacritty";
    };
  };
}

