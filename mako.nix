{ config, pkgs, ... }:

{
  # Mako installed as package only.
  # Config is managed by the theme switcher and seeded via home.activation in home.nix.
  home.packages = [ pkgs.mako pkgs.libnotify ];
}
