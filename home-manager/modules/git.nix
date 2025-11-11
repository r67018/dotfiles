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
        cm = "commit -m";
        st = "status";
        br = "branch";
        co = "checkout";
        df = "diff";
      };
    };
  };
}

