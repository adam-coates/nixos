return {
	{
		"williamboman/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"lua_ls",
				"zls",
				"ts_ls",
				"rust_analyzer",
				"bashls",
				"pyright",
				"cssls",
				"html",
				"jsonls",
				"yamlls",
				"ltex_plus",
				"tinymist",
			},
		},
		dependencies = {
			{
				"williamboman/mason.nvim",
				opts = {
					ui = {
						icons = {
							package_installed = "✓",
							package_pending = "➜",
							package_uninstalled = "✗",
						},
					},
				},
			},
			"neovim/nvim-lspconfig",
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = {
			ensure_installed = {
				-- Linters
				"eslint_d",
				"luacheck",
				"shellcheck",
				"markdownlint",
				"yamllint",
				"jsonlint",
				"htmlhint",
				"stylelint",
				"phpstan",
				"ruff",
				"mypy",
				-- Formatters
				"stylua",
				"prettier",
				"black",
				"isort",
				"shfmt",
			},
		},
		dependencies = {
			"williamboman/mason.nvim",
		},
	},
}
