{ config, pkgs, ... }:

let
  darkWallpaper  = "/home/adam/Pictures/wallpapers/gruvbox_dark.png";
  lightWallpaper = "/home/adam/Pictures/wallpapers/gruvbox_light.png";
  activeWallpaper = if config.theme.dark then darkWallpaper else lightWallpaper;
  c = config.theme.colors;
in
{
  # ── Hyprland ──────────────────────────────────────────────────────────────
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Monitor - auto detect
      monitor = ",preferred,auto,1";

      # Autostart
      exec-once = [
        "hyprpaper"
        "waybar"
        "mako"
        "hypridle"
        "nm-applet --indicator"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      # Environment variables
      env = [
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "HYPRCURSOR_SIZE,24"
        "QT_QPA_PLATFORM,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      # Input
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
        sensitivity = 0;
      };

      # General — border colors come from theme.colors
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 1;
        "col.active_border" = "rgb(${c.accent}) rgb(${c.orange}) 45deg";
        "col.inactive_border" = "rgb(${c.bg1})";
        layout = "dwindle";
        allow_tearing = false;
      };

      # Decoration
      decoration = {
        rounding = 0;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Layouts
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      # Misc
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      # Keybindings
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$fileManager" = "thunar";
      "$menu" = "walker";
      "$themeSwitcher" = "bash ~/.config/scripts/theme-switch.sh";
      "$powerMenu" = "bash ~/.config/scripts/power-menu.sh";
      "$lock" = "bash ~/.config/scripts/lock.sh";

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, $fileManager"
        "$mod, V, togglefloating,"
        "$mod, R, exec, $menu"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, F, fullscreen,"
        "$mod SHIFT, T, exec, $themeSwitcher"
        "$mod SHIFT, P, exec, $powerMenu"
        "$mod SHIFT, L, exec, $lock"

        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        ''$mod SHIFT, S, exec, mkdir -p ~/Pictures/screenshots && grim -g "$(slurp)" ~/Pictures/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && notify-send "Screenshot saved" "~/Pictures/screenshots" -t 2000''

        # Clipboard
        "$mod, C, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media keys
      bindel = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };

  # ── Hyprpaper ─────────────────────────────────────────────────────────────
  home.packages = [ pkgs.hyprpaper ];

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${darkWallpaper}
    preload = ${lightWallpaper}
    wallpaper = ,${activeWallpaper}
    splash = false
  '';

  # ── Hypridle ──────────────────────────────────────────────────────────────
  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;

  # ── Hyprlock ──────────────────────────────────────────────────────────────
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        ignore_empty_input = true;
      };

      background = [{
        monitor = "";
        color = c.hyprlockBg;
        blur_passes = 3;
      }];

      animations = {
        enabled = false;
      };

      input-field = [{
        monitor = "";
        size = "650, 100";
        position = "0, 0";
        halign = "center";
        valign = "center";
        inner_color = c.hyprlockBgInner;
        outer_color = c.hyprlockOuter;
        outline_thickness = 4;
        font_family = "TX02 Nerd Font";
        font_color = c.hyprlockFont;
        placeholder_text = "Enter Password";
        check_color = c.hyprlockCheck;
        fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
        rounding = 0;
        shadow_passes = 0;
        fade_on_empty = false;
      }];

      auth = {
        "fingerprint:enabled" = false;
      };
    };
  };
}
