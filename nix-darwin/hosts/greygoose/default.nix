{ ... }: {
  networking.hostName = "greygoose";
  networking.computerName = "greygoose";

  system.primaryUser = "ryosei";
  users.users."ryosei".home = "/Users/ryosei";

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

  homebrew.casks = [
    "brave-browser"
    "tailscale-app"
    "betterdisplay"
    "discord"
    "slack"
    "microsoft-teams"
    "codex-app"
    "adobe-acrobat-reader"
    "proton-drive"
    "proton-mail"
    "proton-meet"
    "proton-pass"
    "protonvpn"
  ];

  homebrew.masApps = {
    "LINE" = 539883307;
  };
}
