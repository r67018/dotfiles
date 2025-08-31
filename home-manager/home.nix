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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  imports = [
    inputs.zen-browser.homeModules.twilight
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    bat
    seahorse
    _1password
    _1password-gui

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
    };
  };

  # Use SSH key managed in 1Password
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
          IdentityAgent ${onePassPath}
    '';
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      cat = "bat";
    };
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
    ];
  };

  # VSCode
  programs.vscode.enable = true;
  # Use gnome-keyring in VSCode
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

  programs.zen-browser = {
    enable = true;
    policies = let
      mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
      installation_mode = "force_installed";
    });
    in {
      # Refer https://github.com/0xc000022070/zen-browser-flake?tab=readme-ov-file#extensions to know how to check extension id
      ExtensionSettings = mkExtensionSettings {
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = "1password-x-password-manager";
      };
    };
  };
}
