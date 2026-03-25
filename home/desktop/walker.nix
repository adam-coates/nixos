{ config, inputs, lib, ... }:

let
  gruvbox = import ../../modules/colorscheme/gruvbox.nix;

  mkCSS = c: ''
    @define-color base #${c.bg};
    @define-color text #${c.fg};
    @define-color border #${c.accent};
    @define-color surface #${c.bg1};
    @define-color selected-text #${c.accent};
    @define-color muted #${c.gray};

    * {
      all: unset;
    }

    * {
      font-family: "TX02 Nerd Font";
      font-size: 14px;
      color: @text;
    }

    scrollbar {
      opacity: 0;
    }

    .normal-icons {
      -gtk-icon-size: 16px;
    }

    .large-icons {
      -gtk-icon-size: 32px;
    }

    .box-wrapper {
      background: alpha(@base, 0.97);
      padding: 20px;
      border: 1px solid @border;
      border-radius: 12px;
    }

    .search-container {
      background: @surface;
      padding: 10px;
      border-radius: 6px;
    }

    .input placeholder {
      opacity: 0.5;
    }

    .input {
      color: @text;
      caret-color: @text;
    }

    .item-box {
      padding-left: 14px;
    }

    .item-text-box {
      padding: 10px 0;
    }

    .item-subtext {
      font-size: 11px;
      opacity: 0.6;
    }

    .item-image {
      margin-right: 10px;
    }

    child:selected .item-box {
      background: alpha(@border, 0.2);
      border-radius: 6px;
    }

    child:selected .item-box * {
      color: @selected-text;
    }
  '';
in
{
  imports = [ inputs.walker.homeManagerModules.default ];

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = if config.theme.dark then "gruvbox-dark" else "gruvbox-light";
      force_keyboard_focus = true;
      selection_wrap = true;
      placeholders.default = { input = " Search..."; list = "No Results"; };
    };

    themes = {
      gruvbox-dark.style  = mkCSS gruvbox.dark;
      gruvbox-light.style = mkCSS gruvbox.light;
    };
  };
}
