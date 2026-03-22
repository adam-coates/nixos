{ config, pkgs, ... }:

{
  # Mako installed as package only.
  # Config is generated from theme.colors in home.nix via xdg.configFile."mako/config".
  home.packages = [ pkgs.mako pkgs.libnotify ];
}
