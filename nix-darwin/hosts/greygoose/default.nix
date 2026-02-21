{ ... }: {
  networking.hostName = "greygoose";
  networking.computerName = "greygoose";

  system.primaryUser = "ryosei";
  users.users."ryosei".home = "/Users/ryosei";

  system.defaults.dock.persistent-apps = [
    "/Applications/Zen Browser.app"
    "/Applications/Thunderbird.app"
    "/Applications/Discord.app"
    "/Applications/LINE.app"
    "/Applications/Slack.app"
    "/Applications/Microsoft Teams.app"
  ];

  homebrew.casks = [
    "zen"
    "thunderbird"
    "discord"
    "slack"
    "microsoft-teams"
  ];

  homebrew.masApps = {
    "LINE" = 539883307;
  };

  system.keyboard.userKeyMapping = [
    {
      HIDKeyboardModifierMappingSrc = 30064771296;
      HIDKeyboardModifierMappingDst = 30064771298;
    }
  ];
}
