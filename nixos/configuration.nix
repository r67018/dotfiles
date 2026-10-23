{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "belvedere";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

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

  virtualisation.docker.enable = true;

  users.users.ryosei = {
    isNormalUser = true;
    description = "Ryosei Goto";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      # 起動ファイルが1つも無いと zsh が zsh-newuser-install を実行する。
      # /etc/zshenv で先に空の関数を定義して、そのウィザードを止める。
      shellInit = ''
        zsh-newuser-install() { : }
      '';
      shellAliases = {
        ls = "ls --color=auto";
        la = "ls -A";
        ll = "ls -lA";
        lh = "ls -lh";
        grep = "grep --color=auto";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    unzip
    wget
  ];

  environment.interactiveShellInit = ''
    if [ -n "$ZSH_VERSION" ]; then
      bindkey -e
    fi
  '';

  services.openvpn.servers = {
    tsukuba = {
      config = ''
        config ${config.sops.templates."openvpn-tsukuba-config".path}
      '';
      up = ''
        ${pkgs.iproute2}/bin/ip route replace 130.158.6.63/32 via 192.168.0.1 dev enp2s0f1 metric 1
      '';
      down = ''
        ${pkgs.iproute2}/bin/ip route del 130.158.6.63/32 2>/dev/null || true
      '';
      autoStart = false;
    };
  };

  sops = {
    age.keyFile = "/etc/sops/age/keys.txt";
    secrets = {
      "openvpn/tsukuba/config" = {
        sopsFile = ../secrets/secrets-openvpn.yaml;
      };
      "openvpn/tsukuba/user-pass" = {
        sopsFile = ../secrets/secrets-openvpn.yaml;
      };
    };
    templates."openvpn-tsukuba-config" = {
      content = ''
        ${config.sops.placeholder."openvpn/tsukuba/config"}

        auth-user-pass ${config.sops.secrets."openvpn/tsukuba/user-pass".path}

        data-ciphers AES-256-GCM:AES-128-GCM:AES-128-CBC
      '';
    };
  };

  system.stateVersion = "25.05";
}
