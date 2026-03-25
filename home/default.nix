{ config, pkgs, lib, inputs, ... }:

let
  gruvbox = import ../modules/colorscheme/gruvbox.nix;
in

{
  imports = [
    ./hyprland
    ./desktop
    ./programs
    ./shell
    inputs.nixvim.homeManagerModules.nixvim
    ./nixvim
  ];

  options.theme = {
    colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      description = "Color scheme attribute set.";
      default = gruvbox.dark;
    };
    dark = lib.mkOption {
      type = lib.types.bool;
      description = "Whether the active theme is dark.";
      default = true;
    };
  };

  config = {
    specialisation.light.configuration = {
      theme.colors = gruvbox.light;
      theme.dark = false;
    };

    # Record the BASE home-manager generation path for theme-switch.sh.
    home.activation.saveThemeProfile = lib.hm.dag.entryAfter ["writeBoundary"] ''
      SCRIPT_DIR="$(dirname "$(realpath "''${BASH_SOURCE[0]}")")"
      if [ -d "$SCRIPT_DIR/specialisation" ]; then
        $DRY_RUN_CMD mkdir -p "$HOME/.local/state"
        $DRY_RUN_CMD ln -sfn "$SCRIPT_DIR" "$HOME/.local/state/hm-generation"
      fi
    '';

    home.username = "adam";
    home.homeDirectory = "/home/adam";
    home.stateVersion = "25.11";
    home.sessionPath = [ "$HOME/.local/bin" ];

    programs.home-manager.enable = true;

    home.packages = with pkgs; [
      # File manager
      thunar
      xfce.thunar-archive-plugin
      xfce.thunar-volman
      gvfs

      # Notifications (mako managed by services.mako)
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

      # Hyprlock (managed by programs.hyprlock)
      hypridle

      # PDF reader (zathura managed by programs.zathura)
      dbus
    ];

    # --- Wallpapers ---

    home.file."Pictures/wallpapers/gruvbox_dark.png".source = ../modules/colorscheme/gruvbox_dark.png;
    home.file."Pictures/wallpapers/gruvbox_light.png".source = ../modules/colorscheme/gruvbox_light.png;

    # --- Scripts ---

    home.file.".config/scripts/theme-switch.sh" = {
      source = ../scripts/theme-switch.sh;
      executable = true;
    };

    home.file.".config/scripts/idle-toggle.sh" = {
      source = ../scripts/idle-toggle.sh;
      executable = true;
    };

    home.file.".config/scripts/idle-status.sh" = {
      source = ../scripts/idle-status.sh;
      executable = true;
    };

    home.file.".config/scripts/lock.sh" = {
      source = ../scripts/lock.sh;
      executable = true;
    };

    home.file.".config/scripts/power-menu.sh" = {
      source = ../scripts/power-menu.sh;
      executable = true;
    };

    home.file.".local/bin/mkflake" = {
      source = ../scripts/mkflake.sh;
      executable = true;
    };

    # --- GTK ---

    gtk = {
      enable = true;
      theme = {
        name = config.theme.colors.gtkTheme;
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

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = config.theme.colors.gtkColorScheme;
      };
    };

    xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar" version="1.0">
        <property name="last-view" type="string" value="ThunarDetailsView"/>
        <property name="last-show-hidden" type="bool" value="true"/>
      </channel>
    '';

    # --- Programs ---

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
    };

    xdg.enable = true;
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
