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
    tree-sitter
    fzf

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

  # Theme source files
  home.file.".config/themes/gruvbox-dark.sh".source = ./themes/gruvbox-dark.sh;
  home.file.".config/themes/gruvbox-light.sh".source = ./themes/gruvbox-light.sh;
  home.file.".config/ghostty/themes/gruvbox-dark".source = ./themes/ghostty-gruvbox-dark;
  home.file.".config/ghostty/themes/gruvbox-light".source = ./themes/ghostty-gruvbox-light;

  # Theme switcher script
  home.file.".config/scripts/theme-switch.sh" = {
    source = ./scripts/theme-switch.sh;
    executable = true;
  };

  # Apply default theme script - runs on login to seed all theme files
  home.file.".config/scripts/theme-apply.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Apply current theme on startup, defaulting to gruvbox-dark
      CURRENT="$HOME/.config/themes/current"
      THEME=$(cat "$CURRENT" 2>/dev/null || echo "gruvbox-dark")
      THEME_FILE="$HOME/.config/themes/$THEME.sh"
      source "$THEME_FILE"

      mkdir -p "$HOME/.config/waybar"
      mkdir -p "$HOME/.config/hypr"
      mkdir -p "$HOME/.config/mako"
      mkdir -p "$HOME/.config/rofi"

      # Waybar colors
      cat > "$HOME/.config/waybar/colors.css" << EOF
@define-color bg $waybar_bg;
@define-color fg $waybar_fg;
@define-color border $waybar_border;
@define-color accent $waybar_accent;
@define-color red $waybar_red;
@define-color green $waybar_green;
@define-color blue $waybar_blue;
@define-color purple $waybar_purple;
@define-color aqua $waybar_aqua;
@define-color orange $waybar_orange;
@define-color gray $waybar_gray;
EOF

      # Hyprland theme
      cat > "$HOME/.config/hypr/theme.conf" << EOF
\$active_border = $active_border
\$inactive_border = $inactive_border
\$bg = $bg
\$fg = $fg
EOF

      # Mako
      cat > "$HOME/.config/mako/config" << EOF
background-color=$bg
border-color=$active_border_solid
text-color=$fg
border-radius=0
border-size=2
default-timeout=5000
font=JetBrainsMono Nerd Font 11
width=300
height=100
padding=10
margin=10
icons=1
max-icon-size=32
EOF

      # Rofi colors
      cat > "$HOME/.config/rofi/colors.rasi" << EOF
* {
    bg: $bg;
    fg: $fg;
    accent: $waybar_accent;
    gray: $waybar_gray;
    red: $waybar_red;
}
EOF

      # Write current theme name
      echo "$THEME" > "$CURRENT"

      # Ghostty - create/update theme symlink and reload
      mkdir -p "$HOME/.config/ghostty/themes"
      ln -sf "$HOME/.config/ghostty/themes/$THEME" "$HOME/.config/ghostty/theme-link"
      pkill -USR2 ghostty 2>/dev/null || true

      # GTK
      if [ "$THEME" = "gruvbox-dark" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Dark"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
      else
        gsettings set org.gnome.desktop.interface gtk-theme "Gruvbox-Light"
        gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
      fi
      gsettings set org.gnome.desktop.interface icon-theme "Gruvbox-Dark"
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

