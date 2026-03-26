{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    nvim-tree = {
      enable = true;
      settings = {
        view = {
          width = 50;
          relativenumber = true;
        };
        renderer = {
          indent_markers.enable = true;
          icons.glyphs.folder = {
            arrow_closed = "";
            arrow_open = "";
          };
        };
        actions.open_file.window_picker.enable = false;
        filters.custom = [ ".DS_Store" ];
        git.ignore = false;
      };
    };

    which-key = {
      enable = true;
      settings = {
        preset = "classic";
        spec = [
          { __unkeyed-1 = "<leader>c"; group = "Code"; }
          { __unkeyed-1 = "<leader>e"; group = "File Explorer"; }
          { __unkeyed-1 = "<leader>f"; group = "Find Files"; }
          { __unkeyed-1 = "<leader>r"; group = "Smart Rename/ RestartLSP"; }
          { __unkeyed-1 = "<leader>t"; group = "Tab"; }
          { __unkeyed-1 = "z"; group = "Folding"; }
          { __unkeyed-1 = "["; group = "Jump backwards"; }
          { __unkeyed-1 = "]"; group = "Jump forwards"; }
          { __unkeyed-1 = "<leader>\\"; group = "Toggle"; }
          { __unkeyed-1 = "g"; group = "LSP"; }
          { __unkeyed-1 = "<leader>l"; group = "[L]azy [G]it"; }
          { __unkeyed-1 = "<leader>m"; group = "[M]ake [P]retty"; }
          { __unkeyed-1 = "<leader>o"; group = "[O]bsidian"; }
          { __unkeyed-1 = "<leader>d"; group = "[D]ebug"; }
        ];
      };
    };

    zen-mode = {
      enable = true;
      settings = {
        window.options = {
          signcolumn = "no";
          number = false;
          relativenumber = false;
        };
        plugins = {
          twilight.enabled = true;
          tmux.enabled = true;
        };
      };
    };

    twilight = {
      enable = true;
      settings.dimming.alpha = 0.5;
    };
  };

  # Dropbar (breadcrumbs) via extraPlugins since nixvim may not have it built-in
  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [
    dropbar-nvim
  ];

  programs.nixvim.extraConfigLuaPost = ''
    -- Dropbar keymaps
    local dropbar_api = require("dropbar.api")
    vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
    vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
    vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
  '';

  # Nvim-tree keymaps
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>ee"; action = "<cmd>NvimTreeToggle<CR>"; options.desc = "Toggle file explorer"; }
    { mode = "n"; key = "<leader>ef"; action = "<cmd>NvimTreeFindFileToggle<CR>"; options.desc = "Toggle file explorer on current file"; }
    { mode = "n"; key = "<leader>ec"; action = "<cmd>NvimTreeCollapse<CR>"; options.desc = "Collapse file explorer"; }
    { mode = "n"; key = "<leader>er"; action = "<cmd>NvimTreeRefresh<CR>"; options.desc = "Refresh file explorer"; }
  ];
}
