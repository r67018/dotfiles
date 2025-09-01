{ config, ... }:
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Alt";
      terminal = "alacritty";
    };
  };
}

