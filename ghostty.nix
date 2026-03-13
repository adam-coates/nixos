{ config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      theme = "catppuccin-mocha";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 13;
      window-padding-x = 10;
      window-padding-y = 10;
      cursor-style = "bar";
      cursor-style-blink = true;
      shell-integration-features = "no-cursor";
      window-decoration = false;
      background-opacity = 0.95;
    };
  };
}
