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
                disable = [
                  "inject-field"
                  "undefined-field"
                  "missing-fields"
                ];
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
              markdown.nodes = {
                Link = "dummy";
              };
            };
          };
        };

        nixd = {
          enable = true;
          rootMarkers = [
            "flake.nix"
            ".git"
          ];
          settings = {
            nixd = {
              formatting.command = [ "nixfmt" ];
              nixpkgs.expr = "import <nixpkgs> { }";
              options.nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.YOUR_HOSTNAME.options";
              # options.home-manager.expr =
              #   "(builtins.getFlake (builtins.toString ./.)).homeConfigurations.\"YOUR_USER@YOUR_HOSTNAME\".options";
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
          "K" = {
            action = "hover";
            desc = "Hover";
          };
          "<leader>ca" = {
            action = "code_action";
            desc = "Code Action";
          };
          "<leader>cr" = {
            action = "rename";
            desc = "Rename Symbol";
          };
        };

        extra = [
          {
            mode = [
              "n"
              "i"
            ];
            key = "<C-k>";
            action.__raw = "vim.lsp.buf.signature_help";
            options.desc = "Signature Help";
          }
          {
            mode = "n";
            key = "[d";
            action.__raw = "function() vim.diagnostic.jump({ count = -1 }) end";
            options.desc = "Prev Diagnostic";
          }
          {
            mode = "n";
            key = "]d";
            action.__raw = "function() vim.diagnostic.jump({ count = 1 }) end";
            options.desc = "Next Diagnostic";
          }
          {
            mode = "n";
            key = "<leader>cd";
            action.__raw = "vim.diagnostic.open_float";
            options.desc = "Line Diagnostic";
          }
          {
            mode = "n";
            key = "<leader>cv";
            action = "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>";
            options.desc = "Definition in Vsplit";
          }
          {
            mode = "n";
            key = "<leader>li";
            action = "<cmd>checkhealth vim.lsp<cr>";
            options.desc = "LSP Info";
          }
          {
            mode = "n";
            key = "<leader>lr";
            action = "<cmd>lsp restart *<cr>";
            options.desc = "LSP Restart";
          }
          {
            mode = "n";
            key = "<leader>lh";
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

    # LSP file operations
    plugins.lsp-file-operations.enable = true;

    # Lazydev for Neovim Lua development
    plugins.lazydev.enable = true;

    # Diagnostic configuration + document highlight on cursor hold
    extraConfigLuaPost = ''
      -- Diagnostic configuration (vim.diagnostic.config)
      vim.diagnostic.config({
        virtual_text = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded", source = true, header = "", prefix = "" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "󰅚 ",
            [vim.diagnostic.severity.WARN] = "󰀪 ",
            [vim.diagnostic.severity.INFO] = "󰋽 ",
            [vim.diagnostic.severity.HINT] = "󰌶 ",
          },
          numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
          },
        },
      })

      -- Document highlight on cursor hold
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspHighlight", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end
          if client:supports_method("textDocument/documentHighlight") then
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
