{ config, pkgs, ... }:

{
  services.mako.settings = {
    enable = true;
    backgroundColor = "#1e1e2e";
    borderColor = "#cba6f7";
    textColor = "#cdd6f4";
    borderRadius = 10;
    borderSize = 2;
    defaultTimeout = 5000;
    font = "JetBrainsMono Nerd Font 11";
    width = 300;
    height = 100;
    padding = "10";
    margin = "10";
    icons = true;
    maxIconSize = 32;
  };
}
