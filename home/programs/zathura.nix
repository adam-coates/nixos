{ config, ... }:

let
  c = config.theme.colors;
  z = c.zathura;
in
{
  programs.zathura = {
    enable = true;

    mappings = {
      u = "scroll half-up";
      d = "scroll half-down";
      D = "toggle_page_mode";
      r = "reload";
      R = "rotate";
      K = "zoom in";
      J = "zoom out";
      i = "recolor";
      p = "print";
    };

    options = {
      selection-clipboard = "clipboard";
      render-loading = true;
      adjust-open = "best-fit";
      pages-per-row = 1;
      scroll-step = 50;

      notification-error-bg = z.notifErrBg;
      notification-error-fg = z.notifErrFg;
      notification-warning-bg = z.notifWarnBg;
      notification-warning-fg = z.notifWarnFg;
      notification-bg = z.notifBg;
      notification-fg = z.notifFg;
      completion-bg = z.completionBg;
      completion-fg = z.completionFg;
      completion-group-bg = z.completionGrpBg;
      completion-group-fg = z.completionGrpFg;
      completion-highlight-bg = z.completionHighBg;
      completion-highlight-fg = z.completionHighFg;
      index-bg = z.indexBg;
      index-fg = z.indexFg;
      index-active-bg = z.indexActiveBg;
      index-active-fg = z.indexActiveFg;
      inputbar-bg = z.inputbarBg;
      inputbar-fg = z.inputbarFg;
      statusbar-bg = z.statusbarBg;
      statusbar-fg = z.statusbarFg;
      highlight-color = z.highlightColor;
      highlight-active-color = z.highlightActive;
      default-bg = z.defaultBg;
      default-fg = z.defaultFg;
      render-loading-bg = z.defaultBg;
      render-loading-fg = z.defaultFg;
      recolor-lightcolor = z.recolorLight;
      recolor-darkcolor = z.recolorDark;
      recolor = false;
      recolor-keephue = false;
    };
  };
}
