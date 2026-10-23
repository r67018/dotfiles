{ inputs, pkgs, ... }:

{
  imports = [
    inputs.xremap.nixosModules.default
  ];

  fonts.packages = with pkgs; [
    corefonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-sans-static
    noto-fonts-cjk-serif
    noto-fonts-cjk-serif-static
    nerd-fonts.jetbrains-mono
    nerd-fonts.noto
  ];

  services.xserver.enable = false;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = false;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire = {
      "99-custom-sample-rate" = {
        "context.properties" = {
          "default.clock.rate" = 192000;
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 192000 384000 ];
        };
      };
    };
    extraConfig.pipewire-pulse = {
      "99-custom-sample-rate" = {
        "context.properties" = {
          "default.clock.rate" = 192000;
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 192000 384000 ];
        };
      };
    };
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings = {
        screencast = {
          chooser_type = "none";
          output_name = "eDP-1";
        };
      };
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      sway = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.Screencast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

  services.xremap = {
    enable = true;
    userName = "ryosei";
    serviceMode = "user";
    withSway = true;
    config = {
      keymap = [
        {
          name = "Ctrl+H should be enabled on all apps as BackSpace";
          remap = {
            C-h = "Backspace";
          };
          application = {
            not = [ "Wezterm" ];
          };
        }
      ];
    };
  };

  users.users.ryosei.extraGroups = [ "inputs" ];

  nixpkgs.overlays = [
    (final: prev: {
      _1password-gui = let
        wrap = pkg: pkg.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ final.makeWrapper ];
          postFixup = (old.postFixup or "") + ''
            if [ -f $out/bin/1password ]; then
              chmod +x $out/bin/1password
            fi
            wrapProgram $out/bin/1password \
              --unset GTK_IM_MODULE \
              --unset QT_IM_MODULE \
              --add-flags "--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime"
          '';
        }) // {
          override = args: wrap (pkg.override args);
        };
      in wrap prev._1password-gui;
    })
  ];

  programs.firefox.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "ryosei" ];
  };

  environment.systemPackages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako
    pamixer
    pulseaudio
  ];

  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      zen
    '';
    mode = "0755";
  };

  environment.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
  };
}
