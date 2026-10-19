{ pkgs, ... }:
{
  # ~/.local/bin is the usual place for user-installed binaries.
  home.sessionPath = [ "$HOME/.local/bin" ];

  programs.zsh = {
    enable = true;
    shellAliases = {
      grep = "rg";
      vi = "nvim";
      vim = "nvim";
    } // (if pkgs.stdenv.isDarwin then {
      ls = "/bin/ls -G";
      ll = "/bin/ls -alFG";
      la = "/bin/ls -AG";
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

      # Auto-attach to the default tmux session (create "main" if missing).
      # Do not gate on SHLVL: GUI terminals (e.g. bash → kitty) start zsh with SHLVL>1.
      if [[ -o interactive ]] && [[ -z ''${TMUX:-} ]] && command -v tmux >/dev/null; then
        exec tmux new-session -A -s main
      fi
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

