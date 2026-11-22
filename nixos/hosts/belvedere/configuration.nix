{ config, lib, pkgs, inputs, ... }:
let
  ryoseiAuthorizedKeys = pkgs.writeText "ryosei-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfs8/T24RWsi7XqZfGTgWp9PvmQ91aODX6ZlDQ0Uxek ryosei@belvedere
  '';
in
{
  # AMD FCH SATA (1022:7901) と SD Ultra 3D (fw 52008100) の組み合わせで
  # med_power_with_dipm からの復帰時に ATA bus error (Emask 0x10 / CommWake) が頻発するため、
  # SATA Link Power Management を max_performance (1) に固定する。
  boot.kernelParams = [ "ahci.mobile_lpm_policy=1" ];

  environment.systemPackages = [
    pkgs.nodejs_26
    pkgs._1password-cli
  ];

  # Antigravity のリモート SSH Language Server など、汎用 Linux 向けの動的リンクバイナリを実行できるようにする。
  programs.nix-ld.enable = true;

  # configuration.nix の allowUnfree = true はそのまま残す。
  # 1password-cli（属性名は _1password-cli）だけを名前で追加で許可する。
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password-cli"
    ];

  # トークンは既定の /etc/manaba-reminder/op-service-account-token に手で置く。
  services.manaba-reminder = {
    enable = true;
    schedule = [
      "*-*-* 12:00:00 Asia/Tokyo"
      "*-*-* 17:00:00 Asia/Tokyo"
      "*-*-* 21:00:00 Asia/Tokyo"
    ];
    opPackage = pkgs._1password-cli;
    opEnv = {
      MANABA_USERNAME = "op://Belvedere/manaba/username";
      MANABA_PASSWORD = "op://Belvedere/manaba/password";
      WEBHOOK_URL = "op://Belvedere/grokbot-manaba-reminder/url";
      WEBHOOK_AUTHORIZATION = "op://Belvedere/grokbot-manaba-reminder/credential";
    };
  };

  # SSH は Tailscale SSH が受ける。sshd は起動しない。
  # Tailworm (TS-2026-014/015) の修正は 1.104.4 以降。locked nixpkgs は 1.104.1 のままなので、
  # 本体の flake 入力は動かさず、nixpkgs-unstable の tailscale だけ使う。
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraSetFlags = [
      "--ssh"
      "--advertise-exit-node"
    ];
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
  };

  networking.firewall = {
    # 直接接続用。閉じたままでも中継経由では繋がる。
    allowedUDPPorts = [ config.services.tailscale.port ];
    # Tailscale SSH は tailscale0 の 22 番で受ける。
    # IMAP/SMTP は protonmail-bridge.nix が同じインタフェースに足す。
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };

  imports = [ ./protonmail-bridge.nix ];

  services.openssh.enable = false;

  # sudo は転送された SSH エージェントの署名で通す。
  # PAM には auth sufficient pam_ssh_agent_auth.so が入り、
  # sudoers は SSH_AUTH_SOCK を残す。署名に失敗したときはパスワードに戻る。
  # 公開鍵が無いとエージェントに署名を頼まず、Touch ID も出ない。
  security.pam.sshAgentAuth.enable = true;

  # environment.etc だと /nix/store への symlink になり、pam_ssh_agent_auth が
  # 「bad ownership or modes for directory /nix/store」で拒否する。
  # 通常ファイルとしてコピーすれば、検査対象の親ディレクトリは /etc/ssh になる。
  system.activationScripts.pamSshAgentAuthKeys = {
    deps = [ "etc" ];
    text = ''
      install -d -m 755 -o root -g root /etc/ssh/authorized_keys.d
      install -m 644 -o root -g root ${ryoseiAuthorizedKeys} /etc/ssh/authorized_keys.d/ryosei
    '';
  };
}
