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

  system.defaults.dock.persistent-apps = [
    "/Applications/Google Chrome.app"
    "/Applications/kitty.app"
    "/Applications/1Password.app"
    "/Applications/Thunderbird.app"
    "/Applications/Discord.app"
    "/Applications/Slack.app"
    "/Applications/Microsoft Teams.app"
    "/Applications/LINE.app"
    "/Applications/Notion.app"
    "/Applications/Claude.app"
    "/Applications/Codex.app"
  ];

  homebrew.casks = [
    "tailscale-app"
    "betterdisplay"
    "thunderbird"
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
