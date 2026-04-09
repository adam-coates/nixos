{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # OpenConnect SSO — handles SAML/MFA via embedded Qt WebEngine browser
  openconnect-sso = pkgs.python3Packages.buildPythonApplication rec {
    pname = "openconnect-sso";
    version = "0.8.1";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "vlaci";
      repo = "openconnect-sso";
      rev = "master";
      hash = "sha256-JFVvTw11KFnrd/A5z3QCh30ac9MZG+ojDY3udAFpmCE=";
    };

    nativeBuildInputs = with pkgs.python3Packages; [ poetry-core ];

    # Relax version constraints for nixpkgs compatibility
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail 'requires = ["poetry>=0.12"]' 'requires = ["poetry-core>=1.0.0"]' \
        --replace-fail 'build-backend = "poetry.masonry.api"' 'build-backend = "poetry.core.masonry.api"' \
        --replace-fail 'lxml = "^4.3"' 'lxml = ">=4.3"' \
        --replace-fail 'keyring = ">=21.1, <24.0.0"' 'keyring = ">=21.1"' \
        --replace-fail 'colorama = "^0.4"' 'colorama = ">=0.4"' \
        --replace-fail 'pyxdg = ">=0.26, <0.29"' 'pyxdg = ">=0.26"'
    '';

    propagatedBuildInputs = with pkgs.python3Packages; [
      attrs
      colorama
      lxml
      keyring
      prompt-toolkit
      pyxdg
      requests
      structlog
      toml
      setuptools
      pysocks
      pyqt6
      pyqt6-webengine
      pyotp
    ];

    doCheck = false;
  };

  # Script to cleanly kill openconnect (used with NOPASSWD sudo)
  vpnDisconnect = pkgs.writeShellScript "vpn-disconnect-oc" ''
    if [ -f /tmp/openconnect-vpn.pid ]; then
      kill -INT "$(cat /tmp/openconnect-vpn.pid)" 2>/dev/null
      rm -f /tmp/openconnect-vpn.pid
    else
      ${pkgs.procps}/bin/pkill -INT openconnect 2>/dev/null || true
    fi
  '';

  # Main VPN helper script called by QuickShell
  vpnHelper = pkgs.writeShellScriptBin "qs-vpn" ''
    # Ensure display environment is set (needed when launched from QuickShell)
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
    export DISPLAY="''${DISPLAY:-:0}"

    case "$1" in
      oc-connect)
        GATEWAY="$2"
        AUTHGROUP="''${3:-}"

        GROUPFLAG=""
        if [ -n "$AUTHGROUP" ]; then
          GROUPFLAG="--authgroup=$AUTHGROUP"
        fi

        # Step 1: Authenticate via SAML (opens Qt WebEngine browser window)
        # --authenticate shell outputs COOKIE, HOST, FINGERPRINT as shell vars
        AUTH=$(${openconnect-sso}/bin/openconnect-sso \
          --server "$GATEWAY" \
          $GROUPFLAG \
          --authenticate shell \
          2>/tmp/openconnect-auth.log)

        if [ $? -ne 0 ] || [ -z "$AUTH" ]; then
          echo "FAILED"
          exit 1
        fi

        # Parse auth output safely — only extract known variable assignments
        while IFS='=' read -r key value; do
          # Strip any leading/trailing whitespace
          key="$(echo "$key" | ${pkgs.coreutils}/bin/tr -d '[:space:]')"
          # Only allow known safe variable names
          case "$key" in
            COOKIE|HOST|FINGERPRINT|RESOLVE|CONNECT_URL)
              # Strip surrounding quotes if present
              value="$(echo "$value" | ${pkgs.gnused}/bin/sed "s/^['\"]//;s/['\"]$//")"
              printf -v "$key" '%s' "$value"
              ;;
          esac
        done <<< "$AUTH"

        if [ -z "$COOKIE" ]; then
          echo "FAILED"
          exit 1
        fi

        # Step 2: Connect tunnel as root, daemonized in background
        echo "$COOKIE" | sudo ${pkgs.openconnect}/bin/openconnect \
          --protocol=anyconnect \
          --cookie-on-stdin \
          --servercert="$FINGERPRINT" \
          --background \
          --pid-file=/tmp/openconnect-vpn.pid \
          --quiet \
          "$HOST"

        if [ $? -eq 0 ]; then
          echo "CONNECTED"
        else
          echo "FAILED"
          exit 1
        fi
        ;;

      oc-disconnect)
        sudo ${vpnDisconnect}
        echo "DISCONNECTED"
        ;;

      oc-status)
        if ${pkgs.procps}/bin/pgrep -f "${pkgs.openconnect}/bin/openconnect" > /dev/null 2>&1; then
          echo "CONNECTED"
        else
          echo "DISCONNECTED"
        fi
        ;;

      wg-connect)
        ${pkgs.networkmanager}/bin/nmcli connection up "$2"
        ;;

      wg-disconnect)
        ${pkgs.networkmanager}/bin/nmcli connection down "$2"
        ;;

      wg-import)
        ${pkgs.networkmanager}/bin/nmcli connection import type wireguard file "$2"
        ;;
    esac
  '';
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "adam";
  networking.networkmanager.enable = true;

  # VPN plugins for NetworkManager (WireGuard + OpenConnect)
  networking.networkmanager.plugins = [
    pkgs.networkmanager-openconnect
  ];

  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";

  # User
  users.users.adam = {
    isNormalUser = true;
    description = "adam";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "lp"
    ];
    shell = pkgs.bash;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;

  programs.java = {
    enable = true;
    package = pkgs.jdk;
  };

  # Automatic system cleaning via nh
  programs.nh = {
    enable = true;
    flake = "/home/adam/nixos";

    clean = {
      enable = true;
      extraArgs = "--keep 3";
    };
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Hypridle
  services.hypridle.enable = true;

  # PAM service for quickshell lock screen
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.quickshell = { };

  # Gnome keyring (provides org.freedesktop.secrets for udisks2 passphrase storage)
  services.gnome.gnome-keyring.enable = true;

  # Display manager - ly
  services.displayManager.ly.enable = true;

  # Audio - pipewire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.extraConfig."11-bluetooth-policy" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
  };

  # printing
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };
  services.ipp-usb.enable = true;
  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Power management (required by quickshell widgets)
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Thunar
  services.gvfs.enable = true;
  programs.xfconf.enable = true;

  # Udisks2 + polkit - allow wheel users to mount/unlock drives
  services.udisks2.enable = true;
  security.polkit.enable = true;

  # logitech mouse
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # Make sleep work
  systemd.services.toggle-acpi-fix = {
    description = "Disable GPP0 and PTXH to fix suspend issue";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "toggle-acpi-fix" ''
        while read -r device _ status _; do
          case "$device" in
            GPP0|PTXH)
              if [[ "$status" == *enabled* ]]; then
                echo "$device" > /proc/acpi/wakeup
              fi
              ;;
          esac
        done < /proc/acpi/wakeup
      '';
    };
  };

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
    openconnect
    wireguard-tools
    vpnHelper
    networkmanagerapplet
    hyprpolkitagent
    libusb1
    uv
    nodejs
    yarn
    sqlite
    # GTK theming
    gruvbox-gtk-theme
    gruvbox-dark-icons-gtk
    bibata-cursors
  ];

  # Epson printer USB access (restricted to lp group)
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04b8", ATTR{idProduct}=="0e39", MODE="0660", GROUP="lp"
  '';

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

  # Sudo rules for VPN (openconnect needs root for tun device)
  security.sudo.extraRules = [
    {
      users = [ "adam" ];
      commands = [
        {
          command = "${pkgs.openconnect}/bin/openconnect";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${openconnect-sso}/bin/openconnect-sso";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${vpnDisconnect}";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  system.stateVersion = "25.11";
}
