{ ... }: {
  networking.hostName = "greygoose";
  networking.computerName = "greygoose";

  system.primaryUser = "ryosei";
  users.users."ryosei".home = "/Users/ryosei";

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
}
