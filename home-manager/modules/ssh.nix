{ ... }:
let
  onePassPath = "~/.1password/agent.sock";
in
{
  # Use SSH key managed in 1Password
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "config.d/*" ];
    matchBlocks."*" = {
    };
    extraConfig = ''
        IdentityAgent ${onePassPath}
    '';
  };
}

