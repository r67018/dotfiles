# Proton Mail Bridge は 127.0.0.1 にしか聴かない。
# socat で Tailscale の IPv4 にだけ渡し、公開側のポートは開けない。
# 鍵束は pass。パスフレーズ無しの GPG 鍵は stateDir の中だけ。
{ config, lib, pkgs, ... }:
let
  stateDir = "/var/lib/protonmail-bridge";
  imapPort = 1143;
  smtpPort = 1025;
  bridge = lib.getExe pkgs.protonmail-bridge;
  tailscale = lib.getExe config.services.tailscale.package;
  socat = lib.getExe pkgs.socat;
  gnupg = lib.getBin pkgs.gnupg;
  pass = lib.getBin pkgs.pass;
  gpgHome = "${stateDir}/gnupg";
  passwordStore = "${stateDir}/pass";
  bridgeEnv = {
    HOME = stateDir;
    XDG_CONFIG_HOME = "${stateDir}/.config";
    XDG_DATA_HOME = "${stateDir}/.local/share";
    XDG_CACHE_HOME = "${stateDir}/.cache";
    GNUPGHOME = gpgHome;
    PASSWORD_STORE_DIR = passwordStore;
  };
  gpgBatch = pkgs.writeText "protonmail-bridge-gpg-batch" ''
    %no-protection
    Key-Type: eddsa
    Key-Curve: ed25519
    Key-Usage: sign
    Subkey-Type: ecdh
    Subkey-Curve: cv25519
    Subkey-Usage: encrypt
    Name-Real: Proton Mail Bridge
    Expire-Date: 0
    %commit
  '';
  setupPass = pkgs.writeShellScript "protonmail-bridge-pass-setup" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.gawk pkgs.gnugrep gnupg pass ]}:$PATH"
    export GNUPGHOME=${gpgHome}
    export PASSWORD_STORE_DIR=${passwordStore}
    mkdir -p "$GNUPGHOME" "$PASSWORD_STORE_DIR"
    chmod 700 "$GNUPGHOME" "$PASSWORD_STORE_DIR"
    if ! gpg --list-secret-keys --with-colons | grep -q '^fpr:'; then
      gpg --batch --gen-key ${gpgBatch}
    fi
    if [ ! -f "$PASSWORD_STORE_DIR/.gpg-id" ]; then
      fpr=$(gpg --list-secret-keys --with-colons | awk -F: '$1=="fpr"{print $10; exit}')
      pass init "$fpr"
    fi
  '';
in
{
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    imapPort
    smtpPort
  ];

  environment.systemPackages = [
    pkgs.protonmail-bridge
    (pkgs.writeShellScriptBin "protonmail-bridge-cli" ''
      set -euo pipefail
      if [ "$(id -un)" != "ryosei" ]; then
        echo "ryosei で実行して。例: sudo -u ryosei protonmail-bridge-cli" >&2
        exit 1
      fi
      if systemctl is-active --quiet protonmail-bridge || systemctl is-active --quiet protonmail-bridge-tailscale; then
        echo "先に止めて。sudo systemctl stop protonmail-bridge protonmail-bridge-tailscale" >&2
        echo "ログインが終わったら sudo systemctl start protonmail-bridge" >&2
        exit 1
      fi
      export HOME=${stateDir}
      export XDG_CONFIG_HOME=${stateDir}/.config
      export XDG_DATA_HOME=${stateDir}/.local/share
      export XDG_CACHE_HOME=${stateDir}/.cache
      export GNUPGHOME=${gpgHome}
      export PASSWORD_STORE_DIR=${passwordStore}
      export PATH="${gnupg}/bin:${pass}/bin:$PATH"
      ${setupPass}
      exec ${bridge} --cli "$@"
    '')
  ];

  systemd.services.protonmail-bridge = {
    description = "Proton Mail Bridge";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = bridgeEnv;
    path = [
      gnupg
      pass
    ];
    serviceConfig = {
      User = "ryosei";
      Group = "users";
      StateDirectory = "protonmail-bridge";
      StateDirectoryMode = "0700";
      ExecStartPre = setupPass;
      ExecStart = "${bridge} --noninteractive --log-level info";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.protonmail-bridge-tailscale = {
    description = "Expose Proton Mail Bridge on Tailscale";
    after = [
      "protonmail-bridge.service"
      "tailscaled.service"
    ];
    bindsTo = [ "protonmail-bridge.service" ];
    partOf = [ "protonmail-bridge.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "protonmail-bridge.service" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 3;
      ExecStart = pkgs.writeShellScript "protonmail-bridge-tailscale" ''
        set -euo pipefail
        ip=""
        for _ in $(seq 1 30); do
          ip=$(${tailscale} ip -4 2>/dev/null | head -n 1 || true)
          if [ -n "$ip" ]; then
            break
          fi
          sleep 1
        done
        if [ -z "$ip" ]; then
          echo "tailscale の IPv4 が取れない" >&2
          exit 1
        fi
        # Bridge は空いてるポートを vault に覚える。先にここが 1143/1025 を掴むと、
        # 初回起動が 1144/1026 にずれて、転送先が空になる。
        ss=${pkgs.iproute2}/bin/ss
        ready=0
        for _ in $(seq 1 60); do
          if "$ss" -ltnH src 127.0.0.1 sport = :${toString imapPort} | grep -q . \
            && "$ss" -ltnH src 127.0.0.1 sport = :${toString smtpPort} | grep -q .; then
            ready=1
            break
          fi
          sleep 0.5
        done
        if [ "$ready" != 1 ]; then
          echo "127.0.0.1:${toString imapPort} と ${toString smtpPort} が開かない" >&2
          exit 1
        fi
        ${socat} TCP-LISTEN:${toString imapPort},bind="$ip",fork,reuseaddr TCP:127.0.0.1:${toString imapPort} &
        imap_pid=$!
        ${socat} TCP-LISTEN:${toString smtpPort},bind="$ip",fork,reuseaddr TCP:127.0.0.1:${toString smtpPort} &
        smtp_pid=$!
        trap 'kill "$imap_pid" "$smtp_pid" 2>/dev/null || true' EXIT
        wait -n "$imap_pid" "$smtp_pid"
        exit 1
      '';
    };
  };
}
