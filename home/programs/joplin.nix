{ ... }:

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
{
  programs.joplin-desktop = {
    enable = true;

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
