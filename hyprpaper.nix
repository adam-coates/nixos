{ config, pkgs, ... }:

{
  # hyprpaper is managed as a package + config file
  home.packages = [ pkgs.hyprpaper ];

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    # Add your wallpaper path here after install
    # preload = /home/adam/Pictures/wallpaper.jpg
    # wallpaper = ,/home/adam/Pictures/wallpaper.jpg
    splash = false
  '';
}
