{ pkgs, inputs, ... }:

{
  home.packages = [
    pkgs.quickshell
  ];

  # Deploy the entire qml directory as one unit so all files share
  # the same Nix store path and QML can resolve sibling types.
  xdg.configFile."quickshell".source = ./qml;

  # EasyEffects EQ presets (XDG data dir, not config)
  xdg.dataFile."easyeffects/output/Flat.json".source = ./easyeffects/Flat.json;
  xdg.dataFile."easyeffects/output/BassBoost.json".source = ./easyeffects/BassBoost.json;
  xdg.dataFile."easyeffects/output/Rock.json".source = ./easyeffects/Rock.json;
  xdg.dataFile."easyeffects/output/Vocal.json".source = ./easyeffects/Vocal.json;
  xdg.dataFile."easyeffects/output/Treble.json".source = ./easyeffects/Treble.json;
  xdg.dataFile."easyeffects/output/Enhanced.json".source = ./easyeffects/Enhanced.json;

  # App list helper script used by the launcher
  home.file.".local/bin/qs-list-apps" = {
    source = ./list-apps.sh;
    executable = true;
  };
}
