{ pkgs, lib, ... }:
{
  wayland.windowManager.sway = lib.mkIf pkgs.stdenv.isLinux (rec {
    enable = true;
    config = {
      modifier = "Alt";
      terminal = "alacritty";
      defaultWorkspace = "workspace number 1";
      bars = []; # Disable swaybar
      startup = [
        {
          # Update env for dbus and systemd, then restart portals
          command = "${pkgs.bash}/bin/bash -c 'systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK; dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK; systemctl --user stop xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk; systemctl --user start xdg-desktop-portal xdg-desktop-portal-wlr'";
        }
        {
          command = "1password";
        }
        {
          command = "thunderbird";
        }
      ];
      keybindings = lib.mkOptionDefault {
        "${config.modifier}+d" = "exec wofi --show drun";
        # "${config.modifier}+Shift+e" = "exec swaylock";
        "${config.modifier}+c" = ''exec grim -g "$(slurp)" - | wl-copy'';
        "${config.modifier}+Shift+c" = ''exec grim - | wl-copy'';
      };
    };
    extraConfig = ''
      # Window design to match Waybar
      default_border pixel
      gaps inner 10
      gaps outer 5

      # Remove window title bars
      for_window [title="^.*"] title_format ""

      # Colors to match Waybar
      client.focused              #4c566a #161821 #c6c8d1 #4c566a #4c566a
      client.focused_inactive     #282a36 #161821 #c6c8d1 #282a36 #282a36
      client.unfocused            #282a36 #161821 #c6c8d1 #282a36 #282a36
      client.urgent               #ebcb8b #161821 #161821 #ebcb8b #ebcb8b
      client.placeholder          #282a36 #161821 #c6c8d1 #282a36 #282a36
    '';
  });
}
