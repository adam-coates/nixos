{ pkgs, ... }:

# Joplin keeps its own settings.json and rewrites it constantly, so the
# home-manager module jq-merges the values below into whatever is already
# there rather than replacing the file. Anything not declared here stays
# imperative and survives a rebuild:
#
#   - api.token          secret, must not live in the repo
#   - ui.layout          panel widths, changes every time you drag a divider
#   - noteVisiblePanes   toggled by keyboard shortcut
#   - plugins            installed/updated from the plugin manager
#
# Profile lives at ~/.config/joplin-desktop (the module hardcodes that path).
#
# nixpkgs tracks the stable channel (3.6.x, built from source). We want the
# prerelease channel instead, so the package below wraps the official
# prerelease AppImage from GitHub. Bumping it means changing `version` and
# `hash` here — get the new hash with:
#
#   nix store prefetch-file https://github.com/laurent22/joplin/releases/download/vX.Y.Z/Joplin-X.Y.Z.AppImage
#
# Latest prerelease tag: https://github.com/laurent22/joplin/releases
let
  version = "3.7.10";

  src = pkgs.fetchurl {
    url = "https://github.com/laurent22/joplin/releases/download/v${version}/Joplin-${version}.AppImage";
    hash = "sha256-v/1C7mw5RberJL7oVZLf8kcw1iGFxwZcJ+ZJgn2qBRQ=";
  };

  # Unpacked AppImage, used only to lift out the .desktop file and icons.
  contents = pkgs.appimageTools.extract {
    pname = "joplin-desktop";
    inherit version src;
  };

  joplin-prerelease = pkgs.appimageTools.wrapType2 {
    pname = "joplin-desktop";
    inherit version src;

    extraInstallCommands = ''
      install -Dm644 ${contents}/appimagekit-joplin.desktop \
        $out/share/applications/joplin.desktop
      substituteInPlace $out/share/applications/joplin.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=joplin-desktop'

      for icon in ${contents}/usr/share/icons/hicolor/*/apps/joplin.png; do
        resolution=$(basename "$(dirname "$(dirname "$icon")")")
        install -Dm644 "$icon" \
          "$out/share/icons/hicolor/$resolution/apps/joplin.png"
      done
    '';

    meta = {
      description = "Note taking and to-do application with synchronisation capabilities (prerelease)";
      homepage = "https://joplinapp.org";
      license = pkgs.lib.licenses.agpl3Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "joplin-desktop";
    };
  };
in
{
  programs.joplin-desktop = {
    enable = true;
    package = joplin-prerelease;

    # Self-hosted Joplin Server (see ~/joplin flake).
    sync.target = "joplin-server";

    extraConfig = {
      "sync.9.path" = "https://joplin.home.adamcoates.at";
      "sync.9.username" = "admin@localhost";

      "locale" = "en_US";

      # Dark only — the gruvbox theme plugin (com.adamcoates.gruvbox) is
      # dark-only, so don't let this follow the light specialisation.
      "theme" = 2;
      "themeAutoDetect" = false;

      "editor.codeView" = true;
      "markdown.plugin.softbreaks" = false;
      "markdown.plugin.typographer" = false;

      "notes.sortOrder.field" = "todo_due";
      "notes.sortOrder.reverse" = true;

      "spellChecker.languages" = [ "en-US" ];
    };
  };
}
