{ ... }: {
  networking.hostName = "r-gotonoMacBook-Air";
  networking.computerName = "r-gotonoMacBook-Air";

  system.primaryUser = "r_goto";
  users.users."r_goto".home = "/Users/r_goto";

  homebrew.casks = [
    "slack"
    "microsoft-teams"
  ];
}
