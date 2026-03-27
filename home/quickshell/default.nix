{ pkgs, inputs, ... }:

{
  home.packages = [
    pkgs.quickshell
  ];

  # Deploy the entire qml directory as one unit so all files share
  # the same Nix store path and QML can resolve sibling types.
  xdg.configFile."quickshell".source = ./qml;

  # App list helper script used by the launcher
  home.file.".local/bin/qs-list-apps" = {
    source = ./list-apps.sh;
    executable = true;
  };
}
