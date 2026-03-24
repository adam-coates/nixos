{ config, inputs, ... }:

let
  c = config.theme.colors;
in
{
  imports = [ inputs.walker.homeManagerModules.default ];

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = if config.theme.dark then "gruvbox-dark" else "gruvbox-light";
      placeholder = "Search...";
    };

    themes = {
      gruvbox-dark = {
        style = ''
          * {
            font-family: "TX02 Nerd Font";
            font-size: 13px;
            color: #${c.fg};
          }

          #window {
            background: #${c.bg};
            border: 1px solid #${c.accent};
            border-radius: 12px;
          }

          #box {
            padding: 12px;
          }

          #search {
            background: #${c.bg1};
            border: 1px solid #${c.bg2};
            border-radius: 6px;
            padding: 8px 12px;
            margin-bottom: 8px;
            color: #${c.fg};
          }

          #search:focus {
            border-color: #${c.accent};
          }

          #list {
            background: transparent;
          }

          row {
            border-radius: 6px;
            padding: 4px 8px;
          }

          row:selected {
            background: #${c.bg2};
            color: #${c.accent};
          }

          .icon {
            margin-right: 10px;
          }

          .label {
            color: #${c.fg};
          }

          row:selected .label {
            color: #${c.accent};
          }

          .sub {
            color: #${c.gray};
            font-size: 11px;
          }
        '';
      };

      gruvbox-light = {
        style = ''
          * {
            font-family: "TX02 Nerd Font";
            font-size: 13px;
            color: #${c.fg};
          }

          #window {
            background: #${c.bg};
            border: 1px solid #${c.accent};
            border-radius: 12px;
          }

          #box {
            padding: 12px;
          }

          #search {
            background: #${c.bg1};
            border: 1px solid #${c.bg2};
            border-radius: 6px;
            padding: 8px 12px;
            margin-bottom: 8px;
            color: #${c.fg};
          }

          #search:focus {
            border-color: #${c.accent};
          }

          #list {
            background: transparent;
          }

          row {
            border-radius: 6px;
            padding: 4px 8px;
          }

          row:selected {
            background: #${c.bg2};
            color: #${c.accent};
          }

          .icon {
            margin-right: 10px;
          }

          .label {
            color: #${c.fg};
          }

          row:selected .label {
            color: #${c.accent};
          }

          .sub {
            color: #${c.gray};
            font-size: 11px;
          }
        '';
      };
    };
  };
}
