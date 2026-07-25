{ pkgs, lib, ... }:
let
  vscodeArgvFile = "~/.vscode/argv.json";
  # macOS には gnome-keyring が無いので Keychain を使う
  passwordStore = if pkgs.stdenv.hostPlatform.isDarwin then "keychain" else "gnome-libsecret";
in
{
  programs.vscode.enable = true;
  # Configure VSCode's keyring backend (Linux: gnome-keyring / macOS: Keychain)
  # ref: https://code.visualstudio.com/docs/configure/settings-sync#_recommended-configure-the-keyring-to-use-with-vs-code
  home.activation.vscodeArgs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f ${vscodeArgvFile} ]; then
      # Remove comment in JSON and merge with extra options
      sed -e 's://.*$::' -e '/\/\*/,/\*\//d' ${vscodeArgvFile} | \
      ${pkgs.jq}/bin/jq '. + {"password-store": "${passwordStore}"}' > ${vscodeArgvFile}.tmp
      mv ${vscodeArgvFile}.tmp ${vscodeArgvFile}
    else
      mkdir -p $(dirname ${vscodeArgvFile})
      echo '{"password-store": "${passwordStore}"}' > ${vscodeArgvFile}
    fi
  '';
}

