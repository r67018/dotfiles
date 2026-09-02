{ lib, pkgs, ... }: {
  networking.hostName = "r-gotonoMacBook-Air";
  networking.computerName = "r-gotonoMacBook-Air";

  system.primaryUser = "r_goto";
  users.users."r_goto".home = "/Users/r_goto";

  environment.systemPackages = [ pkgs.pnpm ];

  system.defaults.dock.persistent-apps = [
    "/Applications/Zen Browser.app"
    "/Applications/Alacritty.app"
    "/Applications/Slack.app"
  ];

  homebrew.casks = [
    "zen"
    "slack"
    "postman"
    "google-gemini"
    "openvpn-connect"
    "codex-app"
    "cursor"
  ];

  homebrew.onActivation.autoUpdate = true;
  
  # Disable shared key remaps on work profile
  system.keyboard.remapCapsLockToControl = lib.mkForce false;
  system.keyboard.userKeyMapping = lib.mkForce [];
}
