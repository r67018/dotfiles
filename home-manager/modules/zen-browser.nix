{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies = let
      mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
      installation_mode = "force_installed";
    });
    in {
      # Refer https://github.com/0xc000022070/zen-browser-flake?tab=readme-ov-file#extensions to know how to check extension id
      ExtensionSettings = mkExtensionSettings {
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1password-x-password-manager";
        "uBlock0@raymondhill.net" = "ublock-origin";
      };
    };
  };
}

