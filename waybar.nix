{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 35;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" "hyprland/submap" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{name}";
        };

        clock = {
          format = " {:%H:%M}";
          format-alt = " {:%A, %B %d, %Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = " {usage}%";
          tooltip = false;
        };

        memory = {
          format = " {}%";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-icons = [ "" "" "" "" "" ];
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " {ipaddr}";
          format-disconnected = "󰤭 Disconnected";
          tooltip-format = "{essid} {ipaddr}";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";
          format-icons = {
            default = [ "" "" " " ];
          };
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 10;
        };
      };
    };

    style = ''
      @import "colors.css";

      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: @bg;
        border-bottom: 2px solid @border;
        color: @fg;
      }

      .modules-left, .modules-center, .modules-right {
        padding: 0 10px;
      }

      #workspaces button {
        padding: 0 8px;
        color: @gray;
        background: transparent;
        border: none;
        border-radius: 6px;
        transition: all 0.3s ease;
      }

      #workspaces button.active {
        color: @accent;
        background: rgba(0, 0, 0, 0.1);
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.05);
        color: @fg;
      }

      #clock {
        color: @blue;
        font-weight: bold;
      }

      #cpu { color: @green; }
      #memory { color: @orange; }
      #battery { color: @green; }
      #battery.warning { color: @yellow; }
      #battery.critical { color: @red; }
      #network { color: @aqua; }
      #pulseaudio { color: @purple; }
      #tray { padding: 0 5px; }
    '';
  };
}

