{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = "gruvbox";
    font = "TX02 Nerd Font 12";
    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      drun-display-format = "{name}";
      display-drun = " Apps";
      display-run = " Run";
      display-window = " Windows";
    };
  };

  # Gruvbox rofi theme that imports colors.rasi written by theme switcher
  xdg.configFile."rofi/gruvbox.rasi".text = ''
    @import "colors.rasi"

    * {
      width: 600;
      font: "TX02 Nerd Font 12";
    }

    element-text, element-icon, mode-switcher {
      background-color: inherit;
      text-color: inherit;
    }

    window {
      height: 360px;
      border: 3px;
      border-color: @accent;
      background-color: @bg;
      border-radius: 12px;
    }

    mainbox {
      background-color: @bg;
    }

    inputbar {
      children: [prompt,entry];
      background-color: @bg;
      border-radius: 5px;
      padding: 2px;
    }

    prompt {
      background-color: @accent;
      padding: 6px;
      text-color: @bg;
      border-radius: 3px;
      margin: 20px 0px 0px 20px;
    }

    entry {
      padding: 6px;
      margin: 20px 0px 0px 10px;
      text-color: @fg;
      background-color: @bg;
    }

    listview {
      border: 0px 0px 0px;
      padding: 6px 0px 0px;
      margin: 10px 0px 0px 20px;
      columns: 2;
      lines: 5;
      background-color: @bg;
    }

    element {
      padding: 5px;
      background-color: @bg;
      text-color: @fg;
      border-radius: 6px;
    }

    element-icon {
      size: 25px;
    }

    element selected {
      background-color: @bg;
      text-color: @accent;
    }

    mode-switcher {
      spacing: 0;
    }

    button {
      padding: 10px;
      background-color: @bg;
      text-color: @gray;
      vertical-align: 0.5;
      horizontal-align: 0.5;
    }

    button selected {
      background-color: @bg;
      text-color: @accent;
    }
  '';
}
