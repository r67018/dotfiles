{ pkgs, inputs, lib, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta
    ../../modules/zen-browser.nix
  ];

  home.packages = lib.mkIf pkgs.stdenv.isLinux (with pkgs; [
    google-chrome
    thunderbird
    rquickshare
    jetbrains-toolbox
    bottles
  ]);
}
