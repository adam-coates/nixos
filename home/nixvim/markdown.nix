{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    render-markdown = {
      enable = true;
      settings = {
        file_types = [ "markdown" "quarto" "Avante" ];
        heading = {
          enabled = true;
          sign = true;
          position = "overlay";
          icons = [ "󰲡 " "󰲣 " "󰲥 " "󰲧 " "󰲩 " "󰲫 " ];
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
      settings = {
        workspaces = [
          { name = "notes"; path = "~/notes"; }
        ];
        open_notes_in = "vsplit";
        ui.enable = false;
        completion = {
          nvim_cmp = true;
          blink = false;
          min_chars = 2;
        };
        templates = {
          folder = "999-extra/Templates";
          date_format = "%Y-%m-%d";
        };
        notes_subdir = "00 - Inbox";
        attachments.folder = "999-extra/images";
        new_notes_location = "notes_subdir";
        preferred_link_style = "markdown";
        frontmatter.enabled = false;
        note_id_func.__raw = ''
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
    { mode = "n"; key = "<leader>os"; action = ":Obsidian search<cr>"; options.desc = "Obsidian Search"; }
  ];
}
