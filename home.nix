{ config, pkgs, lib, ... }:

let
  gruvbox = import ./modules/colorscheme/gruvbox.nix;
in

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./mako.nix
    ./hyprpaper.nix
    ./ghostty.nix
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
    # Light specialisation — activated at runtime by theme-switch.sh via:
    #   $PROFILE/specialisation/light/activate
    # Return to dark (base) with:
    #   $PROFILE/activate
    # where PROFILE=/nix/var/nix/profiles/per-user/$USER/home-manager
    specialisation.light.configuration = {
      theme.colors = gruvbox.light;
      theme.dark = false;
    };

    home.username = "adam";
    home.homeDirectory = "/home/adam";
    home.stateVersion = "25.11";

    programs.home-manager.enable = true;

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
      hypridle

      # PDF reader
      zathura
      dbus
    ];

    # --- Generated theme configs ---

    # Hyprlock theme variables (sourced by hyprlock.conf)
    xdg.configFile."hypr/hyprlock-theme.conf".text =
      let c = config.theme.colors; in ''
        $color = ${c.hyprlockBg}
        $inner_color = ${c.hyprlockBgInner}
        $outer_color = ${c.hyprlockOuter}
        $font_color = ${c.hyprlockFont}
        $check_color = ${c.hyprlockCheck}
      '';

    xdg.configFile."hypr/hyprlock.conf".source = ./home/hyprlock.conf;
    xdg.configFile."hypr/hypridle.conf".source = ./home/hypridle.conf;

    # Mako notification daemon
    xdg.configFile."mako/config".text =
      let c = config.theme.colors; in ''
        background-color=#${c.bg}
        border-color=#${c.accent}
        text-color=#${c.fg}
        border-radius=0
        border-size=2
        default-timeout=5000
        font=TX02 Nerd Font 11
        width=300
        height=100
        padding=10
        margin=10
        icons=1
        max-icon-size=32
      '';

    # Rofi color variables (imported by gruvbox.rasi)
    xdg.configFile."rofi/colors.rasi".text =
      let c = config.theme.colors; in ''
        * {
            bg: #${c.bg};
            fg: #${c.fg};
            accent: #${c.accent};
            gray: #${c.gray};
            red: #${c.red};
        }
      '';

    # Zathura
    xdg.configFile."zathura/zathurarc".text =
      let c = config.theme.colors; z = c.zathura; in ''
        # Keybindings
        map u scroll half-up
        map d scroll half-down
        map D toggle_page_mode
        map r reload
        map R rotate
        map K zoom in
        map J zoom out
        map i recolor
        map p print

        # General settings
        set selection-clipboard clipboard
        set render-loading      true
        set adjust-open         best-fit
        set pages-per-row       1
        set scroll-step         50

        set notification-error-bg       "${z.notifErrBg}"
        set notification-error-fg       "${z.notifErrFg}"
        set notification-warning-bg     "${z.notifWarnBg}"
        set notification-warning-fg     "${z.notifWarnFg}"
        set notification-bg             "${z.notifBg}"
        set notification-fg             "${z.notifFg}"
        set completion-bg               "${z.completionBg}"
        set completion-fg               "${z.completionFg}"
        set completion-group-bg         "${z.completionGrpBg}"
        set completion-group-fg         "${z.completionGrpFg}"
        set completion-highlight-bg     "${z.completionHighBg}"
        set completion-highlight-fg     "${z.completionHighFg}"
        set index-bg                    "${z.indexBg}"
        set index-fg                    "${z.indexFg}"
        set index-active-bg             "${z.indexActiveBg}"
        set index-active-fg             "${z.indexActiveFg}"
        set inputbar-bg                 "${z.inputbarBg}"
        set inputbar-fg                 "${z.inputbarFg}"
        set statusbar-bg                "${z.statusbarBg}"
        set statusbar-fg                "${z.statusbarFg}"
        set highlight-color             "${z.highlightColor}"
        set highlight-active-color      "${z.highlightActive}"
        set default-bg                  "${z.defaultBg}"
        set default-fg                  "${z.defaultFg}"
        set render-loading-bg           "${z.defaultBg}"
        set render-loading-fg           "${z.defaultFg}"
        set recolor-lightcolor          "${z.recolorLight}"
        set recolor-darkcolor           "${z.recolorDark}"
        set recolor                     "false"
        set recolor-keephue             "false"
      '';

    # --- Scripts ---

    home.file.".config/scripts/theme-switch.sh" = {
      source = ./scripts/theme-switch.sh;
      executable = true;
    };

    home.file.".config/scripts/idle-toggle.sh" = {
      source = ./scripts/idle-toggle.sh;
      executable = true;
    };

    home.file.".config/scripts/idle-status.sh" = {
      source = ./scripts/idle-status.sh;
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

    # --- Programs ---

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableBashIntegration = true;
    };

    programs.git = {
      enable = true;
      userName = "adam-coates";
      userEmail = ""; # add your email
    };

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

    xdg.enable = true;
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
