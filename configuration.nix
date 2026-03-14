{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader - change to systemd-boot if using UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "adam";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Vienna"; # change to your timezone

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

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome
    noto-fonts
    noto-fonts-color-emoji
  ];

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
    # GTK theming
    gruvbox-gtk-theme
    gruvbox-dark-icons-gtk
    gsettings-desktop-schemas
    glib
  ];

  # GTK/gsettings support on Wayland
  programs.dconf.enable = true;

  environment.sessionVariables = {
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };

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
