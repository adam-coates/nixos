{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/fonts.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "adam";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.adam = {
    isNormalUser = true;
    description = "adam";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.bash;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hypridle
  services.hypridle.enable = true;

  # PAM service for quickshell lock screen
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.quickshell = {};

  # Display manager - ly
  services.displayManager.ly.enable = true;

  # Audio - pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Power management (required by quickshell widgets)
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Thunar
  services.gvfs.enable = true;
  programs.xfconf.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

  # Include user fonts from ~/.local/share/fonts
  fonts.fontDir.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    unzip
    ripgrep
    fd
    fzf
    brightnessctl
    pamixer
    networkmanagerapplet
    nodejs
    yarn
    # GTK theming
    gruvbox-gtk-theme
    gruvbox-dark-icons-gtk
    bibata-cursors
  ];

  # GTK/dconf support on Wayland
  programs.dconf.enable = true;

  # XDG portal for Wayland/Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  system.stateVersion = "25.11";
}
