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

  # Theme source files
  home.file.".config/themes/gruvbox-dark.sh".source = ./themes/gruvbox-dark.sh;
  home.file.".config/themes/gruvbox-light.sh".source = ./themes/gruvbox-light.sh;

  # Theme switcher script
  home.file.".config/scripts/theme-switch.sh" = {
    source = ./scripts/theme-switch.sh;
    executable = true;
  };

  # Seed writable theme-controlled files on activation
  # These must be real files (not symlinks) so the theme switcher can overwrite them
  home.activation.seedThemeFiles = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Only seed if not already present as real files
    WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
    HYPR_THEME="$HOME/.config/hypr/theme.conf"
    MAKO_CONFIG="$HOME/.config/mako/config"

    mkdir -p "$HOME/.config/waybar"
    mkdir -p "$HOME/.config/hypr"
    mkdir -p "$HOME/.config/mako"

    if [ ! -f "$WAYBAR_COLORS" ] || [ -L "$WAYBAR_COLORS" ]; then
      rm -f "$WAYBAR_COLORS"
      cat > "$WAYBAR_COLORS" << 'EOF'
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
EOF
    fi

    if [ ! -f "$HYPR_THEME" ] || [ -L "$HYPR_THEME" ]; then
      rm -f "$HYPR_THEME"
      cat > "$HYPR_THEME" << 'EOF'
$active_border = rgb(d79921) rgb(d65d0e) 45deg
$inactive_border = rgb(3c3836)
$bg = rgb(282828)
$fg = rgb(ebdbb2)
EOF
    fi

    if [ ! -f "$MAKO_CONFIG" ] || [ -L "$MAKO_CONFIG" ]; then
      rm -f "$MAKO_CONFIG"
      cat > "$MAKO_CONFIG" << 'EOF'
background-color=#282828
border-color=#d79921
text-color=#ebdbb2
border-radius=10
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
    fi
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

