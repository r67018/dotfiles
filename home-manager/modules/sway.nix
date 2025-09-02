{ ... }:
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Alt";
      terminal = "alacritty";
      bars = []; # Disable swaybar
      startup = [
        {
          command = "1password";
        }
        {
          command = "thunderbird";
        }
      ];
    };
  };
}

