{ pkgs, lib, ... }:
let
  vscodeArgvFile = "~/.vscode/argv.json";
in
{
  programs.vscode.enable = true;
  # Use gnome-keyring in VSCode:!
  # ref: https://code.visualstudio.com/docs/configure/settings-sync#_recommended-configure-the-keyring-to-use-with-vs-code
  home.activation.vscodeArgs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f ${vscodeArgvFile} ]; then
      # Remove comment in JSON and merge with extra options
      sed -e 's://.*$::' -e '/\/\*/,/\*\//d' ${vscodeArgvFile} | \
      ${pkgs.jq}/bin/jq '. + {"password-store": "gnome-libsecret"}' > ${vscodeArgvFile}.tmp
      mv ${vscodeArgvFile}.tmp ${vscodeArgvFile}
    else
      mkdir -p $(dirname ${vscodeArgvFile})
      echo '{"password-store": "gnome-libsecret"}' > ${vscodeArgvFile}
    fi
  '';
}

