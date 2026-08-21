return {
	"hrsh7th/cmp-nvim-lsp",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/lazydev.nvim", opts = {} },
	},
	config = function()
		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- ════════════════════════════════════════════════════════════════════
		-- Custom LSP Server Configurations
		-- ════════════════════════════════════════════════════════════════════
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
						disable = { "inject-field", "undefined-field", "missing-fields" },
					},
					runtime = { version = "LuaJIT" },
					workspace = {
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
						checkThirdParty = false,
					},
					telemetry = { enable = false },
				},
			},
		})

		vim.lsp.config("ltex_plus", {
			capabilities = capabilities,
			settings = {
				ltex = {
					language = "en-US",
					disabledRules = {
						["en-US"] = {
							"MORFOLOGIK_RULE_EN_US",
							"EN_QUOTES",
							"WHITESPACE_RULE",
							"UPPERCASE_SENTENCE_START",
							"CONSECUTIVE_SPACES",
						},
					},
					markdown = {
						nodes = { Link = "dummy" },
					},
				},
			},
		})

		-- Default config for all other servers
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		-- ════════════════════════════════════════════════════════════════════
		-- LSP Keymaps Setup
		-- ════════════════════════════════════════════════════════════════════
		local function setup_keymaps(bufnr)
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
			end

			-- Hover & Signature
			map("n", "K", vim.lsp.buf.hover, "Hover")
			map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

			-- gd, gD, gr, gi, gy handled by Snacks picker (snacks.lua)

			-- Diagnostics navigation
			map("n", "[d", function()
				vim.diagnostic.jump({ count = -1 })
			end, "Prev Diagnostic")
			map("n", "]d", function()
				vim.diagnostic.jump({ count = 1 })
			end, "Next Diagnostic")

			-- <leader>c = Code
			map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
			map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
			map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostic")
			map("n", "<leader>cv", "<cmd>vsplit | lua vim.lsp.buf.definition()<cr>", "Definition in Vsplit")

			-- <leader>l = LSP
			map("n", "<leader>li", "<cmd>checkhealth vim.lsp<cr>", "LSP Info")
			map("n", "<leader>lr", "<cmd>lsp restart *<cr>", "LSP Restart")
			map("n", "<leader>lh", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
			end, "Toggle Inlay Hints")
		end

		-- ════════════════════════════════════════════════════════════════════
		-- LSP Attach Handler
		-- ════════════════════════════════════════════════════════════════════
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
			callback = function(args)
				local bufnr = args.buf
				local client = vim.lsp.get_client_by_id(args.data.client_id)
				if not client then
					return
				end

				setup_keymaps(bufnr)
				vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

				-- Inlay hints disabled by default (toggle with <leader>lh)

				-- Document highlight on cursor hold
				if client:supports_method("textDocument/documentHighlight") then
					local group = vim.api.nvim_create_augroup("LspDocumentHighlight_" .. bufnr, { clear = true })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = bufnr,
						group = group,
						callback = vim.lsp.buf.document_highlight,
					})
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = bufnr,
						group = group,
						callback = vim.lsp.buf.clear_references,
					})
				end
			end,
		})

		-- ════════════════════════════════════════════════════════════════════
		-- Diagnostic Configuration
		-- ════════════════════════════════════════════════════════════════════
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
	end,
}
