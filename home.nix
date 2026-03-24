{ config, pkgs, lib, inputs, ... }:

let
  gruvbox = import ./modules/colorscheme/gruvbox.nix;
in

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./walker.nix
    ./mako.nix
    ./hyprpaper.nix
    ./ghostty.nix
    ./tmux.nix
    ./starship.nix
    ./firefox.nix
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
    # The base package always contains a "specialisation/" directory;
    # the specialisation packages do not — so we use that to distinguish them.
    # This runs on every nixos-rebuild and keeps hm-generation pointing at
    # the base, even after the user has activated the light specialisation.
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

      # Wallpaper
      hyprpaper


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
        border-size=1
        default-timeout=5000
        font=TX02 Nerd Font 11
        width=300
        height=100
        padding=10
        margin=10
        icons=1
        max-icon-size=32
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

    # --- Wallpapers ---

    home.file."Pictures/wallpapers/gruvbox_dark.png".source = ./modules/colorscheme/gruvbox_dark.png;
    home.file."Pictures/wallpapers/gruvbox_light.png".source = ./modules/colorscheme/gruvbox_light.png;

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

    home.file.".local/bin/mkflake" = {
      source = ./scripts/mkflake.sh;
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
        export PATH="$HOME/.local/bin:$PATH"
      '';
    };

    xdg.enable = true;
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
