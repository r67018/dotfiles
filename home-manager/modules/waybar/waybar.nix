{ ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = builtins.readFile ./style.css;
    settings = [{
      layer = "top";
      position = "top";
      modules-left = [
        "sway/workspaces"
        "sway/mode"
        "network"
        "cpu"
        "memory"
        "temperature"
        "battery"
      ];
      modules-center = [ "sway/window" ];
      modules-right = [
        "pulseaudio"
        "clock"
        "tray"
      ];
      "sway/window" = {
        max-length = 50;
      };
      battery = {
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-alt = "{time} {icon}";
        format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };
      clock = {
        format = "  {:%H:%M}";
        format-alt = "{:%H:%M}";
        tooltip-format = "{:%Y-%m-%d | %H:%M:%S}";
      };
      cpu = {
        interval = 10;
        format = "  {}%";
      };
      memory = {
        interval = 30;
        format = "   {}%";
        format-alt = " {used:0.1f}G";
      };
      network = {
        format-wifi = "󰖩  {essid}";
        format-ethernet = "󰈀  {ifname}: {ipaddr}/{cidr}";
        format-disconnected = "󰖪 disconnected";
      };
      temperature = {
        thermal-zone = 0;
        format = "{temperatureC}°C ";
      };
      tray = {
        tooltip = false;
        spacing = 10;
      };
      pulseaudio = {
        format = "{icon}   {volume}%";
        tooltip = false;
        format-muted = " Muted";
        on-click = "pamixer -t";
        on-scroll-up = "pamixer -i 5";
        on-scroll-down = "pamixer -d 5";
        scroll-step = 5;
        format-icons = {
          headphone = "";
          hands-free = "";
          headset = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
      };
    }];
  };
}

