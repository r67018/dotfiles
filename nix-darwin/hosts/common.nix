{ config, lib, pkgs, ... }:
let
  primaryUser = config.system.primaryUser;
in
{
  # Determine Installer collision
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";

  # System packages
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
    pkgs.docker
    pkgs.docker-compose
    pkgs.colima
    pkgs.tmux
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    newcomputermodern
  ];

  # Authenticate sudo with Touch ID (reattach makes it work inside tmux too)
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };

  # System defaults
  system.defaults = {
    finder._FXShowPosixPathInTitle = true;
    finder.AppleShowAllExtensions = true;
    dock.autohide = true;
    dock.autohide-delay = 0.0;
    dock.autohide-time-modifier = 0.6;
    dock.show-recents = false;
    trackpad.Clicking = true;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
    NSGlobalDomain."com.apple.keyboard.fnState" = true;
    NSGlobalDomain.AppleInterfaceStyle = "Dark";
    dock.persistent-apps = lib.mkDefault [
      "/Applications/kitty.app"
      "/Applications/1Password.app"
    ];
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
  };

  system.activationScripts.postActivation.text = ''
    # azooKey is a regular macOS input source (Ctrl+Space / Ctrl+Option+Space).
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{ enabled = 1; value = { parameters = (32, 49, 262144); type = standard; }; }'
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{ enabled = 1; value = { parameters = (32, 49, 786432); type = standard; }; }'

    # Keep ABC unless the input source is switched explicitly. Otherwise each
    # text field restores azooKey from its last document context.
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.HIToolbox AppleGlobalTextInputProperties -dict TextInputGlobalPropertyPerContextInput -int 0

    # Stop the annoying "Application is damaged" or "can't be opened" for downloaded apps
    echo "Removing quarantine attribute from applications..."
    apps=(
      "/Applications/kitty.app"
      "/Applications/Zen Browser.app"
      "/Applications/Discord.app"
      "/Applications/Slack.app"
      "/Applications/Microsoft Teams.app"
      "/Applications/1Password.app"
      "/Applications/ChatGPT.app"
    )
    
    for app in "''${apps[@]}"; do
      if [ -e "$app" ]; then
        xattr -d com.apple.quarantine "$app" 2>/dev/null || true
      fi
    done
  '';

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = 5; 

  # Homebrew
  homebrew = {
    enable = true;
    casks = [
      "1password"
      "kitty"
      "claude"
      "chatgpt"
      "azookey"
      "jetbrains-toolbox"
      # Ice: menu bar manager
      "jordanbaird-ice"
    ];
    brews = [
      "mas"
    ];
  };
}
