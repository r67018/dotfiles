{ pkgs, ... }:
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
        "tray"
        "pulseaudio"
        "clock"
        "custom/power"
      ];
      "custom/power" = {
        format = "";
        on-click = "${pkgs.wlogout}/bin/wlogout";
        tooltip = false;
      };
      "sway/window" = {
        max-length = 50;
      };
      battery = {
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-plugged = " {capacity}%";
        format-alt = "{icon} {time}";
        format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };
      clock = {
        format = " {:%H:%M}";
        format-alt = " {:%Y/%m/%d %H:%M}";
        tooltip-format = "{:%Y-%m-%d | %H:%M:%S}";
      };
      cpu = {
        interval = 10;
        format = " {}%";
      };
      memory = {
        interval = 30;
        format = " {}%";
        format-alt = " {used:0.1f}G";
      };
      network = {
        format-wifi = "󰖩 {essid}";
        format-ethernet = "󰈀 {ifname}: {ipaddr}/{cidr}";
        format-disconnected = "󰖪 disconnected";
      };
      temperature = {
        thermal-zone = 0;
        format = " {temperatureC}°C";
      };
      tray = {
        tooltip = false;
        spacing = 10;
      };
      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = " Muted";
        on-click = "${pkgs.pamixer}/bin/pamixer -t";
        on-scroll-up = "${pkgs.pamixer}/bin/pamixer -i 5";
        on-scroll-down = "${pkgs.pamixer}/bin/pamixer -d 5";
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

