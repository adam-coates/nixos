{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    render-markdown = {
      enable = true;
      settings = {
        file_types = [
          "markdown"
          "quarto"
          "Avante"
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
          nvim_cmp = true;
          blink = false;
          min_chars = 2;
        };
        templates = {
          enabled = true;
          folder = "999-extra/Templates";
          date_format = "%Y-%m-%d";
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
        note = {
          template = "note.md";
          id_func = {
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
        };

        legacy_commands = false;
        notes_subdir = "00 - Inbox";
        attachments.folder = "999-extra/images";
        new_notes_location = "notes_subdir";
        link.style = "markdown";
        frontmatter = {
          enabled = true;
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

  programs.nixvim.extraConfigLuaPost = ''
    local function create_obsidian_figure()
      local line = vim.fn.trim(vim.api.nvim_get_current_line())
      if line == "" then
        vim.notify("Type figure name on current line first", vim.log.levels.WARN)
        return
      end
      local result = vim.fn.system('obsidian-inkscape "' .. line .. '"')
      if vim.v.shell_error ~= 0 then
        vim.notify("Error creating figure: " .. result, vim.log.levels.ERROR)
        return
      end
      local markdown_link = vim.fn.trim(result)
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(0, row - 1, row, false, { markdown_link })
      vim.notify("Figure created: " .. line, vim.log.levels.INFO)
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        vim.keymap.set(
          { "i", "n" },
          "<C-f>",
          create_obsidian_figure,
          { buffer = true, desc = "Create Obsidian figure" }
        )
      end,
    })
  '';
}
