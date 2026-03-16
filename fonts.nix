{ config, pkgs, lib, ... }:

let
  mkFont = { pname, version, url, sha256 }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit pname version;
      src = pkgs.fetchzip {
        inherit url sha256;
        stripRoot = false;
      };
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        find . \( -name '*.ttf' -o -name '*.otf' \) -print0 \
          | xargs -0 cp -t $out/share/fonts/truetype/
      '';
      meta = with lib; {
        platforms = platforms.all;
      };
    };

  font1 = mkFont {
    pname = "font1";
    version = "1.0";
    url = "https://fonts.adamcoates.at/font1.zip";
    sha256 = "sha256-VkuxfWOkzxe9cABPtIowpM5Oklm/BuPixHBWpiFlixM=";
  };

  font2 = mkFont {
    pname = "font2";
    version = "1.0";
    url = "https://fonts.adamcoates.at/font2.zip";
    sha256 = "sha256-hfnu/JMxTdAbZWdDj5Mcj0bSw1CSmIqkJXAksZBzJoE=";
  };

in {
  fonts.packages = [ font1 font2 ];
}
