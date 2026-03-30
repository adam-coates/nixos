{ pkgs, inputs, ... }:

let
  emojiData = pkgs.runCommand "emoji-data" {} ''
    ${pkgs.gnugrep}/bin/grep "; fully-qualified" \
      ${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt | \
      ${pkgs.gnused}/bin/sed 's/.*# //' | \
      ${pkgs.gnused}/bin/sed 's/ E[0-9.]* /\t/' > $out
  '';

  listAudioProfiles = pkgs.runCommand "qs-list-audio-profiles" {} ''
    substitute ${./list-audio-profiles.sh} $out \
      --replace-fail "@jq@" "${pkgs.jq}/bin/jq"
    chmod +x $out
  '';

  magicpodscore = pkgs.stdenv.mkDerivation {
    pname = "magicpodscore";
    version = "2.0.7";
    src = pkgs.fetchurl {
      url = "https://github.com/steam3d/MagicPodsCore/releases/download/2.0.7/magicpodscore_2.0.7.zip";
      hash = "sha256-XiobmMWYw6cY/UFRnzubk5lyBIZKbRFJGg8+tzbVu2g=";
    };
    nativeBuildInputs = [ pkgs.unzip pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.bluez
      pkgs.openssl
      pkgs.libpulseaudio
      pkgs.systemd
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib
    ];
    sourceRoot = ".";
    unpackPhase = ''
      unzip $src
    '';
    installPhase = ''
      install -Dm755 magicpodscore $out/bin/magicpodscore
    '';
  };

  getBudsBattery = pkgs.runCommand "qs-get-buds-battery" {} ''
    substitute ${./get-buds-battery.sh} $out \
      --replace-fail "@websocat@" "${pkgs.websocat}/bin/websocat"
    chmod +x $out
  '';

  whisperModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin";
    hash = "sha256-xhONbVjsyDIgl+D5h8MvG+i7ChhTKj+I9zTRu/nEHl0=";
  };
in
{
  home.packages = [
    pkgs.quickshell
    magicpodscore
  ];

  # Deploy the entire qml directory as one unit so all files share
  # the same Nix store path and QML can resolve sibling types.
  xdg.configFile."quickshell".source = ./qml;

  # Emoji data for the emoji picker
  xdg.dataFile."quickshell/emojis.txt".source = emojiData;

  # Whisper model for voxtype dictation
  xdg.dataFile."voxtype/models/ggml-small.en.bin".source = whisperModel;

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

  # Audio profile listing script
  home.file.".local/bin/qs-list-audio-profiles" = {
    source = listAudioProfiles;
    executable = true;
  };

  # Bluetooth earbuds battery query script
  home.file.".local/bin/qs-get-buds-battery" = {
    source = getBudsBattery;
    executable = true;
  };
}
