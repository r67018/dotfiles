{ lib, ... }: {
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
  
  # Disable shared key remaps on work profile
  system.keyboard.remapCapsLockToControl = lib.mkForce false;
  system.keyboard.userKeyMapping = lib.mkForce [];
}
