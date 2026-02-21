{ ... }: {
  networking.hostName = "r-gotonoMacBook-Air";
  networking.computerName = "r-gotonoMacBook-Air";

  system.primaryUser = "r_goto";
  users.users."r_goto".home = "/Users/r_goto";

  system.defaults.dock.persistent-apps = [
    "/Applications/Slack.app"
  ];

  homebrew.casks = [
    "slack"
  ];
  
  # Reset key mapping for JIS keyboard
  system.keyboard.userKeyMapping = [];
}
