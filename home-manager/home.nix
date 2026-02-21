{ pkgs, ... }: {
  home.username = "ryosei";
  home.homeDirectory = "/home/ryosei";

  imports = [
    ./hosts/common.nix
    ./hosts/personal/default.nix
    ./hosts/work/default.nix
    ./hosts/linux-desktop/default.nix
  ];
}
