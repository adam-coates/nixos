{ config, pkgs, lib, inputs, ... }:

let
  gruvbox = import ../modules/colorscheme/gruvbox.nix;

  todoist = pkgs.appimageTools.wrapType2 {
    pname = "todoist";
    version = "9.26.4";
    src = pkgs.fetchurl {
      url = "https://electron-dl.todoist.net/linux/Todoist-linux-9.26.4-x86_64-latest.AppImage";
      hash = "sha256-zzRUU/ZLwoBRILFEHShjy8GOpww/spDVQM/EehjRNwY=";
    };
  };

  stylinator = pkgs.runCommand "stylinator" {} ''
    mkdir -p $out/bin
    cp ${./scripts/stylinator.py} $out/bin/stylinator
    chmod +x $out/bin/stylinator
    sed -i '1s|.*|#!${pkgs.python3}/bin/python3|' $out/bin/stylinator
  '';

  obsidian-inkscape = pkgs.writeShellScriptBin "obsidian-inkscape" ''
    export PATH="${pkgs.inkscape}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:$PATH"
    ${builtins.readFile ./scripts/obsidian-inkscape.sh}
  '';
in

{
  imports = [
    ./hyprland
    ./quickshell
    ./programs
    ./shell
    inputs.nixvim.homeModules.nixvim
    ../nixvim
    ./hardware
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
    font = lib.mkOption {
      type = lib.types.str;
      description = "Primary font family used across the system.";
      default = "TX02 Nerd Font";
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

    # Audio effects / equalizer
    services.easyeffects.enable = true;

    home.packages = with pkgs; [
      # File manager
      thunar
      thunar-archive-plugin
      thunar-volman

      # Notifications (for notify-send CLI tool)
      libnotify

      # Utilities
      wl-clipboard
      cliphist
      grim
      slurp
      swappy
      playerctl
      btop
      bat
      eza
      zoxide

      # PDF reader (zathura managed by programs.zathura)
      dbus

      # File preview (pdftoppm for PDF thumbnails in launcher)
      poppler-utils

      # WebP/AVIF/TIFF support for Qt image viewer (Quickshell file preview)
      qt6.qtimageformats

      claude-code

      # Productivity
      nextcloud-client
      todoist
      libreoffice-qt6
      zotero
      (typora.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/typora \
            --prefix XDG_DATA_DIRS : "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}" \
            --prefix XDG_DATA_DIRS : "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        '';
      }))

      # Voice dictation
      voxtype-vulkan

      # Notes
      obsidian

      # Vector graphics
      inkscape
      stylinator
      obsidian-inkscape
    ];

    # --- Wallpapers ---

    home.file."Pictures/wallpapers/gruvbox_dark.png".source = ../modules/colorscheme/gruvbox_dark.png;
    home.file."Pictures/wallpapers/gruvbox_light.png".source = ../modules/colorscheme/gruvbox_light.png;

    # --- Scripts ---

    home.file.".config/scripts/theme-switch.sh" = {
      source = ./scripts/theme-switch.sh;
      executable = true;
    };

    home.file.".config/scripts/idle-toggle.sh" = {
      source = ./scripts/idle-toggle.sh;
      executable = true;
    };

    home.file.".config/scripts/lock.sh" = {
      source = ./scripts/lock.sh;
      executable = true;
    };

    home.file.".config/scripts/resume.sh" = {
      source = ./scripts/resume.sh;
      executable = true;
    };

    home.file.".local/bin/mkflake" = {
      source = ./scripts/mkflake.sh;
      executable = true;
    };


    # --- GTK ---

    gtk = {
      enable = true;
      gtk4.theme = null;
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

    # --- swappy screenshot editor ---
    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=${config.home.homeDirectory}/Pictures/screenshots
      save_filename_format=screenshot_%Y%m%d_%H%M%S.png
      show_panel=true
    '';

    xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/thunar.xml".force = true;
    xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/thunar.xml".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar" version="1.0">
        <property name="last-view" type="string" value="ThunarDetailsView"/>
        <property name="last-show-hidden" type="bool" value="true"/>
      </channel>
    '';

    # --- Voxtype dictation config ---
    xdg.configFile."voxtype/config.toml".text = ''
      state_file = "auto"

      [hotkey]
      enabled = false

      [audio]
      device = "default"
      sample_rate = 16000
      max_duration_secs = 60

      [whisper]
      model = "small.en"
      language = "en"
      translate = false

      [output]
      mode = "type"
      fallback_to_clipboard = true
      type_delay_ms = 1

      [output.notification]
      on_recording_start = false
      on_recording_stop = false
      on_transcription = false
    '';

    xdg.desktopEntries.todoist = {
      name = "Todoist";
      exec = "todoist %U";
      icon = "todoist";
      comment = "Todoist task manager";
      categories = [ "Office" "ProjectManagement" ];
      terminal = false;
    };

    xdg.enable = true;
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
    };
  };
}
