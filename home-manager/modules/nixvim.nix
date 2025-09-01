{ config, pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    opts = {
      number = true;
      relativenumber = true;
    };
  };
}

