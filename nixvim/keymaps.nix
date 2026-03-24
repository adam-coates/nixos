{ ... }:

{
  programs.nixvim.keymaps = [
    # Replace current word
    { mode = "n"; key = "<leader>s"; action = ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>"; options.desc = "Replace current word"; }

    # Window management
    { mode = "n"; key = "<leader>sv"; action = "<C-w>v"; options.desc = "Split window vertically"; }
    { mode = "n"; key = "<leader>sh"; action = "<C-w>s"; options.desc = "Split window horizontally"; }
    { mode = "n"; key = "<leader>se"; action = "<C-w>="; options.desc = "Make splits equal size"; }
    { mode = "n"; key = "<leader>sx"; action = "<cmd>close<CR>"; options.desc = "Close current split"; }

    # Scroll in middle
    { mode = "n"; key = "<C-d>"; action = "<C-d>zz"; }
    { mode = "n"; key = "<C-u>"; action = "<C-u>zz"; }

    # Visual paste without overwriting register
    { mode = "x"; key = "p"; action = "\"_dP"; }

    # Move selected lines up or down
    { mode = "v"; key = "J"; action = ":m '>+1<CR>gv=gv"; }
    { mode = "v"; key = "K"; action = ":m '<-2<CR>gv=gv"; }

    # Better movement (wrap-aware)
    { mode = "n"; key = "j"; action = "gj"; options = { noremap = true; silent = true; }; }
    { mode = "n"; key = "k"; action = "gk"; options = { noremap = true; silent = true; }; }
    { mode = "v"; key = "j"; action = "gj"; options = { noremap = true; silent = true; }; }
    { mode = "v"; key = "k"; action = "gk"; options = { noremap = true; silent = true; }; }
  ];

  # Obsidian note creation keybinding (complex, done in Lua)
  programs.nixvim.extraConfigLuaPost = ''
    vim.keymap.set("n", "<leader>on", function()
      if vim.fn.bufname("%") == "" and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
        local title = vim.fn.input("Enter note title: ")
        if title == "" then
          print("Title cannot be empty!")
          return
        end
        local dir = vim.fn.expand("~/notes/00 - Inbox/")
        local filename = dir .. title .. ".md"
        vim.fn.mkdir(dir, "p")
        vim.cmd("edit " .. filename)
        vim.cmd("write")
      end
      local original_cwd = vim.fn.getcwd()
      vim.cmd("cd ~/notes")
      vim.cmd(":Obsidian template note")
      vim.cmd("cd " .. original_cwd)
    end, { desc = "Create Obsidian note with template" })
  '';
}
