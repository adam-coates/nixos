{
  config,
  pkgs,
  lib,
  ...
}:
{
  # =============================================================================
  # AMD GPU DRIVER
  # =============================================================================
  # amdgpu is the open-source kernel driver — works out of box on NixOS
  # No explicit config needed for desktop AMD GPUs (auto-detected)
  # Your GPU: RX 6800/6900 XT at PCI:13:0:0 (0d:00.0)

  # =============================================================================
  # GRAPHICS / OPENGL (NEW API — hardware.opengl is DEPRECATED)
  # =============================================================================
  hardware.graphics = {
    enable = true;       # OpenGL support
    enable32Bit = true;  # 32-bit libs for Wine/Proton games

    # 64-bit graphics packages
    extraPackages = with pkgs; [
      # mesa: OpenGL/Vulkan implementation (RADV for AMD)
      # - Provides libGL.so, libvulkan_radeon.so
      # - RADV is the default and best Vulkan driver for AMD
      mesa

      # vulkan-loader: Vulkan ICD loader
      # - Routes Vulkan calls to correct driver (mesa's RADV)
      # - Required for any Vulkan game
      vulkan-loader
    ];

    # 32-bit packages (Wine/Proton games are often 32-bit)
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
    ];
  };

  # =============================================================================
  # STEAM
  # =============================================================================
  programs.steam = {
    enable = true;

    # Remote play ports
    remotePlay.openFirewall = true;

    # Dedicated server ports (if hosting)
    dedicatedServer.openFirewall = true;

    # Extra packages available to Steam/Proton
    extraPackages = with pkgs; [
      # gamemode integration
      gamemode
    ];

    # -------------------------------------------------------------------------
    # gamescopeSession — CAREFUL WITH THIS
    # -------------------------------------------------------------------------
    # What it does:
    #   Creates a separate "Steam + Gamescope" session in your display manager
    #   Boots directly into Steam Big Picture inside gamescope compositor
    #   Bypasses your normal desktop entirely (Hyprland)
    #
    # Pros:
    #   - Lower latency (no compositor overhead)
    #   - Better VRR/FreeSync control
    #   - Console-like experience
    #   - FSR upscaling built-in
    #
    # Cons:
    #   - REPLACES your desktop session (no Hyprland access while gaming)
    #   - Can cause login issues (black screen, session crash)
    #   - Harder to alt-tab to browser/Discord
    #   - Some games don't like nested compositors
    #   - Debugging is harder (no terminal access)
    #
    # Recommendation: Leave DISABLED. Use gamescope manually per-game instead.
    # Enable only if building a dedicated gaming/TV setup.
    # -------------------------------------------------------------------------
    gamescopeSession.enable = false;  # Set true only if you want SteamDeck-like session
  };

  # =============================================================================
  # GAMESCOPE — Valve's micro-compositor
  # =============================================================================
  # What: Nested Wayland compositor that wraps a single game
  # Why:  Provides FSR upscaling, frame limiting, VRR, resolution scaling
  #
  # Usage (in Steam launch options):
  #   gamescope -W 2560 -H 1440 -f -- %command%
  #
  # Common flags:
  #   -W/-H         Output resolution (your monitor)
  #   -w/-h         Game render resolution (for FSR upscaling)
  #   -f            Fullscreen
  #   -F fsr        Enable FSR upscaling
  #   -r 144        Limit framerate
  #   --adaptive-sync  Enable VRR/FreeSync
  #
  # Example: Render at 1080p, upscale to 1440p with FSR, cap 144fps
  #   gamescope -W 2560 -H 1440 -w 1920 -h 1080 -F fsr -r 144 -f -- %command%
  #
  # Pros:
  #   - FSR upscaling (play at lower res, get higher performance)
  #   - Frame limiting without in-game settings
  #   - Better VRR handling than some games
  #   - Isolates game in its own compositor (stability)
  #
  # Cons:
  #   - Some games have issues (stuttering, input lag)
  #   - Extra layer = potential bugs
  #   - Wayland-only (you're on Hyprland, so fine)
  programs.gamescope = {
    enable = true;
    capSysNice = true;  # Allow gamescope to set higher process priority
  };

  # =============================================================================
  # GAMEMODE — Feral Interactive's performance optimizer
  # =============================================================================
  # What: Daemon that applies system optimizations while games run
  # Why:  Squeezes extra FPS by tuning CPU governor, I/O priority, etc.
  #
  # What it does when activated:
  #   - Sets CPU governor to "performance" (higher clocks)
  #   - Adjusts I/O priority for game process
  #   - Applies GPU performance mode (via sysfs)
  #   - Optionally runs custom scripts (start/end)
  #   - Inhibits screen saver
  #
  # Usage (in Steam launch options):
  #   gamemoderun %command%
  #
  # Or combine with gamescope:
  #   gamemoderun gamescope -W 2560 -H 1440 -f -- %command%
  #
  # Verify it's working:
  #   gamemoded -s        # Check if daemon is running
  #   gamemoded -t        # Test activation
  #
  # Pros:
  #   - 5-15% FPS improvement in CPU-bound games
  #   - No permanent system changes (reverts when game exits)
  #   - Works with any game (Steam, Lutris, native)
  #
  # Cons:
  #   - Higher power consumption while active
  #   - Laptop users: may increase heat/fan noise
  #   - Minimal benefit if already GPU-bound
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;  # Give game higher priority (-10 nice value)
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;  # First GPU (your RX 6800/6900)
      };
      custom = {
        # Optional: run commands on game start/stop
        # start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Started'";
        # end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Stopped'";
      };
    };
  };

  # =============================================================================
  # MANGOHUD — Performance overlay (like MSI Afterburner)
  # =============================================================================
  # What: HUD overlay showing FPS, frametime, CPU/GPU temps, VRAM, etc.
  # Why:  Monitor performance, identify bottlenecks
  #
  # Usage (in Steam launch options):
  #   mangohud %command%
  #
  # Or combine with everything:
  #   gamemoderun mangohud gamescope -W 2560 -H 1440 -f -- %command%
  #
  # Configure via ~/.config/MangoHud/MangoHud.conf or env vars:
  #   MANGOHUD_CONFIG="fps,frametime,gpu_temp,cpu_temp"
  #
  # Toggle visibility in-game: Right Shift + F12 (default)
  #
  # Useful config options:
  #   fps             Show FPS
  #   frametime       Show frame time graph
  #   gpu_temp        GPU temperature
  #   cpu_temp        CPU temperature
  #   vram            VRAM usage
  #   ram             RAM usage
  #   cpu_load        CPU load per core
  #   gpu_load        GPU utilization
  #   position=top-left  HUD position

  # =============================================================================
  # SYSTEM PACKAGES — Gaming tools
  # =============================================================================
  environment.systemPackages = with pkgs; [
    # MangoHud — performance overlay
    mangohud

    # ProtonUp-Qt — install custom Proton versions (GE-Proton, etc.)
    # GE-Proton often has better compatibility than Valve's Proton
    protonup-qt

    # Vulkan tools — debugging/info
    vulkan-tools        # vulkaninfo, vkcube
    vulkan-validation-layers

    # DXVK/VKD3D for Wine (Proton includes these, but useful for Lutris)
    dxvk
    vkd3d

    # Alternative launchers (optional)
    # lutris            # Multi-platform game launcher
    # heroic            # Epic/GOG launcher
    # bottles           # Wine prefix manager

    # Monitoring
    radeontop           # AMD GPU monitoring (like nvidia-smi)
    lact                # AMD GPU control panel (clocks, fan curves)
  ];

  # =============================================================================
  # QUICK REFERENCE — Steam Launch Options
  # =============================================================================
  #
  # Basic (just run the game):
  #   %command%
  #
  # With GameMode (performance boost):
  #   gamemoderun %command%
  #
  # With MangoHud (FPS overlay):
  #   mangohud %command%
  #
  # With Gamescope (FSR, frame limit):
  #   gamescope -W 2560 -H 1440 -f -- %command%
  #
  # Full stack (all optimizations):
  #   gamemoderun mangohud gamescope -W 2560 -H 1440 -f -- %command%
  #
  # FSR upscaling (render 1080p → display 1440p):
  #   gamemoderun mangohud gamescope -W 2560 -H 1440 -w 1920 -h 1080 -F fsr -f -- %command%
  #
  # =============================================================================
  # AMD-SPECIFIC ENVIRONMENT VARIABLES
  # =============================================================================
  #
  # Force RADV (mesa) over AMDVLK:
  #   AMD_VULKAN_ICD=RADV %command%
  #
  # Enable ACO shader compiler (faster shader compilation):
  #   RADV_PERFTEST=aco %command%   # Usually default now
  #
  # Mesa debug/performance:
  #   MESA_DEBUG=1 %command%        # Debug output
  #   mesa_glthread=true %command%  # Threaded GL (can help older OpenGL games)
  #
  # =============================================================================
}
