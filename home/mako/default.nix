{ config, pkgs, ... }:

let c = config.theme.colors; in
{
  services.mako = {
    enable = true;
    settings = {
      background-color = "#${c.bg}";
      border-color = "#${c.accent}";
      text-color = "#${c.fg}";
      border-radius = 0;
      border-size = 1;
      default-timeout = 5000;
      font = "${config.theme.font} 11";
      width = 300;
      height = 100;
      padding = 10;
      margin = 10;
      icons = true;
      max-icon-size = 32;
    };
  };
}
