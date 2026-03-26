{ pkgs, inputs, ... }:

let
  qmlFiles = {
    "quickshell/shell.qml"          = ./qml/shell.qml;
    "quickshell/Theme.qml"          = ./qml/Theme.qml;
    "quickshell/GlobalState.qml"    = ./qml/GlobalState.qml;
    "quickshell/Bar.qml"            = ./qml/Bar.qml;
    "quickshell/Workspaces.qml"     = ./qml/Workspaces.qml;
    "quickshell/Clock.qml"          = ./qml/Clock.qml;
    "quickshell/Battery.qml"        = ./qml/Battery.qml;
    "quickshell/Network.qml"        = ./qml/Network.qml;
    "quickshell/Bluetooth.qml"      = ./qml/Bluetooth.qml;
    "quickshell/Audio.qml"          = ./qml/Audio.qml;
    "quickshell/IdleIndicator.qml"  = ./qml/IdleIndicator.qml;
    "quickshell/NotifServer.qml"    = ./qml/NotifServer.qml;
    "quickshell/NotifPopup.qml"     = ./qml/NotifPopup.qml;
    "quickshell/Launcher.qml"       = ./qml/Launcher.qml;
    "quickshell/ControlCenter.qml"  = ./qml/ControlCenter.qml;
    "quickshell/AudioSlider.qml"    = ./qml/AudioSlider.qml;
    "quickshell/BluetoothPanel.qml" = ./qml/BluetoothPanel.qml;
    "quickshell/NetworkPanel.qml"   = ./qml/NetworkPanel.qml;
    "quickshell/Wallpaper.qml"      = ./qml/Wallpaper.qml;
    "quickshell/LockScreen.qml"     = ./qml/LockScreen.qml;
    "quickshell/PowerMenu.qml"      = ./qml/PowerMenu.qml;
  };
in
{
  home.packages = [
    pkgs.quickshell
  ];

  xdg.configFile = builtins.mapAttrs (name: source: {
    inherit source;
  }) qmlFiles;
}
