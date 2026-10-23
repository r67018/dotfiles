{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nodejs_26
  ];

  # SSH は Tailscale SSH が受ける。sshd は起動しない。
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh" ];
  };

  networking.firewall = {
    # 直接接続用。閉じたままでも中継経由では繋がる。
    allowedUDPPorts = [ config.services.tailscale.port ];
    # Tailscale SSH は tailscale0 の 22 番で受ける。
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };

  services.openssh.enable = false;

  # sudo は転送された SSH エージェントの署名で通す。
  # PAM には auth sufficient pam_ssh_agent_auth.so が入り、
  # sudoers は SSH_AUTH_SOCK を残す。署名に失敗したときはパスワードに戻る。
  # 公開鍵が無いとエージェントに署名を頼まず、Touch ID も出ない。
  security.pam.sshAgentAuth.enable = true;

  environment.etc."ssh/authorized_keys.d/ryosei".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfs8/T24RWsi7XqZfGTgWp9PvmQ91aODX6ZlDQ0Uxek ryosei@belvedere
  '';
}
