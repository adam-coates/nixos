{ pkgs, inputs, ... }:

let
  emojiData = pkgs.runCommand "emoji-data" {} ''
    ${pkgs.gnugrep}/bin/grep "; fully-qualified" \
      ${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt | \
      ${pkgs.gnused}/bin/sed 's/.*# //' | \
      ${pkgs.gnused}/bin/sed 's/ E[0-9.]* /\t/' > $out
  '';

  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
    hash = "sha256-oDd5yG3zMjB19eeWyyzlAp8A7Ihp7uP9+4l6/jbG0AI=";
  };
in
{
  home.packages = [
    pkgs.quickshell
  ];

  # Deploy the entire qml directory as one unit so all files share
  # the same Nix store path and QML can resolve sibling types.
  xdg.configFile."quickshell".source = ./qml;

  # Emoji data for the emoji picker
  xdg.dataFile."quickshell/emojis.txt".source = emojiData;

  # Whisper model for voxtype dictation
  xdg.dataFile."voxtype/models/ggml-base.en.bin".source = whisperModel;

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
