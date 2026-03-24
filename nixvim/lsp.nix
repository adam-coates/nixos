{ pkgs, ... }:

{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;

      servers = {
        lua_ls = {
          enable = true;
          settings = {
            Lua = {
              diagnostics = {
                globals = [ "vim" ];
                disable = [ "inject-field" "undefined-field" "missing-fields" ];
              };
              runtime.version = "LuaJIT";
              workspace.checkThirdParty = false;
              telemetry.enable = false;
            };
          };
        };

        ltex = {
          enable = true;
          settings = {
            ltex = {
              language = "en-US";
              disabledRules = {
                "en-US" = [
                  "MORFOLOGIK_RULE_EN_US"
                  "EN_QUOTES"
                  "WHITESPACE_RULE"
                  "UPPERCASE_SENTENCE_START"
                  "CONSECUTIVE_SPACES"
                ];
              };
              markdown.nodes = { Link = "dummy"; };
            };
          };
        };

        ts_ls.enable = true;
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
        };
        pyright.enable = true;
        bashls.enable = true;
        cssls.enable = true;
        html.enable = true;
        jsonls.enable = true;
        yamlls.enable = true;
      };

      keymaps = {
        lspBuf = {
          "K" = { action = "hover"; desc = "Hover"; };
          "<leader>ca" = { action = "code_action"; desc = "Code Action"; };
          "<leader>cr" = { action = "rename"; desc = "Rename Symbol"; };
        };

        extra = [
          { mode = [ "n" "i" ]; key = "<C-k>"; action.__raw = "vim.lsp.buf.signature_help"; options.desc = "Signature Help"; }
          { mode = "n"; key = "[d"; action.__raw = "function() vim.diagnostic.jump({ count = -1 }) end"; options.desc = "Prev Diagnostic"; }
          { mode = "n"; key = "]d"; action.__raw = "function() vim.diagnostic.jump({ count = 1 }) end"; options.desc = "Next Diagnostic"; }
          { mode = "n"; key = "<leader>cd"; action.__raw = "vim.diagnostic.open_float"; options.desc = "Line Diagnostic"; }
          { mode = "n"; key = "<leader>cv"; action = "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>"; options.desc = "Definition in Vsplit"; }
          { mode = "n"; key = "<leader>li"; action = "<cmd>LspInfo<cr>"; options.desc = "LSP Info"; }
          { mode = "n"; key = "<leader>lr"; action = "<cmd>LspRestart<cr>"; options.desc = "LSP Restart"; }
          {
            mode = "n"; key = "<leader>lh";
            action.__raw = ''
              function()
                local bufnr = vim.api.nvim_get_current_buf()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
              end
            '';
            options.desc = "Toggle Inlay Hints";
          }
        ];
      };
    };

    # Diagnostic configuration
    diagnostic = {
      virtual_text = true;
      underline = true;
      update_in_insert = false;
      severity_sort = true;
      float = { border = "rounded"; source = true; header = ""; prefix = ""; };
      signs = {
        text = {
          "__rawKey__vim.diagnostic.severity.ERROR" = "󰅚 ";
          "__rawKey__vim.diagnostic.severity.WARN" = "󰀪 ";
          "__rawKey__vim.diagnostic.severity.INFO" = "󰋽 ";
          "__rawKey__vim.diagnostic.severity.HINT" = "󰌶 ";
        };
        numhl = {
          "__rawKey__vim.diagnostic.severity.ERROR" = "ErrorMsg";
          "__rawKey__vim.diagnostic.severity.WARN" = "WarningMsg";
        };
      };
    };

    # LSP file operations
    plugins.lsp-file-operations.enable = true;

    # Lazydev for Neovim Lua development
    plugins.lazydev.enable = true;

    # Document highlight on cursor hold
    extraConfigLuaPost = ''
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspHighlight", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end
          vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
          if client.server_capabilities.documentHighlightProvider then
            local group = vim.api.nvim_create_augroup("LspDocumentHighlight_" .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = bufnr, group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = bufnr, group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    '';
  };
}
