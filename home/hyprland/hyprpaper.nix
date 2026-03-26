{ config, pkgs, ... }:

let
  darkWallpaper  = "/home/adam/Pictures/wallpapers/gruvbox_dark.png";
  lightWallpaper = "/home/adam/Pictures/wallpapers/gruvbox_light.png";
  activeWallpaper = if config.theme.dark then darkWallpaper else lightWallpaper;
in
{
  home.packages = [ pkgs.hyprpaper ];

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${darkWallpaper}
    preload = ${lightWallpaper}
    wallpaper = ,${activeWallpaper}
    splash = false
  '';
}
