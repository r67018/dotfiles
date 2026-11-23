{ pkgs, ... }: {
  imports = [ ../../modules/scrcpy-launcher.nix ];

  networking.hostName = "greygoose";
  networking.computerName = "greygoose";

  system.primaryUser = "ryosei";
  users.users."ryosei".home = "/Users/ryosei";

  # scrcpy: Android screen mirroring/control (launcher module vendors adb)
  environment.systemPackages = [
    pkgs.scrcpy
  ];

  # Keyboard settings
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771296;
      HIDKeyboardModifierMappingDst = 30064771298;
    }
  ];

  # Virtual displays and VITURE suppress Touch ID for sudo unless this is set.
  system.activationScripts.ignoreArd.text = ''
    /usr/bin/sudo -u ryosei /usr/bin/defaults write /Users/ryosei/Library/Preferences/com.apple.security.authorization.plist ignoreArd -bool true
  '';

  homebrew.taps = [
    "fanckush/solodisplay"
  ];

  homebrew.casks = [
    "brave-browser"
    "tailscale-app"
    "betterdisplay"
    "discord"
    "slack"
    "microsoft-teams"
    "antigravity"
    "obsidian"
    "adobe-acrobat-reader"
    "proton-drive"
    "proton-mail"
    "proton-meet"
    "proton-pass"
    "protonvpn"
    "figma"
    # Logi Options+: Logitech mouse/keyboard customization
    "logi-options+"
    # Morisawa Fonts: font sync app
    "morisawa-desktop-manager"
    # SoloDisplay: turn off the built-in display when an external display is connected
    "solodisplay"
  ];

  homebrew.masApps = {
    "LINE" = 539883307;
  };
}
