{ pkgs, ... }:

{
  home.packages = [
    pkgs.nodejs_24
  ];

  programs.ssh.settings.belvedere = {
    ForwardAgent = true;
  };
}
