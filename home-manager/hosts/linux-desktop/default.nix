{ pkgs, lib, ... }:
{
  imports = [
    ../../modules/sway.nix
    ../../modules/waybar/waybar.nix
    ../../modules/wofi/wofi.nix
  ];

  config = lib.mkIf pkgs.stdenv.isLinux {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5.waylandFrontend = true;
      fcitx5.addons = with pkgs; [
        fcitx5-skk
        fcitx5-gtk
      ];
    };

    home.packages = with pkgs; [
      swaylock
      grim
      slurp
      wl-clipboard
      seahorse # Keyring
    ];

    home.sessionVariables = {
      _JAVA_AWT_WM_NONREPARENTING = "1";
      NIXOS_OZONE_WL = "1";
    };

    dconf.settings = {
      "org/gnome/shell" = {
        favorite-apps = [
          "zen-twilight.desktop" # Zen Browser
          "org.gnome.Console.desktop"
          "org.gnome.Nautilus.desktop"
          "1password.desktop"
        ];
      };
    };
  };
}
