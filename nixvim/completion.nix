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
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              if cmp.visible() then
                cmp.confirm({ select = true })
              elseif luasnip.jumpable(1) then
                luasnip.jump(1)
              else
                fallback()
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
    lspkind = {
      enable = true;
      cmp.enable = true;
      cmp.maxWidth = 50;
      cmp.ellipsisChar = "...";
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
