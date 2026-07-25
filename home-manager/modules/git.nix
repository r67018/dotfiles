{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ryosei Goto";
        email = "contact@r67018.com";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = true;
      };
      alias = {
        alias = "config --get-regexp ^alias\\.";
        cm = "commit -m";
        st = "status";
        br = "branch";
        co = "checkout";
        df = "diff";
        l = "log --oneline";
        l1 = "log --oneline -1";
        l2 = "log --oneline -2";
        l3 = "log --oneline -3";
        l4 = "log --oneline -4";
        l5 = "log --oneline -5";
        l10 = "log --oneline -10";
      };
    };
  };
}

