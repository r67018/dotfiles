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
}
