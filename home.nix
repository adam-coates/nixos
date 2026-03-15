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

    # Neovim dependencies
    fzf
    tree-sitter
    gcc
    gnumake

    # Hyprlock
    hyprlock
  ];

  # Theme files - declared by Nix, owned by Nix store
  # gruvbox-dark
  xdg.configFile."themes/gruvbox-dark/waybar.css".source = ./themes/gruvbox-dark/waybar.css;
  xdg.configFile."themes/gruvbox-dark/hyprland.conf".source = ./themes/gruvbox-dark/hyprland.conf;
  xdg.configFile."themes/gruvbox-dark/mako.conf".source = ./themes/gruvbox-dark/mako.conf;
  xdg.configFile."themes/gruvbox-dark/rofi.rasi".source = ./themes/gruvbox-dark/rofi.rasi;
  # gruvbox-light
  xdg.configFile."themes/gruvbox-light/waybar.css".source = ./themes/gruvbox-light/waybar.css;
  xdg.configFile."themes/gruvbox-light/hyprland.conf".source = ./themes/gruvbox-light/hyprland.conf;
  xdg.configFile."themes/gruvbox-light/mako.conf".source = ./themes/gruvbox-light/mako.conf;
  xdg.configFile."themes/gruvbox-light/rofi.rasi".source = ./themes/gruvbox-light/rofi.rasi;
  # ghostty themes
  xdg.configFile."ghostty/themes/gruvbox-dark".source = ./themes/ghostty-gruvbox-dark;
  xdg.configFile."ghostty/themes/gruvbox-light".source = ./themes/ghostty-gruvbox-light;

  xdg.configFile."themes/gruvbox-dark/hyprlock.conf".source = ./themes/gruvbox-dark/hyprlock.conf;
  xdg.configFile."themes/gruvbox-light/hyprlock.conf".source = ./themes/gruvbox-light/hyprlock.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./home/hyprlock.conf;

  # Theme switcher script
  home.file.".config/scripts/theme-switch.sh" = {
    source = ./scripts/theme-switch.sh;
    executable = true;
  };

  home.file.".config/scripts/lock.sh" = {
    source = ./scripts/lock.sh;
    executable = true;
  };

  home.file.".config/scripts/power-menu.sh" = {
    source = ./scripts/power-menu.sh;
    executable = true;
  };

  # Apply theme on startup by pointing symlinks at the current theme directory
  home.file.".config/scripts/theme-apply.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      CURRENT="$HOME/.config/themes/current"
      THEME=$(cat "$CURRENT" 2>/dev/null || echo "gruvbox-dark")
      THEME_DIR="$HOME/.config/themes/$THEME"

      mkdir -p "$HOME/.config/waybar"
      mkdir -p "$HOME/.config/hypr"
      mkdir -p "$HOME/.config/mako"
      mkdir -p "$HOME/.config/rofi"

      # Point symlinks at current theme files
      ln -sf "$THEME_DIR/waybar.css"    "$HOME/.config/waybar/colors.css"
      ln -sf "$THEME_DIR/hyprland.conf" "$HOME/.config/hypr/theme.conf"
      ln -sf "$THEME_DIR/mako.conf"     "$HOME/.config/mako/config"
      ln -sf "$THEME_DIR/rofi.rasi"     "$HOME/.config/rofi/colors.rasi"
      ln -sf "$THEME_DIR/hyprlock.conf" "$HOME/.config/hypr/hyprlock-theme.conf"

      # Ghostty symlink
      mkdir -p "$HOME/.config/ghostty/themes"
      ln -sf "$HOME/.config/ghostty/themes/$THEME" "$HOME/.config/ghostty/theme-link"

      # GTK via dconf
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
      export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
      if [ "$THEME" = "gruvbox-dark" ]; then
        dconf write /org/gnome/desktop/interface/gtk-theme "'Gruvbox-Dark'"
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
      else
        dconf write /org/gnome/desktop/interface/gtk-theme "'Gruvbox-Light'"
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
      fi
      dconf write /org/gnome/desktop/interface/icon-theme "'Gruvbox-Dark'"

      echo "$THEME" > "$CURRENT"
    '';
  };
  # GTK theme - default gruvbox dark
  gtk = {
    enable = true;
    theme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-gtk-theme;
    };
    iconTheme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      size = 24;
      package = pkgs.bibata-cursors;
    };
  };

  # Direnv - auto-activate nix dev shells per project
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };

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

