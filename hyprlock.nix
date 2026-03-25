{ config, ... }:

let c = config.theme.colors; in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        ignore_empty_input = true;
      };

      background = [{
        monitor = "";
        color = c.hyprlockBg;
        blur_passes = 3;
      }];

      animations = {
        enabled = false;
      };

      input-field = [{
        monitor = "";
        size = "650, 100";
        position = "0, 0";
        halign = "center";
        valign = "center";
        inner_color = c.hyprlockBgInner;
        outer_color = c.hyprlockOuter;
        outline_thickness = 4;
        font_family = "TX02 Nerd Font";
        font_color = c.hyprlockFont;
        placeholder_text = "Enter Password";
        check_color = c.hyprlockCheck;
        fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
        rounding = 0;
        shadow_passes = 0;
        fade_on_empty = false;
      }];

      auth = {
        "fingerprint:enabled" = false;
      };
    };
  };
}
