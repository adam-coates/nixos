{ ... }:

{
  programs.nixvim.plugins.telescope = {
    enable = true;

    extensions = {
      fzf-native.enable = true;
      ui-select.enable = true;
    };

    settings = {
      defaults = {
        path_display = [ "truncate" ];
        layout_strategy = "horizontal";
        mappings.i = {
          "__rawKey__['<C-k>']".__raw = "require('telescope.actions').move_selection_previous";
          "__rawKey__['<C-j>']".__raw = "require('telescope.actions').move_selection_next";
          "__rawKey__['<C-q>']".__raw = "require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist";
        };
      };
    };

    keymaps = {
      "<leader>ff" = { action = "find_files"; options.desc = "Fuzzy find files in cwd"; };
      "<leader>fr" = { action = "oldfiles"; options.desc = "Find recent files"; };
      "<leader>fs" = { action = "live_grep"; options.desc = "Find string in cwd"; };
      "<leader>fc" = { action = "grep_string"; options.desc = "Find string under cursor in cwd"; };
      "<leader>fb" = { action = "buffers"; options.desc = "Find open buffers"; };
    };
  };

  # Obsidian notes grep
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>oz";
      action = ":Telescope live_grep search_dirs={\"/home/adam/notes\"}<cr>";
      options.desc = "grep notes";
    }
  ];
}
