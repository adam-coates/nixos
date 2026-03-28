{ pkgs, inputs, ... }:

{
  home.packages = [
    pkgs.quickshell
  ];

  # Deploy the entire qml directory as one unit so all files share
  # the same Nix store path and QML can resolve sibling types.
  xdg.configFile."quickshell".source = ./qml;

  # EasyEffects EQ presets
  xdg.configFile."easyeffects/output/Flat.json".source = ./easyeffects/Flat.json;
  xdg.configFile."easyeffects/output/BassBoost.json".source = ./easyeffects/BassBoost.json;
  xdg.configFile."easyeffects/output/Rock.json".source = ./easyeffects/Rock.json;
  xdg.configFile."easyeffects/output/Vocal.json".source = ./easyeffects/Vocal.json;
  xdg.configFile."easyeffects/output/Treble.json".source = ./easyeffects/Treble.json;

  # App list helper script used by the launcher
  home.file.".local/bin/qs-list-apps" = {
    source = ./list-apps.sh;
    executable = true;
  };
}
