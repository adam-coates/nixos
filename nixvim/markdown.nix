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
        legacy_commands = false;
        notes_subdir = "00 - Inbox";
        attachments.folder = "999-extra/images";
        new_notes_location = "notes_subdir";
        link.style = "markdown";
        frontmatter = {
          enabled = true;
          sort = [ "title" "tags" "date" "location" ];
          func.__raw = ''
            function(note)
              local out = {}
        
              -- Always keep title in YAML.
              -- Prefer explicit metadata title from the template, otherwise fall back to note.title.
              out.title = (note.metadata and note.metadata.title) or note.title or note.id
        
              -- Always keep tags in YAML, even if empty.
              out.tags = note.tags or {}
        
              -- Preserve any other metadata fields from the template/manual YAML.
              if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                for k, v in pairs(note.metadata) do
                  if k ~= "title" then
                    out[k] = v
                  end
                end
              end
        
              return out
            end
          '';
        };
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
