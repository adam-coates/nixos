{ ... }:

{
  programs.nixvim.plugins = {
    cmp = {
      enable = true;

      settings = {
        completion.completeopt = "menu,menuone,preview,noselect";

        snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";

        mapping = {
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = false })";
          # Tab: confirm -> jump snippet -> plain Tab on leading whitespace ->
          # otherwise open the completion menu (matches check_back_space in the
          # upstream dotfiles config).
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              local function check_back_space()
                local col = vim.fn.col(".") - 1
                return col == 0 or vim.fn.getline("."):sub(col, col):match("%s") ~= nil
              end
              if cmp.visible() then
                cmp.confirm({ select = true })
              elseif luasnip.jumpable(1) then
                luasnip.jump(1)
              elseif check_back_space() then
                fallback()
              else
                cmp.complete()
              end
            end, { "i", "s" })
          '';
          "<S-Tab>" = ''
            cmp.mapping(function()
              require('luasnip').jump(-1)
            end, { "i", "s" })
          '';
        };

        sources = [
          { name = "luasnip"; }
          { name = "nvim_lsp"; }
          { name = "buffer"; }
          { name = "path"; }
        ];
      };
    };

    luasnip = {
      enable = true;
      fromVscode = [ {} ];
      settings = {
        store_selection_keys = "<C-s>";
      };
    };

    friendly-snippets.enable = true;
    # `cmp` is an extraOption (the cmp integration switch); everything under
    # `settings` is passed verbatim to `lspkind.cmp_format`, so the option is
    # spelled `maxwidth` and must NOT be nested under `cmp`.
    lspkind = {
      enable = true;
      cmp.enable = true;
      settings = {
        maxwidth = 50;
        ellipsis_char = "...";
      };
    };
    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp-path.enable = true;
    cmp_luasnip.enable = true;
  };

  # Extend luasnip quarto filetype and snippet keymaps
  programs.nixvim.extraConfigLuaPost = ''
    require("luasnip").filetype_extend("quarto", { "markdown" })

    vim.keymap.set({ "i", "s" }, "<C-s>", function()
      if require("luasnip").expandable() then
        require("luasnip").expand({})
      end
    end)

    vim.api.nvim_set_keymap("i", "<C-u>",
      '<cmd>lua require("luasnip.extras.select_choice")()<CR>',
      { noremap = true })
  '';
}
