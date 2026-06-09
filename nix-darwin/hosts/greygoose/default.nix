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
    "/Applications/Gemini.app"
  ];

  homebrew.casks = [
    "zen"
    "thunderbird"
    "discord"
    "slack"
    "microsoft-teams"
    "cloudflare-warp"
    "codex-app"
  ];

  homebrew.masApps = {
    "LINE" = 539883307;
  };
}
