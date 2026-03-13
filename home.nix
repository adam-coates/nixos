{ config, pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./mako.nix
    ./hyprpaper.nix
    ./ghostty.nix
  ];

  home.username = "adam";
  home.homeDirectory = "/home/adam";
  home.stateVersion = "25.11";

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Neovim - managed via your own dotfiles (cloned by install.sh)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Packages managed by home-manager
  home.packages = with pkgs; [
    # File manager
    thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    gvfs

    # Wallpaper
    hyprpaper

    # App launcher
    rofi-wayland

    # Notifications
    mako
    libnotify

    # Utilities
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    playerctl
    pavucontrol
    btop
    bat
    eza
    zoxide
  ];

  # Git
  programs.git = {
    enable = true;
    userName = "adam-coates";
    userEmail = ""; # add your email
  };

  # Shell aliases
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      cd = "z";
      rebuild = "sudo nixos-rebuild switch --flake ~/.config/nixos#adam";
    };
    initExtra = ''
      eval "$(zoxide init bash)"
    '';
  };

  # XDG dirs
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
