{
  dark = {
    # Core palette (hex without #)
    bg = "282828";
    fg = "ebdbb2";
    accent = "d79921";
    red = "cc241d";
    green = "98971a";
    blue = "458588";
    purple = "b16286";
    aqua = "689d6a";
    orange = "d65d0e";
    gray = "928374";
    bg1 = "3c3836"; # inactive border / dark surface
    bg2 = "504945"; # selection background

    # Waybar (pre-formatted with opacity)
    waybarBg = "rgba(40, 40, 40, 0.9)";
    waybarBorder = "rgba(215, 153, 33, 0.5)";

    # Hyprlock variables
    hyprlockBg = "rgba(40,40,40, 1.0)";
    hyprlockBgInner = "rgba(40,40,40, 0.8)";
    hyprlockOuter = "rgba(215,153,33, 1.0)";
    hyprlockFont = "rgba(235,219,178, 1.0)";
    hyprlockCheck = "rgba(104,157,106, 1.0)";

    # GTK
    gtkTheme = "Gruvbox-Dark";
    gtkColorScheme = "prefer-dark";

    # Ghostty
    ghosttyBg = "282828";
    ghosttyFg = "ebdbb2";
    ghosttyCursor = "ebdbb2";
    ghosttySelBg = "504945";
    ghosttySelFg = "ebdbb2";
    ghosttyPalette = [
      "0=#282828" "1=#cc241d" "2=#98971a" "3=#d79921"
      "4=#458588" "5=#b16286" "6=#689d6a" "7=#a89984"
      "8=#928374" "9=#fb4934" "10=#b8bb26" "11=#fabd2f"
      "12=#83a598" "13=#d3869b" "14=#8ec07c" "15=#ebdbb2"
    ];

    # Zathura (pre-formatted rgba strings)
    zathura = {
      notifErrBg       = "rgba(50,48,47,1)";
      notifErrFg       = "rgba(251,73,52,1)";
      notifWarnBg      = "rgba(50,48,47,1)";
      notifWarnFg      = "rgba(250,189,47,1)";
      notifBg          = "rgba(50,48,47,1)";
      notifFg          = "rgba(184,187,38,1)";
      completionBg     = "rgba(80,73,69,1)";
      completionFg     = "rgba(235,219,178,1)";
      completionGrpBg  = "rgba(60,56,54,1)";
      completionGrpFg  = "rgba(146,131,116,1)";
      completionHighBg = "rgba(131,165,152,1)";
      completionHighFg = "rgba(80,73,69,1)";
      indexBg          = "rgba(80,73,69,1)";
      indexFg          = "rgba(235,219,178,1)";
      indexActiveBg    = "rgba(131,165,152,1)";
      indexActiveFg    = "rgba(80,73,69,1)";
      inputbarBg       = "rgba(50,48,47,1)";
      inputbarFg       = "rgba(235,219,178,1)";
      statusbarBg      = "rgba(80,73,69,1)";
      statusbarFg      = "rgba(235,219,178,1)";
      highlightColor   = "rgba(250,189,47,0.5)";
      highlightActive  = "rgba(254,128,25,0.5)";
      defaultBg        = "rgba(50,48,47,1)";
      defaultFg        = "rgba(235,219,178,1)";
      recolorLight     = "rgba(50,48,47,1)";
      recolorDark      = "rgba(235,219,178,1)";
    };
  };

  light = {
    bg = "fbf1c7";
    fg = "3c3836";
    accent = "b57614";
    red = "cc241d";
    green = "79740e";
    blue = "076678";
    purple = "8f3f71";
    aqua = "427b58";
    orange = "af3a03";
    gray = "7c6f64";
    bg1 = "d5c4a1";
    bg2 = "d5c4a1";

    waybarBg = "rgba(251, 241, 199, 0.9)";
    waybarBorder = "rgba(181, 118, 20, 0.5)";

    hyprlockBg = "rgba(251,241,199, 1.0)";
    hyprlockBgInner = "rgba(251,241,199, 0.8)";
    hyprlockOuter = "rgba(181,118,20, 1.0)";
    hyprlockFont = "rgba(60,56,54, 1.0)";
    hyprlockCheck = "rgba(66,123,88, 1.0)";

    gtkTheme = "Gruvbox-Light";
    gtkColorScheme = "prefer-light";

    ghosttyBg = "fbf1c7";
    ghosttyFg = "3c3836";
    ghosttyCursor = "3c3836";
    ghosttySelBg = "d5c4a1";
    ghosttySelFg = "3c3836";
    ghosttyPalette = [
      "0=#fbf1c7" "1=#cc241d" "2=#79740e" "3=#b57614"
      "4=#076678" "5=#8f3f71" "6=#427b58" "7=#7c6f64"
      "8=#928374" "9=#9d0006" "10=#79740e" "11=#b57614"
      "12=#076678" "13=#8f3f71" "14=#427b58" "15=#3c3836"
    ];

    zathura = {
      notifErrBg       = "rgba(251,241,199,1)";
      notifErrFg       = "rgba(157,0,6,1)";
      notifWarnBg      = "rgba(251,241,199,1)";
      notifWarnFg      = "rgba(181,118,20,1)";
      notifBg          = "rgba(251,241,199,1)";
      notifFg          = "rgba(121,116,14,1)";
      completionBg     = "rgba(213,196,161,1)";
      completionFg     = "rgba(60,56,54,1)";
      completionGrpBg  = "rgba(235,219,178,1)";
      completionGrpFg  = "rgba(124,111,100,1)";
      completionHighBg = "rgba(7,102,120,1)";
      completionHighFg = "rgba(213,196,161,1)";
      indexBg          = "rgba(213,196,161,1)";
      indexFg          = "rgba(60,56,54,1)";
      indexActiveBg    = "rgba(7,102,120,1)";
      indexActiveFg    = "rgba(213,196,161,1)";
      inputbarBg       = "rgba(251,241,199,1)";
      inputbarFg       = "rgba(60,56,54,1)";
      statusbarBg      = "rgba(213,196,161,1)";
      statusbarFg      = "rgba(60,56,54,1)";
      highlightColor   = "rgba(181,118,20,0.5)";
      highlightActive  = "rgba(175,58,3,0.5)";
      defaultBg        = "rgba(251,241,199,1)";
      defaultFg        = "rgba(60,56,54,1)";
      recolorLight     = "rgba(251,241,199,1)";
      recolorDark      = "rgba(60,56,54,1)";
    };
  };
}
