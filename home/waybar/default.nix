{ config, pkgs, lib, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        reload_style_on_change = true;
        layer = "top";
        position = "top";
        height = 26;
        spacing = 0;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" "custom/idle-indicator" ];
        modules-right = [
          "tray"
          "bluetooth"
          "network"
          "pulseaudio"
          "cpu"
          "battery"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "";
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "0";
            active = "󱓻";
          };
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };

        clock = {
          format = "{:%A %H:%M}";
          format-alt = "{:%d %B %Y}";
          tooltip = false;
        };

        cpu = {
          interval = 5;
          format = "󰍛";
          tooltip = true;
        };

        network = {
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          format = "{icon}";
          format-wifi = "{icon}";
          format-ethernet = "󰀂";
          format-disconnected = "󰤮";
          tooltip-format-wifi = "{essid}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-disconnected = "Disconnected";
          interval = 3;
        };

        battery = {
          format = "{icon}";
          format-discharging = "{icon}";
          format-charging = "{icon}";
          format-plugged = "";
          format-full = "󰂅";
          format-icons = {
            charging = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
            default = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          };
          tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
          tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
          interval = 5;
          states = {
            warning = 20;
            critical = 10;
          };
        };

        bluetooth = {
          format = "";
          format-off = "󰂲";
          format-disabled = "󰂲";
          format-connected = "󰂱";
          tooltip-format = "Devices connected: {num_connections}";
          on-click = "blueman-manager";
        };

        pulseaudio = {
          format = "{icon}";
          on-click = "pavucontrol";
          on-click-right = "pamixer -t";
          tooltip-format = "Volume: {volume}%";
          scroll-step = 5;
          format-muted = "";
          format-icons = {
            headphone = "";
            headset = "";
            default = [ "" "" "" ];
          };
        };

        tray = {
          icon-size = 12;
          spacing = 17;
        };

        "custom/idle-indicator" = {
          exec = "~/.config/scripts/idle-status.sh";
          on-click = "bash ~/.config/scripts/idle-toggle.sh";
          return-type = "json";
          interval = 5;
          signal = 9;
        };
      };
    };

    style =
      let c = config.theme.colors; in ''
      @define-color bg ${c.waybarBg};
      @define-color fg #${c.fg};
      @define-color border ${c.waybarBorder};
      @define-color accent #${c.accent};
      @define-color red #${c.red};
      @define-color green #${c.green};
      @define-color blue #${c.blue};
      @define-color purple #${c.purple};
      @define-color aqua #${c.aqua};
      @define-color orange #${c.orange};
      @define-color gray #${c.gray};

      * {
        font-family: "${config.theme.font}";
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background-color: @bg;
        border-bottom: 1px solid @border;
        color: @fg;
      }

      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 6px;
        color: @gray;
        background: transparent;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.active {
        color: @accent;
        border-bottom: 2px solid @accent;
      }

      #workspaces button:hover {
        color: @fg;
        background: transparent;
        border-bottom: 2px solid @fg;
      }

      #clock {
        color: @fg;
        padding: 0 10px;
      }

      #cpu,
      #network,
      #battery,
      #bluetooth,
      #pulseaudio,
      #tray {
        padding: 0 8px;
        color: @fg;
      }

      #battery.warning { color: @orange; }
      #battery.critical { color: @red; }

      #custom-idle-indicator {
        padding: 0 8px;
        color: @gray;
      }

      #custom-idle-indicator.idle-on {
        color: @green;
      }

      #custom-idle-indicator.idle-off {
        color: @gray;
      }
    '';
  };
}
