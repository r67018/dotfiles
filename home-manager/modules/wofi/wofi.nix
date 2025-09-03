{ ... }:
{
  programs.wofi = {
    enable = true;
    style = builtins.readFile ./style.css;
    settings = {
      key_up = "Ctrl-p";
      key_down = "Ctrl-n";
    };
  };
}

