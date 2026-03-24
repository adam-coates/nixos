{ pkgs, ... }:

let
  # Custom plugin: printer.nvim
  printer-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "printer-nvim";
    version = "latest";
    src = pkgs.fetchFromGitHub {
      owner = "adam-coates";
      repo = "printer.nvim";
      rev = "main";
      sha256 = pkgs.lib.fakeHash;
    };
  };

  # Custom plugin: markdown-preview.nvim (custom fork)
  markdown-preview-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "markdown-preview-nvim";
    version = "latest";
    src = pkgs.fetchFromGitHub {
      owner = "adam-coates";
      repo = "markdown-preview.nvim";
      rev = "master";
      sha256 = pkgs.lib.fakeHash;
    };
  };
in
{
  programs.nixvim = {
    # Avante (AI assistant)
    extraPlugins = with pkgs.vimPlugins; [
      avante-nvim
      nui-nvim
      copilot-lua
      printer-nvim
      markdown-preview-nvim
      # Quarto ecosystem
      quarto-nvim
      otter-nvim
      vim-slime
      # Zotcite
      zotcite
    ];

    extraConfigLuaPost = ''
      -- Avante setup
      require("avante").setup({
        provider = "gemini",
        providers = {
          gemini = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.5-flash",
            timeout = 30000,
            temperature = 0,
            max_tokens = 8192,
          },
          ollama = {
            endpoint = "http://127.0.0.1:11434",
            model = "kimi-k2.5:cloud",
          },
        },
      })

      -- Printer setup
      require("printer").setup({
        python_cmd = "uv run",
        printer_vendor_id = "0x04B8",
        printer_product_id = "0x0E39",
        line_width = 48,
      })
      vim.api.nvim_create_user_command("PrintBuffer", require("printer").print_buffer, {})
      vim.api.nvim_create_user_command("PrintLine", require("printer").print_current_line, {})
      vim.api.nvim_create_user_command("PrintLive", require("printer").toggle_live_mode, {})
      vim.keymap.set("n", "<leader>pb", require("printer").print_buffer, { desc = "Print buffer" })
      vim.keymap.set("n", "<leader>pl", require("printer").print_current_line, { desc = "Print current line" })
      vim.keymap.set("v", "<leader>pp", require("printer").print_selection, { desc = "Print selection" })
      vim.keymap.set("n", "<leader>pL", require("printer").toggle_live_mode, { desc = "Toggle live printing" })

      -- Markdown preview
      vim.g.mkdp_filetypes = { "markdown" }

      -- Quarto setup
      require("quarto").setup({
        lspFeatures = {
          enabled = true,
          chunks = "curly",
          languages = { "r", "python", "julia", "bash", "html" },
          diagnostics = { enabled = true, triggers = { "BufWritePost" } },
          completion = { enabled = true },
        },
        codeRunner = { enabled = true, default_method = "slime" },
      })

      local quarto = require("quarto")
      local runner = require("quarto.runner")
      vim.keymap.set("n", "<leader>qp", quarto.quartoPreview, { desc = "Quarto Preview" })
      vim.keymap.set("n", "<leader>qq", quarto.quartoClosePreview, { desc = "Quarto Close Preview" })
      vim.keymap.set("n", "<leader>qa", "<cmd>QuartoActivate<cr>", { desc = "Quarto Activate" })

      -- Otter setup
      require("otter").setup({ buffers = { set_filetype = true } })

      -- Vim-slime setup
      vim.g.slime_target = "tmux"
      vim.g.slime_no_mappings = true
      vim.g.slime_python_ipython = 1
      vim.g.slime_dont_ask_default = 1
      vim.g.slime_default_config = { socket_name = "default", target_pane = "{right-of}" }
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false

      vim.b["quarto_is_python_chunk"] = false
      Quarto_is_in_python_chunk = function()
        require("otter.tools.functions").is_otter_language_context("python")
      end

      vim.cmd([[
        let g:slime_dispatch_ipython_pause = 100
        function SlimeOverride_EscapeText_quarto(text)
          call v:lua.Quarto_is_in_python_chunk()
          if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk && !(exists('b:quarto_is_r_mode') && b:quarto_is_r_mode)
            return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
          else
            if exists('b:quarto_is_r_mode') && b:quarto_is_r_mode && b:quarto_is_python_chunk
              return [a:text, "\n"]
            else
              return [a:text]
            endif
          endif
        endfunction
      ]])

      -- REPL pane management
      _G.repl_panes = { python = nil, r = nil, bash = nil }

      _G.get_current_language = function()
        local ok, otter = pcall(require, "otter.tools.functions")
        if ok then
          if otter.is_otter_language_context("python") then return "python"
          elseif otter.is_otter_language_context("r") then return "r"
          end
        end
        local ft = vim.bo.filetype
        if ft == "python" then return "python"
        elseif ft == "r" then return "r"
        end
        return "bash"
      end

      _G.update_slime_config = function()
        local lang = _G.get_current_language()
        local pane = _G.repl_panes[lang]
        if pane then
          vim.b.slime_config = { socket_name = "default", target_pane = pane }
          vim.cmd(string.format([[let b:slime_config = {"socket_name": "default", "target_pane": "%s"}]], pane))
        else
          vim.b.slime_config = { socket_name = "default", target_pane = "{right-of}" }
          vim.cmd([[let b:slime_config = {"socket_name": "default", "target_pane": "{right-of}"}]])
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "quarto", "markdown", "python", "r" },
        callback = function()
          vim.cmd([[let b:slime_config = {"socket_name": "default", "target_pane": "{right-of}"}]])
          vim.b.slime_config = { socket_name = "default", target_pane = "{right-of}" }
        end,
      })

      vim.cmd([[
        function! SlimeOverride_ConfigureTarget()
          if !exists('b:slime_config')
            let b:slime_config = {"socket_name": "default", "target_pane": "{right-of}"}
          endif
          call luaeval('_G.update_slime_config()')
          return b:slime_config
        endfunction
      ]])

      local function start_repl(repl_type, repl_cmd)
        local panes_before = vim.fn.systemlist("tmux list-panes -F '#{pane_id}'")
        vim.fn.system(string.format("tmux split-window -h '%s'", repl_cmd))
        vim.defer_fn(function()
          local panes_after = vim.fn.systemlist("tmux list-panes -F '#{pane_id}'")
          local new_pane = nil
          for _, pane in ipairs(panes_after) do
            local found = false
            for _, old_pane in ipairs(panes_before) do
              if pane == old_pane then found = true; break end
            end
            if not found then new_pane = pane; break end
          end
          if new_pane then
            _G.repl_panes[repl_type] = new_pane
            print(string.format("%s REPL started in pane %s", repl_type, new_pane))
            _G.update_slime_config()
          else
            print(string.format("Warning: Could not detect new pane for %s", repl_type))
          end
        end, 300)
      end

      vim.keymap.set("n", "<leader>cip", function() start_repl("python", "ipython") end, { desc = "Start IPython REPL" })
      vim.keymap.set("n", "<leader>cir", function() start_repl("r", "R") end, { desc = "Start R REPL" })
      vim.keymap.set("n", "<leader>cib", function() start_repl("bash", "bash") end, { desc = "Start Bash REPL" })

      vim.keymap.set("n", "<leader>cl", function()
        print("REPL Panes:")
        for lang, pane in pairs(_G.repl_panes) do
          if pane then print(string.format("  %s: %s", lang, pane)) end
        end
        print("Current language: " .. _G.get_current_language())
        _G.update_slime_config()
      end, { desc = "List REPL panes and update config" })

      vim.keymap.set("n", "<leader>cm", function() vim.fn.call("slime#config", {}) end, { desc = "Slime config/set terminal" })

      vim.keymap.set("n", "<c-c><c-c>", function()
        _G.update_slime_config()
        vim.cmd("SlimeSendCell")
      end, { desc = "Send cell to REPL" })

      vim.keymap.set("x", "<c-c><c-c>", function()
        _G.update_slime_config()
        vim.cmd("'<,'>SlimeRegionSend")
      end, { desc = "Send selection to REPL" })

      -- Quarto runner keymaps
      vim.keymap.set("n", "<localleader>rc", function() _G.update_slime_config(); require("quarto.runner").run_cell() end, { desc = "Run cell" })
      vim.keymap.set("n", "<localleader>ra", function() _G.update_slime_config(); require("quarto.runner").run_above() end, { desc = "Run cell and above" })
      vim.keymap.set("n", "<localleader>rb", function() _G.update_slime_config(); require("quarto.runner").run_below() end, { desc = "Run cell and below" })
      vim.keymap.set("n", "<localleader>rA", function() _G.update_slime_config(); require("quarto.runner").run_all() end, { desc = "Run all cells" })
      vim.keymap.set("n", "<localleader>rl", function() _G.update_slime_config(); require("quarto.runner").run_line() end, { desc = "Run line" })
      vim.keymap.set("v", "<localleader>r", function() _G.update_slime_config(); require("quarto.runner").run_range() end, { desc = "Run visual range" })

      -- Zotcite setup
      require("zotcite").setup({
        zotero_sqlite_path = "/home/adam/Zotero/zotero.sqlite",
        attach_dir = "/home/adam/Nextcloud/zotero",
        open_in_zotero = true,
      })
    '';
  };
}
