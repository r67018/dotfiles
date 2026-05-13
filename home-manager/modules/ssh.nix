{ config, lib, pkgs, ... }:
let
  # Use different path for macOS and Linux
  onePassPath = if pkgs.stdenv.isDarwin
    then "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\""
    else "~/.1password/agent.sock";
in
{
  # Use SSH key managed in 1Password
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "config.d/*" ];
    matchBlocks = {
      "*" = {};
      "github.com" = {
        hostname = "github.com";
        user = "git";
      };
    };
    extraConfig = ''
      IdentityAgent ${onePassPath}
    '';
  };

  # This file is intentionally copied from the HM symlink below. Allow HM to
  # replace an existing regular file on subsequent activations.
  home.file.".ssh/config".force = true;

  # Fix "Bad owner or permissions on ~/.ssh/config" by converting symlink to file
  home.activation.fixSshConfigPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -L "${config.home.homeDirectory}/.ssh/config" ]; then
      target=$(readlink "${config.home.homeDirectory}/.ssh/config")
      rm "${config.home.homeDirectory}/.ssh/config"
      cp "$target" "${config.home.homeDirectory}/.ssh/config"
      chmod 600 "${config.home.homeDirectory}/.ssh/config"
    fi
  '';
}
