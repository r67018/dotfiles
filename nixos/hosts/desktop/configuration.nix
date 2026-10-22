{ config, ... }:
{
  # Tailscale に入っている相手だけ SSH できるようにする。
  services.tailscale.enable = true;

  networking.firewall = {
    # 直接接続用。閉じたままでも中継経由では繋がる。
    allowedUDPPorts = [ config.services.tailscale.port ];
    interfaces."tailscale0".allowedTCPPorts = [ 22 ];
  };

  services.openssh = {
    enable = true;
    # 22番は tailscale0 以外では開けない。
    openFirewall = false;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [
        "ryosei@100.64.0.0/10"
        "ryosei@fd7a:115c:a1e0::/48"
      ];
    };
  };
}
