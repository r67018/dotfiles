# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # xremap module
      inputs.xremap.nixosModules.default
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-skk # Japanese input method
    ];
  };
  systemd.user.services.fcitx5 = {
    description = "Fcitx5 Input Method Framework";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5";
      Restart = "always";
    };
  };


  # Configure fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans # Japanese, Chinese and Korean fonts
  ];

  # Disable the X11 windowing system.
  services.xserver.enable = false;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = false;

  # For starting fcitx5 on Sway automatically
  # ref: https://wiki.nixos.org/wiki/Fcitx5
  # services.xserver.desktopManager.runXdgAutostartIfNone = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable Sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  # Enable the gnome-keyring secrets vault. 
  # Will be exposed through DBus to programs willing to store secrets.
  services.gnome.gnome-keyring.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  services.xremap = {
    enable = true;
    userName = "ryosei";
    serviceMode = "user";
    withSway = true;
    config = {
      modmap = [
        {
          # CapsLockをCtrlに置換
          name = "Swap left Ctrl and CapsLock";
          remap = {
            CapsLock = "Ctrl_L";
	    Ctrl_L = "CapsLock";
          };
        }
     ];
     keymap = [
       {
         # Ctrl + HがどのアプリケーションでもBackspaceになるように変更
         name = "Ctrl+H should be enabled on all apps as BackSpace";
         remap = {
           C-h = "Backspace";
         };
         # 一部アプリケーション（ターミナルエミュレータ）を対象から除外
         application = {
           not = [ "Wezterm" ];
         };
       }
     ];
   };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ryosei = {
    isNormalUser = true;
    description = "Ryosei Goto";
    extraGroups = [
      "networkmanager"
      "wheel"
      "inputs"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install packages with options
  programs = {
    git = {
      enable = true;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
    starship = {
      enable = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls = "ls --color=auto";
        la = "ls -A";
        ll = "ls -lA";
        lh = "ls -lh";
	grep = "grep --color=auto";
      };
    };
    firefox = {
      enable = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    mako # notification system developed by swaywm maintainer
  ];

  # Use emacs key binding in zsh
  environment.interactiveShellInit = ''
    if [ -n "$ZSH_VERSION" ]; then
      bindkey -e # Specify emacs key binding
    fi
  '';

  # Define environment variables
  # environment.sessionVariables = {
  #   GTK_IM_MODULE = "fcitx"; # For fcitx5
  #   QT_IM_MODULE = "fcitx"; # For fcitx5
  #   XMODIFIERS = "@im=fcitx"; # For fcitx5
  # };


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
