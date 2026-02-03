{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      grep = "rg";
      vi = "nvim";
      vim = "nvim";
    } // (if pkgs.stdenv.isDarwin then {
      ls = "ls -G";
      ll = "ls -alFG";
      la = "ls -AG";
      c = "pbcopy";
      p = "pbpaste";
    } else {
      ls = "ls --color=auto";
      ll = "ls -alF --color=auto";
      la = "ls -A --color=auto";
      c = "wl-copy";
      p = "wl-paste";
    });
    initContent = ''
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    '';
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--layout=reverse"
    ];
  };
}

