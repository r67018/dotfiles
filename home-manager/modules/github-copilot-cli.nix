{ pkgs, ... }:
{
  home.packages = [
    pkgs.github-copilot-cli
  ];

  programs.zsh.initContent = ''
    eval "$(github-copilot-cli alias -- "$0")"
  '';
}
