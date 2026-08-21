{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  vpn = import ../../modules/vpn.nix;

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

      # setuptools >= 81 no longer ships pkg_resources; use importlib.resources
      substituteInPlace openconnect_sso/browser/webengine_process.py \
        --replace-fail 'import pkg_resources' 'from importlib.resources import files as _resource_files' \
        --replace-fail 'pkg_resources.resource_string(__name__, "user.js").decode()' '(_resource_files("openconnect_sso.browser") / "user.js").read_text()'

      # Python 3.14 removed the implicit loop creation in asyncio.get_event_loop();
      # create and install one explicitly before the first use.
      substituteInPlace openconnect_sso/app.py \
        --replace-fail 'asyncio.get_event_loop().run_until_complete(' '(asyncio.set_event_loop(asyncio.new_event_loop()) or asyncio.get_event_loop()).run_until_complete('

      # The univpn.uni-graz.at ASA now asks for a TLS client certificate and
      # replies <client-cert-request/> instead of the SAML form. Declare that we
      # have no certificate, the same way openconnect does on its retry.
      substituteInPlace openconnect_sso/authenticator.py \
        --replace-fail 'AuthMethod = getattr(E, "auth-method")' 'AuthMethod = getattr(E, "auth-method"); ClientCertFail = getattr(E, "client-cert-fail")' \
        --replace-fail 'Capabilities(AuthMethod("single-sign-on-v2")),' 'Capabilities(AuthMethod("single-sign-on-v2")), ClientCertFail(),'
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

  # Arduino IDE with extra FHS packages for ESP32 toolchain
  arduino-ide-with-extras = pkgs.buildFHSEnv (
    pkgs.arduino-ide.passthru.args
    // {
      targetPkgs =
        p:
        (pkgs.arduino-ide.passthru.args.targetPkgs p)
        ++ (with p; [
          python3
          esptool
          libxkbfile
        ]);
    }
  );

  # Main VPN helper script called by QuickShell
  vpnHelper = pkgs.writeShellScriptBin "qs-vpn" ''
    # Ensure display environment is set (needed when launched from QuickShell)
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
    export DISPLAY="''${DISPLAY:-:0}"

    # Uni Graz login. Also the keyring account holding the password and, under
    # "totp/$VPN_USER", the 2FA seed that `qr-totp save` writes.
    VPN_USER="${vpn.user}"

    # True when the keyring holds a secret for the given account.
    have_secret() {
      ${pkgs.libsecret}/bin/secret-tool lookup \
        service openconnect-sso username "$1" > /dev/null 2>&1
    }

    case "$1" in
      oc-connect)
        GATEWAY="$2"
        AUTHGROUP="''${3:-}"

        GROUPFLAG=""
        if [ -n "$AUTHGROUP" ]; then
          GROUPFLAG="--authgroup=$AUTHGROUP"
        fi

        # Launched from QuickShell there is no terminal, so a missing secret
        # would leave openconnect-sso blocked on an invisible getpass prompt.
        # Fail loudly instead and point at the one-time setup.
        if ! have_secret "$VPN_USER"; then
          echo "NO_PASSWORD: run 'qs-vpn oc-setup' in a terminal once"
          exit 1
        fi
        if ! have_secret "totp/$VPN_USER"; then
          echo "NO_TOTP: run 'nix run ~/auto-vpn -- save <qr.png> --user $VPN_USER'"
          exit 1
        fi

        # Step 1: Authenticate via SAML. The Qt WebEngine window still opens,
        # but the auto-fill rules in ~/.config/openconnect-sso/config.toml drive
        # it: username, password, then a TOTP code derived from the stored seed.
        # --authenticate shell outputs COOKIE, HOST, FINGERPRINT as shell vars
        AUTH=$(${openconnect-sso}/bin/openconnect-sso \
          --server "$GATEWAY" \
          $GROUPFLAG \
          --user "$VPN_USER" \
          --authenticate shell \
          < /dev/null \
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

      oc-setup)
        # One-time, from a terminal: openconnect-sso prompts for whatever is
        # missing and saves it to the keyring itself, so the password never
        # passes through this script or the Nix config.
        echo "Seeding the keyring for $VPN_USER."
        if have_secret "$VPN_USER"; then
          echo "  password: already stored"
        else
          echo "  password: prompting (openconnect-sso stores it)"
        fi
        if have_secret "totp/$VPN_USER"; then
          echo "  totp:     already stored"
        else
          echo "  totp:     not stored -- either paste the base32 seed at the"
          echo "            prompt below, or press Enter and instead run"
          echo "            nix run ~/auto-vpn -- save <qr.png> --user $VPN_USER"
        fi
        SETUP_LOG="$(${pkgs.coreutils}/bin/mktemp)"
        ${openconnect-sso}/bin/openconnect-sso \
          --server ${vpn.gateway} \
          --authgroup ${vpn.authgroup} \
          --user "$VPN_USER" \
          --authenticate shell > /dev/null 2>"$SETUP_LOG"
        SETUP_STATUS=$?

        # openconnect-sso rewrites config.toml after every successful login, but
        # Home Manager owns that file read-only -- which is exactly what keeps
        # the auto-fill rules from drifting. The write fails, openconnect-sso
        # logs it and carries on. Drop that one traceback so it does not read
        # like a failure; everything else goes through untouched.
        ${pkgs.gawk}/bin/awk '
          /Could not save configuration file/ { drop = 1; next }
          drop && /^PermissionError/          { drop = 0; next }
          !drop
        ' "$SETUP_LOG" >&2
        ${pkgs.coreutils}/bin/rm -f "$SETUP_LOG"

        if [ $SETUP_STATUS -ne 0 ]; then
          echo "Setup failed (exit $SETUP_STATUS)." >&2
          exit $SETUP_STATUS
        fi

        echo "Setup done. The panel button should now connect without prompting."
        ;;

      oc-status-secrets)
        # What the panel would find before attempting a connection.
        have_secret "$VPN_USER" && echo "password: stored" || echo "password: missing"
        have_secret "totp/$VPN_USER" && echo "totp: stored" || echo "totp: missing"
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
    ./gaming.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CIFS/SMB support
  boot.supportedFilesystems = [ "cifs" ];

  # boot.kernelPatches = [{
  #   name = "btmtk-wmt-func-ctrl-fix";
  #   patch = ./btmtk-wmt-func-ctrl-fix.patch;
  # }];

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  networking.hostName = "adam";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.networkmanager.wifi.powersave = false;

  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  # VPN plugins for NetworkManager (WireGuard + OpenConnect)
  networking.networkmanager.plugins = [
    pkgs.networkmanager-openconnect
  ];

  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";

  # Default editor system-wide (overrides NixOS's mkDefault "nano")
  environment.variables.EDITOR = "nvim";

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
      "libvirtd"
      "dialout"
      "psychopy"
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

  # gpu-screen-recorder needs cap_sys_admin on gsr-kms-server for KMS capture
  security.wrappers.gsr-kms-server = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+ep";
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
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

  # PsychoPy real-time scheduling privileges
  users.groups.psychopy = { };
  security.pam.loginLimits = [
    { domain = "@psychopy"; type = "-"; item = "nice";    value = "-20"; }
    { domain = "@psychopy"; type = "-"; item = "rtprio";  value = "50"; }
    { domain = "@psychopy"; type = "-"; item = "memlock"; value = "unlimited"; }
  ];

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

  # Virtualization - virt-manager + libvirtd
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
      vhostUserPackages = [ pkgs.virtiofsd ];
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  networking.firewall.trustedInterfaces = [ "virbr0" ];
  networking.extraHosts = ''
    192.168.122.195  jellyfin.nixflix sonarr.nixflix radarr.nixflix lidarr.nixflix prowlarr.nixflix seerr.nixflix qbittorrent.nixflix
  '';

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
    corefonts
    vista-fonts
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
    hyprsunset # night light toggle in the quickshell bar
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
    cifs-utils
    keyutils
    arduino-ide-with-extras
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
