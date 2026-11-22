# Proton Mail Bridge は 127.0.0.1 にしか聴かない。
# HAProxy で Tailscale の IPv4 にだけ待ち受け、Tailscale 証明書で SSL/TLS 終端して
# 127.0.0.1 の Bridge SSL/TLS へ中継する。公開側のポートは開けない。
# 鍵束は pass。パスフレーズ無しの GPG 鍵は stateDir の中だけ。
{ config, lib, pkgs, ... }:
let
  stateDir = "/var/lib/protonmail-bridge";
  imapPort = 1143;
  smtpPort = 1025;
  bridge = lib.getExe pkgs.protonmail-bridge;
  tailscale = lib.getExe config.services.tailscale.package;
  haproxy = lib.getExe pkgs.haproxy;
  certDomain = "belvedere.tailec8a4.ts.net";
  certDir = "/var/lib/protonmail-bridge-cert";
  certBundle = "${certDir}/bundle.pem";
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
  renewCert = pkgs.writeShellScript "protonmail-bridge-cert-renew" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.diffutils pkgs.systemd ]}:$PATH"
    mkdir -p "${certDir}"
    chmod 700 "${certDir}"
    for _ in $(seq 1 30); do
      if ${tailscale} ip -4 >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    tmp_cert=$(mktemp "${certDir}/.cert.XXXXXX")
    tmp_key=$(mktemp "${certDir}/.key.XXXXXX")
    tmp_bundle=$(mktemp "${certDir}/.bundle.XXXXXX")
    trap 'rm -f "$tmp_cert" "$tmp_key" "$tmp_bundle"' EXIT
    chmod 600 "$tmp_key" "$tmp_bundle"
    ${tailscale} cert --min-validity 720h --cert-file "$tmp_cert" --key-file "$tmp_key" "${certDomain}"
    {
      cat "$tmp_cert"
      echo
      cat "$tmp_key"
    } > "$tmp_bundle"
    if [ ! -f "${certBundle}" ] || ! cmp -s "$tmp_bundle" "${certBundle}"; then
      mv -f "$tmp_cert" "${certDir}/cert.pem"
      mv -f "$tmp_key" "${certDir}/key.pem"
      mv -f "$tmp_bundle" "${certBundle}"
      chmod 600 "${certDir}/key.pem" "${certBundle}"
      if [ "''${1:-}" = "--restart" ] && systemctl is-active --quiet protonmail-bridge-tailscale; then
        systemctl restart --no-block protonmail-bridge-tailscale
      fi
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

  systemd.services.protonmail-bridge-cert = {
    description = "Renew Tailscale TLS certificate for Proton Mail Bridge";
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "tailscaled.service" "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "protonmail-bridge-cert";
      StateDirectoryMode = "0700";
      ExecStart = "${renewCert} --restart";
    };
  };

  systemd.timers.protonmail-bridge-cert = {
    description = "Daily Tailscale TLS certificate renewal for Proton Mail Bridge";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
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
      RuntimeDirectory = "protonmail-bridge-tailscale";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "protonmail-bridge-cert";
      StateDirectoryMode = "0700";
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
        if [ ! -s "${certBundle}" ]; then
          ${renewCert}
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
        cfg="/run/protonmail-bridge-tailscale/haproxy.cfg"
        cat > "$cfg" <<EOF
        global
            log stderr format raw local0 warning
            ssl-default-bind-options ssl-min-ver TLSv1.2

        defaults
            mode tcp
            log global
            option tcplog
            timeout connect 10s
            timeout client 1h
            timeout server 1h
            timeout tunnel 1h

        frontend imap_in
            bind $ip:${toString imapPort} ssl crt ${certBundle}
            default_backend imap_out

        backend imap_out
            server bridge 127.0.0.1:${toString imapPort} ssl verify none

        frontend smtp_in
            bind $ip:${toString smtpPort} ssl crt ${certBundle}
            default_backend smtp_out

        backend smtp_out
            server bridge 127.0.0.1:${toString smtpPort} ssl verify none
        EOF
        exec ${haproxy} -db -f "$cfg"
      '';
    };
  };
}
