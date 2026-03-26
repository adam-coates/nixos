{ pkgs, inputs, ... }:

let
  qmlFiles = {
    "quickshell/shell.qml"                            = ./qml/shell.qml;
    "quickshell/Theme.qml"                             = ./qml/Theme.qml;
    "quickshell/GlobalState.qml"                       = ./qml/GlobalState.qml;
    "quickshell/bar/Bar.qml"                           = ./qml/bar/Bar.qml;
    "quickshell/bar/Workspaces.qml"                    = ./qml/bar/Workspaces.qml;
    "quickshell/bar/Clock.qml"                         = ./qml/bar/Clock.qml;
    "quickshell/bar/Battery.qml"                       = ./qml/bar/Battery.qml;
    "quickshell/bar/Network.qml"                       = ./qml/bar/Network.qml;
    "quickshell/bar/Bluetooth.qml"                     = ./qml/bar/Bluetooth.qml;
    "quickshell/bar/Audio.qml"                         = ./qml/bar/Audio.qml;
    "quickshell/bar/IdleIndicator.qml"                 = ./qml/bar/IdleIndicator.qml;
    "quickshell/notifications/NotificationServer.qml"  = ./qml/notifications/NotificationServer.qml;
    "quickshell/notifications/NotificationPopup.qml"   = ./qml/notifications/NotificationPopup.qml;
    "quickshell/launcher/Launcher.qml"                 = ./qml/launcher/Launcher.qml;
    "quickshell/controlcenter/ControlCenter.qml"       = ./qml/controlcenter/ControlCenter.qml;
    "quickshell/controlcenter/AudioSlider.qml"         = ./qml/controlcenter/AudioSlider.qml;
    "quickshell/controlcenter/BluetoothPanel.qml"      = ./qml/controlcenter/BluetoothPanel.qml;
    "quickshell/controlcenter/NetworkPanel.qml"        = ./qml/controlcenter/NetworkPanel.qml;
    "quickshell/wallpaper/Wallpaper.qml"               = ./qml/wallpaper/Wallpaper.qml;
    "quickshell/lock/Lock.qml"                         = ./qml/lock/Lock.qml;
    "quickshell/powermenu/PowerMenu.qml"               = ./qml/powermenu/PowerMenu.qml;
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
