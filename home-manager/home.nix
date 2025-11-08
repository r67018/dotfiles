{ config, lib, pkgs, inputs, ... }:
let
  onePassPath = "~/.1password/agent.sock";
  vscodeArgvFile = "~/.vscode/argv.json";
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ryosei";
  home.homeDirectory = "/home/ryosei";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-skk
      fcitx5-gtk
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.zen-browser.homeModules.beta
    inputs.nixvim.homeModules.nixvim
    inputs.sops-nix.homeManagerModules.sops

    ./modules/sway.nix
    ./modules/waybar/waybar.nix
    ./modules/wofi/wofi.nix
    ./modules/zsh.nix
    ./modules/direnv.nix
    ./modules/bat.nix
    ./modules/nixvim.nix
    ./modules/alacritty.nix
    ./modules/zen-browser.nix
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    # For Sway
    swaylock
    grim # Screenshot
    slurp # Clip screen area 
    wl-clipboard # Clipboard

    # CLI tools
    ripgrep
    jq
    sops
    gemini-cli
    # Desktop applications
    seahorse
    thunderbird
    webcord
    slack
    rquickshare
    jetbrains-toolbox
    bottles

    dotnet-sdk
    nil # Nix language server
    typst
    tinymist # Typst
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".ideavimrc".source = ../.ideavimrc;
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ryosei/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "vim";
    _JAVA_AWT_WM_NONREPARENTING = "1"; # Enable fcitx5 on JetBrains IDE
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
  };

  dconf.settings = {
    "org/gnome/shell" = {
      # Applications pinned on the dock
      favorite-apps = [
        "zen-twilight.desktop" # Zen Browser
	"org.gnome.Console.desktop" # Console
        "org.gnome.Nautilus.desktop" # File Manager
	"1password.desktop" # 1Password
      ];
    };
  };

  home.file.".config/wireplumber/main.lua.d/51-force-sample-rate.lua" = {
    text = ''
      rule = {
        matches = {
          {
            { "node.name", "matches", "alsa_output.usb-iFi__by_AMR__iFi__by_AMR__HD_USB_Audio_00000000-00.analog-stereo" },
          },
        },
        apply_properties = {
          ["audio.rate"] = 384000,
          ["clock.rate"] = 384000,
        },
      }
      table.insert(wireplumber_config, rule)
    '';
  };

  # Secret files
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      "ssh/private-servers" = {
        path = "${config.home.homeDirectory}/.ssh/config.d/private-servers";
        mode = "0600";
      };
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Ryosei Goto";
    userEmail = "contact@r67018.com";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      pull.rebase = true;
    };
    aliases = {
      cm = "commit -m";
      st = "status";
      br = "branch";
      co = "checkout";
      df = "diff";
    };
  };

  # Use SSH key managed in 1Password
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "config.d/*" ];
    matchBlocks."*" = {
    };
    extraConfig = ''
        IdentityAgent ${onePassPath}
    '';
  };

  # VSCode
  programs.vscode.enable = true;
  # Use gnome-keyring in VSCode:!
  # ref: https://code.visualstudio.com/docs/configure/settings-sync#_recommended-configure-the-keyring-to-use-with-vs-code
  home.activation.vscodeArgs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f ${vscodeArgvFile} ]; then
      # Remove comment in JSON and merge with extra options
      sed -e 's://.*$::' -e '/\/\*/,/\*\//d' ${vscodeArgvFile} | \
      ${pkgs.jq}/bin/jq '. + {"password-store": "gnome-libsecret"}' > ${vscodeArgvFile}.tmp
      mv ${vscodeArgvFile}.tmp ${vscodeArgvFile}
    else
      mkdir -p $(dirname ${vscodeArgvFile})
      echo '{"password-store": "gnome-libsecret"}' > ${vscodeArgvFile}
    fi
  '';

  # GitHub CLI
  programs.gh = {
    enable = true;
    extensions = with pkgs; [
      gh-copilot
    ];
  };
}
