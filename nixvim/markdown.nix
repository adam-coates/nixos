{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    render-markdown = {
      enable = true;
      settings = {
        file_types = [
          "markdown"
          "quarto"
        ];
        heading = {
          enabled = true;
          sign = true;
          position = "overlay";
          icons = [
            "󰲡 "
            "󰲣 "
            "󰲥 "
            "󰲧 "
            "󰲩 "
            "󰲫 "
          ];
          signs = [ "󰫎 " ];
          width = "full";
          left_margin = 0;
          left_pad = 0;
          right_pad = 0;
          min_width = 0;
          border = false;
          border_virtual = false;
          border_prefix = false;
          above = "▄";
          below = "▀";
          backgrounds = [
            "RenderMarkdownH1Bg"
            "RenderMarkdownH2Bg"
            "RenderMarkdownH3Bg"
            "RenderMarkdownH4Bg"
            "RenderMarkdownH5Bg"
            "RenderMarkdownH6Bg"
          ];
          foregrounds = [
            "RenderMarkdownH1"
            "RenderMarkdownH2"
            "RenderMarkdownH3"
            "RenderMarkdownH4"
            "RenderMarkdownH5"
            "RenderMarkdownH6"
          ];
        };
        code.disable_background = [ 1 ];
        quote = {
          enabled = true;
          highlight = "fffcfc";
        };
      };
    };

    obsidian = {
      enable = true;
      package = pkgs.vimPlugins.obsidian-nvim.overrideAttrs {
        version = "3.16.4";
        src = pkgs.fetchFromGitHub {
          owner = "obsidian-nvim";
          repo = "obsidian.nvim";
          rev = "v3.16.4";
          hash = "sha256-9Su5t8cJAHlXV+EE4GLa1+BhezfHZIZgl2P6kBrkX8E=";
        };
      };
      settings = {
        workspaces = [
          {
            name = "notes";
            path = "~/notes";
          }
        ];
        open_notes_in = "vsplit";
        ui.enable = false;
        completion = {
          min_chars = 2;
        };
        templates = {
          folder = "999-extra/Templates";
          date_format = "%d-%m-%Y";
          substitutions = {
            citation_title = {
              __raw = ''
                function()
                  vim.cmd("FindCitation")
                end
              '';
            };
          };
        };
        note_id_func = {
          __raw = ''
            function(title)
              if title then
                return title
              else
                local suffix = ""
                for _ = 1, 4 do
                  suffix = suffix .. string.char(math.random(65, 90))
                end
                return "untitled_" .. suffix
              end
            end
          '';
        };
        legacy_commands = false;
        notes_subdir = "00 - Inbox";
        attachments.folder = "999-extra/images";
        new_notes_location = "notes_subdir";
        link.style = "markdown";
        frontmatter = {
          enabled = false;
        };
        footer = {
          enabled = true;
          separator = "";
          format = "{{backlinks}} backlinks";
        };
        daily_notes = {
          enabled = true;
          folder = "03 - Logs/Daily";
          date_format = "YYYY-MM-DD";
          default_tags = [ "Daily" ];
          workdays_only = false;
          template = "999-extra/Templates/daily.md";
        };
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>os";
      action = ":Obsidian search<cr>";
      options.desc = "Obsidian Search";
    }
  ];

  # NOTE: the <C-f> "create Obsidian figure" mapping lives in autocmds.nix --
  # it used to be defined here as well, registering the same FileType autocmd
  # twice.
}
