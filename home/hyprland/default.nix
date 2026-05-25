{ config, pkgs, lib, ... }:

let
  lua = lib.generators.mkLuaInline;

  dsp = {
    exec = cmd: lua ''hl.dsp.exec_cmd("${cmd}")'';
    close = lua "hl.dsp.window.close()";
    exit = lua "hl.dsp.exit()";
    float = lua ''hl.dsp.window.float({ action = "toggle" })'';
    fullscreen = lua "hl.dsp.window.fullscreen()";
    pseudo = lua "hl.dsp.window.pseudo()";
    layout = msg: lua ''hl.dsp.layout("${msg}")'';
    focus = dir: lua ''hl.dsp.focus({ direction = "${dir}" })'';
    focusWorkspace = ws: lua ''hl.dsp.focus({ workspace = "${toString ws}" })'';
    moveToWorkspace = ws: lua ''hl.dsp.window.move({ workspace = "${toString ws}" })'';
    drag = lua "hl.dsp.window.drag()";
    resize = lua "hl.dsp.window.resize()";
  };

  bind = keys: dispatcher: { _args = [ keys dispatcher ]; };
  bindOpts = keys: dispatcher: opts: { _args = [ keys dispatcher opts ]; };

  workspaceBinds = lib.concatMap (i:
    let key = toString (lib.mod i 10);
    in [
      (bind "SUPER + ${key}" (dsp.focusWorkspace i))
      (bind "SUPER + SHIFT + ${key}" (dsp.moveToWorkspace i))
    ]
  ) (lib.range 1 10);

  c = config.theme.colors;
in

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    settings = {
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };

      config = {
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          touchpad = {
            natural_scroll = true;
          };
          sensitivity = 0;
        };

        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 1;
          col = {
            active_border = {
              colors = [ "rgb(${c.accent})" "rgb(${c.orange})" ];
              angle = 45;
            };
            inactive_border = "rgb(${c.bg1})";
          };
          layout = "dwindle";
          allow_tearing = false;
        };

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

        animations = {
          enabled = true;
        };

        dwindle = {
          preserve_split = true;
          force_split = 2;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };
      };

      env = [
        { _args = [ "XCURSOR_SIZE" "24" ]; }
        { _args = [ "XCURSOR_THEME" "Bibata-Modern-Classic" ]; }
        { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        { _args = [ "QT_QPA_PLATFORM" "wayland" ]; }
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "XDG_SESSION_TYPE" "wayland" ]; }
        { _args = [ "XDG_SESSION_DESKTOP" "Hyprland" ]; }
      ];

      curve = [{
        _args = [
          "myBezier"
          {
            type = "bezier";
            points = lua "{ {0.05, 0.9}, {0.1, 1.05} }";
          }
        ];
      }];

      animation = [
        { leaf = "windows"; enabled = true; speed = 7; bezier = "myBezier"; }
        { leaf = "windowsOut"; enabled = true; speed = 7; bezier = "default"; style = "popin 80%"; }
        { leaf = "border"; enabled = true; speed = 10; bezier = "default"; }
        { leaf = "borderangle"; enabled = true; speed = 8; bezier = "default"; }
        { leaf = "fade"; enabled = true; speed = 7; bezier = "default"; }
        { leaf = "workspaces"; enabled = true; speed = 6; bezier = "default"; }
      ];

      on = {
        _args = [
          "hyprland.start"
          (lua ''
            function()
              hl.exec_cmd("systemctl --user start hyprpolkitagent")
              hl.exec_cmd("nm-applet --indicator")
              hl.exec_cmd("wl-paste --type text --watch cliphist store")
              hl.exec_cmd("wl-paste --type image --watch cliphist store")
              hl.exec_cmd("solaar --window=hide")
              hl.exec_cmd("voxtype daemon")
              hl.exec_cmd("nextcloud --background")
            end'')
        ];
      };

      bind = [
        (bind "SUPER + Return" (dsp.exec "ghostty"))
        (bind "SUPER + Q" dsp.close)
        (bind "SUPER + M" dsp.exit)
        (bind "SUPER + E" (dsp.exec "thunar"))
        (bind "SUPER + V" dsp.float)
        (bind "SUPER + R" (dsp.exec "qs ipc call shell toggleLauncher"))
        (bind "SUPER + P" dsp.pseudo)
        (bind "SUPER + J" (dsp.layout "togglesplit"))
        (bind "SUPER + F" dsp.fullscreen)
        (bind "SUPER + SHIFT + T" (dsp.exec "bash ~/.config/scripts/theme-switch.sh"))
        (bind "SUPER + SHIFT + P" (dsp.exec "qs ipc call shell togglePowermenu"))
        (bind "SUPER + SHIFT + L" (dsp.exec "qs ipc call shell lock"))
        (bind "SUPER + grave" (dsp.exec "qs ipc call shell toggleCapture"))
        (bind "SUPER + T" (dsp.exec "qs ipc call shell toggleTodoist"))

        # Focus
        (bind "SUPER + left" (dsp.focus "left"))
        (bind "SUPER + right" (dsp.focus "right"))
        (bind "SUPER + up" (dsp.focus "up"))
        (bind "SUPER + down" (dsp.focus "down"))

        # Scroll workspaces
        (bind "SUPER + mouse_down" (dsp.focusWorkspace "e+1"))
        (bind "SUPER + mouse_up" (dsp.focusWorkspace "e-1"))

        # Screenshot
        (bind "Print" (lua ''hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]])''))
        (bind "SUPER + SHIFT + S" (lua ''hl.dsp.exec_cmd([[mkdir -p ~/Pictures/screenshots && grim -g "$(slurp)" ~/Pictures/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png && notify-send "Screenshot saved" "~/Pictures/screenshots" -t 2000]])''))

        # Clipboard
        (bind "SUPER + C" (dsp.exec "qs ipc call shell toggleClipboard"))

        # Emoji picker
        (bind "SUPER + period" (dsp.exec "qs ipc call shell toggleEmoji"))

        # Inkscape stylinator
        (bind "SUPER + I" (dsp.exec "qs ipc call shell toggleStylinator"))

        # Dictation toggle
        (bind "SUPER + SHIFT + X" (dsp.exec "voxtype record toggle"))

        # Media keys
        (bindOpts "XF86AudioRaiseVolume" (dsp.exec "pamixer -i 5") { locked = true; repeating = true; })
        (bindOpts "XF86AudioLowerVolume" (dsp.exec "pamixer -d 5") { locked = true; repeating = true; })
        (bindOpts "XF86MonBrightnessUp" (dsp.exec "brightnessctl s 10%+") { locked = true; repeating = true; })
        (bindOpts "XF86MonBrightnessDown" (dsp.exec "brightnessctl s 10%-") { locked = true; repeating = true; })
        (bindOpts "XF86AudioMute" (dsp.exec "pamixer -t") { locked = true; })
        (bindOpts "XF86AudioPlay" (dsp.exec "playerctl play-pause") { locked = true; })
        (bindOpts "XF86AudioNext" (dsp.exec "playerctl next") { locked = true; })
        (bindOpts "XF86AudioPrev" (dsp.exec "playerctl previous") { locked = true; })

        # Mouse move/resize
        (bindOpts "SUPER + mouse:272" dsp.drag { mouse = true; })
        (bindOpts "SUPER + mouse:273" dsp.resize { mouse = true; })
      ] ++ workspaceBinds;
    };
  };

  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
}
