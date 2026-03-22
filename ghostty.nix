{ config, pkgs, lib, ... }:

{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      font-family = "TX02 Nerd Font";
      font-size = 13;
      window-padding-x = 10;
      window-padding-y = 10;
      cursor-style = "bar";
      cursor-style-blink = true;
      shell-integration-features = "no-cursor";
      window-decoration = false;
      background-opacity = 0.95;
      # Theme colors are loaded from this generated file
      config-file = "~/.config/ghostty/theme.conf";
    };
  };

  # Generated from theme.colors — updated on every nixos-rebuild
  xdg.configFile."ghostty/theme.conf".text =
    let c = config.theme.colors; in ''
      background = #${c.ghosttyBg}
      foreground = #${c.ghosttyFg}
      cursor-color = #${c.ghosttyCursor}
      selection-background = #${c.ghosttySelBg}
      selection-foreground = #${c.ghosttySelFg}
      ${lib.concatStringsSep "\n" (map (p: "palette = ${p}") c.ghosttyPalette)}
    '';
}
