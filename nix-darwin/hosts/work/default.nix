{ ... }: {
  networking.hostName = "r-gotonoMacBook-Air";
  networking.computerName = "r-gotonoMacBook-Air";

  system.primaryUser = "r_goto";
  users.users."r_goto".home = "/Users/r_goto";

  system.defaults.dock.persistent-apps = [
    "/Applications/Zen Browser.app"
    "/Applications/Alacritty.app"
    "/Applications/Slack.app"
  ];

  homebrew.casks = [
    "zen"
    "slack"
    "postman"
  ];
  
  # Reset key mapping for JIS keyboard
  system.keyboard.userKeyMapping = [];
}
