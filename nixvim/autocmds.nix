{ ... }:

{
  programs.nixvim.autoCmd = [
    # Highlight yanked text
    {
      event = [ "TextYankPost" ];
      desc = "Highlight when yanking (copying) text";
      group = "kickstart-highlight-yank";
      callback.__raw = ''
        function()
          vim.highlight.on_yank()
        end
      '';
    }

    # Obsidian figure creation for markdown files
    {
      event = [ "FileType" ];
      pattern = [ "markdown" ];
      callback.__raw = ''
        function()
          vim.keymap.set({ "i", "n" }, "<C-f>", function()
            local line = vim.api.nvim_get_current_line():match("^%%s*(.-)%%s*$")
            if line == "" then
              vim.notify("Type figure name on current line first", vim.log.levels.WARN)
              return
            end
            local result = vim.fn.system('obsidian-inkscape "' .. line .. '"')
            if vim.v.shell_error ~= 0 then
              vim.notify("Error creating figure: " .. result, vim.log.levels.ERROR)
              return
            end
            local markdown_link = result:gsub("%%s+$", "")
            local row = vim.api.nvim_win_get_cursor(0)[1]
            vim.api.nvim_buf_set_lines(0, row - 1, row, false, { markdown_link })
            vim.notify("Figure created: " .. line, vim.log.levels.INFO)
          end, { buffer = true, desc = "Create Obsidian figure" })
        end
      '';
    }

    # Markdown/quarto wrap settings
    {
      event = [ "FileType" ];
      pattern = [ "markdown" "quarto" ];
      callback.__raw = ''
        function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
        end
      '';
    }
  ];

  programs.nixvim.autoGroups = {
    "kickstart-highlight-yank" = { clear = true; };
  };
}
