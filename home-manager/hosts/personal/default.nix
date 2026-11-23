{ pkgs, lib, ... }:
{
  home.packages = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (with pkgs; [
    google-chrome
    rquickshare
    jetbrains-toolbox
    bottles
  ]);
}
