{ config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      font-family = "TX02 Nerd Font";
      font-size = 13;
      window-padding-x = 10;
      window-padding-y = 10;
      cursor-style = "bar";
      cursor-style-blink = true;
      shell-integration-features = "no-cursor";
      window-decoration = false;
      background-opacity = 0.95;
      # Include theme via symlink - theme switcher updates this symlink
      config-file = "~/.config/ghostty/theme-link";
    };
  };
}
