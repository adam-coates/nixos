{ config, pkgs, ... }:

{
  services.mako = {
    enable = true;
    backgroundColor = "#282828";
    borderColor = "#d79921";
    textColor = "#ebdbb2";
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
