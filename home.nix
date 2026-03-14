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

  # Packages managed by home-manager
  home.packages = with pkgs; [
    # Editor
    neovim

    # File manager
    thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    gvfs

    # Wallpaper
    hyprpaper

    # App launcher
    rofi

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

    # Node
    nodejs
  ];

  # Theme files
  home.file.".config/themes/gruvbox-dark.conf".source = ./themes/gruvbox-dark.conf;
  home.file.".config/themes/gruvbox-light.conf".source = ./themes/gruvbox-light.conf;
  home.file.".config/themes/current".text = "gruvbox-dark";

  # Theme switcher script
  home.file.".config/scripts/theme-switch.sh" = {
    source = ./scripts/theme-switch.sh;
    executable = true;
  };

  # Initial waybar colors (gruvbox dark)
  home.file.".config/waybar/colors.css".text = ''
    @define-color bg rgba(40, 40, 40, 0.9);
    @define-color fg #ebdbb2;
    @define-color border rgba(215, 153, 33, 0.5);
    @define-color accent #d79921;
    @define-color red #cc241d;
    @define-color green #98971a;
    @define-color blue #458588;
    @define-color purple #b16286;
    @define-color aqua #689d6a;
    @define-color orange #d65d0e;
    @define-color gray #928374;
  '';

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

