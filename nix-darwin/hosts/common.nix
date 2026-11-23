{ config, pkgs, ... }:
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
    # scrcpy: Android screen mirroring/control; android-tools puts adb on PATH
    pkgs.scrcpy
    pkgs.android-tools
  ];

  fonts.packages = with pkgs; [
    # JetBrains Mono: static TTF only. Having the OTF copies (and the variable
    # [wght] files) installed alongside the same family confuses Affinity.
    (runCommand "jetbrains-mono-ttf-${jetbrains-mono.version}" { } ''
      mkdir -p $out/share/fonts/truetype
      for f in ${jetbrains-mono}/share/fonts/truetype/*.ttf; do
        case "$(basename "$f")" in
          *"["*) ;;
          *) cp "$f" $out/share/fonts/truetype/ ;;
        esac
      done
    '')
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    newcomputermodern
  ];

  # 1Password CLI (installed to /usr/local/bin/op for desktop app integration)
  programs._1password.enable = true;

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
    NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
  };

  system.activationScripts.postActivation.text = ''
    # Input source switching (Ctrl+Space / Ctrl+Option+Space).
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '{ enabled = 1; value = { parameters = (32, 49, 262144); type = standard; }; }'
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 '{ enabled = 1; value = { parameters = (32, 49, 786432); type = standard; }; }'

    # Keep ABC unless the input source is switched explicitly. Otherwise each
    # text field restores the Japanese input source from its last document context.
    sudo -u "${primaryUser}" /usr/bin/defaults write com.apple.HIToolbox AppleGlobalTextInputProperties -dict TextInputGlobalPropertyPerContextInput -int 0

    # Re-add Meltype to AppleEnabledInputSources after the HIToolbox write above.
    # On macOS 27, TISEnableInputSource often does not persist this list, so the
    # input menu can drop Meltype even though Meltype.app is still installed.
    sudo -u "${primaryUser}" /bin/bash -c '
      id=io.github.yksr-melt.inputmethod.Meltype
      mode=io.github.yksr-melt.inputmethod.Meltype.Japanese
      app="$HOME/Library/Input Methods/Meltype.app"
      if [ -d "$app" ]; then
        if ! /usr/bin/defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | /usr/bin/grep -q "$id"; then
          /usr/bin/defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add \
            "<dict><key>Bundle ID</key><string>$id</string><key>InputSourceKind</key><string>Keyboard Input Method</string></dict>" \
            "<dict><key>Bundle ID</key><string>$id</string><key>Input Mode</key><string>$mode</string><key>InputSourceKind</key><string>Input Mode</string></dict>"
        fi
        if [ -x "$app/Contents/MacOS/MeltypeRegisterInputSource" ]; then
          "$app/Contents/MacOS/MeltypeRegisterInputSource" || true
        fi
        /usr/bin/killall TextInputMenuAgent 2>/dev/null || true
      fi
    '

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
      "google-gemini"
      "jetbrains-toolbox"
      # Handy: local speech-to-text / dictation
      "handy"
      # Ice: menu bar manager
      "jordanbaird-ice"
      # Logi Options+: Logitech mouse/keyboard customization
      "logi-options+"
      # Morisawa Fonts: font sync app
      "morisawa-desktop-manager"
    ];
    brews = [
      "mas"
    ];
  };
}
