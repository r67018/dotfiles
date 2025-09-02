{ ... }:
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Alt";
      terminal = "alacritty";
      defaultWorkspace = "workspace number 1";
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

