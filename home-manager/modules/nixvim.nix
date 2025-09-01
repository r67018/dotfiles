{ config, pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    opts = {
      number = true;
      relativenumber = true;
      autoindent = true;
      smartindent = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
    };
    plugins = {
      nvim-tree = {
        enable = true;
      };
      nvim-autopairs = {
       enable = true;
      };

      # Declare plugins below explicitly because they are depended on by other plugins
      # by nvim-tree
      web-devicons = {
        enable = true;
      };
    };
  };
}

